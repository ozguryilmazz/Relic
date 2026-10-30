class_name HeroEmblem
extends Control
## Kahraman kartındaki geçici portre (gerçek çizimler gelene kadar).

var hero_id := ""
var col := Color.WHITE
var t := 0.0

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.46
	draw_circle(c, r, col.darkened(0.55))
	draw_arc(c, r, 0, TAU, 64, Ui.GOLD, 4.0)
	match hero_id:
		"tepegoz": _tepegoz(c, r)
		"sahmeran": _sahmeran(c, r)
		"alkarasi": _alkarasi(c, r)

func _tepegoz(c: Vector2, r: float) -> void:
	var skin := Color(0.62, 0.48, 0.34)
	draw_circle(c + Vector2(0, r * 0.15), r * 0.62, skin)
	draw_rect(Rect2(c.x - r * 0.5, c.y + r * 0.35, r, r * 0.5), skin.darkened(0.15))
	# tek göz
	var blink := 1.0 if fmod(t, 4.0) > 0.15 else 0.15
	Gfx.ellipse(self, c + Vector2(0, -r * 0.05), r * 0.3, r * 0.22 * blink, Color(0.97, 0.95, 0.88))
	draw_circle(c + Vector2(sin(t) * r * 0.08, -r * 0.05), r * 0.13 * blink, Color(0.65, 0.15, 0.1))
	draw_circle(c + Vector2(sin(t) * r * 0.08, -r * 0.05), r * 0.06 * blink, Color(0.05, 0.05, 0.05))
	# ağız ve dişler
	draw_rect(Rect2(c.x - r * 0.3, c.y + r * 0.38, r * 0.6, r * 0.12), Color(0.25, 0.08, 0.06))
	for i in 4:
		var x := c.x - r * 0.24 + i * r * 0.16
		draw_colored_polygon(PackedVector2Array([Vector2(x, c.y + r * 0.38), Vector2(x + r * 0.08, c.y + r * 0.38), Vector2(x + r * 0.04, c.y + r * 0.47)]), Color.WHITE)

func _sahmeran(c: Vector2, r: float) -> void:
	# yılan gövdesi
	var pts := PackedVector2Array()
	for i in 40:
		var k := float(i) / 39.0
		var a := k * TAU * 1.3 + t * 0.6
		pts.append(c + Vector2(cos(a) * r * (0.7 - k * 0.35), r * 0.45 + sin(a) * r * 0.18 - k * r * 0.2))
	draw_polyline(pts, Color(0.25, 0.55, 0.3), r * 0.16, true)
	draw_polyline(pts, Color(0.75, 0.8, 0.3, 0.6), r * 0.04, true)
	# kadın yüzü ve taç
	var skin := Color(0.93, 0.78, 0.62)
	draw_circle(c + Vector2(0, -r * 0.15), r * 0.3, skin)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.32, -r * 0.3), c + Vector2(r * 0.32, -r * 0.3), c + Vector2(r * 0.2, -r * 0.62), c + Vector2(0, -r * 0.45), c + Vector2(-r * 0.2, -r * 0.62)]), Ui.GOLD)
	draw_circle(c + Vector2(-r * 0.11, -r * 0.15), r * 0.04, Color(0.1, 0.3, 0.15))
	draw_circle(c + Vector2(r * 0.11, -r * 0.15), r * 0.04, Color(0.1, 0.3, 0.15))

func _alkarasi(c: Vector2, r: float) -> void:
	var cloak := Color(0.12, 0.08, 0.14)
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r * 0.7), c + Vector2(r * 0.55, r * 0.7), c + Vector2(-r * 0.55, r * 0.7)]), cloak)
	draw_circle(c + Vector2(0, -r * 0.2), r * 0.34, cloak)
	Gfx.ellipse(self, c + Vector2(0, -r * 0.15), r * 0.22, r * 0.26, Color(0.03, 0.02, 0.04))
	var glow := 0.7 + sin(t * 3.0) * 0.3
	draw_circle(c + Vector2(-r * 0.09, -r * 0.18), r * 0.05, Color(1, 0.2, 0.15, glow))
	draw_circle(c + Vector2(r * 0.09, -r * 0.18), r * 0.05, Color(1, 0.2, 0.15, glow))
	# dağınık saç
	for i in 7:
		var a := -PI * 0.9 + i * 0.3
		draw_line(c + Vector2(cos(a), sin(a)) * r * 0.3 + Vector2(0, -r * 0.2), c + Vector2(cos(a), sin(a)) * r * 0.6 + Vector2(sin(t * 2 + i) * 4, -r * 0.1), Color(0.2, 0.12, 0.22), 4.0)
