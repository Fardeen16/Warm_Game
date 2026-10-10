# Assets

Raw art and audio for the game. Scenes, scripts and shaders live in the top-level
`scenes/`, `scripts/` and `shaders/` folders; everything you import goes in here.

```
assets/
├── models/          3D models (.glb preferred, .fbx/.blend also import)
│   ├── environment/
│   │   ├── trees/       pine trees, dead trees, bushes
│   │   ├── rocks/       boulders, stones
│   │   └── terrain/     ground pieces, snow drifts, cliffs
│   ├── animals/
│   │   └── bison/       the carcass (one folder per animal)
│   ├── characters/
│   │   └── player/      hands, arms, body
│   └── props/           knife, tools, anything you pick up or place
├── textures/        images used by materials (.png)
│   ├── environment/  snow, ground, bark, rock
│   ├── animals/      fur, flesh
│   ├── characters/
│   ├── props/
│   └── vfx/          snowflakes, frost, blood
├── materials/       shared Godot materials (.tres)
├── animations/      animation files not baked into a model
│   ├── player/       crouch, crawl, cut
│   └── animals/
├── audio/
│   ├── music/        background music (.ogg, looping)
│   ├── ambience/     long loops: blizzard wind, howling, creaking trees (.ogg)
│   ├── sfx/          short one-shot sounds (.wav)
│   │   ├── player/       footsteps in snow, breathing, shivering, heartbeat, teeth chattering
│   │   ├── interaction/  knife cutting, flesh tearing, crawling inside
│   │   ├── animals/      distant wolves, other animal calls
│   │   ├── environment/  branch snaps, gusts, snow falling off trees
│   │   └── ui/           menu clicks, death sting
│   └── voice/        grunts, gasps, any lines
├── ui/
│   ├── fonts/        .ttf / .otf
│   ├── icons/        prompt keys, small HUD icons
│   └── images/       title screen, menu backgrounds
└── vfx/             particle textures and effect resources
```

## Conventions
- **Names:** `snake_case`, most general part first, then a variant number:
  `footstep_snow_01.wav`, `tree_pine_02.glb`, `bark_pine_albedo.png`.
- **Texture suffixes:** `_albedo`, `_normal`, `_roughness`, `_ao`, `_emission`.
- **Audio formats:** `.ogg` for music and loops, `.wav` for short sound effects.
- **One folder per model** when it comes with its own textures, e.g.
  `models/animals/bison/bison.glb` plus `bison_fur_albedo.png` beside it.
- **Move or rename files inside the Godot editor** (FileSystem dock), not in Finder,
  so Godot updates every scene that uses them.
- The `.gitkeep` files only keep empty folders in git; delete one once its folder has files.
