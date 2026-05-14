# Veil Memory Tuner — MVP 3D Model Kit

Generated: MVP blockout meshes for Roblox prototype use.

## Files

- `vmt_tuner_console_blockout.obj` — rough tuner console with dials/buttons.
- `vmt_memory_core_crystal.obj` — central glowing memory core/crystal.
- `vmt_thread_anchor_pylon.obj` — repeatable pylon for Beam/Attachment thread starts.
- `vmt_marked_selection_glyph.obj` — persistent marked-selection glyph.
- `vmt_focus_reticle.obj` — focused/live-target reticle.
- `vmt_tuner_floor_ring.obj` — circular platform/floor ring.
- `vmt_mvp_modelkit_combined_showcase.obj` — combined reference layout.

Each `.obj` has a matching `.mtl` material file.

## Roblox Usage Notes

These are placeholder/blockout meshes. In Roblox Studio:
1. Import the `.obj` files with Studio's Importer.
2. Use them as MeshParts or Models.
3. Add Attachments manually in Studio:
   - Thread anchor: add `StartAttachment` at the crystal/top node.
   - Memory core: add `CoreAttachment` near the crystal center/top.
   - Connect anchors to core with Beam objects.
4. Add real VFX in Roblox:
   - ParticleEmitters for Static, Drift, Dissonance, Overload.
   - BillboardGuis for labels, focus reticles, marked glyphs.
   - TweenService for pulsing and feedback.

## Scale

The kit is roughly human-scale in Roblox studs:
- Console width: about 6 studs.
- Core height: about 2.5 studs.
- Anchor pylon height: about 2 studs.
- Floor ring diameter: about 7.6 studs.

## Suggested MVP Scene

Place:
- Floor ring at origin.
- Memory core at center.
- Four anchors around the ring.
- Console in front of the core.
- Use Beams for the actual memory threads.