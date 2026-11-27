# Gods Die Here

A dark-fantasy 3v3 arena game built for landscape play on a phone. Choose from 16 champions, each sworn to an original god, and fight across five arenas with different terrain and hazards. The first build is a practice match with two allied bots and three opposing bots.

## Play

Pick a champion and an arena, then start the match. Each team has a guard, a healer, and a damage dealer. The first team to win three rounds takes the match. Each round can last up to five minutes. At the time limit, the team with more surviving fighters wins. If survivor counts match, remaining team health as a percentage of maximum decides the round.

| Touch | Action |
|---|---|
| Drag from the lower left | Move your champion with the floating stick. |
| Tap or hold the large attack button | Use the basic attack and build your class resource. Holding repeats it when ready and in range. |
| Tap an ability | Cast one of your five class abilities. A tap up to 0.22 seconds before cooldown ends is queued. The icon indicates whether it targets a rival, supports an ally, affects you, or aims at the ground. |
| Tap Ultimate | Start your signature move once its charge reaches 100%. The marked area stays in place during the windup. Stun, silence, or a cast interrupt can stop it. |
| Tap Dodge | Evade in your movement direction. The button becomes Break Free during a stun, root, or silence until you use your one escape for the round. |
| Tap a fighter or the arena floor | Lock onto a target or clear the lock. With no lock, enemies in line of sight and eligible allies are picked automatically. |
| Tap Pause | Resume, return to the champion roster, or toggle sound, blood effects, and camera shake. |

The champion screen previews all six regular moves and each class's unique ultimate. Build ultimate charge by dealing and taking combat damage, healing, and absorbing hits. Each champion gets one ultimate attempt per round. Use the warning ring or lane to step clear or interrupt the caster. The [pantheon](docs/pantheon.md) introduces each patron.

### Claim the relic

A relic opens at the center of each map nine seconds into the round. Hold its circle for five seconds to earn a team reward. Both teams in the circle pause progress. Leaving it empty or conceding it to the other team loses your progress. A claimed relic reopens after 24 seconds.

| Arena relic | Reward |
|---|---|
| Lockwater · Tidefont | Restores 14% of maximum health to living teammates. |
| Kiln · Cinderheart | Increases team damage by 18% for 11 seconds. |
| Orchard · Rootwell | Restores 12% of maximum health to living teammates. |
| Quarry · Oathstone | Reduces combat damage taken by 24% for 11 seconds. |
| Observatory · Eclipse Lens | Increases team damage by 14% for 15 seconds. |

### Read the ground

Dashed hazard outlines count down to activation. Solid outlines show hazards already in effect. Spell fields name their caster's team and move, show an effect icon, and count down to expiration. Stay inside the shrinking arena ring when the late-round warning appears.

| Arena | Marking | What it does |
|---|---|---|
| Copperbell Kiln | Flame | Deals 10 damage per second to anyone inside. |
| Ironleaf Orchard | Direction arrows | Pushes fighters on either team in the direction of the arrows. |
| Shale Quarry | Rising stone | Raises cover that blocks movement and sight. |
| Hollowglass Observatory | Eclipse eye | Blocks targeting across a veil's edge. Fighters inside the same veil can target each other. |
| Lockwater Gatehouse | Waves | Slows fighters inside the water by 40%. |

See the [arena guide](docs/arenas.md) for the terrain and warning windows on each map.

## Run from source

Open `project.godot` in Godot 4.7.2 and press **F5**, or run `godot --path .`. On a computer, use **WASD** to move, **1–6** for abilities, **7** for the ultimate, **Space** to dodge, and **Escape** to pause. Click fighters to select them, or use **Tab** to cycle enemies.

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
godot --headless --path . --script res://tests/mobile_guides_test.gd
godot --headless --path . --script res://tests/arena_objectives_test.gd
godot --headless --path . --script res://tests/mobile_ultimate_test.gd
godot --headless --path . --script res://tests/ultimate_motion_test.gd
godot --headless --path . --script res://tests/arena_match_test.gd
godot --headless --path . --script res://tests/arena_scene_test.gd
godot --headless --path . --script res://tests/champion_art_test.gd
```
