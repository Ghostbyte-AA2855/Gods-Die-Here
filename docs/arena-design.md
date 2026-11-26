# Lockwater arena design

Gods Die Here is an original third-person dark-fantasy arena game. The first project milestone is a small, instanced competitive arena where teams can develop coordinated play and find a response to each class's strongest abilities.

## First playable

The arena prototype is a local 3v3 match with one human player, two allied bots, and three opposing bots. Choose from 16 full-strength kits and lock a mastery before entering. Each team has one guard, one healer and one damage dealer. Team compositions and masteries carry over between rounds. The first team to take three rounds wins. Eliminate the opposing team or outlast it until the 60-second timer expires. At time, the team with more surviving fighters wins, followed by remaining team health as a percentage of starting health. A full tie sends the teams into another round without awarding a point. The safe area contracts in the final 25 seconds and damages fighters outside it.

The playtest should answer three questions.

- Can players tell who is under pressure and respond in time to help a teammate?
- Can each role change the outcome through positioning, timing, or target selection?
- Do teams have enough time to regroup after an opening exchange and enough reason to contest the center late in a round?

## Combat direction

Build fights around **setup, commitment, and reset**. Players take a favorable angle, draw out a defensive ability, and commit to a short attack window. The other team can spend a save, break line of sight, or counter while the attackers' abilities recover. Give each class a way to create an opening and a way to support a teammate's play.

- **Positioning.** Fixed cover and changing terrain offer multiple routes to each opponent. A healer can use cover to escape pressure and step out to see an ally. Wide lanes reward ranged pressure, and routes around pillars let melee close in. Test every spawn and approach from both sides.
- **Readable abilities.** Use distinct visual and sound cues for big attacks, protection, interrupts, and escapes. An aimed attack is strongest when allies create a safe moment to commit. Keep the status bar focused on effects that change the next decision.
- **Crowd control.** Prototype short hard-control windows with one diminishing-returns meter per target across all sources of stuns, roots, and similar effects that remove control. Within the same window, the first effect gets full duration and the second gets half. Further applications fail until the meter resets. Show the current tier and reset timing beside the target.
- **Arena rotation.** Five mirrored arena layouts feature rising tides, furnace vents, directional gusts, rising cover and walkable sight-blocking veils. Each layout signals its upcoming change before it takes effect. Test whether each map rewards a different approach while preserving fair opening routes. See the [arena guide](arenas.md) for timing, landmarks and team tactics.

The [class guide](classes.md) covers the entire playable roster, including resource loops, all 128 abilities, 32 alternative masteries, opening exchanges and counterplay.

## Combat presentation

Characters carry class-specific equipment, and their team color appears on the base ring. Class colors and spell shapes identify the action. A thrown hook draws metal links, an allied heal draws a thread, and a dash traces the distance the fighter traveled. The eight ability keys keep the same positions across matches.

Cast and impact poses, walking motion, spell trails and short sound cues come from match events. Bots and players use the same presentation. A rejected cast leaves the battlefield clear. A placed field stays visible for its simulated lifetime, while short cast flourishes fade. Map warnings use floor patterns, text, and a separate sound cue. Press M to toggle sound.

The current art is a stylized, low-poly prototype with procedural animation. A human playtest should check whether a player can identify the spell, its target and the safe exit in a six-fighter exchange at normal speed.

## Ranked design proposal

- **Format and loadouts.** Use the same 3v3 rules for solo and premade competition. Give each class fixed ranked stats and make the same legal traits available to every player from their first ranked match. Traits trade one strength for another. Lock selections for the match and show both teams' choices after the lock.
- **Ladders and matchmaking.** Propose a solo ladder with role-balanced teams and a separate premade ladder for full trios. Pair teams by rating and connection quality. Widen the rating search gradually as the wait grows, and validate queue times before operating both ranked pools. Reward competition with rating, seasonal titles, and cosmetics.
- **Private play and reconnect.** Use invite-only rooms for practice and scrims with the same round rules. Reserve a disconnected player's slot during a short reconnect window. The server retains the fighter's match state and lets the player rejoin the same instance with current health, position, and cooldowns.
- **Round recap.** Start with a short timeline around an elimination that shows the abilities, control effects, interrupts, and saves leading to it. Let players expand the timeline to inspect the full exchange. Show enough detail to answer why a teammate died or which defensive ability bought the enemy time.

## Next engineering checkpoint

Run one private networked 3v3 match with six human clients. Give each match its own instance and have the server resolve movement, attacks, cooldowns, round timers, and results. Verify isolation between two simultaneous matches, agreement on the winner across clients, and consistent handling of a disconnect. Keep the local bot match available for class iteration.
