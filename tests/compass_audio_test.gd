extends Node
## Headless sinov: godot --headless --path . res://tests/compass_audio_test.tscn
## Kompas / Radar, Dushmanlar 3D HP bari va Milliy musiqani (Dombira) tekshiradi.

var main: Node
var player: Player
var hud: CanvasLayer

func _ready() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _frames(10)
	player = main.get_node("Player") as Player
	hud = main.get_node("HUD") as CanvasLayer
	_check(hud != null, "HUD topilmadi")

	# 1. Kompas UI mavjudligi va chizma tekshiruvi
	var compass_container = hud.get("_compass_container")
	var compass_canvas = hud.get("_compass_canvas")
	var compass_info = hud.get("_compass_info_label")
	_check(compass_container != null, "Kompas konteyneri topilmadi")
	_check(compass_canvas != null, "Kompas chizma maydoni topilmadi")
	_check(compass_info != null, "Kompas masofa yorlig'i topilmadi")

	compass_canvas.queue_redraw()
	await _frames(2)
	print("Kompas masofa tekshiruvi: ", compass_info.text)
	_check(compass_info.text != "", "Kompasda eng yaqin nishon masofasi ko'rinmadi")

	# 2. Dushmanlar 3D sog'liq bari tekshiruvi
	var enemies = get_tree().get_nodes_in_group("enemies")
	_check(enemies.size() > 0, "Dushmanlar topilmadi")
	var test_enemy: Enemy = null
	for e in enemies:
		if e is Enemy:
			test_enemy = e
			break
	_check(test_enemy != null, "Oddiy qalmoq dushmani topilmadi")

	var prev_hp: float = test_enemy.health
	test_enemy.take_damage(20.0, player.global_position, 2.0)
	await _frames(2)
	_check(test_enemy.health < prev_hp, "Dushman zarar olmadi")
	var label: Label3D = test_enemy.get("_label")
	_check(label != null, "Dushman 3D sog'liq paneli topilmadi")
	print("Dushman 3D sog'liq bari: ", label.text)
	_check("█" in label.text or "░" in label.text, "3D sog'liq barida grafik progress chizilmadi")

	# 3. Milliy musiqa va do'mbira sintezi tekshiruvi
	_check(Audio._streams.has("dom_d3"), "Do'mbira D3 notasi topilmadi")
	_check(Audio._streams.has("dom_strum"), "Do'mbira strum akkordi topilmadi")
	_check(Audio.current_music_state in [Audio.MusicState.CALM, Audio.MusicState.BATTLE], "Musiqa holati noto'g'ri")

	# Jang holatiga o'tish tekshiruvi
	player.global_position = test_enemy.global_position + Vector3(0, 0, 5) # 5 metr yaqinlik
	await _frames(15)
	_check(Audio.current_music_state == Audio.MusicState.BATTLE, "Dushman yaqin bo'lganda jang musiqasiga o'tmadi")

	print("KOMPAS, DUSHMAN HP VA MILLIY MUSIQA TESTI MUVAFFAQIYATLI O'TDI!")
	get_tree().quit(0)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _check(ok: bool, msg: String) -> void:
	if not ok:
		printerr("XATO: ", msg)
		get_tree().quit(1)
