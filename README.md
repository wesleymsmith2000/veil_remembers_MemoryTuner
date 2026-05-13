# Veil Memory Tuner

Prototype workspace for the **Veil Memory Tuner**, a standalone Roblox minigame/station that can later plug into the larger **Veil Skiff** co-op game.

## Current project state

- Design handoff docs are in this repo root.
- MVP art and style sheets currently live in [`assets/`](C:\Users\wesle\OneDrive\Documents\The Veil Remembers\MemoryTunerGame\assets).
- Git has been initialized on the `main` branch.
- VS Code extension recommendations are included for Roblox-focused development.

## Core gameplay direction

The tuner loop centers on identifying unstable memory threads, targeting the affected thread or threads, and applying one of four universal actions:

- `Cleanse`
- `Anchor`
- `Harmonize`
- `Vent`

The design intent and controller/input details live in:

- [`veil_memory_tuner_codex_handoff_part2.md`](C:\Users\wesle\OneDrive\Documents\The Veil Remembers\MemoryTunerGame\veil_memory_tuner_codex_handoff_part2.md)
- [`veil_memory_tuner_codex_handoff.md`](C:\Users\wesle\OneDrive\Documents\The Veil Remembers\MemoryTunerGame\veil_memory_tuner_codex_handoff.md)
- [`Veil Memory Tuner Codex Handoff.pdf`](C:\Users\wesle\OneDrive\Documents\The Veil Remembers\MemoryTunerGame\Veil%20Memory%20Tuner%20Codex%20Handoff.pdf)

## Suggested next steps

1. Decide whether we want a plain Roblox Studio start or a Rojo-based local dev workflow.
2. Create the initial source tree for UI, thread logic, and action resolution.
3. Import the current spritesheets into the first tuner UI prototype.
