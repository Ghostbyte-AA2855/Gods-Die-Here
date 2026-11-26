# Gods Die Here

A dark-fantasy 3v3 arena game built for landscape play on a phone. Choose from 16 champions, each sworn to an original god, and fight across five arenas with different terrain and hazards. The first build is a practice match with two allied bots and three opposing bots.

## Play

Pick a champion and an arena, then start the match. Each team has a guard, a healer, and a damage dealer. The first team to win two rounds takes the match. Rounds last up to 52 seconds. At the time limit, the team with more surviving fighters wins. If the survivor counts match, remaining team health decides the round. Watch for the ring closing toward the end.

| Touch | Action |
|---|---|
| Drag from the lower left | Move your champion with the floating stick. |
| Tap or hold the large attack button | Use the basic attack and build your class resource. Holding repeats it when ready and in range. |
| Tap I, II, or III | Cast one of your three class abilities. |
| Tap Dodge | Evade in your movement direction. The button becomes Break Free during a stun, root, or silence until you use your one escape for the round. |
| Tap a fighter or the arena floor | Lock onto a target or clear the lock. With no lock, enemies in line of sight and eligible allies are picked automatically. |
| Tap Pause | Resume or return to the champion roster. |

You can preview each of your four attacks and spells in the champion screen. The 16 champions use their existing models, animation clips, sound cues, and elimination effects in combat. The [pantheon](docs/pantheon.md) introduces each patron. The [arena guide](docs/arenas.md) covers cover, movement, and hazard warnings.

## Run from source

Open `project.godot` in Godot 4.7.2 and press **F5**, or run `godot --path .`. On a computer, use **WASD**, **1–4**, **Space**, and **Escape** for movement, abilities, dodge, and pause. Click fighters to select them, or use **Tab** to cycle enemies.

To export the practice build for a phone browser, install the matching Godot export templates and run the following from the repo root.

```sh
python tools/mobile/export_web.py
python -m http.server 8000 --directory build/mobile-web
```

Open the server computer's Wi-Fi IP address on port 8000 in your phone browser while both devices are on the same network. Hold the phone sideways. The web build uses WebGL 2.

## Development

`mobile.tscn` launches the mobile practice mode. `arena.tscn` can still be run explicitly to exercise the original eight-ability rules and desktop controls. The [class guide](docs/classes.md) documents those full kits.

```sh
godot --headless --path . --script res://tests/mobile_rules_test.gd
godot --headless --path . --script res://tests/mobile_touch_test.gd
godot --headless --path . --script res://tests/arena_match_test.gd
godot --headless --path . --script res://tests/arena_scene_test.gd
godot --headless --path . --script res://tests/champion_art_test.gd
```
