class_name Menu
extends Control
## Ana menü: Oyna / Skor Tablosu / Ayarlar, kahraman seçimi, güncelleme bildirimi.

signal hero_chosen(index: int)

var update_bar: Control
var board_overlay: ColorRect
var board_list: VBoxContainer
var main_screen: Control
var hero_screen: Control
var settings_overlay: ColorRect
var settings_status: Label
var settings_download: TouchButton
var settings_check: TouchButton
var name_edit: LineEdit

func _ready() -> void:
	theme = Ui.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.16, 0.11)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_build_main_screen()
	_build_hero_screen()

	update_bar = Ui.button("", 28)
	update_bar.visible = false
	update_bar.add_theme_stylebox_override("normal", Ui.box(Color(0.2, 0.45, 0.2), 12, Ui.GOLD, 2))
	update_bar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	update_bar.offset_left = -560
	update_bar.offset_right = -20
	update_bar.offset_top = 20
	update_bar.offset_bottom = 90
	add_child(update_bar)
	update_bar.pressed.connect(func(): OS.shell_open(Firebase.update_info.get("url", Firebase.RELEASES_URL)))
	Firebase.update_available.connect(_on_update)
	if not Firebase.update_info.is_empty():
		_on_update(Firebase.update_info.name, Firebase.update_info.url)

	_build_board()
	_build_settings()

func _card(i: int) -> Control:
	var h: Dictionary = Bal.HEROES[i]
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(520, 0)
	p.add_theme_stylebox_override("panel", Ui.box(Color(0.1, 0.08, 0.07, 0.92), 18, h.color.lightened(0.2), 3))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	p.add_child(vb)
	var em := HeroEmblem.new()
	em.hero_id = h.id
	em.col = h.color
	em.custom_minimum_size = Vector2(0, 190)
	em.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(em)
	var nm := Ui.label(h.name, 42, h.color.lightened(0.45))
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(nm)
	var desc := Ui.label(h.desc, 22, Color(0.85, 0.8, 0.72))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(desc)
	for u in h.ultis:
		var ul := Ui.label("%s · %d sn" % [u.name, int(u.cooldown)], 25, Ui.GOLD)
		vb.add_child(ul)
		var ui := Ui.label(u.info, 21)
		ui.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vb.add_child(ui)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(sp)
	var b := Ui.button("Seç ve Başla", 30)
	b.pressed.connect(func(): hero_chosen.emit(i))
	vb.add_child(b)
	return p

func _on_update(version_name: String, _url: String) -> void:
	update_bar.text = "Yeni sürüm var (%s) · İndir" % version_name
	update_bar.visible = true

func _build_board() -> void:
	board_overlay = ColorRect.new()
	board_overlay.color = Color(0, 0, 0, 0.7)
	board_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board_overlay.visible = false
	add_child(board_overlay)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board_overlay.add_child(cc)
	var p := PanelContainer.new()
	cc.add_child(p)
	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(1100, 760)
	vb.add_theme_constant_override("separation", 12)
	p.add_child(vb)
	var t := Ui.label("Skor Tablosu", 44, Ui.GOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(sc)
	board_list = VBoxContainer.new()
	board_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_list.add_theme_constant_override("separation", 6)
	sc.add_child(board_list)
	var close := Ui.button("Kapat", 30)
	close.pressed.connect(func(): board_overlay.visible = false)
	vb.add_child(close)

func _row(cols: Array, col := Color(1, 0.96, 0.88), size := 26) -> HBoxContainer:
	var hb := HBoxContainer.new()
	var widths := [70, 330, 200, 150, 150, 150]
	for i in cols.size():
		var l := Ui.label(str(cols[i]), size, col)
		l.custom_minimum_size.x = widths[i]
		l.clip_text = true
		hb.add_child(l)
	return hb

func _open_board() -> void:
	board_overlay.visible = true
	for c in board_list.get_children():
		c.queue_free()
	board_list.add_child(Ui.label("Yükleniyor...", 26))
	var scores: Array = await Firebase.fetch_scores(30)
	for c in board_list.get_children():
		c.queue_free()
	if scores.is_empty():
		board_list.add_child(Ui.label("Henüz skor yok ya da bağlantı kurulamadı.", 26))
		return
	board_list.add_child(_row(["#", "Ad", "Kahraman", "Dalga", "Süre", "Öldürme"], Ui.GOLD, 24))
	for i in scores.size():
		var s: Dictionary = scores[i]
		board_list.add_child(_row([i + 1, s.get("name", "?"), s.get("hero", ""), int(s.get("waves", 0)), Ui.fmt_time(float(s.get("seconds", 0))), int(s.get("kills", 0))]))

# ---------------------------------------------------------------- ekranlar

func _build_main_screen() -> void:
	main_screen = CenterContainer.new()
	main_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(main_screen)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 22)
	vb.custom_minimum_size.x = 520
	main_screen.add_child(vb)
	var title := Ui.label("RELIC", 120, Ui.GOLD, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	var sub := Ui.label("Kaleni koru.", 32, Color(0.9, 0.85, 0.75))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub)
	var gap := Control.new()
	gap.custom_minimum_size.y = 30
	vb.add_child(gap)
	var play := Ui.button("Oyna", 40)
	play.custom_minimum_size.y = 90
	play.pressed.connect(func(): _show(hero_screen))
	vb.add_child(play)
	var board := Ui.button("Skor Tablosu", 34)
	board.custom_minimum_size.y = 80
	board.pressed.connect(_open_board)
	vb.add_child(board)
	var settings := Ui.button("Ayarlar", 34)
	settings.custom_minimum_size.y = 80
	settings.pressed.connect(_open_settings)
	vb.add_child(settings)
	var ver := Ui.label("Sürüm %s" % AppVersion.NAME, 22, Color(1, 1, 1, 0.5))
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(ver)

