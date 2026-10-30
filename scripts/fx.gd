class_name Fx
extends Node2D
## Efektler: ölüm dumanı, ulti dalgaları, yüzen yazılar.

var items: Array = []

func puff(p: Vector2, col := Color(0.9, 0.9, 0.9)) -> void:
	items.append({"type": "puff", "pos": p, "t": 0.0, "dur": 0.45, "col": col})

func ring(p: Vector2, r: float, col: Color, dur := 0.6) -> void:
	items.append({"type": "ring", "pos": p, "t": 0.0, "dur": dur, "r": r, "col": col})

func projectile(from: Vector2, to: Vector2, kind: String, dur: float, on_hit: Callable) -> void:
	items.append({"type": "proj", "from": from, "to": to, "kind": kind, "t": 0.0, "dur": dur, "on_hit": on_hit})

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
		if it.type == "proj" and it.t >= it.dur and not it.get("done", false):
			it.done = true
			it.on_hit.call()
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
			"proj":
				var a: Vector2 = it.from
				var b: Vector2 = it.to
				var h := 60.0 if it.kind == "arrow" else 140.0
				var pos := a.lerp(b, k) + Vector2(0, -sin(k * PI) * h)
				var nxt := a.lerp(b, minf(k + 0.03, 1.0)) + Vector2(0, -sin(minf(k + 0.03, 1.0) * PI) * h)
				match it.kind:
					"arrow":
						var d := (nxt - pos).normalized()
						draw_line(pos - d * 14.0, pos, Color(0.35, 0.25, 0.15), 2.0)
						draw_line(pos - d * 14.0, pos - d * 10.0, Color(0.9, 0.9, 0.9), 3.0)
					"ball":
						draw_circle(pos, 6.0, Color(0.12, 0.12, 0.14))
					"rock":
						Gfx.shadow(self, a.lerp(b, k) + Vector2(0, 30), 12.0 * (1.0 - sin(k * PI) * 0.5), 4.0, 0.2)
						draw_circle(pos, 11.0, Color(0.5, 0.5, 0.52))
						draw_circle(pos + Vector2(-3, -3), 4.0, Color(0.65, 0.65, 0.68))
			"ring":
				var c2: Color = it.col
				c2.a = 1.0 - k
				var pts := Gfx.ellipse_pts(it.pos, it.r * k, it.r * k * 0.6, 40)
				pts.append(pts[0])
				draw_polyline(pts, c2, 8.0 * (1.0 - k) + 2.0)
