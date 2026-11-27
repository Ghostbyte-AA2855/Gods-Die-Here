extends SceneTree

const ArenaMatch = preload("res://scripts/arena_match.gd")
const MobileKits = preload("res://scripts/mobile_kits.gd")
const TICK := 1.0 / 60.0

var checks := 0
var failures := 0


func _initialize() -> void:
	_check(ArenaMatch.CLASS_INFO.size() == 16, "The mobile roster has sixteen classes")
	for class_id: String in ArenaMatch.CLASS_INFO:
		_check_kit(class_id)
	_check_bot_casts()
	_check_series()
	_check_mobile_endgame()
	_check_field_name()
	print("Mobile rules: %d/%d checks passed" % [checks - failures, checks])
	quit(1 if failures else 0)


func _check_kit(class_id: String) -> void:
	var slots: Array = MobileKits.slots(class_id)
	var kit: Dictionary = ArenaMatch.CLASS_INFO[class_id]
	_check(slots.size() == 6 and slots.front() == 0, class_id + " offers one basic attack and five abilities")
	var seen := {}
	for slot: int in slots:
		_check(slot >= 0 and slot < kit.abilities.size() and not seen.has(slot), class_id + " exposes a distinct valid slot %d" % slot)
		seen[slot] = true
	if slots.size() != 6 or seen.size() != 6 or seen.keys().any(func(slot): return slot < 0 or slot >= kit.abilities.size()):
		return

	var blocked = _encounter(class_id)
	var player: Dictionary = blocked.fighters[0]
	_check(not blocked.try_mobile_ability(-1) and not blocked.try_mobile_ability(6), class_id + " rejects out-of-range touch buttons")
	for slot in kit.abilities.size():
		if not slots.has(slot):
			var target := _target_for(kit.abilities[slot])
			_check(not blocked.try_ability(slot, target) and player.cooldowns[slot] == 0.0, class_id + " cannot cast hidden slot %d" % slot)
	_check(blocked.cast_events.is_empty() and player.meter == 100.0, class_id + " rejected inputs spend no resource and produce no cast events")

	for button in slots.size():
		var slot: int = slots[button]
		var game = _encounter(class_id)
		var fighter: Dictionary = game.fighters[0]
		var ability: Dictionary = fighter.abilities[slot]
		var label := "%s / %s" % [kit.name, ability.name]
		_prepare_cast(game, class_id, slot, slots)
		var count: int = game.cast_events.size()
		var target := _target_for(ability)
		_check(game.try_mobile_ability(button, target), label + " casts through its touch button")
		if game.cast_events.size() > count:
			var event: Dictionary = game.cast_events[-1]
			_check(event.slot == slot and event.source_id == 0 and event.name == ability.name, label + " preserves the original animation and effects slot")
		_check(is_equal_approx(fighter.cooldowns[slot], ability.cooldown), label + " recovers on the original ability's cooldown")
		_check(not game.try_mobile_ability(button, target), label + " cannot be tapped again on cooldown")


func _encounter(class_id: String, mobile := true, seed := 701):
	var game = ArenaMatch.new()
	game.mobile_mode = mobile
	game.start_match(class_id, seed)
	var positions := [Vector2.ZERO, Vector2(2.9, 0), Vector2(0, -1), Vector2(1.6, 0), Vector2(1.6, 0.8), Vector2(1.6, -1.1)]
	for fighter in game.fighters:
		fighter.position = positions[fighter.id]
		fighter.health = fighter.max_health * 0.65
		fighter.stun = 20.0 if fighter.id != 0 else 0.0
		fighter.break_free_available = false
	game.fighters[0].meter = 100.0
	return game


func _target_for(ability: Dictionary) -> int:
	match ability.target:
		"ally": return 1
		"enemy": return 3
	return -1


func _prepare_cast(game, class_id: String, slot: int, slots: Array) -> void:
	var setup := -1
	match class_id:
		"breakwater":
			if slot == 6:
				setup = 2
		"threadkeeper":
			if slot == 3:
				setup = 2
		"echo_duelist":
			if slot in [2, 4]:
				setup = 1
		"blood_cantor":
			if slot == 6:
				setup = 0
		"bellwarden":
			if slot == 2:
				setup = 0
		"ash_dancer":
			if slot in [2, 7]:
				setup = 0
		"winter_scribe":
			if slot in [2, 7]:
				game.fighters[3].position = Vector2(4.5, 0)
				setup = 1
		"lamplighter":
			if slot in [5, 7]:
				setup = 2
		"longwatch", "forgecaller", "chainrunner":
			if slot == 7:
				setup = 1
		"glassmage":
			if slot in [2, 4, 7]:
				setup = 1
		"duskmoth":
			if slot in [5, 7]:
				setup = 1
	if setup >= 0:
		var ability: Dictionary = game.fighters[0].abilities[setup]
		_check(game.try_mobile_ability(slots.find(setup), _target_for(ability)), class_id + " can set up its combo with " + ability.name)
		if class_id == "threadkeeper" and slot == 3:
			game._deal_damage(game.fighters[3], game.fighters[1], 16.0)


