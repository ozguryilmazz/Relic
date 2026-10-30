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
var speed_btn: TouchButton
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
var combo_label: Label
var boss_box: Control
var boss_bar: ProgressBar
var boss_label: Label
var thorn_btn: TouchButton
var relic_overlay: Control
var relic_cards: HBoxContainer
var relic_title: Label
var pause_relics: Label

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
	_build_extras()
	_build_pause()
	_build_relics()

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
	speed_btn = Ui.button("x1", 30, 90)
	speed_btn.pressed.connect(func():
		game.set_fast(not game.fast)
		speed_btn.text = "x2" if game.fast else "x1"
		speed_btn.add_theme_color_override("font_color", Ui.GOLD if game.fast else Color(1, 0.95, 0.85)))
	hb.add_child(speed_btn)
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
	banner_label.offset_left = -600
	banner_label.offset_right = 600
	banner_label.offset_top = -330
	banner_label.offset_bottom = -130
	banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
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
	pause_relics = Ui.label("", 22, Color(0.9, 0.85, 0.7))
	pause_relics.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(pause_relics)
	var cont := Ui.button("Devam", 32)
	cont.pressed.connect(_resume)
	vb.add_child(cont)
	Ui.audio_toggles(vb)
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
		"En uzun kombo: %d · Relik: %d" % [stats.best_combo, stats.relics],
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
	pause_relics.text = "Relikler: " + relic_summary() if not game.relics.is_empty() else "Henüz relik yok."

func relic_summary() -> String:
	var parts: Array = []
	for id in game.relics:
		var n: int = game.relics[id]
		parts.append(Bal.RELICS[id].name + ("" if n == 1 else " x%d" % n))
	return ", ".join(parts)

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
			"castle": gain = " (+%d)" % int(Bal.CASTLE_VALUE[row.kind] * (1.0 + 0.5 * game.lv("kale_deger")))
			"barricade": gain = " (+%d)" % int(Bal.BARRICADE_VALUE[row.kind] * (1.0 + 0.5 * game.lv("barikat_deger")))
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
		if not game.ult_ready(i) and game.herb_room(i) > 0.0:
			waiting = true
	hint_label.text = "Beklemedeki ultiye dokun: şifa ye (-%d sn) · Şifa %d" % [int(Bal.HERB_COOLDOWN_CUT), int(game.res.sifa)] if waiting and game.res.sifa >= 1.0 else ""
	slave_btn.text = "Köleler %d" % game.slaves
	if slave_panel.visible:
		var cost := game.slave_cost()
		slave_info.text = "Boşta: %d / %d" % [game.free_slaves(), game.slaves]
		slave_buy.text = "Köle al (%d korku)" % cost
		slave_buy.disabled = game.fear < cost
		for k in slave_rows:
			slave_rows[k].text = str(game.slave_assign[k])
	if popup.visible:
		_refresh_popup()
	# kombo
	if game.combo >= 5:
		combo_label.text = "KOMBO %d  ·  x%d" % [game.combo, game.combo_mult()]
		combo_label.modulate.a = 1.0
		var m := game.combo_mult()
		combo_label.add_theme_color_override("font_color", [Color.WHITE, Color.WHITE, Color(1, 0.85, 0.3), Color(1, 0.55, 0.2), Color(1, 0.3, 0.3)][mini(m, 4)])
	else:
		combo_label.modulate.a = maxf(0.0, combo_label.modulate.a - _delta * 3.0)
	# boss
	boss_box.visible = game.boss != null and is_instance_valid(game.boss)
	if boss_box.visible:
		boss_bar.max_value = game.boss.max_hp
		boss_bar.value = maxf(game.boss.hp, 0.0)
		boss_label.text = "%s  %d / %d" % [game.boss.data.name, int(ceil(maxf(game.boss.hp, 0.0))), int(game.boss.max_hp)]
	# diken dök butonu
	var d := int(floor(game.res.diken + 0.0001))
	thorn_btn.text = "Dikenleri dök (%d)" % d
	thorn_btn.disabled = d < 1

# ---------------------------------------------------------------- kombo, boss, relik

