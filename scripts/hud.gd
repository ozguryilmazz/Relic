class_name Hud
extends CanvasLayer
## Oyun içi arayüz: üst bar, ulti butonları, köle paneli, mini pencereler, duraklatma, oyun sonu.

var game: Game
var root: Control
var top_bar: PanelContainer
var res_labels := {}
var wave_label: Label
var phase_label: Label
var time_label: Label
var pause_btn: TouchButton
var ult_buttons: Array = []
var hint_label: Label
var slave_btn: TouchButton
var slave_panel: PanelContainer
var slave_info: Label
var slave_buy: TouchButton
var slave_rows := {}
var popup: PanelContainer
var popup_kind := ""
var popup_title: Label
var popup_rows: Array = []      # [{label, buttons, kind}]
var popup_note: Label
var banner_label: Label
var pause_overlay: Control
var over_overlay: Control
var blockers: Array = []

const SLAVE_KINDS := [["odun", "Orman"], ["tas", "Kayalık"], ["cali", "Çalılık"], ["kemik", "Çöl"]]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.theme = Ui.theme()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_top()
	_build_ults()
	_build_slaves()
	_build_popup()
	_build_banner()
	_build_pause()

# ---------------------------------------------------------------- kurulum

func _build_top() -> void:
	top_bar = PanelContainer.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_bottom = 84
	top_bar.add_theme_stylebox_override("panel", Ui.box(Color(0.08, 0.06, 0.05, 0.82), 0))
	root.add_child(top_bar)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 34)
	top_bar.add_child(hb)
	for k in ["odun", "tas", "kemik", "diken", "sifa"]:
		var l := Ui.label("", 30, Game.RES_COLORS[k])
		hb.add_child(l)
		res_labels[k] = l
	var fl := Ui.label("", 30, Color(0.85, 0.6, 1.0))
	hb.add_child(fl)
	res_labels["korku"] = fl
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(spacer)
	wave_label = Ui.label("", 30, Ui.GOLD)
	hb.add_child(wave_label)
	phase_label = Ui.label("", 26)
	hb.add_child(phase_label)
	time_label = Ui.label("", 28)
	hb.add_child(time_label)
	pause_btn = Ui.button("II", 30, 70)
	pause_btn.pressed.connect(_pause)
	hb.add_child(pause_btn)
	blockers.append(top_bar)

func _build_ults() -> void:
	for i in game.hero.ultis.size():
		var b := UltButton.new()
		b.game = game
		b.index = i
		b.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		b.offset_left = 40 + i * 190
		b.offset_top = -230
		b.offset_right = b.offset_left + 150
		b.offset_bottom = -80
		root.add_child(b)
		ult_buttons.append(b)
		blockers.append(b)
	hint_label = Ui.label("", 22, Color(1, 0.75, 1), true)
	hint_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hint_label.offset_left = 40
	hint_label.offset_top = -270
	hint_label.offset_bottom = -238
	root.add_child(hint_label)

func _build_slaves() -> void:
	slave_btn = Ui.button("Köleler", 28, 200)
	slave_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	slave_btn.offset_left = -240
	slave_btn.offset_top = -100
	slave_btn.offset_right = -30
	slave_btn.offset_bottom = -30
	slave_btn.pressed.connect(func(): slave_panel.visible = not slave_panel.visible)
	root.add_child(slave_btn)
	blockers.append(slave_btn)

	slave_panel = PanelContainer.new()
	slave_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	slave_panel.offset_left = -470
	slave_panel.offset_right = -30
	slave_panel.offset_top = -560
	slave_panel.offset_bottom = -115
	slave_panel.visible = false
	root.add_child(slave_panel)
	blockers.append(slave_panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	slave_panel.add_child(vb)
	slave_info = Ui.label("", 26)
	vb.add_child(slave_info)
	slave_buy = Ui.button("", 26)
	slave_buy.pressed.connect(func(): game.buy_slave())
	vb.add_child(slave_buy)
	for pair in SLAVE_KINDS:
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		vb.add_child(hb)
		var name_l := Ui.label(pair[1], 26)
		name_l.custom_minimum_size.x = 150
		hb.add_child(name_l)
		var minus := Ui.button("-", 30, 64)
		var k: String = pair[0]
		minus.pressed.connect(func(): game.assign_slave(k, -1))
		hb.add_child(minus)
		var cnt := Ui.label("0", 28)
		cnt.custom_minimum_size.x = 60
		cnt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hb.add_child(cnt)
		var plus := Ui.button("+", 30, 64)
		plus.pressed.connect(func(): game.assign_slave(k, 1))
		hb.add_child(plus)
		slave_rows[k] = cnt

func _build_popup() -> void:
	popup = PanelContainer.new()
	popup.visible = false
	root.add_child(popup)
	blockers.append(popup)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	popup.add_child(vb)
	popup_title = Ui.label("", 30, Ui.GOLD)
	vb.add_child(popup_title)
	for i in 3:
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 8)
		vb.add_child(hb)
		var l := Ui.label("", 26)
		l.custom_minimum_size.x = 230
		hb.add_child(l)
		var btns: Array = []
		for amt in [1, 10, -1]:
			var b := Ui.button("Tümü" if amt == -1 else "+%d" % amt, 26, 86)
			var row_i := i
			var a: int = amt
			b.pressed.connect(func(): _popup_add(row_i, a))
			hb.add_child(b)
			btns.append(b)
		popup_rows.append({"box": hb, "label": l, "buttons": btns, "kind": ""})
	popup_note = Ui.label("", 22, Color(1, 0.5, 0.45))
	popup_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	popup_note.custom_minimum_size.x = 480
	vb.add_child(popup_note)
	var close := Ui.button("Kapat", 24)
	close.pressed.connect(close_popup)
	vb.add_child(close)

