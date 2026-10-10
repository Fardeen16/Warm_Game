# Asset provenance and end-of-project credits

## Assets used by the demon interior

### PSX First Person Arms — Drillimpact

- Source: https://drillimpact.itch.io/psx-first-person-arms-free
- License: **CC0**, stated on the author's page.
- Files: `assets/models/psx_arms/` (GLB and original bare-skin textures).
- Changes: original blood shader and restrained arm motion applied in Godot.
- Animation used: `relax`, `grab.R` and `grab.L` supply open/closed finger poses. Original joint reach animates flailing and yanks.
- Required credit: **none**. Optional credit: First-person arms by Drillimpact.

### Heartbeat sounds — bart

- Source: https://opengameart.org/content/heartbeat-sounds
- Download: https://opengameart.org/sites/default/files/heartbeat_slow_0.wav
- License: **CC0**, explicitly listed on the asset page; checked 2026-10-10.
- File: `assets/audio/demon/heartbeat_slow.wav`, original recording, renamed.
- Runtime use: looped at reduced volume to suggest the creature's heartbeat.
- Required credit: **none**. Optional credit: Heartbeat by bart, OpenGameArt.org.

### Gutsy seamless organic texture — cron

- Source: https://opengameart.org/content/gutsy
- Download: https://opengameart.org/sites/default/files/gutsy.png
- License: **CC0 1.0**, explicitly stated by the author; checked 2026-10-10.
- File: `assets/textures/demon/gutsy.png` (original 2048 × 2048 PNG).
- Use: continuous lining, embedded folds and crawl bed. Shading reduces the source's
  saturation and baked highlight contrast for the pulsing red flesh palette.
- Required credit: **none**. Optional credit: Gutsy texture by cron, OpenGameArt.org.

The active arms controller resolves either dots or underscores in imported animation names.

## Original project work

Demon belly geometry, membranes, procedural shading, screen smears, restrained arm reach and struggle motion and subtitle direction are original project work. The earlier eyes/teeth prototype is no longer active. No Amnesia or Dying Light assets were copied. No third-party credits are required for this original work.

## Replaced or reviewed sources

- Blood Screen Effects by ScratchBattles: https://squaremeapixel.itch.io/blood-screen-effects . Author permits free personal and commercial use without credit, but does not explicitly declare CC0. Replaced by original procedural overlays for the new CC0-only direction. Downloaded copies are archived under ignored `.godot/asset-downloads/unused-blood/`; not used/exported.
- HorrorScreenFX Lite by Asago: https://asago.itch.io/horrorscreenfx-lite . Reviewed, **not installed or used**. It requires attribution if added later; it is outside the current CC0-only selection.
- Kenney audio: https://kenney.nl/assets/impact-sounds and https://kenney.nl/support . Reviewed; CC0 and no required credit. Not imported.
- The screenshot lists asset directories and extraction tools, not individual asset licenses. Only the specific creator's license is accepted as evidence of CC0.

## Credits checklist for the end of the project

- Mandatory credits for scene 2 assets currently used: **none**.
- Optional acknowledgments to retain: Drillimpact (arms/poses), bart (heartbeat), cron (texture).
- Audit collaborator assets elsewhere in the project before release; this inventory covers scene 2 additions, not a claim about all existing scene 1 assets.
- Add any new author, source, license, changed files and required wording here when an asset is imported. Complete the final credits screen at the end of the project.

## Restrained interior revision

The active scene has no lantern. It uses the existing CC0 arm rig and both grab poses with original flail/yank motion, original wrist/torso restraints and red pulse shading. No additional third-party assets were added. Unused crawl/lantern controllers have been archived locally outside the shared project.
