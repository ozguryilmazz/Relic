class_name Ui
extends RefCounted
## Arayüz yardımcıları ve tema.

const GOLD := Color(0.95, 0.78, 0.38)
const DARK := Color(0.1, 0.08, 0.07, 0.88)

static func box(col: Color, radius := 14, border := Color(0, 0, 0, 0), bw := 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(radius)
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb

static var _theme: Theme

static func theme() -> Theme:
	if _theme == null:
		_theme = make_theme()
	return _theme

static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 28
	t.set_stylebox("panel", "Panel", box(DARK, 16, Color(0.55, 0.42, 0.22), 2))
	t.set_stylebox("panel", "PanelContainer", box(DARK, 16, Color(0.55, 0.42, 0.22), 2))
	t.set_stylebox("normal", "Button", box(Color(0.42, 0.27, 0.13), 12, Color(0.75, 0.55, 0.25), 2))
	t.set_stylebox("hover", "Button", box(Color(0.5, 0.33, 0.16), 12, Color(0.9, 0.7, 0.3), 2))
	t.set_stylebox("pressed", "Button", box(Color(0.3, 0.19, 0.09), 12, Color(0.9, 0.7, 0.3), 2))
	t.set_stylebox("disabled", "Button", box(Color(0.25, 0.22, 0.2), 12, Color(0.35, 0.3, 0.25), 2))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", Color(1, 0.95, 0.85))
	t.set_color("font_disabled_color", "Button", Color(0.55, 0.5, 0.45))
	t.set_color("font_color", "Label", Color(1, 0.96, 0.88))
	t.set_stylebox("normal", "LineEdit", box(Color(0.15, 0.12, 0.1), 10, Color(0.6, 0.45, 0.25), 2))
	t.set_stylebox("focus", "LineEdit", box(Color(0.18, 0.14, 0.11), 10, GOLD, 2))
	return t

static func label(text: String, size := 28, col := Color(1, 0.96, 0.88), outline := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if outline:
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		l.add_theme_constant_override("outline_size", 7)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

static func button(text: String, size := 28, min_w := 0.0) -> TouchButton:
	var b := TouchButton.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.custom_minimum_size = Vector2(min_w, 64)
	b.focus_mode = Control.FOCUS_NONE
	return b

static func fmt_time(sec: float) -> String:
	var s := int(sec)
	return "%02d:%02d" % [s / 60, s % 60]