func _check_bot_casts() -> void:
	var game = ArenaMatch.new()
	var forgecaller_id := -1
	var selected_seed := -1
	for seed in 32:
		game.start_match("breakwater", seed)
		for bot in game.fighters.slice(3):
			if bot.class_id == "forgecaller":
				forgecaller_id = bot.id
				selected_seed = seed
				break
		if selected_seed >= 0:
			break
	_check(forgecaller_id >= 0, "A seeded match has a Forgecaller opponent for the bot fixture")
	if forgecaller_id < 0:
		return

	for mobile in [false, true]:
		game = _encounter("breakwater", mobile, selected_seed)
		var bot: Dictionary = game.fighters[forgecaller_id]
		bot.stun = 0.0
		bot.bot_wait = 0.0
		bot.meter = 100.0
		bot.cooldowns.fill(10.0)
		bot.cooldowns[0] = 0.0
		bot.cooldowns[2] = 0.0 # Winch is a higher-priority desktop cast.
		game.step(TICK, Vector2.ZERO, Vector2.ZERO)
		var expected_slot := 0 if mobile else 2
		_check(game.cast_events.size() == 1 and game.cast_events[0].source_id == forgecaller_id and game.cast_events[0].slot == expected_slot,
			"Forgecaller bot selects the expected ability in %s mode" % ("mobile" if mobile else "desktop"))

	game = ArenaMatch.new()
	game.mobile_mode = true
	game.start_match("breakwater", 701)
	game.step(18.0, Vector2.ZERO, Vector2.ZERO)
	var sources := {}
	for event in game.cast_events:
		if event.source_id > 0:
			sources[event.source_id] = true
			_check(MobileKits.slots(event.class_id).has(event.slot) or (event.get("ultimate", false) and event.slot == ArenaMatch.ArenaUltimates.SLOT),
				"Bot %d only uses slots in the mobile kit and its ultimate" % event.source_id)
	_check(sources.size() == 5, "Both teams' bots use their mobile kits in a live match")


func _check_series() -> void:
	var game = _encounter("breakwater")
	_check(game.fighters.size() == 6 and is_equal_approx(game.round_time, 300.0), "The mobile 3v3 allows five minutes per round")
	var series := [0, 1, 0, 1, 0]
	for index in series.size():
		var winner: int = series[index]
		for fighter in game.fighters:
			if fighter.team != winner:
				fighter.health = 0.0
				fighter.alive = false
		game.step(TICK, Vector2.ZERO, Vector2.ZERO)
		_check(game.round_winner == winner and game.round_number == index + 1, "The mobile series awards round %d" % (index + 1))
		if index < series.size() - 1:
			_check(game.phase == "round_over" and not game.try_mobile_ability(0), "Combat stops between rounds")
			game.next_round()
			_check(game.phase == "active" and is_equal_approx(game.round_time, 300.0), "A subsequent round restores the timer")
	_check(game.phase == "match_over" and game.match_winner == 0 and game.wins == [3, 2], "The third win ends the mobile series")
	game.next_round()
	_check(game.round_number == 5 and game.phase == "match_over", "The completed series cannot advance another round")


func _check_mobile_endgame() -> void:
	var mobile = _encounter("breakwater")
	var desktop = _encounter("breakwater", false)
	_check(mobile.fighters[0].max_health >= desktop.fighters[0].max_health * 2.0, "Mobile health protects against early burst")
	for game in [mobile, desktop]:
		game.fighters[0].position = Vector2(12.0, 0.0)
		game.fighters[0].health = game.fighters[0].max_health
		game.round_time = 25.0
		game.step(TICK, Vector2.ZERO, Vector2.ZERO)
		_check(game.fighters[0].health == game.fighters[0].max_health, "The ring leaves the outer lane safe at the start of contraction")
		game.round_time = 19.0
		game.step(TICK, Vector2.ZERO, Vector2.ZERO)
		_check(game.safe_radius < 12.0 and game.fighters[0].health < game.fighters[0].max_health, "The final ring forces fighters toward the center")
	var mobile_fraction: float = mobile.fighters[0].health / mobile.fighters[0].max_health
	var desktop_fraction: float = desktop.fighters[0].health / desktop.fighters[0].max_health
	_check(is_equal_approx(mobile_fraction, desktop_fraction), "The ring keeps the same percentage health pressure with larger mobile health pools")


func _check_field_name() -> void:
	var game = _encounter("forgecaller")
	var slots := MobileKits.slots("forgecaller")
	_check(game.try_mobile_ability(slots.find(4)), "Forgecaller can place Furnace Bed on the mobile layout")
	_check(game.fields.size() == 1 and game.fields[0].name == "Furnace Bed" and game.fields[0].kind == "damage",
		"A ground effect carries the originating spell name and behavior for the HUD")


func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)
