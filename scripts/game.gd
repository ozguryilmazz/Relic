class_name Game
extends Node2D
## Oyunun kendisi: harita, kaynaklar, dalgalar, düşmanlar, ultiler.

signal finished(stats: Dictionary)
signal to_menu
signal restart

const MAP_SIZE := Vector2(1920, 1080)
const PATH_POINTS := [
	Vector2(1690, 600), Vector2(1560, 600), Vector2(1480, 420), Vector2(1340, 280),
	Vector2(1170, 300), Vector2(1120, 480), Vector2(1230, 680), Vector2(1180, 870),
	Vector2(990, 900), Vector2(840, 780), Vector2(760, 620), Vector2(560, 600), Vector2(250, 600),
]
const BARRICADE_FROM_END := 300.0
const THORN_ZONE_LEN := 300.0
const RESOURCE_SPOTS := [
	{"kind": "odun", "pos": Vector2(470, 330), "r": 125.0, "n": 9},
	{"kind": "odun", "pos": Vector2(1350, 560), "r": 90.0, "n": 6},
	{"kind": "tas", "pos": Vector2(985, 640), "r": 95.0, "n": 6},
	{"kind": "tas", "pos": Vector2(1420, 870), "r": 90.0, "n": 5},
	{"kind": "cali", "pos": Vector2(620, 830), "r": 110.0, "n": 8},
	{"kind": "cali", "pos": Vector2(880, 420), "r": 95.0, "n": 6},
	{"kind": "kemik", "pos": Vector2(1640, 255), "r": 120.0, "n": 7},
]
const RES_NAMES := {"odun": "Odun", "tas": "Taş", "kemik": "Kemik", "diken": "Diken", "sifa": "Şifa"}
const RES_COLORS := {
	"odun": Color(0.85, 0.6, 0.35), "tas": Color(0.8, 0.82, 0.88), "kemik": Color(1, 0.97, 0.88),
	"diken": Color(0.7, 1.0, 0.55), "sifa": Color(1.0, 0.55, 1.0),
}

var hero: Dictionary
var path: GamePath
var world: Node2D
var fx: Fx
var hud: Hud
var player_castle: Castle
var enemy_castle: Castle
var barricade: Barricade
var nodes: Array = []

var s_barricade := 0.0
var s_zone := 0.0
var s_castle := 0.0
var enemy_speed := 100.0

var res := {"odun": 0.0, "tas": 0.0, "kemik": 0.0, "diken": 0.0, "sifa": 0.0}
var collected := {"odun": 0.0, "tas": 0.0, "kemik": 0.0, "diken": 0.0, "sifa": 0.0}
var castle_def := 0.0
var thorns := 0.0
var fear := 0
var slaves := 0
var slave_assign := {"odun": 0, "tas": 0, "cali": 0, "kemik": 0}
var slave_acc := {"odun": 0.0, "tas": 0.0, "cali": 0.0, "kemik": 0.0}

var wave := 0
var waves_cleared := 0
var phase := "prep"     # prep, wave, over
var prep_left := 0.0
var to_spawn := 0
var spawn_timer := 0.0
var enemies: Array = []
var kills := 0
var time_alive := 0.0

var ult_cd: Array = [0.0, 0.0]
var effects := {"gather": 0.0, "poison": 0.0, "slow": 0.0, "heal": 0.0}
var active_ulti := {}   # kind -> ulti dict (efekt süresince)
var touches := {}
var rng := RandomNumberGenerator.new()

func setup(hero_data: Dictionary) -> void:
	hero = hero_data

