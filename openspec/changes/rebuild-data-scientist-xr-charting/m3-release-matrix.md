# M3 WebXR Release-Candidate Matrix

Status: **experimental flat-web release candidate; not yet a supported WebXR release**.

This matrix separates export/browser evidence from physical immersive certification. Blank or pending headset fields are release blockers, not implied support.

## Build and deployment contract

| Field | Baseline candidate |
| --- | --- |
| Measurement date | 2026-07-17 |
| Godot | 4.6.3.stable.official.7d41c59c4, standard build |
| Preset | `examples/m1/export_presets.cfg`, `Web` |
| Renderer | Compatibility / WebGL 2.0 |
| Runtime | Pure GDScript; single-threaded; extension support disabled; no .NET or native libraries |
| Artifacts | `index.html`, JavaScript, WebAssembly, PCK, generated icons |
| Production origin | HTTPS; localhost HTTP is development-only |
| Live transport | WSS with an explicit server-side Origin allowlist; credentials must use an authorized exchange rather than URL parameters |
| Isolation | Baseline does not require COOP/COEP, `SharedArrayBuffer`, or cross-origin isolation |

Production responses must use `text/html` for HTML, `text/javascript` for JavaScript, `application/wasm` for WebAssembly, `application/octet-stream` for PCK, and the corresponding image media types. `index.html` must revalidate on every release; because generated companion names are stable rather than content-hashed, JavaScript, WebAssembly, and PCK must also revalidate or be versioned by the deployment path. The baseline Content Security Policy is `default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; connect-src 'self' wss:; worker-src 'self' blob:; object-src 'none'; base-uri 'none'; frame-ancestors 'none'`. Narrower `connect-src` WSS origins are preferred in production. Same-origin assets need no CORS; cross-origin assets require explicit allowlists and must not introduce mixed content.

## Executed browser tier

| Tier | Host/runtime | Result | Inputs and capabilities | Measurements |
| --- | --- | --- | --- | --- |
| Flat-web Linux | Fedora Linux, kernel 7.1.3-201.fc44.x86_64; Brave 150.1.92.140; headless SwiftShader WebGL 2.0; 1280×720 requested window | Pass: release Wasm startup, revision 1/four points, keyboard move/commit, failed-WSS offline preservation, WebXR-unavailable explanation, deterministic reload | Keyboard verified through trusted CDP events. Pointer command parity passes the Godot UI suite. Headless Brave did not translate trusted canvas mouse events into Godot `Control` activation, so physical pointer use remains a manual browser check. WebXR unavailable in this tier. | 180 `requestAnimationFrame` samples: 16.7 ms median, 16.8 ms p95/max. Five command-to-published-state samples: 49.2 ms median, 53.9 ms max with 10 ms harness polling. JavaScript heap: 17,336,956 used / 25,804,800 allocated bytes. |

These numbers characterize this host and software renderer only. They are regression evidence, not a claim about mobile GPU, headset, stereo, motion-to-photon, or thermal performance.

Set `M3_REPORT_PATH=/path/to/report.json` when running `scripts/test-web-browser.sh` to retain the measured state, frame timing, command latency, and heap result as a JSON artifact.

## Candidate budgets and content limits

| Area | Candidate gate | Current evidence |
| --- | --- | --- |
| Flat-web 60 Hz frame interval | median ≤16.8 ms, p95 ≤20 ms over at least 180 warm frames | Pass on the executed Brave tier |
| Flat-web command update | published semantic state ≤75 ms p95 over at least 20 commands | Five samples pass the ceiling; sample count is not yet sufficient for release statistics |
| Browser JS heap | ≤64 MiB used after recorded-scene warm-up and replay | Pass on the four-point fixture |
| 72 Hz stereo WebXR | p95 ≤13.9 ms with no sustained missed-frame sequence | Pending physical headset measurement |
| 90 Hz stereo WebXR | p95 ≤11.1 ms with no sustained missed-frame sequence | Optional enhanced tier; pending |
| Protocol message | ≤1,048,576 bytes | Enforced by the transport contract |
| Normalized table | ≤10,000 rows, 64 columns | Protocol-advertised limit; graphical limit not certified at this maximum |
| Figure layers | ≤16 | Protocol-advertised limit; graphical limit not certified at this maximum |
| Current certified fixture | Four scatter rows, one layer, one bounded linked table | Browser and deterministic test coverage |

## Required physical WebXR tier

At least one row below must pass before M3.7 can close or the release can be labeled WebXR-supported.

Execute [the physical-headset testing runbook](../../../docs/webxr-headset-testing.md) for each candidate row.

| Headset | Browser/runtime version | Refresh/render scale | Reference space | Baseline input | Enhancements | Stereo p50/p95/max | Update latency | Memory | 15-minute thermal/degradation | Result |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Pending representative standalone or tethered headset | Pending | Pending | Must prove `local-floor`; record fallback if used | Pose + ray + select required | Squeeze and hands optional | Pending | Pending | Pending | Pending | Blocked on device run |

The physical run must prove user-gesture entry, readable authored pose/scale, ray/select frame focus and a reversible move/commit, revision preservation, explicit exit, runtime/session loss back to flat web, reset, controller profile reporting, and absence of a hand-only critical workflow. Record mono mirror and stereo timing separately, plus browser/headset memory telemetry when available. If the runtime exposes no reliable memory or thermal API, record the vendor telemetry source or explicitly mark the measurement unavailable and use observed throttling/frame degradation as the operational signal.

## Known limitations

- No physical WebXR runtime, stereo frame budget, controller profile, hand-tracking, or thermal evidence has been collected yet.
- The current graphical browser fixture is intentionally small; protocol maxima are not graphical capacity claims.
- Headless SwiftShader is useful for deterministic release smoke coverage but is not representative of headset GPU behavior.
- Baseline ray/select is implemented and deterministic adapter parity is tested; squeeze and hand tracking remain progressive enhancements rather than certified inputs.
- The release remains experimental until the required physical row passes.
