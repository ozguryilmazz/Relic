extends Node
## Otomatik oyuncu ile hızlı denge testi:
## godot --headless --path . --fixed-fps 60 res://tools/sim_test.tscn -- [tık/sn] [kahraman]
## Ortalama bir oyuncuyu taklit eder ve kaçıncı dalgada düştüğünü yazar.

var game: Game
var frames := 0
var taps_per_sec := 5.0
var hero_i := 0
var acc := 0.0
var spend_timer := 0.0
var last_wave := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		taps_per_sec = float(args[0])
	if args.size() > 1:
		hero_i = int(args[1])
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://sim_%d.log" % hero_i))
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main.start_game(hero_i)
	game = main.current
	game.finished.connect(_done)

func _process(delta: float) -> void:
	if game == null or game.phase == "over":
		return
	frames += 1
	if game.hud.relic_open():
		var ch: Array = []
		for c in game.hud.relic_cards.get_children():
			ch.append(c)
		var keys: Array = []
		for id in Bal.RELICS:
			pass
		# kartlar butonlardır; ilk kartı seç
		if ch.size() > 0:
			ch[randi() % ch.size()].pressed.emit()
		return
	acc += taps_per_sec * delta
	while acc >= 1.0:
		acc -= 1.0
		# kaynak dağılımı: çalı ağırlıklı
		# dokunuşların bir kısmı öndeki düşmana vuruş
		if not game.enemies.is_empty() and randf() < 0.3:
			var front: Enemy = game.enemies[0]
			for e in game.enemies:
				if e.s > front.s:
					front = e
			game.strike(front)
			continue
		var r := randf()
		var kind := "cali"
		if r < 0.2: kind = "odun"
		elif r < 0.4: kind = "tas"
		elif r < 0.5: kind = "kemik"
		game._gather(kind, Vector2.ZERO, false)
	spend_timer -= delta
	if spend_timer <= 0.0:
		spend_timer = 1.0
		game.add_thorns(100000)
		if game.barricade.hp < 60.0:
			game.add_barricade("kemik", 100000)
			game.add_barricade("tas", 100000)
		game.add_castle("odun", 100000)
		while game.buy_slave():
			game.assign_slave("cali", 1)
	for i in game.ult_cd.size():
		if game.ult_ready(i) and game.phase == "wave" and game.enemies.size() > 3:
			game.ult_press(i)
		elif game.res.sifa > 20:
			game.eat_herb(i)
	if game.wave != last_wave and game.wave % 5 == 0:
		last_wave = game.wave
		_log("dalga %d  kale %.0f  barikat %.0f  diken %.0f  köle %d  relik %d  t=%s" % [game.wave, game.castle_def, game.barricade.hp, game.thorns, game.slaves, game.relics.size(), Ui.fmt_time(game.time_alive)])
	if frames > 60 * 60 * 75:
		_log("zaman aşımı dalga %d" % game.wave)
		get_tree().quit()

func _log(t: String) -> void:
	print(t)
	var f := FileAccess.open("user://sim_%d.log" % hero_i, FileAccess.READ_WRITE if FileAccess.file_exists("user://sim_%d.log" % hero_i) else FileAccess.WRITE)
	f.seek_end()
	f.store_line(t)
	f.close()

func _done(stats: Dictionary) -> void:
	_log("SONUÇ " + str(stats))
	get_tree().quit()