func _ready() -> void:
	rng.randomize()
	path = GamePath.new(PATH_POINTS)
	s_barricade = path.length - BARRICADE_FROM_END
	s_zone = s_barricade - THORN_ZONE_LEN
	s_castle = path.length - 10.0
	enemy_speed = path.length / Bal.ENEMY_TRAVEL_TIME
	castle_def = Bal.START_CASTLE
	prep_left = Bal.PREP_TIME

	world = Node2D.new()
	world.y_sort_enabled = true
	add_child(world)

	for spot in RESOURCE_SPOTS:
		var n := ResourceNode.new()
		n.position = spot.pos
		n.setup(spot.kind, spot.r, spot.n, int(spot.pos.x * 7 + spot.pos.y))
		world.add_child(n)
		nodes.append(n)

	player_castle = Castle.new()
	player_castle.is_player = true
	player_castle.position = Vector2(140, 660)
	world.add_child(player_castle)

	enemy_castle = Castle.new()
	enemy_castle.is_player = false
	enemy_castle.position = Vector2(1800, 660)
	world.add_child(enemy_castle)

	barricade = Barricade.new()
	barricade.position = path.pos_at(s_barricade)
	world.add_child(barricade)

	fx = Fx.new()
	fx.z_index = 10
	add_child(fx)

	hud = Hud.new()
	hud.game = self
	add_child(hud)

	get_viewport().size_changed.connect(_layout)
	_layout()

func _layout() -> void:
	var vs := get_viewport().get_visible_rect().size
	position = ((vs - MAP_SIZE) * 0.5).floor()

# ---------------------------------------------------------------- girdi

func _unhandled_input(event: InputEvent) -> void:
	if phase == "over":
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if touches.size() >= Bal.MAX_FINGERS:
				return
			touches[event.index] = true
			if hud.blocks(event.position):
				return
			_tap(event.position - position)
		else:
			touches.erase(event.index)

func _tap(p: Vector2) -> void:
	if hud.popup_open():
		hud.close_popup()
		return
	if Rect2(player_castle.position + Vector2(-150, -280), Vector2(300, 310)).has_point(p):
		hud.open_popup("castle", p + position)
		return
	if p.distance_to(path.pos_at(s_barricade)) < 70.0:
		hud.open_popup("barricade", p + position)
		return
	var c := path.closest(p)
	if c.dist < 60.0 and c.s >= s_zone - 20.0 and c.s < s_barricade - 30.0:
		hud.open_popup("thorns", p + position)
		return
	for n in nodes:
		if n.contains(p):
			n.tap(p)
			_gather(n.kind, p, true)
			return

func _gather(kind: String, p: Vector2, show_text: bool) -> void:
	var mult := 1.0
	if effects.gather > 0.0:
		mult = float(active_ulti.get("gather", {}).get("mult", 2.0))
	var amount: float = Bal.YIELD[kind] * mult
	var key := kind
	if kind == "cali":
		key = "sifa" if rng.randf() < Bal.BUSH_HEAL_CHANCE else "diken"
	res[key] += amount
	collected[key] += amount
	if show_text:
		var s := "+%s %s" % [_fmt(amount), RES_NAMES[key]]
		fx.text(p, s, RES_COLORS[key], 28)

func _fmt(v: float) -> String:
	if is_equal_approx(v, round(v)):
		return str(int(round(v)))
	return ("%.2f" % v).rstrip("0").rstrip(".")

# ---------------------------------------------------------------- harcama

func spend(kind: String, want: int) -> int:
	var have := int(floor(res[kind] + 0.0001))
	var n := mini(want, have)
	if n > 0:
		res[kind] -= n
	return n

func add_castle(kind: String, want: int) -> void:
	var n := spend(kind, want)
	if n > 0:
		castle_def += n * Bal.CASTLE_VALUE[kind]
		fx.text(player_castle.position + Vector2(0, -250), "+%d" % int(n * Bal.CASTLE_VALUE[kind]), Color(0.6, 0.85, 1.0), 32)

func barricade_locked() -> bool:
	if barricade.hp > 0.0:
		return false
	for e in enemies:
		if absf(e.s - s_barricade) < 70.0:
			return true
	return false

func add_barricade(kind: String, want: int) -> void:
	if barricade_locked():
		return
	var n := spend(kind, want)
	if n > 0:
		barricade.hp += n * Bal.BARRICADE_VALUE[kind]
		fx.text(barricade.position + Vector2(0, -120), "+%d" % int(n * Bal.BARRICADE_VALUE[kind]), Color(1, 0.85, 0.4), 30)

