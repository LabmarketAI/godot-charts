# Blender / 3D Asset Prompting Guide

This guide defines what every asset-generation or Blender-authoring prompt must include before we create chart components. It applies to Codex-driven Blender MCP work, artist briefs, and any ComfyUI/Text-to-3D concept pass that might later become a GLB draft.

## Research Basis

- Text-to-3D prompt guidance consistently recommends placing the object/subject first, then form, material/texture, art style, use case, and technical constraints. Meshy’s guide frames this as subject + material/texture + art style + technical specs and warns that clarity matters more than length: https://docs.meshy.ai/en/webapp/guides/prompting
- Other text-to-3D guides make the same practical point: describe shape and form, name materials, state the use case, avoid multiple unrelated objects, avoid contradictory descriptors, and provide scale/platform constraints: https://www.meshy.ai/tutorials/text-to-3d-model-tutorial and https://magicobj.com/blog/how-to-write-3d-generation-prompts
- Android XR recommends accessible target sizing, hover/focus states, non-overlapping pointer targets, 8dp spacing, 56dp or larger recommended interactive targets, and a 1.75m launch/viewing distance for panels: https://developer.android.com/design/ui/xr/guides/visual-design
- Apple spatial-layout guidance distinguishes fixed and dynamic scale; AR guidance warns not to fake distance by scaling and recommends accepting near misses for small/distant interactive objects: https://developer.apple.com/design/human-interface-guidelines/spatial-layout/ and https://developer.apple.com/design/human-interface-guidelines/augmented-reality
- W3C WCAG 2.2 defines baseline accessibility criteria relevant to chart assets, including non-text contrast, focus visibility, dragging alternatives, target size, labels/names/roles/values, and predictable input: https://w3c.github.io/wcag/guidelines/22/
- W3C XR Accessibility User Requirements should inform immersive extensions beyond flat WCAG, especially alternate input modes, captions/text alternatives, orientation, comfort, and avoiding barriers from spatial presentation: https://www.w3.org/TR/xaur/

## Prompt Formula

Use this order for every asset prompt:

1. **Role and object**
   - Stable role id and concrete object.
   - Example: `control/handle_linear: a linear axis-domain endpoint handle`.

2. **Chart function**
   - What analytical operation it supports.
   - Example: `used to drag the min/max endpoint of an x, y, or z axis domain`.

3. **Diegetic scale**
   - Real-world dimensions in meters/centimeters and expected viewing/interaction distance.
   - Example: `visible body 10 cm diameter, collision target 16 cm, intended for controller ray and direct reach at 0.6-1.5 m`.

4. **Interaction vocabulary**
   - Allowed operations and state feedback.
   - Example: `normal, hover, focus, active-drag, invalid constraint, disabled; supports ray select and direct grab; no gaze-only affordance`.

5. **Lookbook theme**
   - One target theme and optional variants.
   - Example: `WebXR Dark Instrument, professional matte instrument control, not toy-like, not neon arcade`.

6. **Shape and silhouette**
   - Geometric proportions, key forms, symmetry, readable silhouette, exact value-bearing surfaces.
   - Example: `rounded capsule puck with shallow grip groove and separate focus ring; symmetric; no thin floating parts`.

7. **Material and shader policy**
   - PBR/unshaded choice, roughness, metallic, alpha/emission limits, semantic slots.
   - Example: `nonmetal matte PBR body, high roughness, low emissive focus ring only, no glass, no chrome, no baked color state`.

8. **Professional polish**
   - Normals, smoothing, bevels, topology, export expectations.
   - Example: `shade smooth curved surfaces, sharp broad faces, small bevels with weighted normals, clean topology, no unintended low-poly faceting`.

9. **Accessibility / ADA baseline**
   - WCAG/XR-derived non-negotiables: contrast, focus, size, alternatives, labels.
   - Example: `3:1 non-text contrast for meaningful control outline, non-color active cue, accessible name/value metadata, target size meets XR pointer target guidance`.

10. **Performance and fallback**
    - Triangle/material budget, LOD, fallback role.
    - Example: `WebXR P0 low-poly-but-polished LOD, no shadows, <= target triangle budget, procedural fallback/minimal_handle`.

11. **Negative constraints**
    - What must not appear.
    - Example: `no labels baked into mesh, no decorative screws, no glass material, no background scene, no extra objects, no fused concept geometry`.

## Diegetic Scale Rules

Yes: prompts must set a diegetic scale. Chart assets are not abstract icons floating in isolation; they are objects inside a spatial analytical environment. Scale consistency prevents controls from feeling arbitrary and keeps frame manipulation, axis manipulation, labels, and selection targets usable across desktop and headset modes.

Baseline scale vocabulary:

