# Warm_Game — Staying Warm

<img width="767" height="342" alt="image" src="https://github.com/user-attachments/assets/8cd7f401-dd76-4b99-853b-69b5988bf293" />

A first-person survival game made in **Godot 4.7**. You are caught out in a blizzard at night.
The cold is killing you: frost creeps over your vision, the world goes dark and you fight to keep
your eyes open. Your only chance is the dead bison lying in the snow. Cut it open and crawl inside
before you freeze.

## Controls
| Key | Action |
|---|---|
| W A S D / arrow keys | Move |
| Mouse | Look around |
| Space | Jump |
| E (hold) | Cut the bison open (stand at its belly) |
| E | Crawl inside once it's open |
| R | Try again after dying |
| Esc | Free the mouse (click to capture it again) |

## Running it
1. Install [Godot 4.7](https://godotengine.org/download).
2. Clone this repo and open `project.godot` in Godot.
3. Press **F5** to play.

Note: the **SnowStorm** node in `scenes/main.tscn` is currently hidden to save battery while
editing, so there is no snow in-game until you un-hide it (eye icon next to SnowStorm).

## Scenes
- **Scene 1, outside** (`scenes/main.tscn`): the blizzard, freezing to death over 90 seconds,
  cutting open the bison and crawling in.
- **Scene 2, inside the carcass** (`scenes/inside_carcass.tscn`): placeholder, still to be built.

## Project layout
```
assets/     models, textures, audio and other imported files (see assets/README.md)
scenes/     game scenes; scenes/props/ holds reusable objects like the bison
scripts/    GDScript code
shaders/    snow clouds and the freezing screen effect
```
See [assets/README.md](assets/README.md) for where each kind of asset goes and how to name files.

## Tweaking
Most things can be adjusted in the Godot inspector:
- **SnowStorm:** storm intensity, flake sizes, wind and how often it changes direction, clouds, haze.
- **FreezeEffect:** time until death, when frost, darkness and blinking start.
- **BisonCarcass:** how long cutting takes, which scene loads once inside.
- **MapBounds:** size of the play area.