func add_thorns(want: int) -> void:
	var n := spend("diken", want)
	if n > 0:
		thorns += n
		fx.text(path.pos_at((s_zone + s_barricade) * 0.5), "+%d Diken" % n, RES_COLORS.diken, 28)

func buy_slave() -> bool:
	var cost := Bal.slave_cost(slaves)
	if fear < cost:
		return false
	fear -= cost
	slaves += 1
	return true

func free_slaves() -> int:
	var used := 0
	for k in slave_assign:
		used += slave_assign[k]
	return slaves - used

func assign_slave(kind: String, delta: int) -> void:
	if delta > 0 and free_slaves() > 0:
		slave_assign[kind] += 1
	elif delta < 0 and slave_assign[kind] > 0:
		slave_assign[kind] -= 1
	for n in nodes:
		n.slaves = 0
	for k in slave_assign:
		var left: int = slave_assign[k]
		var spots := nodes.filter(func(x): return x.kind == k)
		for i in spots.size():
			var share := int(ceil(float(left) / (spots.size() - i)))
			spots[i].slaves = share
			left -= share
			spots[i].queue_redraw()

# ---------------------------------------------------------------- ultiler

func ult_ready(i: int) -> bool:
	return ult_cd[i] <= 0.0

## Hazırsa ultiyi kullanır; bekliyorsa bir şifalı bitki yer.
func ult_press(i: int) -> void:
	if phase == "over":
		return
	if ult_ready(i):
		_activate(i)
	else:
		eat_herb(i)

func eat_herb(i: int) -> bool:
	if ult_ready(i) or res.sifa < 1.0:
		return false
	res.sifa -= 1.0
	ult_cd[i] = maxf(0.0, ult_cd[i] - Bal.HERB_COOLDOWN_CUT)
	return true

func _activate(i: int) -> void:
	var u: Dictionary = hero.ultis[i]
	ult_cd[i] = u.cooldown
	match u.kind:
		"smash":
			var front: Enemy = null
			for e in enemies:
				if e.state != Enemy.State.FLEE and (front == null or e.s > front.s):
					front = e
			var center := front.position if front else path.pos_at(s_barricade - 120.0)
			var dmg: float = Bal.enemy_hp(maxi(wave, 1)) * u.damage_mult
			for e in enemies:
				if e.position.distance_to(center) <= u.radius:
					e.hit(dmg)
			fx.ring(center, u.radius * 1.3, Color(0.9, 0.6, 0.2), 0.7)
			fx.ring(center, u.radius * 0.8, Color(1, 0.9, 0.5), 0.5)
			fx.text(center + Vector2(0, -60), u.name + "!", Color(1, 0.8, 0.3), 40)
		"gather", "poison", "slow", "heal":
			effects[u.kind] = u.duration
			active_ulti[u.kind] = u
			fx.text(Vector2(960, 200), u.name + "!", hero.color.lightened(0.4), 44)
		"fear":
			var pool := enemies.filter(func(e): return e.state != Enemy.State.FLEE)
			pool.shuffle()
			var count := int(ceil(pool.size() * float(u.ratio)))
			for k in count:
				pool[k].state = Enemy.State.FLEE
				fx.puff(pool[k].position, Color(0.5, 0.3, 0.6))
			fx.text(Vector2(960, 200), u.name + "!", hero.color.lightened(0.4), 44)

# ---------------------------------------------------------------- döngü

func _process(delta: float) -> void:
	if phase == "over":
		return
	time_alive += delta
	for i in ult_cd.size():
		ult_cd[i] = maxf(0.0, ult_cd[i] - delta)
	for k in effects:
		effects[k] = maxf(0.0, effects[k] - delta)

	if effects.heal > 0.0:
		var u: Dictionary = active_ulti.heal
		var sc := Bal.wave_scale(maxi(wave, 1))
		castle_def += u.castle_per_sec * sc * delta
		if barricade.hp > 0.0:
			barricade.hp += u.barricade_per_sec * sc * delta
		thorns += u.thorns_per_sec * sc * delta

	_update_slaves(delta)
	_update_waves(delta)
	_update_enemies(delta)

	player_castle.value = castle_def
	queue_redraw()

	if castle_def <= 0.0:
		_game_over(false)

