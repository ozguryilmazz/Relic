extends Node
## Ses efektleri ve titreşim. Sesler dosya yerine kodla sentezleniyor (geçici; gerçek seslerle değiştirilebilir).
## Ayarlar user://settings.cfg içinde saklanır.

const RATE := 22050
const SETTINGS_PATH := "user://settings.cfg"
const POOL := 14

var sound_on := true
var vibration_on := true
var streams := {}
var players: Array = []
var next_player := 0
var last_play := {}
# aynı sesin en sık çalınma aralığı (sn): hızlı tekrarlarda kulak yormasın
const THROTTLE := {"thorn": 0.07, "tap": 0.03, "hit_bar": 0.12, "death": 0.05, "shoot": 0.08}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load()
	for i in POOL:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	_build()

# ---------------------------------------------------------------- ayarlar

func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		sound_on = cfg.get_value("audio", "sound", true)
		vibration_on = cfg.get_value("audio", "vibration", true)

func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "sound", sound_on)
	cfg.set_value("audio", "vibration", vibration_on)
	cfg.save(SETTINGS_PATH)

func set_sound(on: bool) -> void:
	sound_on = on
	_save()
	play("click")

func set_vibration(on: bool) -> void:
	vibration_on = on
	_save()
	if on:
		vibrate(40)

# ---------------------------------------------------------------- çalma

func play(id: String, pitch := 1.0, volume_db := 0.0) -> void:
	if not sound_on or not streams.has(id):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if THROTTLE.has(id) and now - float(last_play.get(id, -10.0)) < THROTTLE[id]:
		return
	last_play[id] = now
	var p: AudioStreamPlayer = players[next_player]
	next_player = (next_player + 1) % POOL
	p.stream = streams[id]
	p.pitch_scale = pitch * randf_range(0.95, 1.05)
	p.volume_db = volume_db
	p.play()

func vibrate(ms: int) -> void:
	if vibration_on:
		Input.vibrate_handheld(ms)

# ---------------------------------------------------------------- sentez

func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	return w

## Ton: f0'dan f1'e kayan frekans, üstel sönüm. wave: sine / square / saw
func _tone(dur: float, f0: float, f1: float, decay: float, wave := "sine", vol := 0.6, noise := 0.0) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var k := float(i) / n
		var f := lerpf(f0, f1, k)
		phase += TAU * f / RATE
		var v := 0.0
		match wave:
			"sine": v = sin(phase)
			"square": v = 1.0 if sin(phase) > 0.0 else -1.0
			"saw": v = fmod(phase / TAU, 1.0) * 2.0 - 1.0
		v = v * (1.0 - noise) + randf_range(-1.0, 1.0) * noise
		var env := exp(-t * decay) * minf(1.0, t * 400.0)
		out[i] = v * env * vol
	return out

func _mix(a: PackedFloat32Array, b: PackedFloat32Array, offset_sec := 0.0) -> PackedFloat32Array:
	var off := int(offset_sec * RATE)
	var out := a.duplicate()
	if out.size() < off + b.size():
		out.resize(off + b.size())
	for i in b.size():
		out[off + i] += b[i]
	return out

func _build() -> void:
	seed(1234)
	streams["tap"] = _wav(_tone(0.07, 880, 620, 45.0, "sine", 0.5))
	streams["thorn"] = _wav(_tone(0.03, 2400, 1800, 120.0, "square", 0.18, 0.5))
	streams["hit_bar"] = _wav(_mix(_tone(0.12, 240, 160, 30.0, "sine", 0.6), _tone(0.08, 400, 300, 50.0, "sine", 0.3, 0.8)))
	streams["hit_castle"] = _wav(_mix(_tone(0.35, 110, 55, 9.0, "sine", 0.9), _tone(0.2, 200, 100, 18.0, "sine", 0.4, 0.9)))
	streams["death"] = _wav(_tone(0.18, 500, 150, 20.0, "sine", 0.35, 0.7))
	streams["place"] = _wav(_mix(_tone(0.12, 300, 260, 25.0, "sine", 0.5), _tone(0.1, 600, 500, 35.0, "sine", 0.2), 0.03))
	streams["herb"] = _wav(_mix(_tone(0.25, 990, 990, 12.0, "sine", 0.3), _tone(0.25, 1320, 1320, 12.0, "sine", 0.25), 0.06))
	streams["ulti"] = _wav(_mix(_tone(0.5, 300, 900, 5.0, "saw", 0.35), _tone(0.5, 450, 1350, 5.0, "sine", 0.3)))
	streams["smash"] = _wav(_mix(_tone(0.6, 90, 40, 6.0, "sine", 1.0), _tone(0.4, 300, 80, 9.0, "sine", 0.5, 0.9)))
	streams["wave"] = _wav(_mix(_tone(0.35, 220, 220, 3.0, "saw", 0.3), _tone(0.5, 330, 330, 3.0, "saw", 0.3), 0.3))
	streams["arrow"] = _wav(_tone(0.15, 1800, 900, 18.0, "sine", 0.25, 0.8))
	streams["boom"] = _wav(_mix(_tone(0.5, 70, 35, 7.0, "sine", 1.0), _tone(0.3, 300, 100, 10.0, "sine", 0.6, 0.95)))
	streams["rock"] = _wav(_tone(0.4, 160, 60, 6.0, "sine", 0.7, 0.6))
	streams["click"] = _wav(_tone(0.04, 1200, 1000, 80.0, "sine", 0.35))
	streams["break"] = _wav(_mix(_tone(0.5, 200, 60, 6.0, "sine", 0.7, 0.85), _tone(0.3, 140, 90, 10.0, "square", 0.25), 0.05))
	var go := _tone(0.3, 392, 392, 4.0, "saw", 0.3)
	go = _mix(go, _tone(0.3, 330, 330, 4.0, "saw", 0.3), 0.3)
	go = _mix(go, _tone(0.7, 262, 262, 3.0, "saw", 0.3), 0.6)
	streams["gameover"] = _wav(go)
	streams["shoot"] = streams["arrow"]
