# Creative direction

- Jam theme: **Autumn**. Limitation: **Staying Warm**.
- First-person snowstorm survival. Near death from cold, the protagonist hears a voice promising warmth. It leads them into an apparently dead, strange being. The apparent carcass is the demon that lured them; shelter becomes captivity.
- This supersedes the earlier kill-a-bison premise. Bison research remains an archived scale reference, not the current creature's biology or story.
- Scene 2 is a **living demon belly** with one continuous textured lining, broad embedded folds, a closed throat as the focal point and subtle contractions. Scattered eyes, teeth, ribs and loose organ spheres have been replaced for a cohesive appearance.
- Keep the interior almost claustrophobic: protagonist **1.78 m**, cavity about **1.90 m long × 0.72 m wide × 0.62 m high**. The survivor is pinned by living wrist tethers and broad torso bands. WASD makes small restrained body movements; mouse look is limited by the trapped posture.
- The interior lantern has been removed. Red light and a pulsing red tissue glow come from the demon itself. Both arms flail when free, grasp the fleshy restraints when LMB/RMB is held, and yank when E is pressed. Restraints stretch and recoil without releasing the player.
- The snow-lit entrance closes over about fourteen seconds. Small wall contractions and the creature's heartbeat reveal that this body is alive.
- Subtitle lines are temporary direction for the enticing voice. A recorded voice, exterior approach, new creature silhouette, and full entry sequence remain future work; scene 1 still contains the collaborator's original bison/cutting prototype.
- The interior survival mechanic and ending are **undecided**. Closure is an atmosphere beat, not a completed lose condition or escape puzzle.
- Imported assets added for this direction must have a verified **CC0** license. Maintain provenance and credit obligations in `assets/THIRD_PARTY.md`.

The project owner keeps creative control. New story decisions, the interior gameplay loop and ending should be discussed before implementation.

## Collaboration

Windows and Mac collaborators share the Godot project through GitHub, each on their own branch. Review before merging into `main`, and coordinate scene-file ownership. Commit scripts, scenes, shaders and `.uid` files; `.godot/` stays ignored.

Current scene 2 work: `scenes/inside_carcass.tscn`, `scripts/demon_belly.gd`, `scripts/demon_bound_hands.gd`, `scenes/player/carcass_hands.tscn`, and `shaders/demon_mucosa.gdshader`. Unused earlier carcass, crawl and lantern controllers have been removed from the shared project. Local retired copies are archived under ignored `.godot/asset-downloads/retired-scene2/`.

## Latest restraint direction

The chamber is now approximately 1.90 m long × 0.72 m wide × 0.62 m high, with thicker side pads and an overhanging lining. The bound-arm controller is `scripts/demon_bound_hands.gd`. Escape conditions and restraint damage are still undecided.
