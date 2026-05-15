# Veil Memory Tuner — Phase A Sprite Pack

Transparent PNG sprite sheets for Phase A of the Veil Memory Tuner chamber.

## Files

- `vmt_phase_a_icon_spritesheet_4x4_1024.png`
  - 16 icons: active/dormant lane, roof oculus, crystals, pylons, thread states, focus, marked, warning, static, drift, dissonance, overload.
- `vmt_phase_a_icon_spritesheet_atlas.json`

- `vmt_phase_a_vfx_particles_spritesheet_4x4_1024.png`
  - Particle/VFX textures: soft glows, ripple rings, star bursts, static noise, spark shards, wisp.
- `vmt_phase_a_vfx_particles_atlas.json`

- `vmt_phase_a_pulse_animation_strips_8frame_1024x512.png`
  - 4 rows of 8-frame pulse strips: cyan, gold, violet, red.
- `vmt_phase_a_pulse_animation_atlas.json`

- `vmt_phase_a_ui_spritesheet_1024x512.png`
  - Sample UI panels, action buttons, meters, labels, and warning banner.
- `vmt_phase_a_ui_atlas.json`

## Roblox Usage Notes

Upload the PNGs as image assets. Use the JSON atlas coordinates to crop sprites manually in ImageLabels/ImageButtons or to create equivalent UI pieces.

Suggested usage:
- Icons: BillboardGui labels, HUD state icons, active/dormant lane indicators.
- VFX particles: ParticleEmitter.Texture for glows, sparks, static, ripples.
- Pulse strips: animated ImageLabels/BillboardGuis or particle flipbooks if you implement frame cycling.
- UI sprites: temporary HUD panels and action button references.

## Important

These are MVP production placeholders, not final art. They are designed to be readable in Roblox and easy to replace later.
