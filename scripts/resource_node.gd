class_name ResourceNode
extends Node2D
## Kaynak bölgesi: orman (odun), kayalık (taş), çalılık (diken/şifa), çöl kemikleri (kemik).
## Tükenmez; tıklanınca zıplar.

var kind := "odun"
var radius := 110.0
var items: Array = []        # [{pos, size, seed, pop}]
var slaves := 0              # bu bölgeye atanan köle sayısı (çizim için)

func setup(k: String, r: float, count: int, seed_v: int) -> void:
	kind = k
	radius = r
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	for i in count:
		var a := rng.randf() * TAU
		var d := sqrt(rng.randf()) * r * 0.78
		items.append({
			"pos": Vector2(cos(a) * d, sin(a) * d * 0.62),
			"size": rng.randf_range(0.8, 1.2),
			"seed": rng.randi() % 1000,
			"pop": 0.0,
		})
	items.sort_custom(func(a, b): return a.pos.y < b.pos.y)

func contains(p: Vector2) -> bool:
	var d := p - global_position
	return Vector2(d.x, d.y / 0.65).length() <= radius

## Dokunulan noktaya en yakın öğeyi zıplat
func tap(p: Vector2) -> void:
	var local := p - global_position
	var best := 0
	var best_d := INF
	for i in items.size():
		var d: float = items[i].pos.distance_to(local)
		if d < best_d:
			best_d = d
			best = i
	if not items.is_empty():
		items[best].pop = 1.0

func _process(delta: float) -> void:
	var dirty := false
	for it in items:
		if it.pop > 0.0:
			it.pop = maxf(0.0, it.pop - delta * 5.0)
			dirty = true
	if dirty:
		queue_redraw()

func _draw() -> void:
	# zemin lekesi
	match kind:
		"kemik":
			Gfx.ellipse(self, Vector2.ZERO, radius * 1.15, radius * 0.75, Color(0.86, 0.74, 0.48))
			Gfx.ellipse(self, Vector2(10, 6), radius * 0.9, radius * 0.55, Color(0.9, 0.8, 0.55))
		"tas":
			Gfx.ellipse(self, Vector2.ZERO, radius * 1.05, radius * 0.7, Color(0.42, 0.45, 0.36, 0.6))
		_:
			Gfx.ellipse(self, Vector2.ZERO, radius * 1.05, radius * 0.7, Color(0.18, 0.34, 0.16, 0.45))
	for it in items:
		var pop: float = it.pop
		var squash := 1.0 + sin(pop * PI) * 0.25
		var jump := sin(pop * PI) * 14.0
		var sz: float = it.size
		var p: Vector2 = it.pos
		draw_set_transform(p + Vector2(0, -jump), 0.0, Vector2(1.0 / squash * 1.0, squash))
		match kind:
			"odun": _draw_tree(sz, it.seed, jump)
			"tas": _draw_rock(sz, it.seed)
			"cali": _draw_bush(sz, it.seed)
			"kemik": _draw_bone(sz, it.seed)
		draw_set_transform(Vector2.ZERO)
	# köle göstergesi
	for i in slaves:
		var sp := Vector2(-radius * 0.6 + i * 18.0, radius * 0.55)
		if i >= 12:
			break
		Gfx.shadow(self, sp + Vector2(0, 2), 7, 3)
		draw_rect(Rect2(sp.x - 5, sp.y - 16, 10, 14), Color(0.45, 0.38, 0.3))
		draw_circle(sp + Vector2(0, -21), 5.0, Color(0.85, 0.7, 0.55))
	if slaves > 12:
		draw_string(ThemeDB.fallback_font, Vector2(-radius * 0.6 + 12 * 18.0, radius * 0.55), "+%d" % (slaves - 12), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)

