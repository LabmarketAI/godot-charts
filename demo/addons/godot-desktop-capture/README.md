# godot-desktop-capture

A Godot 4 GDExtension that streams a live capture of an OS desktop monitor into a `Texture2D`. Assign it to any material or `Viewport2Din3D` to display your desktop inside a Godot scene — useful for VR virtual-desktop setups, streaming overlays, and similar applications.

**Platform support**

| Platform | Backend | Status |
|----------|---------|--------|
| Windows 8+ | DXGI Desktop Duplication | ✅ Available |
| Linux | xdg-desktop-portal + PipeWire | 🚧 Planned (#5) |
| macOS | — | Not planned |

---

## Installation (Windows)

### Option A — Pre-built binary (recommended)

1. Download the latest `godot-desktop-capture-<version>.zip` from the [Releases](../../releases) page.
2. Extract the `addons/` folder into the root of your Godot project so the layout is:
   ```
   res://addons/godot-desktop-capture/
       godot-desktop-capture.gdextension
       bin/
           libgodot-desktop-capture.windows.release.x86_64.dll
           libgodot-desktop-capture.windows.debug.x86_64.dll
   ```
3. Reload the project (`Project → Reload Current Project`). The `DesktopCaptureTexture` class will be available immediately — no plugin toggle required.

### Option B — Build from source

**Prerequisites**: Python 3, SCons, Git, MinGW-w64 (or MSVC).

```bash
git clone --recurse-submodules https://github.com/LabmarketAI/godot-desktop-capture.git
cd godot-desktop-capture

# Release build (recommended for shipping)
scons target=template_release platform=windows arch=x86_64

# Debug build
scons target=template_debug platform=windows arch=x86_64
```

The compiled `.dll` is written to `project/addons/godot-desktop-capture/bin/`. Copy the `project/addons/` folder into your project as described in Option A.

> **Note**: DXGI Desktop Duplication is a Windows 8+ API. Building requires no additional SDKs — `dxgi.lib` and `d3d11.lib` ship with MinGW-w64 and MSVC.

---

## Usage

### Basic — display desktop on a mesh

```gdscript
extends MeshInstance3D

func _ready() -> void:
    var capture := DesktopCaptureTexture.new()
    capture.monitor_index = 0     # primary monitor
    capture.capture_cursor = true
    capture.max_fps = 60

    # Assign before enabling so the material is ready when the first frame arrives.
    var mat := StandardMaterial3D.new()
    mat.albedo_texture = capture
    set_surface_override_material(0, mat)

    capture.capture_stopped.connect(_on_capture_stopped)
    capture.enabled = true

func _on_capture_stopped(reason: String) -> void:
    push_warning("Capture stopped: " + reason)
```

### Multi-monitor

```gdscript
var capture := DesktopCaptureTexture.new()
print("Monitors available: ", capture.get_monitor_count())

for i in capture.get_monitor_count():
    print("  Monitor %d: %s" % [i, capture.get_monitor_size(i)])

capture.monitor_index = 1  # switch to second monitor
capture.enabled = true
```

### Error handling

```gdscript
capture.capture_stopped.connect(func(reason: String) -> void:
    match reason:
        "permission_denied":
            push_warning("Screen capture permission was denied.")
        "device_lost":
            push_warning("GPU/display device lost — try re-enabling.")
        "monitor_index_out_of_range":
            push_error("monitor_index %d does not exist." % capture.monitor_index)
        _:
            push_warning("Capture stopped: " + reason)
)
```

---

## API reference

### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `enabled` | `bool` | `false` | Start (`true`) or stop (`false`) the capture loop |
| `monitor_index` | `int` | `0` | Zero-based index of the monitor to capture |
| `capture_cursor` | `bool` | `true` | Composite the OS mouse cursor onto each frame |
| `max_fps` | `int` | `60` | Capture rate cap (1–240 fps) |

`enabled` is always truthful: if `set enabled = true` but the backend fails to start, `enabled` reverts to `false` and `capture_stopped(reason)` is emitted.

### Methods

| Signature | Description |
|-----------|-------------|
| `get_monitor_count() -> int` | Number of monitors detected by the platform backend |
| `get_monitor_size(index: int) -> Vector2i` | Pixel dimensions of the monitor at `index` |

### Signals

| Signal | Description |
|--------|-------------|
| `capture_started` | Emitted once the backend initialises successfully |
| `capture_stopped(reason: String)` | Emitted when capture stops for any reason |
| `frame_updated` | Emitted after each new frame is written to the texture |

### `capture_stopped` reason values

| Value | Meaning |
|-------|---------|
| `"disabled"` | Caller set `enabled = false` |
| `"device_lost"` | GPU/display device lost and could not recover |
| `"permission_denied"` | OS security policy refused screen capture |
| `"missing_dependency"` | Required runtime library not found |
| `"monitor_index_out_of_range"` | `monitor_index >= get_monitor_count()` |
| `"unsupported_platform"` | No backend available on this platform |

---

## Requirements

- Godot 4.1 or later
- Windows 8 or later (for the DXGI backend)
- The process must be running in an interactive desktop session. DXGI Desktop Duplication is a per-session API — it only works when the calling process has access to the visible desktop of the logged-in user. Common situations where capture will silently return black frames or fail with `permission_denied` / `device_lost`:
  - **Locked screen** (`Win+L` or unattended timeout) — the secure desktop is a separate session; `DuplicateOutput` returns `E_ACCESSDENIED`. The backend will attempt to recover automatically when the screen is unlocked (up to ~1 second of retries).
  - **Remote Desktop (RDP)** — the local console session is disconnected when an RDP session takes over. The RDP session itself has its own virtual desktop and *can* run DXGI capture, but only from within that session.
  - **Headless / no-display servers** — machines without a physical or virtual display adapter attached will have no outputs to enumerate; `get_monitor_count()` returns 0.
  - **Windows services and scheduled tasks** — these run in Session 0, which is isolated from all interactive user sessions. DXGI Desktop Duplication is not available in Session 0.
  - **UAC elevation prompt** — while the secure desktop is shown for a UAC dialog, capture of the interactive desktop is suspended. Frames will resume automatically once the prompt is dismissed.
