extends Node
## Ekran görüntüsü aracı (geliştirme için): menü ve oyun içinden PNG kaydeder.
## xvfb-run godot --path . --rendering-driver opengl3 res://tools/shot.tscn -- <çıktı klasörü>

func _ready() -> void:
	var out := OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://"
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	for i in 30: await get_tree().process_frame
	_save(out + "/menu.png")
	main.start_game(1)
	var g: Game = main.current
	for i in 5: await get_tree().process_frame
	g.res.odun = 40; g.res.tas = 30; g.res.kemik = 12; g.res.diken = 0; g.res.sifa = 9
	g.thorns = 80
	g.barricade.hp = 120
	g.fear = 25
	g.prep_left = 0.1
	for k in 3: g.buy_slave()
	g.assign_slave("cali", 1); g.assign_slave("odun", 1)
	Engine.time_scale = 6.0
	for i in 220: await get_tree().process_frame
	Engine.time_scale = 1.0
	g.ult_cd[0] = 23.0
	g.hud.open_popup("castle", Vector2(260, 420) + g.position)
	for i in 10: await get_tree().process_frame
	_save(out + "/game.png")
	get_tree().quit()

func _save(p: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(p)
	print("saved ", p)
