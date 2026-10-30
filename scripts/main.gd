extends Node
## Sahne yöneticisi: menü <-> oyun. Uygulama arka plana alınınca oyunu duraklatır.

var current: Node
var hero_index := 0

func _ready() -> void:
	show_menu()

func _clear() -> void:
	get_tree().paused = false
	if current:
		current.queue_free()
		current = null

func show_menu() -> void:
	_clear()
	var m := Menu.new()
	m.hero_chosen.connect(start_game)
	add_child(m)
	current = m

func start_game(index: int) -> void:
	hero_index = index
	_clear()
	var g := Game.new()
	g.setup(Bal.HEROES[index])
	g.to_menu.connect(show_menu)
	g.restart.connect(func(): start_game(hero_index))
	add_child(g)
	current = g

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if current is Game:
			(current as Game).hud.pause_game()