func _build_banner() -> void:
	banner_label = Ui.label("", 72, Ui.GOLD, true)
	banner_label.set_anchors_preset(Control.PRESET_CENTER)
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.offset_left = -400
	banner_label.offset_right = 400
	banner_label.offset_top = -260
	banner_label.offset_bottom = -170
	banner_label.modulate.a = 0.0
	root.add_child(banner_label)

func _overlay() -> Control:
	var c := ColorRect.new()
	c.color = Color(0, 0, 0, 0.6)
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	c.visible = false
	root.add_child(c)
	blockers.append(c)
	return c

func _center_panel(parent: Control) -> VBoxContainer:
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(cc)
	var p := PanelContainer.new()
	cc.add_child(p)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	vb.custom_minimum_size.x = 560
	p.add_child(vb)
	return vb

func _build_pause() -> void:
	pause_overlay = _overlay()
	var vb := _center_panel(pause_overlay)
	var t := Ui.label("Duraklatıldı", 44, Ui.GOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var cont := Ui.button("Devam", 32)
	cont.pressed.connect(_resume)
	vb.add_child(cont)
	var menu := Ui.button("Ana Menü", 32)
	menu.pressed.connect(func():
		get_tree().paused = false
		game.to_menu.emit())
	vb.add_child(menu)

# ---------------------------------------------------------------- dışarıya açık

func blocks(screen_pos: Vector2) -> bool:
	for c in blockers:
		if c.is_visible_in_tree() and c.get_global_rect().has_point(screen_pos):
			return true
	return false

func popup_open() -> bool:
	return popup.visible

func close_popup() -> void:
	popup.visible = false
	popup_kind = ""

func open_popup(kind: String, screen_pos: Vector2) -> void:
	popup_kind = kind
	var kinds: Array = []
	match kind:
		"castle": kinds = ["odun", "tas", "kemik"]
		"barricade": kinds = ["tas", "kemik"]
		"thorns": kinds = ["diken"]
	for i in popup_rows.size():
		var row: Dictionary = popup_rows[i]
		row.box.visible = i < kinds.size()
		row.kind = kinds[i] if i < kinds.size() else ""
	popup.visible = true
	_refresh_popup()
	popup.reset_size()
	await get_tree().process_frame
	var vs := root.size
	var sz := popup.size
	var p := screen_pos + Vector2(30, -sz.y * 0.5)
	if p.x + sz.x > vs.x - 10:
		p.x = screen_pos.x - sz.x - 30
	p.x = clampf(p.x, 10, vs.x - sz.x - 10)
	p.y = clampf(p.y, 94, vs.y - sz.y - 10)
	popup.position = p

func banner(text: String) -> void:
	banner_label.text = text
	var tw := banner_label.create_tween()
	banner_label.modulate.a = 0.0
	tw.tween_property(banner_label, "modulate:a", 1.0, 0.25)
	tw.tween_interval(1.2)
	tw.tween_property(banner_label, "modulate:a", 0.0, 0.5)

func show_game_over(stats: Dictionary) -> void:
	close_popup()
	slave_panel.visible = false
	over_overlay = _overlay()
	over_overlay.visible = true
	var vb := _center_panel(over_overlay)
	var t := Ui.label("Zafer! 100 dalga dayandın." if stats.victory else "Kale düştü!", 46, Ui.GOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var lines := [
		"Kahraman: %s" % stats.hero,
		"Atlatılan dalga: %d" % stats.waves,
		"Dayanma süresi: %s" % Ui.fmt_time(stats.seconds),
		"Öldürülen düşman: %d" % stats.kills,
		"Edinilen köle: %d" % stats.slaves,
		"Toplanan: Odun %d · Taş %d · Kemik %d · Diken %d · Şifa %d" % [stats.odun, stats.tas, stats.kemik, stats.diken, stats.sifa],
	]
	for s in lines:
		vb.add_child(Ui.label(s, 26))
	var name_edit := LineEdit.new()
	name_edit.placeholder_text = "Adın (skor tablosu için)"
	name_edit.max_length = 16
	name_edit.text = Firebase.player_name
	name_edit.add_theme_font_size_override("font_size", 28)
	name_edit.custom_minimum_size.y = 64
	vb.add_child(name_edit)
	var status := Ui.label("", 24, Color(0.8, 0.9, 1.0))
	vb.add_child(status)
	var send := Ui.button("Skoru Gönder", 30)
	send.pressed.connect(func():
		var nm := name_edit.text.strip_edges()
		if nm.is_empty():
			status.text = "Önce bir ad yaz."
			return
		send.disabled = true
		status.text = "Gönderiliyor..."
		var ok: bool = await Firebase.submit_score(nm, stats)
		status.text = "Skor gönderildi!" if ok else "Gönderilemedi, internet bağlantını kontrol et."
		send.disabled = ok)
	vb.add_child(send)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	vb.add_child(hb)
	var again := Ui.button("Tekrar Oyna", 30)
	again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	again.pressed.connect(func(): game.restart.emit())
	hb.add_child(again)
	var menu := Ui.button("Ana Menü", 30)
	menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu.pressed.connect(func(): game.to_menu.emit())
	hb.add_child(menu)

func pause_game() -> void:
	if game.phase == "over" or get_tree().paused:
		return
	_pause()

# ---------------------------------------------------------------- iç işler

func _pause() -> void:
	close_popup()
	get_tree().paused = true
	pause_overlay.visible = true

func _resume() -> void:
	pause_overlay.visible = false
	get_tree().paused = false
	game.touches.clear()

func _popup_add(row_i: int, amt: int) -> void:
	var kind: String = popup_rows[row_i].kind
	var want := 1000000 if amt == -1 else amt
	match popup_kind:
		"castle": game.add_castle(kind, want)
		"barricade": game.add_barricade(kind, want)
		"thorns": game.add_thorns(want)

func _refresh_popup() -> void:
	popup_note.text = ""
	match popup_kind:
		"castle": popup_title.text = "Kale · Savunma %d" % int(ceil(game.castle_def))
		"barricade": popup_title.text = "Barikat · Can %d" % int(ceil(game.barricade.hp))
		"thorns": popup_title.text = "Diken bölgesi · %d diken" % int(game.thorns)
	var locked := popup_kind == "barricade" and game.barricade_locked()
	if locked:
		popup_note.text = "Barikat bölgesinde düşman var, şu an kurulamaz."
	for row in popup_rows:
		if row.kind == "":
			continue
		var have := int(floor(game.res[row.kind] + 0.0001))
		var gain := ""
		match popup_kind:
			"castle": gain = " (+%d)" % int(Bal.CASTLE_VALUE[row.kind])
			"barricade": gain = " (+%d)" % int(Bal.BARRICADE_VALUE[row.kind])
		row.label.text = "%s %d%s" % [Game.RES_NAMES[row.kind], have, gain]
		for b in row.buttons:
			b.disabled = locked or have < 1

func _process(_delta: float) -> void:
	if game == null:
		return
	for k in ["odun", "tas", "kemik", "diken", "sifa"]:
		res_labels[k].text = "%s %d" % [Game.RES_NAMES[k], int(floor(game.res[k] + 0.0001))]
	res_labels.korku.text = "Korku %d" % game.fear
	wave_label.text = "Dalga %d/%d" % [game.wave, Bal.MAX_WAVE]
	if game.phase == "prep":
		phase_label.text = "Hazırlık %d" % int(ceil(game.prep_left))
	elif game.phase == "wave":
		phase_label.text = "Düşman %d" % (game.enemies.size() + game.to_spawn)
	else:
		phase_label.text = ""
	time_label.text = Ui.fmt_time(game.time_alive)
	var waiting := false
	for i in game.ult_cd.size():
		if not game.ult_ready(i):
			waiting = true
	hint_label.text = "Beklemedeki ultiye dokun: şifa ye (-%d sn) · Şifa %d" % [int(Bal.HERB_COOLDOWN_CUT), int(game.res.sifa)] if waiting and game.res.sifa >= 1.0 else ""
	slave_btn.text = "Köleler %d" % game.slaves
	if slave_panel.visible:
		var cost := Bal.slave_cost(game.slaves)
		slave_info.text = "Boşta: %d / %d" % [game.free_slaves(), game.slaves]
		slave_buy.text = "Köle al (%d korku)" % cost
		slave_buy.disabled = game.fear < cost
		for k in slave_rows:
			slave_rows[k].text = str(game.slave_assign[k])
	if popup.visible:
		_refresh_popup()
