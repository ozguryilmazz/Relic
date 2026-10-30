extends Node
## Düşman tipleri testi: belirli bir dalgadan başlatır, ekran görüntüsü alır, hata olup olmadığını yazar.
## xvfb-run godot --path . --rendering-driver opengl3 --resolution 1920x1080 res://tools/types_test.tscn -- <klasör> <dalga>

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "user://"
	var start: int = int(args[1]) if args.size() > 1 else 36
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main.start_game(1)
	var g: Game = main.current
	await get_tree().process_frame
	g.wave = start - 1
	g.prep_left = 0.1
	g.thorns = 400
	g.barricade.hp = 800
	g.castle_def = 3000
	var seen := {}
	Engine.time_scale = 6.0 if DisplayServer.get_name() != "headless" else 4.0
	for i in 60 * 14:
		await get_tree().process_frame
		for e in g.enemies:
			seen[e.type] = true
		if i == 130 and DisplayServer.get_name() != "headless":
			get_viewport().get_texture().get_image().save_png(out + "/types_%d.png" % start)
			break
	print("dalga ", g.wave, " görülen tipler: ", seen.keys(), " kale ", int(g.castle_def), " barikat ", int(g.barricade.hp), " öldürülen ", g.kills)
	get_tree().quit()