func _update_slaves(delta: float) -> void:
	for k in slave_assign:
		if slave_assign[k] == 0:
			continue
		slave_acc[k] += slave_assign[k] * Bal.SLAVE_TAPS_PER_SEC * delta
		while slave_acc[k] >= 1.0:
			slave_acc[k] -= 1.0
			_gather(k, Vector2.ZERO, false)

func _update_waves(delta: float) -> void:
	if phase == "prep":
		prep_left -= delta
		if prep_left <= 0.0:
			wave += 1
			phase = "wave"
			to_spawn = Bal.enemy_count(wave)
			spawn_timer = 0.0
			hud.banner("Dalga %d" % wave)
	elif phase == "wave":
		if to_spawn > 0:
			spawn_timer -= delta
			if spawn_timer <= 0.0:
				spawn_timer = Bal.SPAWN_INTERVAL
				to_spawn -= 1
				_spawn()
		elif enemies.is_empty():
			waves_cleared = wave
			if wave >= Bal.MAX_WAVE:
				_game_over(true)
			else:
				phase = "prep"
				prep_left = Bal.PREP_TIME

func _spawn() -> void:
	var e := Enemy.new()
	e.max_hp = Bal.enemy_hp(wave)
	e.hp = e.max_hp
	e.dps = Bal.enemy_dps(wave)
	e.lane = rng.randf_range(-22.0, 22.0)
	e.set_meta("stop", rng.randf_range(18.0, 60.0))
	e.s = 0.0
	world.add_child(e)
	enemies.append(e)
	_place(e)

func _place(e: Enemy) -> void:
	var d := path.dir_at(e.s)
	var nrm := Vector2(-d.y, d.x)
	e.position = path.pos_at(e.s) + nrm * e.lane
	var moving := -d.x if e.state == Enemy.State.FLEE else d.x
	if absf(moving) > 0.2:
		e.face = signf(moving)

func _update_enemies(delta: float) -> void:
	var spd := enemy_speed
	if effects.slow > 0.0:
		spd *= float(active_ulti.slow.mult)
	var dmg := Bal.THORN_DAMAGE
	if effects.poison > 0.0:
		dmg *= float(active_ulti.poison.mult)
	var dead: Array = []
	var bar_hit := false
	for e in enemies:
		match e.state:
			Enemy.State.WALK:
				var stop_at: float = s_barricade - float(e.get_meta("stop"))
				var ns: float = e.s + spd * delta
				if barricade.hp > 0.0 and e.s <= stop_at and ns >= stop_at:
					e.s = stop_at
					e.state = Enemy.State.ATTACK
				else:
					e.s = ns
				if e.s >= s_castle:
					# sızma: kalan canı kadar vurur ve yok olur
					castle_def -= e.hp
					player_castle.hit_fx()
					fx.text(player_castle.position + Vector2(0, -200), "-%d" % int(ceil(e.hp)), Color(1, 0.35, 0.3), 34)
					e.hp = 0.0
					e.set_meta("leaked", true)
			Enemy.State.ATTACK:
				if barricade.hp <= 0.0:
					e.state = Enemy.State.WALK
				else:
					barricade.hp -= e.dps * delta
					bar_hit = true
			Enemy.State.FLEE:
				e.s -= spd * delta
				if e.s <= 0.0:
					e.hp = 0.0
					e.set_meta("leaked", true)
		# dikenler
		if e.hp > 0.0 and e.s >= s_zone and e.s <= s_barricade:
			e.thorn_acc += Bal.THORNS_EATEN_PER_SEC * delta
			while e.thorn_acc >= 1.0 and thorns >= 1.0 and e.hp > 0.0:
				thorns -= 1.0
				e.thorn_acc -= 1.0
				e.hit(dmg)
			e.thorn_acc = minf(e.thorn_acc, 1.0)
		if e.hp <= 0.0:
			dead.append(e)
		else:
			_place(e)
	if barricade.hp <= 0.0:
		barricade.hp = 0.0
	if bar_hit and rng.randf() < 0.1:
		barricade.hit_fx()
	for e in dead:
		enemies.erase(e)
		if not e.has_meta("leaked"):
			kills += 1
			fear += Bal.FEAR_PER_KILL
			fx.puff(e.position)
		e.queue_free()