func _build_hero_screen() -> void:
	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.offset_top = 30
	vb.offset_bottom = -20
	vb.add_theme_constant_override("separation", 18)
	vb.visible = false
	add_child(vb)
	hero_screen = vb
	var sub := Ui.label("Kahramanını seç", 44, Ui.GOLD, true)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub)
	var cards := HBoxContainer.new()
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", 30)
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(cards)
	for i in Bal.HEROES.size():
		cards.add_child(_card(i))
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(bottom)
	var back := Ui.button("Geri", 30, 260)
	back.pressed.connect(func(): _show(main_screen))
	bottom.add_child(back)

func _show(screen: Control) -> void:
	main_screen.visible = screen == main_screen
	hero_screen.visible = screen == hero_screen

func _build_settings() -> void:
	settings_overlay = ColorRect.new()
	settings_overlay.color = Color(0, 0, 0, 0.7)
	settings_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings_overlay.visible = false
	add_child(settings_overlay)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings_overlay.add_child(cc)
	var p := PanelContainer.new()
	cc.add_child(p)
	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(760, 0)
	vb.add_theme_constant_override("separation", 16)
	p.add_child(vb)
	var t := Ui.label("Ayarlar", 44, Ui.GOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)

	vb.add_child(Ui.label("Oyuncu adı (skor tablosunda görünür)", 24, Color(0.85, 0.8, 0.72)))
	name_edit = LineEdit.new()
	name_edit.max_length = 16
	name_edit.placeholder_text = "Adın"
	name_edit.add_theme_font_size_override("font_size", 28)
	name_edit.custom_minimum_size.y = 64
	name_edit.text_changed.connect(func(txt): Firebase.set_player_name(txt.strip_edges()))
	vb.add_child(name_edit)

	Ui.audio_toggles(vb)
	vb.add_child(Ui.label("Sürüm: %s" % AppVersion.NAME, 28))
	settings_check = Ui.button("Güncellemeleri kontrol et", 30)
	settings_check.pressed.connect(_check_update)
	vb.add_child(settings_check)
	settings_status = Ui.label("", 26, Color(0.8, 0.9, 1.0))
	settings_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(settings_status)
	settings_download = Ui.button("İndir", 30)
	settings_download.visible = false
	settings_download.add_theme_stylebox_override("normal", Ui.box(Color(0.2, 0.45, 0.2), 12, Ui.GOLD, 2))
	settings_download.pressed.connect(func(): OS.shell_open(Firebase.update_info.get("url", Firebase.RELEASES_URL)))
	vb.add_child(settings_download)
	var all := Ui.button("Tüm sürümler (GitHub)", 26)
	all.pressed.connect(func(): OS.shell_open(Firebase.RELEASES_URL.replace("/latest", "")))
	vb.add_child(all)

	var close := Ui.button("Kapat", 30)
	close.pressed.connect(func(): settings_overlay.visible = false)
	vb.add_child(close)

func _open_settings() -> void:
	name_edit.text = Firebase.player_name
	settings_status.text = ""
	settings_download.visible = not Firebase.update_info.is_empty()
	if settings_download.visible:
		settings_status.text = "Yeni sürüm var: %s" % Firebase.update_info.name
	settings_overlay.visible = true

func _check_update() -> void:
	settings_check.disabled = true
	settings_status.text = "Kontrol ediliyor..."
	var r: Dictionary = await Firebase.check_update()
	settings_check.disabled = false
	match r.status:
		"available":
			settings_status.text = "Yeni sürüm var: %s. İndir'e basınca tarayıcıda indirme sayfası açılır; indirilen APK'yı kurman yeterli." % r.name
			settings_download.visible = true
		"uptodate":
			settings_status.text = "En güncel sürümü kullanıyorsun."
			settings_download.visible = false
		"dev":
			settings_status.text = "Geliştirme sürümü, kontrol yapılmadı."
		_:
			settings_status.text = "Kontrol edilemedi. İnternet bağlantını kontrol et."
