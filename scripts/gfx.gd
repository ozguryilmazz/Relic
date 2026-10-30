class_name Gfx
extends RefCounted
## Basit çizim yardımcıları (şimdilik görseller kodla çiziliyor).

static func ellipse_pts(c: Vector2, rx: float, ry: float, n := 24) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts

static func ellipse(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color) -> void:
	ci.draw_colored_polygon(ellipse_pts(c, rx, ry), col)

static func shadow(ci: CanvasItem, c: Vector2, rx: float, ry: float, alpha := 0.28) -> void:
	ellipse(ci, c, rx, ry, Color(0, 0, 0, alpha))

static func blob(ci: CanvasItem, c: Vector2, r: float, col: Color, seed_v: int, n := 10, wobble := 0.18) -> void:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		var w := 1.0 + wobble * sin(a * 3.0 + seed_v * 1.7) * cos(a * 2.0 + seed_v)
		pts.append(c + Vector2(cos(a), sin(a) * 0.85) * r * w)
	ci.draw_colored_polygon(pts, col)

## 2.5D kutu: ön yüz + üst yüz
static func box(ci: CanvasItem, base_center: Vector2, w: float, h: float, depth: float, front: Color, top: Color, side: Color) -> void:
	var x0 := base_center.x - w * 0.5
	var x1 := base_center.x + w * 0.5
	var y0 := base_center.y
	var d := Vector2(depth * 0.45, -depth * 0.55)
	# yan yüz
	ci.draw_colored_polygon(PackedVector2Array([Vector2(x1, y0), Vector2(x1, y0 - h), Vector2(x1, y0 - h) + d, Vector2(x1, y0) + d]), side)
	# üst yüz
	ci.draw_colored_polygon(PackedVector2Array([Vector2(x0, y0 - h), Vector2(x1, y0 - h), Vector2(x1, y0 - h) + d, Vector2(x0, y0 - h) + d]), top)
	# ön yüz
	ci.draw_rect(Rect2(x0, y0 - h, w, h), front)

static func bar(ci: CanvasItem, center: Vector2, w: float, h: float, ratio: float, col: Color) -> void:
	ci.draw_rect(Rect2(center.x - w * 0.5 - 1, center.y - 1, w + 2, h + 2), Color(0, 0, 0, 0.6))
	ci.draw_rect(Rect2(center.x - w * 0.5, center.y, w * clampf(ratio, 0.0, 1.0), h), col)
