extends Node
## Dokunma testi: farklı ekran oranlarında kaynak bölgesine dokunulunca kaynak artıyor mu?
## xvfb-run godot --path . --rendering-driver opengl3 --resolution 2400x1080 res://tools/tap_test.tscn -- <klasör>

func _touch(p: Vector2, idx := 0) -> void:
	var e := InputEventScreenTouch.new()
	e.index = idx
	e.position = p
	e.pressed = true
	Input.parse_input_event(e)
	await get_tree().process_frame
	var r := InputEventScreenTouch.new()
	r.index = idx
	r.position = p
	r.pressed = false
	Input.parse_input_event(r)
	await get_tree().process_frame

func _ready() -> void:
	var out := OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://"
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	for i in 20: await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(out + "/menu_main.png")
	main.current._show(main.current.hero_screen)
	for i in 5: await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(out + "/menu_heroes.png")
	main.current._open_settings()
	for i in 5: await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(out + "/menu_settings.png")
	main.start_game(0)
	var g: Game = main.current
	for i in 5: await get_tree().process_frame
	print("görünür alan ", get_viewport().get_visible_rect().size, " oyun kaydırma ", g.position)
	var ok := true
	for n in g.nodes:
		var before: Dictionary = g.res.duplicate()
		var screen: Vector2 = n.position + g.position + Vector2(0, -10)
		await _touch(screen)
		var gained := false
		for k in g.res:
			if g.res[k] > before[k]:
				gained = true
		print(n.kind, " @", screen, " -> ", "OK" if gained else "BAŞARISIZ")
		ok = ok and gained
	# kaleye dokun -> pencere açılmalı
	await _touch(g.player_castle.position + g.position + Vector2(0, -100))
	await get_tree().process_frame
	print("kale penceresi: ", "OK" if g.hud.popup_open() else "BAŞARISIZ")
	print("SONUÇ: ", "HEPSİ GEÇTİ" if ok and g.hud.popup_open() else "HATA VAR")
	get_tree().quit()
