class_name Enemy
extends Node2D
## Düşman. Hareketi game.gd yönetir; bu sınıf veriyi tutar ve kendini tipine göre çizer.

enum State { WALK, ATTACK, SHOOT, FLEE }

var type := "sopali"
var data: Dictionary = {}
var s := 0.0               # yol üzerindeki konum
var hp := 20.0
var max_hp := 20.0
var dps := 3.0             # barikata yakın dövüş hasarı
var speed_mult := 1.0
var state := State.WALK
var thorn_acc := 0.0
var flash := 0.0
var anim := 0.0
var lane := 0.0
var face := -1.0
var ammo := 0
var shot_timer := 0.0
var recoil := 0.0
var idle := 0.0            # menzilli birliğin hedefsiz beklediği süre

func setup(t: String, wave: int) -> void:
	type = t
	data = Bal.ENEMY_TYPES[t]
	max_hp = Bal.enemy_hp(wave) * float(data.hp)
	hp = max_hp
	dps = Bal.enemy_dps(wave) * float(data.melee)
	speed_mult = float(data.speed)
	if data.has("ranged"):
		ammo = int(data.ranged.ammo)

func ranged() -> Dictionary:
	return data.get("ranged", {}) if ammo > 0 else {}

## Cephanesi bitince ya da hedefsiz kalınca geri çekilen tip mi (okçu, mancınık)
func retreats() -> bool:
	return data.has("ranged") and data.ranged.get("after", "advance") == "retreat"

func hit(amount: float) -> void:
	hp -= amount
	flash = 0.12

func _process(delta: float) -> void:
	flash = maxf(0.0, flash - delta)
	recoil = maxf(0.0, recoil - delta * 3.0)
	var moving := state == State.WALK or state == State.FLEE
	anim += delta * (9.0 * speed_mult if moving else 3.0)
	queue_redraw()

func _body_col(base: Color) -> Color:
	return Color(1, 1, 1) if flash > 0.0 else base

func _draw() -> void:
	var top := -66.0
	match type:
		"koylu": _draw_foot(Color(0.55, 0.4, 0.25), "fork", "hat")
		"sopali": _draw_foot(Color(0.65, 0.16, 0.14), "club", "helmet")
		"okcu": _draw_foot(Color(0.25, 0.45, 0.2), "bow", "hood")
		"atli": top = _draw_rider()
		"topcu": top = _draw_cannon()
		"araba": top = _draw_cart()
		"mancinik": top = _draw_catapult()
		"boss":
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(2.3, 2.3))
			_draw_foot(Color(0.25, 0.22, 0.28), "club", "helmet")
			draw_set_transform(Vector2.ZERO)
			# boynuzlar ve pelerin
			draw_colored_polygon(PackedVector2Array([Vector2(-14, -118), Vector2(-26, -140), Vector2(-8, -124)]), Color(0.9, 0.88, 0.8))
			draw_colored_polygon(PackedVector2Array([Vector2(14, -118), Vector2(26, -140), Vector2(8, -124)]), Color(0.9, 0.88, 0.8))
			top = -160.0
	if hp < max_hp and type != "boss":
		var w := 32.0 if top > -80.0 else 56.0
		Gfx.bar(self, Vector2(0, top), w, 4, hp / max_hp, Color(0.9, 0.2, 0.2))

