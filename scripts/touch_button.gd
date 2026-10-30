class_name TouchButton
extends Button
## İkinci parmakla da basılabilen buton.
## İlk parmak Godot'nun dokunmadan fare taklidiyle çalışır; diğer parmakları burada yakalıyoruz.

func _ready() -> void:
	pressed.connect(func(): Sfx.play("click"))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed and event.index != 0 and not disabled:
		pressed.emit()
		accept_event()
