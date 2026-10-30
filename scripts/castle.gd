class_name Castle
extends Node2D
## Kale çizimi. Oyuncu kalesi solda, düşman kalesi sağda.

var is_player := true
var value := 0.0
var shake := 0.0
var flag_t := 0.0

func hit_fx() -> void:
	shake = 0.25

func _process(delta: float) -> void:
	shake = maxf(0.0, shake - delta)
	flag_t += delta
	queue_redraw()

func _draw() -> void:
	var off := Vector2.ZERO
	if shake > 0.0:
		off = Vector2(randf_range(-4, 4), randf_range(-2, 2))
	draw_set_transform(off)
	var stone := Color(0.62, 0.58, 0.52) if is_player else Color(0.42, 0.36, 0.36)
	var top := stone.lightened(0.2)
	var side := stone.darkened(0.25)
	var flag := Color(0.15, 0.5, 0.85) if is_player else Color(0.8, 0.15, 0.12)
	Gfx.shadow(self, Vector2(20, 0), 150, 34, 0.3)
	# arka kuleler
	Gfx.box(self, Vector2(-70, -40), 56, 190, 50, stone.darkened(0.08), top, side)
	Gfx.box(self, Vector2(70, -40), 56, 190, 50, stone.darkened(0.08), top, side)
	# ana duvar
	Gfx.box(self, Vector2(0, 0), 220, 120, 70, stone, top, side)
	# mazgallar
	for i in 6:
		var x := -105.0 + i * 40.0
		draw_rect(Rect2(x, -136, 22, 16), stone)
	# ön kuleler
	Gfx.box(self, Vector2(-100, 6), 60, 170, 46, stone, top, side)
	Gfx.box(self, Vector2(100, 6), 60, 170, 46, stone, top, side)
	for tx in [-100.0, 100.0]:
		draw_colored_polygon(PackedVector2Array([Vector2(tx - 38, -164), Vector2(tx + 38, -164), Vector2(tx + 10, -214)]), flag.darkened(0.3))
		# bayrak direği
		draw_line(Vector2(tx + 10, -214), Vector2(tx + 10, -262), Color(0.25, 0.2, 0.15), 3.0)
		var w := sin(flag_t * 4.0 + tx) * 5.0
		draw_colored_polygon(PackedVector2Array([Vector2(tx + 10, -262), Vector2(tx + 48, -252 + w), Vector2(tx + 10, -240)]), flag)
	# kapı
	var gx := 0.0
	draw_rect(Rect2(gx - 30, -64, 60, 64), Color(0.18, 0.12, 0.08))
	draw_circle(Vector2(gx, -64), 30.0, Color(0.18, 0.12, 0.08))
	for i in 4:
		draw_line(Vector2(gx - 22 + i * 15, -80), Vector2(gx - 22 + i * 15, 0), Color(0.35, 0.25, 0.15), 3.0)
	draw_set_transform(Vector2.ZERO)
	if is_player:
		var txt := "Savunma %d" % int(ceil(value))
		var font := ThemeDB.fallback_font
		var col := Color(1, 1, 1) if value > 30 else Color(1, 0.4, 0.35)
		draw_string_outline(font, Vector2(-110, -290), txt, HORIZONTAL_ALIGNMENT_CENTER, 220, 30, 8, Color(0, 0, 0, 0.8))
		draw_string(font, Vector2(-110, -290), txt, HORIZONTAL_ALIGNMENT_CENTER, 220, 30, col)