func _draw_foot(tunic: Color, weapon: String, head: String) -> void:
	var bob := absf(sin(anim)) * 3.0
	Gfx.shadow(self, Vector2(0, 2), 16, 6)
	var leg := sin(anim) * 5.0 if state != State.SHOOT and state != State.ATTACK else 0.0
	draw_line(Vector2(-4, -12), Vector2(-4 + leg, 0), Color(0.2, 0.15, 0.12), 4.0)
	draw_line(Vector2(4, -12), Vector2(4 - leg, 0), Color(0.2, 0.15, 0.12), 4.0)
	draw_rect(Rect2(-9, -34 - bob, 18, 23), _body_col(tunic))
	draw_rect(Rect2(-9, -20 - bob, 18, 4), Color(0.3, 0.2, 0.1))
	var hc := Vector2(0, -42 - bob)
	draw_circle(hc, 8.0, Color(0.93, 0.76, 0.6))
	match head:
		"helmet":
			draw_colored_polygon(PackedVector2Array([hc + Vector2(-9, -1), hc + Vector2(9, -1), hc + Vector2(0, -14)]), Color(0.55, 0.55, 0.6))
		"hat":
			draw_rect(Rect2(hc.x - 12, hc.y - 7, 24, 3), Color(0.85, 0.75, 0.4))
			draw_rect(Rect2(hc.x - 6, hc.y - 12, 12, 6), Color(0.85, 0.75, 0.4))
		"hood":
			draw_arc(hc, 9.0, PI, TAU, 12, tunic.darkened(0.3), 5.0)
	var hand := Vector2(face * 8.0, -26 - bob)
	match weapon:
		"fork":
			var tip := hand + Vector2(face * 14.0, -22)
			draw_line(hand + Vector2(-face * 4, 8), tip, Color(0.5, 0.35, 0.18), 3.0)
			for k in 3:
				var b := tip + Vector2(-4 + k * 4, 0)
				draw_line(b, b + Vector2(face * 2, -7), Color(0.7, 0.7, 0.7), 2.0)
		"club":
			var swing := sin(anim * 2.0) * 0.8 if state == State.ATTACK else 0.0
			var tip2 := hand + Vector2(face * 10.0, -20).rotated(swing * face)
			draw_line(hand, tip2, Color(0.4, 0.25, 0.12), 4.0)
			draw_circle(tip2, 5.0, Color(0.45, 0.28, 0.14))
		"bow":
			var bc := hand + Vector2(face * 4.0, -4)
			draw_arc(bc, 13.0, -PI * 0.5 * face - 1.3, -PI * 0.5 * face + 1.3, 10, Color(0.45, 0.3, 0.12), 3.0)
			var pull := 6.0 if state == State.SHOOT and shot_timer < 0.4 else 0.0
			draw_line(bc + Vector2(0, -12), bc + Vector2(-face * pull, 0), Color(0.9, 0.9, 0.85), 1.0)
			draw_line(bc + Vector2(-face * pull, 0), bc + Vector2(0, 12), Color(0.9, 0.9, 0.85), 1.0)

func _draw_rider() -> float:
	var bob := absf(sin(anim)) * 4.0
	Gfx.shadow(self, Vector2(0, 2), 30, 8)
	var horse := _body_col(Color(0.45, 0.3, 0.18))
	for i in 4:
		var lx := -18.0 + i * 11.0
		var sw := sin(anim + i * 1.6) * 6.0
		draw_line(Vector2(lx, -16 - bob * 0.3), Vector2(lx + sw, 0), horse.darkened(0.3), 4.0)
	Gfx.ellipse(self, Vector2(0, -24 - bob), 26, 11, horse)
	# baş ve boyun
	var neck := Vector2(face * 22.0, -30 - bob)
	draw_line(neck, neck + Vector2(face * 10.0, -14), horse, 8.0)
	Gfx.ellipse(self, neck + Vector2(face * 15.0, -16), 9, 5, horse)
	draw_line(Vector2(-face * 24.0, -26 - bob), Vector2(-face * 34.0, -14 - bob), Color(0.2, 0.12, 0.08), 4.0)
	# binici
	draw_rect(Rect2(-7, -54 - bob, 14, 20), _body_col(Color(0.65, 0.16, 0.14)))
	draw_circle(Vector2(0, -60 - bob), 7.0, Color(0.93, 0.76, 0.6))
	draw_colored_polygon(PackedVector2Array([Vector2(-8, -61 - bob), Vector2(8, -61 - bob), Vector2(0, -73 - bob)]), Color(0.6, 0.6, 0.65))
	var tip := Vector2(face * 34.0, -64 - bob)
	draw_line(Vector2(-face * 6.0, -44 - bob), tip, Color(0.45, 0.3, 0.15), 3.0)
	draw_circle(tip, 3.0, Color(0.85, 0.85, 0.9))
	return -88.0

func _wheel(c: Vector2, r: float) -> void:
	draw_circle(c, r, Color(0.3, 0.2, 0.1))
	draw_circle(c, r * 0.35, Color(0.55, 0.4, 0.2))
	for k in 4:
		var a := anim * 0.6 + k * PI * 0.25
		draw_line(c + Vector2(cos(a), sin(a)) * r, c - Vector2(cos(a), sin(a)) * r, Color(0.5, 0.35, 0.18), 2.0)

