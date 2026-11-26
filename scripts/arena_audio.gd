extends Node

const CombatFx = preload("res://scripts/combat_fx.gd")
const RATE := 22050
const VOICE_COUNT := 8
const BACKGROUND_GAP_MS := 55
const INCOMING_GAP_MS := 220
const CLASS_TONES := {
	"breakwater": 145, "forgecaller": 170, "bellwarden": 232, "threadkeeper": 520,
	"lamplighter": 440, "blood_cantor": 245, "dream_shepherd": 466, "echo_duelist": 285,
	"chainrunner": 196, "ash_dancer": 320, "duskmoth": 365, "longwatch": 386,
	"sluicecaller": 304, "glassmage": 554, "winter_scribe": 494, "coilwright": 415,
}
const PATTERN_CUES := {
	"cut": "edge", "sweep": "edge", "crush": "crush",
	"bolt": "bolt", "needle": "bolt", "volley": "bolt",
	"zap": "chain", "chain": "chain", "thread": "chain",
	"dash": "rush", "wave": "rush",
	"heal": "ward", "ward": "ward", "cleanse": "ward", "rally": "rally",
	"field": "mark", "brand": "mark", "interrupt": "burst", "swarm": "burst", "burst": "burst",
}
const MAP_CUES := {
	"lockwater": "tide", "kiln": "vent", "orchard": "gust",
	"quarry": "rise", "observatory": "veil",
}

# Layer gains describe the strike, metal ring, tonal body and filtered air.
# Synthesized once per cue, then the same small mono sample serves all voices.
const CUES := {
	"edge": { "length": 0.20, "pitch": 218.0, "glide": 0.56, "attack": 0.007,
		"strike": 0.48, "ring": 0.20, "body": 0.10, "air": 0.43 },
	"crush": { "length": 0.36, "pitch": 162.0, "glide": 0.52, "attack": 0.006,
		"strike": 0.76, "ring": 0.36, "body": 0.19, "air": 0.33 },
	"bolt": { "length": 0.22, "pitch": 318.0, "glide": 1.46, "attack": 0.014,
		"strike": 0.20, "ring": 0.15, "body": 0.43, "air": 0.23 },
	"chain": { "length": 0.29, "pitch": 265.0, "glide": 0.77, "attack": 0.006,
		"strike": 0.27, "ring": 0.57, "body": 0.21, "air": 0.34 },
	"rush": { "length": 0.29, "pitch": 139.0, "glide": 1.48, "attack": 0.034,
		"strike": 0.24, "ring": 0.03, "body": 0.13, "air": 0.73 },
	"mark": { "length": 0.24, "pitch": 198.0, "glide": 0.72, "attack": 0.010,
		"strike": 0.28, "ring": 0.23, "body": 0.41, "air": 0.20 },
	"burst": { "length": 0.38, "pitch": 221.0, "glide": 0.49, "attack": 0.008,
		"strike": 0.54, "ring": 0.40, "body": 0.32, "air": 0.41 },
	"ward": { "length": 0.33, "pitch": 371.0, "glide": 1.21, "attack": 0.022,
		"strike": 0.11, "ring": 0.09, "body": 0.74, "air": 0.08 },
	"rally": { "length": 0.47, "pitch": 293.0, "glide": 1.34, "attack": 0.023,
		"strike": 0.24, "ring": 0.12, "body": 0.81, "air": 0.15 },
	"windup": { "length": 0.18, "pitch": 179.0, "glide": 2.24, "attack": 0.075,
		"strike": 0.01, "ring": 0.14, "body": 0.27, "air": 0.68 },
	"incoming": { "length": 0.17, "pitch": 472.0, "glide": 0.37, "attack": 0.004,
		"strike": 0.50, "ring": 0.19, "body": 0.57, "air": 0.36 },
	"fall": { "length": 0.55, "pitch": 116.0, "glide": 0.56, "attack": 0.010,
		"strike": 0.61, "ring": 0.26, "body": 0.42, "air": 0.26 },
	"warning": { "length": 0.21, "pitch": 582.0, "glide": 0.99, "attack": 0.010,
		"strike": 0.06, "ring": 0.20, "body": 0.72, "air": 0.07 },
	"tide": { "length": 0.64, "pitch": 110.0, "glide": 0.79, "attack": 0.069,
		"strike": 0.21, "ring": 0.04, "body": 0.10, "air": 0.80 },
	"vent": { "length": 0.50, "pitch": 155.0, "glide": 0.62, "attack": 0.017,
		"strike": 0.45, "ring": 0.19, "body": 0.08, "air": 0.72 },
	"gust": { "length": 0.60, "pitch": 189.0, "glide": 1.17, "attack": 0.092,
		"strike": 0.10, "ring": 0.04, "body": 0.15, "air": 0.79 },
	"rise": { "length": 0.58, "pitch": 97.0, "glide": 0.69, "attack": 0.041,
		"strike": 0.63, "ring": 0.16, "body": 0.13, "air": 0.58 },
	"veil": { "length": 0.60, "pitch": 245.0, "glide": 0.83, "attack": 0.040,
		"strike": 0.16, "ring": 0.30, "body": 0.57, "air": 0.15 },
}
enum Priority { BACKGROUND, WINDUP, NEARBY, INCOMING, PLAYER, WARNING, ELIMINATION }