func _game_over(victory: bool) -> void:
	if phase == "over":
		return
	phase = "over"
	castle_def = maxf(castle_def, 0.0)
	player_castle.value = castle_def
	var stats := {
		"victory": victory,
		"hero": hero.name,
		"waves": waves_cleared,
		"seconds": int(time_alive),
		"slaves": slaves,
		"kills": kills,
		"odun": int(collected.odun),
		"tas": int(collected.tas),
		"kemik": int(collected.kemik),
		"diken": int(collected.diken),
		"sifa": int(collected.sifa),
	}
	hud.show_game_over(stats)
	finished.emit(stats)

# ---------------------------------------------------------------- çizim

func _draw() -> void:
	# çimen
	draw_rect(Rect2(-1200, -800, MAP_SIZE.x + 2400, MAP_SIZE.y + 1600), Color(0.3, 0.5, 0.25))
	var r2 := RandomNumberGenerator.new()
	r2.seed = 42
	for i in 160:
		var p := Vector2(r2.randf_range(0, MAP_SIZE.x), r2.randf_range(100, MAP_SIZE.y))
		Gfx.ellipse(self, p, r2.randf_range(20, 60), r2.randf_range(8, 20), Color(0.27, 0.46, 0.22, 0.6))
	# yol (gölge + kenar + toprak)
	draw_polyline(path.points, Color(0, 0, 0, 0.18), 96.0, true)
	draw_polyline(path.points, Color(0.45, 0.33, 0.2), 86.0, true)
	draw_polyline(path.points, Color(0.68, 0.53, 0.34), 70.0, true)
	for p in path.points:
		draw_circle(p, 35.0, Color(0.68, 0.53, 0.34))
	# diken bölgesi
	var zone := path.sub_points(s_zone, s_barricade)
	var zcol := Color(0.35, 0.22, 0.12, 0.55) if thorns >= 1.0 else Color(0.35, 0.22, 0.12, 0.25)
	draw_polyline(zone, zcol, 70.0)
	var spikes := mini(int(thorns), 140)
	var r3 := RandomNumberGenerator.new()
	r3.seed = 7
	for i in spikes:
		var s := s_zone + r3.randf() * THORN_ZONE_LEN
		var d := path.dir_at(s)
		var nrm := Vector2(-d.y, d.x)
		var p2 := path.pos_at(s) + nrm * r3.randf_range(-30, 30)
		var col := Color(0.85, 0.85, 0.7)
		if effects.poison > 0.0:
			col = Color(0.55, 1.0, 0.35)
		draw_colored_polygon(PackedVector2Array([p2 + Vector2(-4, 3), p2 + Vector2(4, 3), p2 + Vector2(0, -9)]), col)
	var mid := path.pos_at((s_zone + s_barricade) * 0.5)
	var font := ThemeDB.fallback_font
	var label := "Diken %d" % int(thorns)
	draw_string_outline(font, mid + Vector2(-90, 70), label, HORIZONTAL_ALIGNMENT_CENTER, 180, 24, 6, Color(0, 0, 0, 0.7))
	draw_string(font, mid + Vector2(-90, 70), label, HORIZONTAL_ALIGNMENT_CENTER, 180, 24, RES_COLORS.diken)
	# yavaşlatma göstergesi
	if effects.slow > 0.0:
		draw_polyline(path.points, Color(0.5, 0.3, 0.7, 0.25), 80.0)
