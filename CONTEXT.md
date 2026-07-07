# Context

Domain glossary for Tokengochi. The product story lives in `PRODUCT.md`; the visual
system in `DESIGN.md`. This file names the moving parts in the code so refactors and
reviews share one vocabulary.

## Core concepts

- **Snapshot** — a provider-specific JSON file holding the latest usage reading:
  session/weekly utilization, context, reset times, model/effort/fast-mode. Modelled by
  `UsageSnapshot`.
- **Pet state** — the persisted game state that survives between readings: messes, the
  current window's start/peak session, peak weekly. Modelled by `PetState`.
- **Vitals** — the derived, display-ready state for one moment: mood, hunger, happiness,
  health, weight, animation tier. Produced by `PetEngine.update`.
- **Window** — a 5-hour session window. A window is *wasted* when it ends under the
  engagement threshold, which leaves a *mess*.

## Producers

- **Poller** (`TokengochiPoller`) — polls the OAuth usage endpoint and owns
  Claude session/weekly utilization and both reset times.
- **Writer** (`TokengochiWriter`) — reads the Claude Code statusline payload and owns
  context/model/effort/fast-mode.
- **Codex writer** (`TokengochiCodexWriter`) — reads Codex JSONL or hook JSON from
  stdin and accumulates local token usage into an estimated Codex snapshot.
- **Snapshot merge** (`SnapshotMerge`) — owns the field-ownership rule that lets the two
  Claude producers write the same Claude snapshot without clobbering each other. Each
  producer hands it only the fields it owns; it preserves the other's from the previous
  snapshot.
- **Rate-limit window** (`RateLimitWindow`) — extracts a window's percentage and reset
  time from a producer's vendor JSON shape (the usage endpoint's `utilization` vs the
  statusline's `used_percentage`).

## Engine and session

- **Pet engine** (`PetEngine`) — the deep core: turns a snapshot plus pet state into
  vitals, applying the window-roll, mess, mood, and pace rules.
- **Pet session** (`PetSession`) — one refresh tick: load snapshot and pet state through
  a **snapshot store**, advance the engine, persist state only when it changed.
- **Snapshot store** (`SnapshotStore`) — the seam the refresh loop reads and writes
  through. `DiskSnapshotStore` is the production adapter; tests use an in-memory adapter.

## Rendering

- **Creature face** (`CreatureFace`) — the creature's pixel geometry (body rows, eye
  cells, mouth cells) as a pure function of skin, mood, and blink. The renderer fills the
  cells; colours stay with the renderer (the Single-Screen palette is app chrome).
