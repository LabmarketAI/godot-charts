# Asset Prompt Directory

This directory is the source of truth for prompts used to create or refine chart assets with Blender MCP, artist handoff, or ComfyUI/text-to-3D reference generation.

Agents must not invent production prompts from chat history. For any asset task, read these files in order:

1. `../asset-prompting-guide.md`
2. `../lookbook-research.md`
3. `../asset-quality-gates.md`
4. `../fundamental-assets.md`
5. The specific prompt file in this directory.

## Required Workflow

1. Select one asset role and one prompt file.
2. Confirm the target theme and chart function.
3. Use the prompt file as the source of truth for Blender MCP or artist instructions.
4. Record any deviations in the output notes.
5. Validate the result against the manifest, quality gates, and visual gallery.
6. Preserve the procedural fallback for chart-critical roles.

## Directory Layout

- `templates/blender-asset-prompt.md` — canonical Blender MCP / artist prompt template.
- `templates/comfyui-reference-prompt.md` — reference-generation prompt template.
- `p0/` — first production-pass prompts.

## P0 Build Start

Start with the interaction primitives that unblock WebXR chart controls:

1. `p0/control-handle-linear.md`
2. `p0/control-focus-ring.md`
3. `p0/fallback-minimal-handle.md`

After those pass review, continue with structure and mark primitives.
