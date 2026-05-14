# Veil Memory Tuner

Prototype workspace for the **Veil Memory Tuner**, a standalone Roblox minigame/station that can later plug into the larger **Veil Skiff** co-op game.

## Current project state

- Design handoff docs are in this repo root.
- MVP art and style sheets currently live in [`assets/`](C:\Users\wesle\OneDrive\Documents\The Veil Remembers\MemoryTunerGame\assets).
- Git has been initialized on the `main` branch.
- VS Code extension recommendations are included for Roblox-focused development.
- A first-pass Rojo project scaffold now lives in [`default.project.json`](C:\Users\wesle\OneDrive\Documents\The Veil Remembers\MemoryTunerGame\default.project.json) and [`src/`](C:\Users\wesle\OneDrive\Documents\The Veil Remembers\MemoryTunerGame\src).

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

## Dev workflow

The project is set up for a Rojo-style Roblox workflow:

1. Open this folder in VS Code.
2. Install the recommended Roblox extensions.
3. Open Roblox Studio and connect/sync using Rojo.
4. Run the game to spawn the placeholder tuner scene and HUD from code.

Current scaffold includes:

- Shared gameplay modules in [`src/ReplicatedStorage/VeilTuner`](C:\Users\wesle\OneDrive\Documents\The%20Veil%20Remembers\MemoryTunerGame\src\ReplicatedStorage\VeilTuner)
- A server bootstrap scene in [`TunerBootstrap.server.lua`](C:\Users\wesle\OneDrive\Documents\The%20Veil%20Remembers\MemoryTunerGame\src\ServerScriptService\VeilTunerServer\TunerBootstrap.server.lua)
- A client prototype loop and HUD in [`VeilTunerClient.client.lua`](C:\Users\wesle\OneDrive\Documents\The%20Veil%20Remembers\MemoryTunerGame\src\StarterPlayer\StarterPlayerScripts\VeilTunerClient.client.lua)

## Suggested next steps

1. Sync the scaffold into Roblox Studio and verify the placeholder prototype runs.
2. Replace placeholder HUD glyphs and colors with the first pass from the spritesheets in [`assets/spritesheets`](C:\Users\wesle\OneDrive\Documents\The%20Veil%20Remembers\MemoryTunerGame\assets\spritesheets).
3. Move the challenge loop server-side with remotes once the client prototype feel is right.
