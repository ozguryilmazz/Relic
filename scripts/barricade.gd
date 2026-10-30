class_name Barricade
extends Node2D
## Yol üzerindeki barikat. Düşmana hasar vermez, sadece onları diken bölgesinde tutar.

var hp := 0.0
var peak := 1.0
var shake := 0.0

func hit_fx() -> void:
	shake = 0.15

func _process(delta: float) -> void:
	shake = maxf(0.0, shake - delta)
	peak = maxf(peak, hp)
	queue_redraw()

func _draw() -> void:
	var off := Vector2(randf_range(-3, 3), 0) if shake > 0.0 else Vector2.ZERO
	draw_set_transform(off)
	var wood := Color(0.5, 0.33, 0.17)
	var stone := Color(0.55, 0.55, 0.58)
	if hp > 0.0:
		Gfx.shadow(self, Vector2(6, 4), 30, 60, 0.3)
		# taş temel
		for i in 5:
			var y := -48.0 + i * 24.0
			Gfx.blob(self, Vector2(4, y + 6), 14.0, stone.darkened(0.05 * (i % 2)), i)
		# kazıklar
		for i in 7:
			var y := -54.0 + i * 18.0
			var x := -4.0 + (i % 2) * 6.0
			draw_line(Vector2(x, y), Vector2(x - 6, y - 52), wood, 7.0)
			draw_colored_polygon(PackedVector2Array([Vector2(x - 10, y - 50), Vector2(x - 2, y - 54), Vector2(x - 10, y - 66)]), wood.lightened(0.15))
		# kemik süsleri
		draw_circle(Vector2(-8, -70), 7.0, Color(0.95, 0.93, 0.86))
		draw_circle(Vector2(-11, -72), 2.0, Color(0.1, 0.1, 0.1))
		draw_circle(Vector2(-5, -72), 2.0, Color(0.1, 0.1, 0.1))
		draw_set_transform(Vector2.ZERO)
		Gfx.bar(self, Vector2(0, -100), 70, 7, hp / peak, Color(0.95, 0.75, 0.2))
		var font := ThemeDB.fallback_font
		var t := "%d" % int(ceil(hp))
		draw_string_outline(font, Vector2(-50, -110), t, HORIZONTAL_ALIGNMENT_CENTER, 100, 24, 6, Color(0, 0, 0, 0.8))
		draw_string(font, Vector2(-50, -110), t, HORIZONTAL_ALIGNMENT_CENTER, 100, 24, Color.WHITE)
	else:
		# yıkık / boş barikat yeri
		for i in 4:
			var y := -40.0 + i * 26.0
			draw_line(Vector2(-2, y), Vector2(-6, y - 12), wood.darkened(0.3), 6.0)
		draw_set_transform(Vector2.ZERO)
		var font := ThemeDB.fallback_font
		draw_string_outline(font, Vector2(-70, -70), "Barikat", HORIZONTAL_ALIGNMENT_CENTER, 140, 22, 6, Color(0, 0, 0, 0.7))
		draw_string(font, Vector2(-70, -70), "Barikat", HORIZONTAL_ALIGNMENT_CENTER, 140, 22, Color(1, 1, 1, 0.8))