| Concept | Prompt Guidance |
|---|---|
| World unit | Godot/Blender `1.0` unit = 1 meter |
| Standing analytical frame | authored center roughly chest/eye-zone friendly; avoid critical controls above comfortable reach |
| Primary chart viewing | design for roughly `1.0-2.0 m` comfortable viewing distance in headset |
| Panel/reference distance | use `1.75 m` as a reference for panel-like layout when applicable |
| Direct hand/controller reach | controls that must be grabbed should fit roughly `0.35-0.8 m` from user during active manipulation |
| Minimum near distance | avoid placing required interactive content closer than `0.5 m` to the eyes |
| Chart frame size | prompt as physical meters, not “large/small”; include intended use such as desk-scale, wall-scale, or room-scale |
| Control body | visible affordance can be smaller than collision proxy, but proxy must be declared |
| Collision proxy | should be larger than visual mesh for thin/small controls and never overlap unrelated targets |

Prompt example:

```text
Diegetic scale: chart frame component for a 1.2 m wide analytical frame viewed from 1.0-2.0 m; handle visible body 0.10 m, collision proxy 0.16 m, no required target closer than 0.5 m to viewer.
```

## Interaction Vocabulary

Prompts must obey the project interaction vocabulary so assets look and behave consistently:

| Vocabulary | Required asset cue |
|---|---|
| `normal` | quiet readable base state |
| `hover` | pointer-over cue; not color-only |
| `focus` | keyboard/ray/accessibility focus ring or outline |
| `selected` | persistent selection cue distinct from hover |
| `active` | pressed/grabbed/dragging cue |
| `disabled` | reduced affordance but still legible |
| `warning` | constraint or caution state; reserved status color plus shape/pattern |
| `error` | invalid state; reserved status color plus shape/pattern |
| `linked` | counterpart or linked-view state |
| `changed` | streaming/revision update cue |

Interaction prompts should specify:

- input modes: controller ray, direct grab, mouse/pointer, keyboard focus, touch where relevant
- operation: grab, press, drag, scrub, resize, rotate, reset, select, inspect
- affordance: shape, outline, icon socket, grip groove, ring, cursor, label anchor
- feedback: visual, optional audio/haptic hook, and reduced-motion alternative
- cancellation: visible active state must support cancel/release without ambiguity

Top-surface icons and state cues must not stack every possible cue into the default visible mesh. Use only the final intended visible mark geometry for the default asset. Do not place state previews, warning/error overlays, construction guides, or alternate icon variants on top of the asset as simultaneous visible meshes. If an icon is a cross, plus, minus, arrow, or other multi-stroke mark, the visible strokes must be coplanar, centered, and physically intersect or meet cleanly as one integrated symbol. State-specific overlays should be named sockets, metadata, hidden/disabled variants, or runtime-swapped geometry, not exported as stacked visible meshes.

Prompt example:

```text
Interaction vocabulary: supports controller ray select and direct grab; states normal/hover/focus/active/disabled/invalid; focus uses a separate raised ring and size cue, active uses a slight pressed inset plus outline, invalid uses a stripe shape and warning token, never color alone.
```

## Accessibility / ADA Baseline

Do not claim that an individual mesh is “ADA compliant” by itself. ADA compliance depends on the whole product, user flow, content, input alternatives, and deployment context. For asset prompts, require WCAG 2.2 AA-informed and XR accessibility-informed properties that support compliance:

- meaningful non-text controls and graphical states target at least `3:1` contrast against adjacent colors
- ordinary text targets at least `4.5:1`; large text at least `3:1`
- focus state is visible and not obscured
- color is never the only cue for state, category, warning, or error
- pointer targets meet or exceed minimum target guidance; XR targets should prefer larger 56dp-equivalent guidance where panel-like and practical
- dragging workflows have alternate controls or reset/step affordances where required
- assets expose name/role/value metadata through manifest/Godot provider, not baked text
- interaction does not require gaze dwell, precise pinching, two-hand input, or rapid motion unless an equivalent path exists
- motion/pulsing has a reduced-motion static fallback
- charts remain readable under light/dark/high-contrast themes
- small or distant controls use tolerant collision proxies rather than pixel-perfect geometry

Prompt example:

```text
Accessibility: visible focus ring with 3:1 non-text contrast, non-color active and invalid cues, accessible role/name/value metadata in manifest, large collision target for ray selection, no gaze-dwell-only interaction, reduced-motion fallback for pulse.
```

## Prompt Templates

### Blender MCP Prompt Template