var muted := false
var _voices: Array[AudioStreamPlayer] = []
var _priorities: Array[int] = []
var _starts: Array[int] = []
var _clips: Dictionary = {}
var _warm_queue: Array = CUES.keys()
var _last_background := -BACKGROUND_GAP_MS
var _last_incoming := -INCOMING_GAP_MS
var _map := ""
var _phases: Dictionary = {}


func _ready() -> void:
	for i in VOICE_COUNT:
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		_voices.append(voice)
		_priorities.append(Priority.BACKGROUND)
		_starts.append(0)
	set_process(not muted)


func _process(_delta: float) -> void:
	# Spread synthesis over the first lobby frames instead of blocking the
	# first cast of a match with a new cache entry.
	if not muted:
		while not _warm_queue.is_empty():
			var cue: String = _warm_queue.pop_front()
			if not _clips.has(cue):
				_clips[cue] = _synthesize(cue)
				return
	set_process(false)


func toggle() -> void:
	muted = not muted
	if muted:
		for voice in _voices:
			voice.stop()
	elif not _warm_queue.is_empty():
		set_process(true)


func windup(event: Dictionary) -> void:
	if muted or int(event.get("source_id", -1)) != 0 or int(event.get("slot", 0)) == 0:
		return
	var strong := _is_major(event)
	_play("windup", -22.0 if strong else -25.0, _class_pitch(event), Priority.WINDUP)


func cast(event: Dictionary) -> void:
	if muted:
		return
	var slot := int(event.get("slot", -1))
	var class_id := str(event.get("class_id", ""))
	var style: Array = CombatFx.STYLES.get(class_id, [])
	var pattern: String = style[2][slot] if not style.is_empty() and slot >= 0 and slot < style[2].size() else ""
	var cue: String = PATTERN_CUES.get(pattern, "mark")
	var local_player := int(event.get("source_id", -1)) == 0
	var affected: Array = event.get("affected_ids", [])
	var near_player := affected.has(0)
	var strong := _is_major(event)
	var pitch := _class_pitch(event)
	if strong:
		pitch *= 0.91
		if cue == "edge":
			cue = "crush"
		elif cue == "ward":
			cue = "rally"
	var volume := -31.0
	var priority := Priority.BACKGROUND
	if local_player:
		volume = -14.0 if strong else -18.0
		priority = Priority.PLAYER
	elif near_player:
		volume = -22.0 if strong else -25.0
		priority = Priority.NEARBY
		if slot > 0 and int(event.get("team", 0)) == 1:
			_play("incoming", -16.0 if strong else -19.0, 0.90 if strong else 1.0, Priority.INCOMING)
	elif strong:
		volume = -27.0
	if affected.is_empty() and cue in ["edge", "bolt", "crush", "chain"]:
		volume -= 3.0
	_play(cue, volume, pitch, priority)


func _is_major(event: Dictionary) -> bool:
	var slot := int(event.get("slot", -1))
	var affected: Array = event.get("affected_ids", [])
	return slot == 7 or (slot > 0 and affected.size() >= 2)


func elimination(local: bool) -> void:
	_play("fall", -11.5 if local else -17.0, 0.92 if local else 1.07, Priority.ELIMINATION)


func environment(map_id: String, zones: Array, active: bool) -> void:
	if map_id != _map or not active:
		_map = map_id
		_phases.clear()
	if not active:
		return
	var warned := false
	var activated := false
	for i in zones.size():
		var phase: String = zones[i].phase
		if _phases.get(i, "idle") != phase:
			warned = warned or phase == "warning"
			activated = activated or phase == "active"
		_phases[i] = phase
	if warned:
		_play("warning", -15.0, 1.0, Priority.WARNING)
	if activated:
		_play(MAP_CUES.get(map_id, "rise"), -15.5, 1.0, Priority.WARNING)


