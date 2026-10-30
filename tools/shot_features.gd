extends Node
## Ekran görüntüleri: boss, kombo, altın kaynak, relik seçimi.

func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main.start_game(0)
	var g: Game = main.current
	await get_tree().process_frame
	g.wave = 9
	g.prep_left = 0.1
	g.thorns = 300
	g.barricade.hp = 600
	g.castle_def = 900
	g.golden_next = 0.5
	Engine.time_scale = 6.0
	for i in 110: await get_tree().process_frame
	Engine.time_scale = 1.0
	g.combo = 47
	g.combo_timer = 5.0
	for i in 4: await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(out + "/feat_game.png")
	g.relics = {"diken_hasar": 1}
	g.pending_legend = false
	g._offer_relics()
	for i in 4: await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(out + "/feat_relic.png")
	g.hud.relic_overlay.visible = false
	get_tree().paused = false
	g.pending_legend = true
	g._offer_relics()
	for i in 4: await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(out + "/feat_legend.png")
	get_tree().quit()
