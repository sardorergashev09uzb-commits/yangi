extends Node
## Headless sinov: godot --headless --path . res://tests/visuals_environment_test.tscn
## 12-bosqich: WorldEnvironment, ProceduralSky, DayNightCycle (Tong, Tush, Tun nurlari) tekshiruvi.

var main: Node
var cycle: DayNightCycle


func _ready() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _frames(10)

	cycle = get_tree().get_first_node_in_group("day_night_cycle") as DayNightCycle
	_check(cycle != null, "day_night_cycle topilmadi")
	_check(cycle.sun != null, "sun topilmadi")
	_check(cycle.env != null, "environment topilmadi")
	_check(cycle.sky_mat != null, "sky material topilmadi")

	# 1. Tush vaqti (0.5)
	cycle.time_of_day = 0.5
	cycle._update_lighting(0.0)
	await _frames(2)
	_check(cycle.sun.light_energy > 0.8, "tushda quyosh energiyasi past")
	_check(cycle.sun.light_color.r > 0.9, "tushda rang noto'g'ri")

	# 2. Tun vaqti (0.0)
	cycle.time_of_day = 0.0
	cycle._update_lighting(0.0)
	await _frames(2)
	_check(cycle.sun.light_energy < 0.3, "tunda quyosh energiyasi pasaymadi")
	# Tunda ko'kimtir oy nuri
	_check(cycle.sun.light_color.b > cycle.sun.light_color.r, "tunda oy nuri ko'kimtir emas")

	# 3. Tong/Shom (0.25)
	cycle.time_of_day = 0.25
	cycle._update_lighting(0.0)
	await _frames(2)
	_check(cycle.sun.light_energy >= 0.1, "tong/shomda quyosh yo'q")

	print("12-BOSQICH: ATOMOSFERA VA KUN/TUN AYLANISHI TESTI MUVAFFAQIYATLI O'TDI!")
	get_tree().quit(0)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _check(ok: bool, msg: String) -> void:
	if not ok:
		printerr("XATO: ", msg)
		get_tree().quit(1)