func _class_pitch(event: Dictionary) -> float:
	var tone := float(CLASS_TONES.get(event.get("class_id", ""), 300))
	return clampf(pow(tone / 300.0, 0.28), 0.83, 1.20)


func _play(cue: String, volume: float, pitch: float, priority: int) -> void:
	if muted or _voices.is_empty():
		return
	var now := Time.get_ticks_msec()
	if priority == Priority.BACKGROUND and now - _last_background < BACKGROUND_GAP_MS:
		return
	if priority == Priority.INCOMING and now - _last_incoming < INCOMING_GAP_MS:
		return
	var channel := _choose_channel(priority)
	if channel < 0:
		return
	var voice := _voices[channel]
	if voice.playing:
		voice.stop()
	if not _clips.has(cue):
		_clips[cue] = _synthesize(cue)
	voice.volume_db = volume
	voice.pitch_scale = pitch
	voice.stream = _clips[cue]
	_priorities[channel] = priority
	_starts[channel] = now
	if priority == Priority.BACKGROUND:
		_last_background = now
	elif priority == Priority.INCOMING:
		_last_incoming = now
	voice.play()


func _choose_channel(priority: int) -> int:
	var available := -1
	var victim := -1
	var background_count := 0
	for i in _voices.size():
		if not _voices[i].playing:
			if available < 0:
				available = i
			continue
		if _priorities[i] == Priority.BACKGROUND:
			background_count += 1
		if _priorities[i] >= priority:
			continue
		if victim < 0 or _priorities[i] < _priorities[victim] or (_priorities[i] == _priorities[victim] and _starts[i] < _starts[victim]):
			victim = i
	if priority == Priority.BACKGROUND and background_count >= 3:
		return -1
	return available if available >= 0 else victim


func _synthesize(cue: String) -> AudioStreamWAV:
	var profile: Dictionary = CUES[cue]
	var duration := float(profile.length)
	var pitch := float(profile.pitch)
	var glide := float(profile.glide)
	var attack := float(profile.attack)
	var strike_gain := float(profile.strike)
	var ring_gain := float(profile.ring)
	var body_gain := float(profile.body)
	var air_gain := float(profile.air)
	var two_notes := cue == "warning"
	var count := ceili(RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = cue.hash()
	var phase := 0.0
	var bass_phase := 0.0
	var low_noise := 0.0
	var mid_noise := 0.0
	var peak := 0.0
	for i in count:
		var elapsed := float(i) / RATE
		var age := elapsed / duration
		var shape := smoothstep(0.0, attack, elapsed) * pow(1.0 - age, 1.55)
		var noise := rng.randf_range(-1.0, 1.0)
		low_noise = lerpf(low_noise, noise, 0.035)
		mid_noise = lerpf(mid_noise, noise, 0.27)
		var grit := (mid_noise - low_noise) * 1.17 + (noise - mid_noise) * 0.21
		phase += TAU * pitch * lerpf(1.0, glide, smoothstep(0.0, 0.85, age)) / RATE
		bass_phase += TAU * (72.0 + 135.0 * exp(-elapsed * 78.0)) / RATE
		var strike := (sin(bass_phase) * 0.82 + low_noise * 1.5) * exp(-elapsed * 23.0)
		var ring := (sin(phase * 2.74) * 0.61 + sin(phase * 4.21 + 0.2) * 0.27) * exp(-elapsed * 11.0)
		var body := sin(phase) * 0.58 + sin(phase * 1.5) * 0.23 + sin(phase * 2.01) * 0.13
		var air := grit * (0.72 + 0.28 * sin(TAU * elapsed * 23.0))
		var mix := strike * strike_gain + ring * ring_gain + body * body_gain + air * air_gain
		var sample := mix * shape
		if two_notes:
			# Two rising bell strikes cut through combat and read as one warning.
			var note_age := age if age < 0.50 else age - 0.50
			var note := phase if age < 0.50 else TAU * 744.0 * duration * note_age
			var bell := sin(note) * 0.73 + sin(note * 2.58) * 0.21
			sample = bell * smoothstep(0.0, 0.045, note_age) * pow(1.0 - note_age * 2.0, 1.7)
		samples[i] = sample
		peak = maxf(peak, absf(sample))
	var output := PackedByteArray()
	output.resize(count * 2)
	var gain := 24000.0 / maxf(0.01, peak)
	for i in count:
		output.encode_s16(i * 2, roundi(samples[i] * gain))
	var clip := AudioStreamWAV.new()
	clip.format = AudioStreamWAV.FORMAT_16_BITS
	clip.mix_rate = RATE
	clip.data = output
	return clip