func _build_extras() -> void:
	combo_label = Ui.label("", 40, Color.WHITE, true)
	combo_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	combo_label.offset_left = -300
	combo_label.offset_right = 300
	combo_label.offset_top = 92
	combo_label.offset_bottom = 150
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_label.modulate.a = 0.0
	root.add_child(combo_label)

	boss_box = VBoxContainer.new()
	boss_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss_box.offset_left = -360
	boss_box.offset_right = 360
	boss_box.offset_top = 150
	boss_box.offset_bottom = 220
	boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_box.visible = false
	root.add_child(boss_box)
	boss_label = Ui.label("", 26, Color(1, 0.6, 0.5), true)
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_box.add_child(boss_label)
	boss_bar = ProgressBar.new()
	boss_bar.show_percentage = false
	boss_bar.custom_minimum_size.y = 18
	boss_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_bar.add_theme_stylebox_override("background", Ui.box(Color(0, 0, 0, 0.7), 6))
	boss_bar.add_theme_stylebox_override("fill", Ui.box(Color(0.85, 0.15, 0.12), 6))
	boss_box.add_child(boss_bar)

	thorn_btn = Ui.button("", 26, 260)
	thorn_btn.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	thorn_btn.offset_left = 430
	thorn_btn.offset_right = 730
	thorn_btn.offset_top = -100
	thorn_btn.offset_bottom = -30
	thorn_btn.add_theme_color_override("font_color", Game.RES_COLORS.diken)
	thorn_btn.pressed.connect(func(): game.add_thorns(1000000))
	root.add_child(thorn_btn)
	blockers.append(thorn_btn)

func _build_relics() -> void:
	relic_overlay = _overlay()
	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 30)
	relic_overlay.add_child(vb)
	relic_title = Ui.label("", 48, Ui.GOLD, true)
	relic_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(relic_title)
	relic_cards = HBoxContainer.new()
	relic_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	relic_cards.add_theme_constant_override("separation", 30)
	vb.add_child(relic_cards)

func relic_open() -> bool:
	return relic_overlay.visible

func show_relics(choices: Array, legend: bool) -> void:
	close_popup()
	for c in relic_cards.get_children():
		c.queue_free()
	relic_title.text = "Efsanevi relik seç!" if legend else "Dalga %d atlatıldı · Bir relik seç" % game.wave
	for id in choices:
		var r: Dictionary = Bal.RELICS[id]
		var have := game.lv(id)
		var b := TouchButton.new()
		b.custom_minimum_size = Vector2(440, 300)
		b.focus_mode = Control.FOCUS_NONE
		var border := Color(1, 0.7, 0.2) if legend else Color(0.6, 0.5, 0.3)
		var bg := Color(0.25, 0.12, 0.05, 0.96) if legend else Color(0.12, 0.1, 0.08, 0.96)
		b.add_theme_stylebox_override("normal", Ui.box(bg, 18, border, 4))
		b.add_theme_stylebox_override("hover", Ui.box(bg.lightened(0.1), 18, Ui.GOLD, 4))
		b.add_theme_stylebox_override("pressed", Ui.box(bg.darkened(0.2), 18, Ui.GOLD, 4))
		var inner := VBoxContainer.new()
		inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		inner.offset_left = 20
		inner.offset_right = -20
		inner.offset_top = 24
		inner.offset_bottom = -20
		inner.add_theme_constant_override("separation", 14)
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(inner)
		var nm := Ui.label(r.name, 34, Ui.GOLD if legend else Color(1, 0.92, 0.75))
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		inner.add_child(nm)
		var lvl := "Efsanevi" if legend else ("Yeni" if have == 0 else "Seviye %d → %d" % [have, have + 1])
		var ll := Ui.label(lvl, 22, Color(0.75, 0.7, 0.6))
		ll.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		inner.add_child(ll)
		var desc := Ui.label(r.desc, 28)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		inner.add_child(desc)
		var pick_id: String = id
		b.pressed.connect(func(): pick_relic(pick_id))
		relic_cards.add_child(b)
	relic_overlay.visible = true
	get_tree().paused = true
	Sfx.play("ulti", 0.8, -6.0)

func pick_relic(id: String) -> void:
	if not relic_overlay.visible:
		return
	relic_overlay.visible = false
	get_tree().paused = false
	game.touches.clear()
	game.take_relic(id)
	banner(Bal.RELICS[id].name)