func _draw_cannon() -> float:
	Gfx.shadow(self, Vector2(0, 2), 26, 7)
	var back := -face * recoil * 8.0
	# namlu
	var base := Vector2(back, -16)
	var muzzle := base + Vector2(face * 30.0, -8)
	draw_line(base, muzzle, _body_col(Color(0.2, 0.2, 0.22)), 12.0)
	draw_circle(muzzle, 7.0, Color(0.12, 0.12, 0.14))
	draw_rect(Rect2(back - 14, -18, 26, 10), Color(0.45, 0.3, 0.15))
	_wheel(Vector2(back - 4, -8), 9.0)
	# topçu
	var g := Vector2(-face * 22.0, 0)
	draw_line(g + Vector2(-3, -10), g + Vector2(-3, 0), Color(0.2, 0.15, 0.12), 3.0)
	draw_line(g + Vector2(3, -10), g + Vector2(3, 0), Color(0.2, 0.15, 0.12), 3.0)
	draw_rect(Rect2(g.x - 7, -28, 14, 18), _body_col(Color(0.2, 0.25, 0.5)))
	draw_circle(g + Vector2(0, -34), 6.0, Color(0.93, 0.76, 0.6))
	if recoil > 0.6:
		draw_circle(muzzle + Vector2(face * 10.0, 0), 10.0 * recoil, Color(1, 0.8, 0.3, recoil))
	return -60.0

func _draw_cart() -> float:
	Gfx.shadow(self, Vector2(-6, 2), 44, 10)
	var bob := absf(sin(anim)) * 2.0
	# at
	var hx := face * 34.0
	var horse := _body_col(Color(0.45, 0.3, 0.18))
	for i in 2:
		var sw := sin(anim + i * PI) * 5.0
		draw_line(Vector2(hx - 8 + i * 14, -14), Vector2(hx - 8 + i * 14 + sw, 0), horse.darkened(0.3), 4.0)
	Gfx.ellipse(self, Vector2(hx, -20 - bob), 18, 8, horse)
	Gfx.ellipse(self, Vector2(hx + face * 20.0, -32 - bob), 8, 5, horse)
	draw_line(Vector2(hx - face * 16.0, -20), Vector2(-face * 2.0, -20), Color(0.35, 0.22, 0.1), 3.0)
	# araba
	var cx := -face * 14.0
	draw_rect(Rect2(cx - 24, -38 - bob, 48, 22), _body_col(Color(0.5, 0.33, 0.17)))
	draw_rect(Rect2(cx - 24, -38 - bob, 48, 4), Color(0.35, 0.22, 0.1))
	for k in 3:
		var hc := Vector2(cx - 14 + k * 14, -44 - bob)
		draw_circle(hc, 6.0, Color(0.93, 0.76, 0.6))
		draw_colored_polygon(PackedVector2Array([hc + Vector2(-7, -1), hc + Vector2(7, -1), hc + Vector2(0, -11)]), Color(0.55, 0.55, 0.6))
	_wheel(Vector2(cx - 14, -10), 10.0)
	_wheel(Vector2(cx + 14, -10), 10.0)
	return -70.0

func _draw_catapult() -> float:
	Gfx.shadow(self, Vector2(0, 2), 40, 10)
	var wood := _body_col(Color(0.5, 0.33, 0.17))
	draw_rect(Rect2(-32, -22, 64, 10), wood)
	draw_line(Vector2(-10, -22), Vector2(0, -58), wood.darkened(0.15), 7.0)
	draw_line(Vector2(10, -22), Vector2(0, -58), wood.darkened(0.15), 7.0)
	# kol: atışta öne savrulur
	var swing := recoil
	var a := lerpf(-2.4, -0.9, swing) if face > 0 else lerpf(-0.74, -2.24, swing)
	var pivot := Vector2(0, -50)
	var arm_end := pivot + Vector2(cos(a), sin(a)) * 50.0
	var arm_back := pivot - Vector2(cos(a), sin(a)) * 20.0
	draw_line(arm_back, arm_end, wood.lightened(0.1), 6.0)
	if ammo > 0 and swing < 0.5:
		draw_circle(arm_end, 8.0, Color(0.5, 0.5, 0.52))
	draw_rect(Rect2(arm_back.x - 8, arm_back.y, 16, 14), Color(0.4, 0.4, 0.42))
	_wheel(Vector2(-22, -10), 11.0)
	_wheel(Vector2(22, -10), 11.0)
	return -110.0
