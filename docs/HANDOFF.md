# Scene 2 handoff

Branch: **scene-2**. Open `project.godot` in Godot 4.7, then open
`scenes/inside_carcass.tscn` and press **F6** for the interior directly.
F5 still starts the original outdoor prototype.

## Current direction

Autumn / Staying Warm: a voice lures the freezing protagonist into an apparent
carcass that is actually a demon. Inside, living wrist tethers and torso bands trap
the player in a congested, pulsing red chamber. There is no interior lantern.

## Controls

- Mouse: limited head movement.
- Hold LMB: right hand grasps its flesh tether.
- Hold RMB: left hand grasps its flesh tether.
- Press E while grasping: yank; the tethers stretch and recoil.
- WASD: struggle in place, with restrained arm/body motion.
- Esc: release mouse; click inside to capture it again.

## Main files

- `scenes/inside_carcass.tscn`: environment, red lights, view and UI.
- `scripts/demon_belly.gd`: generated lining/restraints, pulse and input.
- `scripts/demon_bound_hands.gd`: CC0 rig poses, joint reach, grasp and yank motion.
- `scenes/player/carcass_hands.tscn`: interior arm rig instance.
- `shaders/demon_mucosa.gdshader`: organic lining and red pulse.
- `shaders/bloody_arms.gdshader`: skin and contact blood.
- `shaders/carcass_vignette.gdshader`: restrained screen shading.
- `assets/THIRD_PARTY.md`: CC0 sources and optional acknowledgments for final credits.
- `docs/creative_direction.md`: owner-approved direction and creative control.

## Work still open

- Outdoor demon model, enticing recorded voice and revised entry sequence. Scene 1
  currently retains the original bison/cutting interaction.
- Escape condition, restraint damage, survival loop and ending: undecided. Current
  yanks are elastic visual reactions, not an implemented escape puzzle.
- Further animation refinement and playtesting, including on Mac. The current
  interior was opened in Godot on Windows; no automated gameplay tests were added.

Coordinate before editing the same scene. Review changes before merging into main.
Commit `.uid` and asset `.import` settings; keep the generated `.godot/` cache ignored.
Retired experiments are archived locally in that ignored cache and are not needed
to run the shared scene.
