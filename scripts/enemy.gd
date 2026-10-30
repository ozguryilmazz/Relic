class_name Enemy
extends Node2D
## Düşman asker. Hareketi game.gd yönetir; bu sınıf veriyi tutar ve kendini çizer.

enum State { WALK, ATTACK, FLEE }

var s := 0.0               # yol üzerindeki konum
var hp := 20.0
var max_hp := 20.0
var dps := 3.0
var state := State.WALK
var thorn_acc := 0.0
var flash := 0.0
var anim := 0.0
var lane := 0.0            # yol içinde yana kayma (kalabalık görünmesin)
var face := -1.0

func hit(amount: float) -> void:
	hp -= amount
	flash = 0.12

func _process(delta: float) -> void:
	flash = maxf(0.0, flash - delta)
	anim += delta * (4.0 if state == State.ATTACK else 9.0)
	queue_redraw()

func _draw() -> void:
	var bob := absf(sin(anim)) * 3.0
	Gfx.shadow(self, Vector2(0, 2), 16, 6)
	# bacaklar
	var leg := sin(anim) * 5.0
	draw_line(Vector2(-4, -12), Vector2(-4 + leg, 0), Color(0.2, 0.15, 0.12), 4.0)
	draw_line(Vector2(4, -12), Vector2(4 - leg, 0), Color(0.2, 0.15, 0.12), 4.0)
	# gövde
	var body := Color(0.65, 0.16, 0.14)
	if flash > 0.0:
		body = Color(1, 1, 1)
	draw_rect(Rect2(-9, -34 - bob, 18, 23), body)
	draw_rect(Rect2(-9, -20 - bob, 18, 4), Color(0.3, 0.2, 0.1))
	# kafa + miğfer
	draw_circle(Vector2(0, -42 - bob), 8.0, Color(0.93, 0.76, 0.6))
	draw_colored_polygon(PackedVector2Array([Vector2(-9, -43 - bob), Vector2(9, -43 - bob), Vector2(0, -56 - bob)]), Color(0.55, 0.55, 0.6))
	# mızrak
	var tip := Vector2(face * 20.0, -48 - bob)
	if state == State.ATTACK:
		tip = Vector2(face * (22.0 + sin(anim * 2.0) * 8.0), -30 - bob)
	draw_line(Vector2(face * 8.0, -26 - bob), tip, Color(0.45, 0.3, 0.15), 3.0)
	draw_circle(tip, 3.0, Color(0.8, 0.8, 0.85))
	# can barı
	if hp < max_hp:
		Gfx.bar(self, Vector2(0, -66), 32, 4, hp / max_hp, Color(0.9, 0.2, 0.2))
