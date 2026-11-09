extends Node
## Headless sinov: godot --headless --path . res://tests/mythic_bosses_test.tscn
## 7-Bosqich: Yetti Boshli Qora Ajdaho, Qalmoq Bosh Shomoni va Tosh Koloss bosslari sinovi.

const BossDragonScript = preload("res://scripts/enemies/boss_dragon.gd")
const BossShamanScript = preload("res://scripts/enemies/boss_shaman.gd")
const BossColossusScript = preload("res://scripts/enemies/boss_colossus.gd")

var main: Node
var player: Player
var dragon: CharacterBody3D
var shaman: CharacterBody3D
var colossus: CharacterBody3D


func _ready() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _frames(10)

	player = main.get_node("Player") as Player
	_check(player != null, "player topilmadi")

	# 1. Bosslarning sahnada mavjudligi tekshiruvi
	dragon = main._dragon
	shaman = main._shaman
	colossus = main._colossus

	_check(dragon != null, "Yetti Boshli Qora Ajdaho sahnada topilmadi")
	_check(shaman != null, "Qora Ko'rpasht Shomon sahnada topilmadi")
	_check(colossus != null, "Qoya Yurar Tosh Koloss sahnada topilmadi")

	# 2. Yetti Boshli Qora Ajdaho sinovlari
	var dragon_hp0: float = dragon.health
	_check(dragon.health > 400.0, "Ajdahoning boshlang'ich salomatligi yetarli emas")
	_check(dragon._heads.size() == 7, "Ajdahoning 7 ta boshi to'liq yaratilmagan")
	_check(dragon._wings.size() == 2, "Ajdahoning 2 ta qanoti to'liq yaratilmagan")

	# Zarba berish va faollashish
	dragon.take_damage(60.0, player.global_position)
	await _frames(2)
	_check(dragon.health < dragon_hp0, "Ajdaho zarar olmadi")
	_check(dragon.state != BossDragonScript.State.DORMANT, "Ajdaho jang holatiga o'tmadi")

	# 2-bosqichga o'tish (HP <= 66%)
	dragon.take_damage(200.0, player.global_position)
	await _frames(2)
	_check(dragon.phase == 2, "Ajdaho 2-bosqichga o'tmadi")

	# 3. Qalmoq Bosh Shomoni sinovlari
	var shaman_hp0: float = shaman.health
	shaman.take_damage(40.0, player.global_position)
	await _frames(2)
	_check(shaman.health < shaman_hp0, "Shomon zarar olmadi")
	_check(shaman.state != BossShamanScript.State.DORMANT, "Shomon faollashmadi")

	# Shomon 2-bosqich: Klonlar chaqirish (HP <= 50%)
	shaman.take_damage(150.0, player.global_position)
	await _frames(2)
	_check(shaman.phase == 2, "Shomon 2-bosqichga o'tmadi")

	# 4. Qoya Yurar Tosh Koloss sinovlari
	var colossus_hp0: float = colossus.health
	colossus.take_damage(50.0, player.global_position)
	await _frames(2)
	_check(colossus.health < colossus_hp0, "Koloss zarar olmadi")
	_check(colossus.state != BossColossusScript.State.DORMANT, "Koloss faollashmadi")

	# Stagger (zaif nuqtaga kuchli zarba) va 2x kritik zarar tekshiruvi
	colossus.state = BossColossusScript.State.STAGGERED
	var col_hp_before: float = colossus.health
	colossus.take_damage(30.0, player.global_position)
	_check(col_hp_before - colossus.health >= 60.0, "Koloss Stagger holatida 2x kritik zarar olmadi")

	print("MYTHIC BOSSES: BARCHA 3 TA MIFOLOGIK BOSS TESTLARI MUVAFFAQIYATLI O'TDI!")
	get_tree().quit(0)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _check(ok: bool, msg: String) -> void:
	if not ok:
		printerr("XATO: ", msg)
		get_tree().quit(1)
