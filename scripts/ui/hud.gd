extends CanvasLayer
## Oddiy HUD: kuch (stamina) paneli va boshqaruv yordam matni.

var _stamina_bar: ProgressBar

func _ready() -> void:
	_stamina_bar = ProgressBar.new()
	_stamina_bar.position = Vector2(30, 30)
	_stamina_bar.size = Vector2(300, 16)
	_stamina_bar.show_percentage = false
	_stamina_bar.max_value = 100.0
	_stamina_bar.value = 100.0
	add_child(_stamina_bar)

	var help := Label.new()
	help.position = Vector2(30, 60)
	help.text = "WASD - yurish | Sichqoncha - kamera | Shift - yugurish | Space - qochish\nX - sakrash | Q / o'rta tugma - nishonga qulflash | Esc - sichqoncha"
	add_child(help)
	_connect_player.call_deferred()


func _connect_player() -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player:
		_stamina_bar.max_value = player.max_stamina
		player.stamina_changed.connect(_on_stamina)


func _on_stamina(current: float, maximum: float) -> void:
	_stamina_bar.max_value = maximum
	_stamina_bar.value = current