func _draw_tree(sz: float, sd: int, jump: float) -> void:
	Gfx.shadow(self, Vector2(0, jump + 4), 26 * sz, 9 * sz)
	draw_rect(Rect2(-5 * sz, -26 * sz, 10 * sz, 28 * sz), Color(0.42, 0.27, 0.14))
	var g1 := Color(0.16, 0.42 + (sd % 7) * 0.02, 0.17)
	var g2 := g1.lightened(0.18)
	draw_colored_polygon(PackedVector2Array([Vector2(-30, -22) * sz, Vector2(30, -22) * sz, Vector2(0, -70) * sz]), g1)
	draw_colored_polygon(PackedVector2Array([Vector2(-24, -48) * sz, Vector2(24, -48) * sz, Vector2(0, -92) * sz]), g2)
	draw_colored_polygon(PackedVector2Array([Vector2(-16, -72) * sz, Vector2(16, -72) * sz, Vector2(0, -108) * sz]), g2.lightened(0.12))

func _draw_rock(sz: float, sd: int) -> void:
	Gfx.shadow(self, Vector2(4, 4), 30 * sz, 10 * sz)
	var base := Color(0.55, 0.55, 0.58).darkened((sd % 5) * 0.04)
	var pts := PackedVector2Array([Vector2(-30, 0), Vector2(-26, -26), Vector2(-6, -44), Vector2(18, -38), Vector2(32, -14), Vector2(28, 0)])
	for i in pts.size():
		pts[i] *= sz
	draw_colored_polygon(pts, base)
	draw_colored_polygon(PackedVector2Array([Vector2(-26, -26) * sz, Vector2(-6, -44) * sz, Vector2(18, -38) * sz, Vector2(2, -24) * sz]), base.lightened(0.25))
	draw_colored_polygon(PackedVector2Array([Vector2(18, -38) * sz, Vector2(32, -14) * sz, Vector2(28, 0) * sz, Vector2(8, -6) * sz]), base.darkened(0.2))

func _draw_bush(sz: float, sd: int) -> void:
	Gfx.shadow(self, Vector2(0, 4), 28 * sz, 9 * sz)
	Gfx.blob(self, Vector2(0, -18) * sz, 26 * sz, Color(0.2, 0.38, 0.14), sd)
	Gfx.blob(self, Vector2(-8, -26) * sz, 16 * sz, Color(0.28, 0.48, 0.18), sd + 3)
	var rng := RandomNumberGenerator.new()
	rng.seed = sd
	for i in 6:
		var p := Vector2(rng.randf_range(-20, 20), rng.randf_range(-34, -6)) * sz
		if i % 2 == 0:
			draw_colored_polygon(PackedVector2Array([p + Vector2(-3, 2), p + Vector2(3, 2), p + Vector2(0, -6)]), Color(0.85, 0.85, 0.7))
		else:
			draw_circle(p, 3.5 * sz, Color(0.75, 0.25, 0.75))

func _draw_bone(sz: float, sd: int) -> void:
	var c := Color(0.95, 0.93, 0.86)
	var dark := Color(0.7, 0.66, 0.58)
	if sd % 3 == 0:
		# kafatası
		Gfx.shadow(self, Vector2(0, 3), 20 * sz, 7 * sz)
		draw_circle(Vector2(0, -16) * sz, 14 * sz, c)
		draw_rect(Rect2(-8 * sz, -8 * sz, 16 * sz, 8 * sz), c)
		draw_circle(Vector2(-5, -17) * sz, 4 * sz, Color(0.2, 0.15, 0.1))
		draw_circle(Vector2(5, -17) * sz, 4 * sz, Color(0.2, 0.15, 0.1))
	else:
		# kemik
		Gfx.shadow(self, Vector2(0, 3), 24 * sz, 6 * sz)
		draw_line(Vector2(-18, -6) * sz, Vector2(18, -10) * sz, c, 7 * sz)
		for e in [Vector2(-18, -6), Vector2(18, -10)]:
			draw_circle((e + Vector2(0, -4)) * sz, 5 * sz, c)
			draw_circle((e + Vector2(0, 4)) * sz, 5 * sz, c)
		draw_line(Vector2(-14, -2) * sz, Vector2(14, -6) * sz, dark, 2 * sz)
