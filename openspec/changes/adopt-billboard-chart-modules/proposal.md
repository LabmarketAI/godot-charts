# Adopt burb-sweeper's Billboard Chart Modules

## Status
**Design capture - cross-repo contract.** Created from burb-sweeper's
pre-implementation design review (2026-07-30), which fixed the code
partition: main game (burb-sweeper), godot-charts (chart rendering),
automate-godot (portable rules cores). This change is the
godot-charts side of that partition for the billboard charts.

## Why

burb-sweeper ships in-world metric billboards whose chart rendering
lives game-side today: line charts drawn into billboard SubViewport
surfaces, fed by a `MetricSeriesAdapter` seam over the game's
longitudinal metrics, organized into chart groups (survival stocks,
population, and the FAUCETS AND DRAINS ledger group). That rendering
is chart code, not game code - by the partition it belongs here, and
the compact billboard chart work already landing on this repo's
billboard branch is the natural home for it.

Adopting it gives godot-charts a real, shipping consumer with a
concrete contract to satisfy - the same first-consumer discipline
automate-godot uses with the crafting core.

## What Changes

- **Absorb the billboard chart feature set** as addon capabilities:
  compact multi-series line charts sized for in-world billboard
  surfaces, grouped series with group titles, day-indexed x-axes,
  render-on-change friendliness (the game renders billboard surfaces
  UPDATE_ONCE on content change for performance).
- **Define the data contract at the boundary**: the game keeps
  `MetricSeriesAdapter` (game types, game state) and hands the addon
  plain series data - labels, points, group metadata. No burb-sweeper
  types cross into the addon; mirror the isolation-guard pattern
  burb-sweeper's recipe core uses for automate-godot.
- **Replacement plan**: once the addon's billboard charts reach
  parity, burb-sweeper's game-side chart drawing is replaced by addon
  consumption; the game-side seam and billboard/composition plumbing
  stay game-side.

## Non-goals

- Billboard placement, composition-camera integration, SubViewport
  ownership - game-side presentation, stays in burb-sweeper.
- Blocking this repo's XR/data-science direction on the game's needs:
  the billboard charts are one consumer, not the architecture.
