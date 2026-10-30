class_name UltButton
extends Control
## Yuvarlak ulti butonu. Hazırsa basınca ulti; beklerken basılı tutunca şifalı bitki yer.

var game: Game
var index := 0
var held := -1
var eat_timer := 0.0
var pulse := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(150, 150)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if held != -1:
				return
			held = event.index
			eat_timer = Bal.HERB_EAT_INTERVAL * 4.0
			game.ult_press(index)
			pulse = 1.0
		elif event.index == held:
			held = -1
		accept_event()

func _process(delta: float) -> void:
	pulse = maxf(0.0, pulse - delta * 4.0)
	if held != -1 and game and not game.ult_ready(index):
		eat_timer -= delta
		if eat_timer <= 0.0:
			eat_timer = Bal.HERB_EAT_INTERVAL
			game.eat_herb(index)
	queue_redraw()

func _draw() -> void:
	if game == null:
		return
	var u: Dictionary = game.hero.ultis[index]
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5 - 4.0
	var col: Color = game.hero.color
	var ready := game.ult_ready(index)
	draw_circle(c + Vector2(0, 5), r, Color(0, 0, 0, 0.35))
	draw_circle(c, r + pulse * 6.0, col.darkened(0.1) if ready else col.darkened(0.55))
	draw_arc(c, r, 0, TAU, 48, Ui.GOLD if ready else Color(0.4, 0.35, 0.3), 5.0)
	var font := get_theme_default_font()
	if not ready:
		var k: float = game.ult_cd[index] / maxf(game.ult_cooldown(index), 0.01)
		var pts := PackedVector2Array([c])
		var steps := 40
		for i in steps + 1:
			var a := -PI * 0.5 + TAU * k * float(i) / steps
			pts.append(c + Vector2(cos(a), sin(a)) * (r - 3))
		if pts.size() >= 3:
			draw_colored_polygon(pts, Color(0, 0, 0, 0.45))
		var cd := "%d" % int(ceil(game.ult_cd[index]))
		draw_string_outline(font, Vector2(0, c.y + 18), cd, HORIZONTAL_ALIGNMENT_CENTER, size.x, 48, 8, Color(0, 0, 0, 0.8))
		draw_string(font, Vector2(0, c.y + 18), cd, HORIZONTAL_ALIGNMENT_CENTER, size.x, 48, Color.WHITE)
	else:
		draw_string_outline(font, Vector2(0, c.y + 10), "HAZIR", HORIZONTAL_ALIGNMENT_CENTER, size.x, 28, 7, Color(0, 0, 0, 0.8))
		draw_string(font, Vector2(0, c.y + 10), "HAZIR", HORIZONTAL_ALIGNMENT_CENTER, size.x, 28, Color.WHITE)
	# isim (altta) ve şifa ipucu
	draw_string_outline(font, Vector2(-20, size.y + 28), u.name, HORIZONTAL_ALIGNMENT_CENTER, size.x + 40, 22, 6, Color(0, 0, 0, 0.8))
	draw_string(font, Vector2(-20, size.y + 28), u.name, HORIZONTAL_ALIGNMENT_CENTER, size.x + 40, 22, Ui.GOLD)
