class_name GamePath
extends RefCounted
## Kıvrımlı yol. Düşman kalesinden (sağ) oyuncu kalesine (sol) uzanır.
## Konumlar "s" ile ifade edilir: yolun başından itibaren piksel cinsinden mesafe.

var points: PackedVector2Array = PackedVector2Array()
var cum: PackedFloat32Array = PackedFloat32Array()
var length := 0.0

func _init(control_points: Array) -> void:
	_build(control_points)

func _build(cp: Array) -> void:
	# Catmull-Rom ile yumuşatılmış çizgi
	var pts: Array = cp.duplicate()
	pts.insert(0, pts[0])
	pts.append(pts[pts.size() - 1])
	for i in range(1, pts.size() - 2):
		var p0: Vector2 = pts[i - 1]
		var p1: Vector2 = pts[i]
		var p2: Vector2 = pts[i + 1]
		var p3: Vector2 = pts[i + 2]
		var steps := 24
		for k in steps:
			var t := float(k) / steps
			var t2 := t * t
			var t3 := t2 * t
			var p := 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3)
			points.append(p)
	points.append(cp[cp.size() - 1])
	cum.resize(points.size())
	cum[0] = 0.0
	for i in range(1, points.size()):
		cum[i] = cum[i - 1] + points[i].distance_to(points[i - 1])
	length = cum[cum.size() - 1]

func pos_at(s: float) -> Vector2:
	s = clampf(s, 0.0, length)
	var lo := 0
	var hi := cum.size() - 1
	while hi - lo > 1:
		var mid := (lo + hi) / 2
		if cum[mid] <= s:
			lo = mid
		else:
			hi = mid
	var seg := cum[hi] - cum[lo]
	if seg <= 0.0001:
		return points[lo]
	return points[lo].lerp(points[hi], (s - cum[lo]) / seg)

func dir_at(s: float) -> Vector2:
	return (pos_at(s + 4.0) - pos_at(s - 4.0)).normalized()

## Verilen noktaya yolun en yakın konumu ve mesafesi
func closest(p: Vector2) -> Dictionary:
	var best_d := INF
	var best_s := 0.0
	for i in range(points.size() - 1):
		var a := points[i]
		var b := points[i + 1]
		var ab := b - a
		var l2 := ab.length_squared()
		var t := 0.0
		if l2 > 0.0:
			t = clampf((p - a).dot(ab) / l2, 0.0, 1.0)
		var q := a + ab * t
		var d := q.distance_to(p)
		if d < best_d:
			best_d = d
			best_s = cum[i] + (cum[i + 1] - cum[i]) * t
	return {"s": best_s, "dist": best_d}

func sub_points(s0: float, s1: float, step := 10.0) -> PackedVector2Array:
	var out := PackedVector2Array()
	var s := s0
	while s < s1:
		out.append(pos_at(s))
		s += step
	out.append(pos_at(s1))
	return out
