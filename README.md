# hellorogue

A top-down roguelike shooter built in **Godot 4.2**. Procedurally generated
dungeon floors, five enemy types, four hand-built arena levels, and a boss.

This is a personal/demo project shared with friends. It is not published, not
sold, and not headed for a storefront.

---

## ⚠️ This repository contains code only

The `Sprites/` and `Music/` directories are **not tracked**. Together they were
~330 MB, and the soundtrack is third-party material (see [Credits](#credits))
that isn't mine to redistribute.

**A fresh clone will not run.** Godot will open the project and report missing
resources for every scene. The code, scenes, shaders, and project configuration
are all here and readable — that is what this repo is for.

To actually run it you need the asset directories dropped back in at:

```
hellorogue/
├── Music/      <- not in this repo
├── Sprites/    <- not in this repo
├── Entities/
├── Levels/
├── Menu/
└── project.godot
```

### Verifying a clone without the assets

`tools/stub_assets.py` writes structurally valid placeholders — magenta squares
and silence — at every missing asset path, which is enough for Godot to import
the project and build all 57 scenes. It is what makes the level scenes loadable,
and therefore what makes the integration tests and `-Deep` mean anything on a
fresh clone. Both asset directories are gitignored, so the placeholders are never
committed, and running it where the real assets are present does nothing.

```
.\tools\smoke.ps1 -Stub     # once per clone
.\tools\smoke.ps1 -All      # smoke + tests + a real boot
```

The game is *playable* only with the real assets. The placeholders are for
verification, not for looking at.

---

## Controls

| Action | Binding |
| --- | --- |
| Move | `WASD` or arrow keys |
| Shoot / melee | Left mouse button |
| Aim | Mouse |
| Pause | `Esc` or `Space` |

You shoot while you have ammo and swing a melee attack when you run out.

---

## Run structure

A run is 22 levels in three acts.

| Levels | Name shown | Scene | What it is |
| --- | --- | --- | --- |
| 1–18 | `1`–`18` | `main_level.tscn` | Procedurally generated floors, on a timer |
| 19 | `F1` | `intermission_level.tscn` | Spike arena — the floor fills with traps |
| 20 | `F2` | `intermission_level_2.tscn` | Crowd fight at the exit |
| 21 | `F3` | `intermission_level_1.tscn` | Every marker is a trap; fight in the gaps |
| 22 | `FINAL` | `final_level.tscn` | Boss, with escorts that ramp as its health drops |

The procedural floors change theme and music every 3 levels, and grow in size,
enemy count, and enemy speed as `PlayerData.levels` climbs. Each floor has a
~121-second timer; running it out sends you back to level 1.

> Note: the intermission scene files are numbered in a different order than they
> are played — `intermission_level_1.tscn` is the *third* one you see. The play
> order lives in `Menu/menu_scripts/loading_screen_intermission.gd`.

---

## Architecture

```
Globals.gd                     autoload - holds a camera reference
Levels/theme_player.tscn       autoload - all music and SFX playback

Entities/entities_script/
  player_data.gd               class PlayerData - static run state + reset_run()
  player.gd                    player state machine
  enemy_1..5.gd                enemy state machines (5 = boss)
  *_bullet*.gd                 projectiles

Levels/level_generator_script/
  walker.gd                    class WalkerRoom - drunkard's-walk map generator
  main_room.gd                 procedural floors (levels 1-18)
  arena_level.gd               class ArenaLevel - shared base for hand-built levels
  intermission_level*.gd       the three intermissions
  final_level.gd               boss room
```

Two pieces carry most of the design:

**`walker.gd`** carves a connected set of floor cells by walking in a random
direction, turning every 7 steps and stamping a room at each turn. The exit goes
in whichever room is furthest from the spawn. `main_room.gd` then subtracts
those cells from a pre-authored solid block of tiles, so the level is *carved
out of rock* rather than built up from nothing.

**`arena_level.gd`** holds everything the four hand-built levels share: loading
screen transitions, pause menu wiring, marker collection, and wave spawning.
Each concrete level is 25–80 lines of configuration on top of it.

**Tests.** `test/unit/` works on detached nodes and pure functions -- it never
boots a level, by design. `test/integration/` boots the real scenes and covers
what `_ready()` puts back and what a state transition leaves behind, which is
where the level-lifecycle bugs lived. The integration tests need the assets (or
the placeholders above) and report as pending without them.

**`PlayerData`** is deliberately all `static` — it persists across scene changes,
which is how progress carries between levels. Anything added there must also be
cleared in `reset_run()`, or it will leak from one run into the next.

---

## Credits

- **Music** — *Pokémon Mystery Dungeon: Red/Blue Rescue Team* soundtrack.
  Copyright Nintendo / Spike Chunsoft. Used here only in an unpublished personal
  project; not redistributed with this repository.
- **Font** — [Press Start 2P](https://fonts.google.com/specimen/Press+Start+2P),
  SIL Open Font License (`Font/OFL.txt`).
- **Code and sprites** — Brandon Chun.
