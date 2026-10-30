class_name Fx
extends Node2D
## Efektler: ölüm dumanı, ulti dalgaları, yüzen yazılar.

var items: Array = []

func puff(p: Vector2, col := Color(0.9, 0.9, 0.9)) -> void:
	items.append({"type": "puff", "pos": p, "t": 0.0, "dur": 0.45, "col": col})

func ring(p: Vector2, r: float, col: Color, dur := 0.6) -> void:
	items.append({"type": "ring", "pos": p, "t": 0.0, "dur": dur, "r": r, "col": col})

func text(p: Vector2, s: String, col := Color.WHITE, size := 30) -> void:
	var l := Label.new()
	l.text = s
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 7)
	l.position = p + Vector2(randf_range(-10, 10), -30)
	l.z_index = 20
	add_child(l)
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 60, 0.7)
	tw.tween_property(l, "modulate:a", 0.0, 0.7).set_delay(0.15)
	tw.chain().tween_callback(l.queue_free)

func _process(delta: float) -> void:
	if items.is_empty():
		return
	for it in items:
		it.t += delta
	items = items.filter(func(it): return it.t < it.dur)
	queue_redraw()

func _draw() -> void:
	for it in items:
		var k: float = it.t / it.dur
		match it.type:
			"puff":
				for i in 5:
					var a := TAU * i / 5.0
					var p: Vector2 = it.pos + Vector2(cos(a), sin(a) * 0.6) * 22.0 * k + Vector2(0, -20)
					var c: Color = it.col
					c.a = 1.0 - k
					draw_circle(p, 9.0 * (1.0 - k * 0.5), c)
			"ring":
				var c2: Color = it.col
				c2.a = 1.0 - k
				var pts := Gfx.ellipse_pts(it.pos, it.r * k, it.r * k * 0.6, 40)
				pts.append(pts[0])
				draw_polyline(pts, c2, 8.0 * (1.0 - k) + 2.0)
