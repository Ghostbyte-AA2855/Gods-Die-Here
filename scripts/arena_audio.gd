extends Node

const RATE := 22050
const CLASS_TONES := {
	"breakwater":145, "forgecaller":170, "bellwarden":232, "threadkeeper":520,
	"lamplighter":440, "blood_cantor":245, "dream_shepherd":466, "echo_duelist":285,
	"chainrunner":196, "ash_dancer":320, "duskmoth":365, "longwatch":386,
	"sluicecaller":304, "glassmage":554, "winter_scribe":494, "coilwright":415
}

var muted := false
var _voices: Array[AudioStreamPlayer] = []
var _clips: Dictionary = {}
var _voice_index := 0
var _map := ""
var _phases: Dictionary = {}


func _ready() -> void:
	for i in range(8):
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		_voices.append(voice)


func toggle() -> void:
	muted = not muted
	if muted:
		for voice in _voices:
			voice.stop()


func cast(event: Dictionary) -> void:
	if muted:
		return
	var tone: float = CLASS_TONES.get(event.class_id, 300)
	var family: String = event.target_kind
	var strong: bool = event.slot == 7
	var key := "%s/%s/%s" % [event.class_id, family, strong]
	if not _clips.has(key):
		var end_ratio := 1.5 if family == "ally" else (0.58 if family == "enemy" else 1.15)
		_clips[key] = _tone(tone, end_ratio, 0.25 if strong else 0.13, family == "enemy")
	_play(_clips[key], -18.0 if event.source_id == 0 else -28.0)
	if event.source_id == 0 and strong:
		if not _clips.has("heavy_cast"):
			_clips["heavy_cast"] = _tone(106.0, 0.54, 0.27, true)
		_play(_clips["heavy_cast"], -19.0)


func elimination(local: bool) -> void:
	if muted:
		return
	if not _clips.has("elimination"):
		_clips["elimination"] = _tone(90.0, 0.45, 0.47, true)
	_play(_clips["elimination"], -10.5 if local else -15.0)


func environment(map_id: String, zones: Array, active: bool) -> void:
	if map_id != _map or not active:
		_map = map_id
		_phases.clear()
	if not active:
		return
	var sounded: Dictionary = {}
	for i in zones.size():
		var phase: String = zones[i].phase
		if _phases.get(i, "idle") != phase and phase in ["warning", "active"] and not sounded.has(phase):
			sounded[phase] = true
			var key := "arena/" + phase
			if not _clips.has(key):
				_clips[key] = _tone(735.0, 1.34, 0.24, false) if phase == "warning" else _tone(172.0, 0.55, 0.32, true)
			_play(_clips[key], -13.0)
		_phases[i] = phase


func _play(clip: AudioStreamWAV, volume: float) -> void:
	if muted or _voices.is_empty():
		return
	var voice := _voices[_voice_index]
	_voice_index = (_voice_index + 1) % _voices.size()
	voice.volume_db = volume
	voice.stream = clip
	voice.play()


func _tone(start_hz: float, ratio: float, seconds: float, percussive: bool) -> AudioStreamWAV:
	var frames := ceili(RATE * seconds)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	var phase := 0.0
	for i in frames:
		var t := float(i) / frames
		phase += TAU * start_hz * lerpf(1.0, ratio, t) / RATE
		var envelope := minf(1.0, t * 28.0) * pow(1.0 - t, 2.3)
		var overtone := sin(phase * 2.7) * 0.28 if percussive else sin(phase * 2.0) * 0.13
		bytes.encode_s16(i * 2, roundi((sin(phase) + overtone) * envelope * 21000.0))
	var clip := AudioStreamWAV.new()
	clip.format = AudioStreamWAV.FORMAT_16_BITS
	clip.mix_rate = RATE
	clip.data = bytes
	return clip
