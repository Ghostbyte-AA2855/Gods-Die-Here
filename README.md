# Gods Die Here

Gods Die Here is a dark-fantasy 3v3 arena game in development. Play as a champion sworn to one of 16 original gods. Every class starts with eight active abilities, a class resource, and two optional pre-match masteries. Win three rounds with two allied bots against a team of three bots.

## Play the local prototype

Open `project.godot` in Godot 4 and press **F5**, or run this command from the repository directory. This build was tested with Godot 4.7.2.

```sh
godot --path .
```

Select a class to inspect its abilities and counterplay, choose a mastery or Standard, pick one of the five arenas, then select Play. Each team fields a guard, a healer, and a damage dealer. Rounds last up to 60 seconds. Defeat the opposing team or lead on surviving fighters at the time limit. If both teams have the same number of survivors, remaining team health as a percentage of starting health decides the round. The safe area contracts in the final 25 seconds and deals damage to fighters outside it.

| Control | Action |
|---|---|
| W, A, S, D | Move relative to the arena camera. |
| Mouse | Aim in the arena. |
| Left click | Select an allied or opposing fighter. Click the floor to clear selection. |
| Tab | Cycle opposing fighters. |
| 1–8 | Use the corresponding class ability. |
| Space | Dodge. |
| G | Toggle blood effects for future eliminations. |
| M | Toggle combat and arena sound cues. |
| R | Clear stun, root, and silence once per round. |
| Enter | Start the next round, rematch after the result, or resume from the quit prompt. |
| Esc | Return to class selection. Press it twice during an active round to confirm. |

Read the [class guide](docs/classes.md) for every ability, mastery, and a suggested opening for each class.

The [arena guide](docs/arenas.md) explains the five environmental mechanics, their warning windows and ways to use the terrain. All 128 ability slots have cast effects. Movement, class poses, impact reactions and sound cues follow local match events.

## Characters and combat presentation

Each champion has a name, a patron, a personal curse, and an armor silhouette shaped by their god. See the [pantheon](docs/pantheon.md) for the full cast. The class panel shows the patron and champion alongside the eight combat abilities.

Each champion has their own articulated 3D armor, weapons, and regalia. The lobby displays the same model used in the arena. Pick a spell to preview its full casting animation, and drag the model to inspect it from another angle.

The game includes 128 ability-specific cast clips and 11 movement and reaction clips per champion. The rig carries the weapons, limbs, mantle, and ornaments. Bolts and tethers begin at the casting hand. Defeated fighters play their own fall with optional blood spray and pooling. This pass uses modeled geometry and materials with rigid joint bindings. Detailed surface textures, facial animation, and live six-human playtesting remain future work.

## Export champion models

The source models and animation curves live in `scripts/champions`. To export a GLB for each champion, including all animation actions, run this command with an absolute output directory.

```sh
godot --headless --path . --script res://tools/preview/export_champions.gd -- /absolute/path/to/champions --animated
```

## Development

The first build is a local practice match with a bot-controlled roster. The next milestone is a private match with six human clients and an authoritative server. The [arena design](docs/arena-design.md) covers match rules and the direction for ranked competition.

Run the combat and scene checks from the repository directory.

```sh
godot --headless --path . --script res://tests/arena_match_test.gd
godot --headless --path . --script res://tests/arena_scene_test.gd
godot --headless --path . --script res://tests/champion_art_test.gd
```