```text
Create [role id]: [concrete asset object] for [chart function].

Scale: [world units and physical dimensions], intended viewing distance [m], interaction reach [m], visible body [cm], collision proxy [cm].

Theme: [Instrument Light | Editorial Presentation | WebXR Dark Instrument]. Mood: [professional attributes]. Avoid: [forbidden style].

Shape: [silhouette, proportions, symmetry, key geometry]. Value-bearing edges/surfaces that must remain exact: [list].

Interaction vocabulary: states [normal, hover, focus, selected, active, disabled, warning, error]; input modes [ray/direct/mouse/keyboard]; required cues [outline, groove, ring, stripe, etc.].

Materials/shaders: semantic slots [list], [PBR/unshaded], metallic [range], roughness [range], alpha/emission limits, no baked data values.

Polish: shade smooth [surfaces], sharp edges [surfaces], bevel radius [range], weighted normals [yes/no], clean topology, no unintended faceting.

Accessibility: contrast target, non-color cues, target size/collision, focus visibility, reduced-motion fallback, metadata needs.

Export: GLB-ready, collections [LOD0, LOD1, COLLISION, SOCKETS], object prefixes, no camera/light/concept geometry, procedural fallback [role].
```

### ComfyUI / Text-to-3D Draft Prompt Template

```text
[Single asset object], [shape and silhouette], [material], [one lookbook style], [use case], [scale cue], [technical constraints].

For a Godot WebXR charting asset. Professional polished geometry, clean topology, smooth curved surfaces, crisp intentional edges, matte nonmetal material, no background scene, no text labels, no decorative unrelated objects, no low-poly faceting unless explicitly requested.
```

Use ComfyUI output as draft/reference only. Before adoption, restate the result as a Blender MCP prompt and validate it through the manifest/polish gates.

## Example Prompts

### Axis Domain Handle

```text
Create control/handle_linear: a linear axis-domain endpoint handle for dragging min/max chart domains.

Scale: Godot/Blender units are meters. Visible body 0.10 m diameter, 0.035 m thick; collision proxy sphere 0.16 m; intended headset viewing 1.0-2.0 m and direct reach 0.35-0.8 m.

Theme: WebXR Dark Instrument. Professional matte analytical instrument, not toy-like, not neon arcade.

Shape: rounded capsule puck with shallow equatorial grip groove, flat center face for value alignment, separate focus ring socket. Symmetric around local origin. No thin floating parts.

Interaction vocabulary: normal, hover, focus, active-drag, invalid-constraint, disabled. Supports controller ray select and direct grab. Focus uses non-color ring; active uses slight inset and outline; invalid uses stripe geometry.

Materials/shaders: control_body matte PBR nonmetal roughness 0.75; control_focus unshaded/emissive low intensity; status_warning token; no glass, chrome, bloom, or baked labels.

Polish: shade smooth curved surfaces, preserve sharp center/value face, small bevels on exposed edges, weighted normals, no unintended low-poly faceting.

Accessibility: 3:1 non-text contrast on focus/invalid outlines, non-color state cues, accessible role/name/value manifest metadata, no gaze-dwell-only interaction, reduced-motion fallback.

Export: GLB-ready with LOD0, LOD1, COLLISION, SOCKETS collections; no cameras/lights/concept objects; fallback role fallback/minimal_handle.
```

### Axis Line and Tick Set

```text
Create structure/axis_line and structure/tick_major: precise structural guide assets for scientific 3D chart axes.

Scale: axis line authored as 1.0 m normalized length with scalable value axis; tick mark 0.045 m length, 0.006 m thickness for 1.0-2.0 m viewing.

Theme: Instrument Light. Crisp, quiet scientific guide geometry, low visual dominance.

Shape: straight rectangular or subtle round tube line with exact endpoints; tick mark perpendicular, centered on axis, no decorative caps except optional axis_endcap socket.

Interaction vocabulary: noninteractive structure; hover/focus not required unless used as an axis grip target.

Materials/shaders: structure_quiet matte/unshaded neutral; no shadows, no emission, no transparency in baseline.

Polish: no accidental faceting; if tube variant, shade smooth with clean normals; if rectangular variant, sharp flat faces.

Accessibility: enough contrast in high-contrast theme, not color-only axis differentiation, labels supplied by guide anchors.

Export: GLB-ready normalized assets with material slots and procedural fallback/minimal_line.
```

## Prompt Review Checklist

Before running Blender MCP, ComfyUI, or handing a brief to an artist, check:

- Does the prompt start with one concrete asset and role id?
- Does it say what chart operation or chart mode it supports?
- Does it define diegetic scale in meters/centimeters?
- Does it define visible mesh size and collision target size separately?
- Does it specify one lookbook theme, not a mixed style soup?
- Does it include interaction states and input modes?
- Does it include accessibility requirements and non-color cues?
- Does it define material/shader limits?
- Does it say where to shade smooth, where to keep sharp, and where to bevel?
- Does it forbid unwanted extras like text, cameras, labels, scene backgrounds, glass, chrome, or low-poly faceting?
- Does it identify the procedural fallback role?
