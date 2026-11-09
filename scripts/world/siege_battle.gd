class_name SiegeBattle
extends Node3D
## 9-bosqich: Qalmoq Qal'asi Katta Qamali (Epic Fortress Siege Battle).
## Do'st botirlar, dushman to'lqinlari, katapulta toshlari va yakuniy g'alaba tantanasi.

signal siege_started()
signal siege_completed()

const AlliedWarriorScript = preload("res://scripts/enemies/allied_warrior.gd")
const EnemyScript = preload("res://scripts/enemies/enemy.gd")
const CatapultRockScript = preload("res://scripts/world/siege_catapult_rock.gd")
const VictoryCelebrationScript = preload("res://scripts/ui/victory_celebration.gd")

var is_active := false
var is_completed := false

var allies: Array[CharacterBody3D] = []
var enemies: Array[CharacterBody3D] = []
var _catapult_timer := 0.0
var _victory_ui: CanvasLayer


func _ready() -> void:
	add_to_group("siege_battles")
	_victory_ui = VictoryCelebrationScript.new()
	add_child(_victory_ui)


func start_siege() -> void:
	if is_active or is_completed:
		return
	is_active = true

	# 1. Do'st Qo'ng'irot botirlarini safga chiqarish
	_spawn_allied_warriors()

	# 2. Qal'a qo'riqchilari to'lqinini chiqarish
	_spawn_fortress_garrison()

	Audio.play_boss_slam()
	FX.shockwave_ring(global_position + Vector3.UP * 0.2, 12.0, Color(1.0, 0.4, 0.1), 0.6)

	var qsys = get_tree().get_first_node_in_group("quest_system")
	if qsys and qsys.has_method("banner_requested"):
		qsys.banner_requested.emit("BUYUK QAMAL BOSHLANDI!", "Qalmoq Qal'asi Darvozasi Qamali — Botirlar jangga kirdi!")

	siege_started.emit()


func _spawn_allied_warriors() -> void:
	var spawn_offsets := [
		Vector3(-5.0, 0, 8.0),
		Vector3(0.0, 0, 10.0),
		Vector3(5.0, 0, 8.0)
	]

	for offset in spawn_offsets:
		var warrior := AlliedWarriorScript.new()
		warrior.position = global_position + offset
		add_child(warrior)
		allies.append(warrior)
		FX.impact_burst(warrior.global_position + Vector3.UP * 0.5, Color(0.2, 0.6, 1.0), 12)


func _spawn_fortress_garrison() -> void:
	var enemy_spawns := [
		{"pos": Vector3(-4.0, 0, -8.0), "kind": EnemyScript.Kind.SPEAR},
		{"pos": Vector3(4.0, 0, -8.0), "kind": EnemyScript.Kind.SWORD},
		{"pos": Vector3(0.0, 0, -12.0), "kind": EnemyScript.Kind.ARCHER}
	]

	for data in enemy_spawns:
		var e := EnemyScript.new()
		e.kind = data.kind
		e.position = global_position + data.pos
		add_child(e)
		enemies.append(e)
		FX.impact_burst(e.global_position + Vector3.UP * 0.5, Color(0.9, 0.1, 0.1), 12)


func _physics_process(delta: float) -> void:
	if not is_active or is_completed:
		return

	# Katapulta olovli toshlari yog'dirish
	_catapult_timer -= delta
	if _catapult_timer <= 0.0:
		_launch_catapult_rock()
		_catapult_timer = randf_range(3.5, 5.5)

	# Dushmanlar tor-mor etilganini tekshirish
	_check_garrison_cleared()


func _launch_catapult_rock() -> void:
	var rock := CatapultRockScript.new()
	add_child(rock)
	var rand_target := global_position + Vector3(randf_range(-12, 12), 0, randf_range(-6, 10))
	rock.launch(rand_target)


func _check_garrison_cleared() -> void:
	var remaining := 0
	for e in enemies:
		if is_instance_valid(e) and not (e.has_method("is_dead") and e.is_dead()):
			remaining += 1

	if remaining == 0:
		complete_siege()


func complete_siege() -> void:
	if is_completed:
		return
	is_completed = true
	is_active = false

	# Barcha tirik botirlar g'alaba quvonchini namoyish etadi
	for a in allies:
		if is_instance_valid(a) and a.has_method("cheer"):
			a.cheer()

	if _victory_ui:
		_victory_ui.show_celebration()

	var qsys = get_tree().get_first_node_in_group("quest_system")
	if qsys and qsys.has_method("complete_quest"):
		qsys.complete_quest("rescue_barchin")

	Audio.play_victory()
	siege_completed.emit()
