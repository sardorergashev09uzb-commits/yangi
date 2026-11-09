class_name TreasureChest
extends StaticBody3D
## Dasht bo'ylab ochiladigan qadimiy xazina sandig'i.
## Ichida tilla tangalar va doston xazinalari saqlanadi.

const CoinDropScript = preload("res://scripts/world/coin_drop.gd")

signal chest_opened(chest_id: String, gold: int)

@export var chest_id: String = ""
@export var gold_amount: int = 45

var is_opened := false

var _prompt: Label3D
var _lid_pivot: Node3D
var _base_mesh: MeshInstance3D
var _lid_mesh: MeshInstance3D


func _ready() -> void:
	add_to_group("treasure_chests")
	collision_layer = 1
	collision_mask = 0

	_build_visuals()
	_build_prompt()


func _build_visuals() -> void:
	# Yog'och va qoramtir po'lat materiallari
	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.38, 0.22, 0.12) # Qadimiy yong'oq yog'ochi
	wood_mat.roughness = 0.75

	var metal_mat := StandardMaterial3D.new()
	metal_mat.albedo_color = Color(0.78, 0.65, 0.22) # Oltin/jez hoshiyalar
	metal_mat.metallic = 0.85
	metal_mat.roughness = 0.3

	# 1. Sandiq asosi (Pastki quti)
	var base_box := BoxMesh.new()
	base_box.size = Vector3(1.2, 0.65, 0.8)
	base_box.material = wood_mat

	_base_mesh = MeshInstance3D.new()
	_base_mesh.mesh = base_box
	_base_mesh.position.y = 0.325
	add_child(_base_mesh)

	# Asos burchaklari / Jez qulf
	var lock_mesh := MeshInstance3D.new()
	var lock_box := BoxMesh.new()
	lock_box.size = Vector3(0.18, 0.2, 0.08)
	lock_box.material = metal_mat
	lock_mesh.mesh = lock_box
	lock_mesh.position = Vector3(0, 0.38, 0.42)
	add_child(lock_mesh)

	# 2. Ochiluvchi Qopqoq (Lid Pivot - orqa yuqori burchakka o'rnatilgan)
	_lid_pivot = Node3D.new()
	_lid_pivot.position = Vector3(0.0, 0.65, -0.4)
	add_child(_lid_pivot)

	var lid_box := BoxMesh.new()
	lid_box.size = Vector3(1.22, 0.22, 0.82)
	lid_box.material = wood_mat

	_lid_mesh = MeshInstance3D.new()
	_lid_mesh.mesh = lid_box
	_lid_mesh.position = Vector3(0.0, 0.11, 0.41)
	_lid_pivot.add_child(_lid_mesh)

	# Qopqoq jez hoshiyasi
	var strip := MeshInstance3D.new()
	var strip_box := BoxMesh.new()
	strip_box.size = Vector3(1.24, 0.06, 0.84)
	strip_box.material = metal_mat
	strip.mesh = strip_box
	strip.position = Vector3(0.0, 0.03, 0.41)
	_lid_pivot.add_child(strip)

	# 3. Kolliziya shakli
	var col := CollisionShape3D.new()
	var cbox := BoxShape3D.new()
	cbox.size = Vector3(1.25, 0.85, 0.85)
	col.shape = cbox
	col.position.y = 0.425
	add_child(col)


func _build_prompt() -> void:
	_prompt = Label3D.new()
	_prompt.text = "XAZINA SANDIG'I\n[ E ] - Ochish"
	_prompt.font_size = 36
	_prompt.position = Vector3(0, 1.45, 0)
	_prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt.no_depth_test = true
	_prompt.modulate = Color(1.0, 0.88, 0.25)
	_prompt.visible = false
	add_child(_prompt)


func _process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null or not is_instance_valid(player):
		_prompt.visible = false
		return

	var dist := global_position.distance_to(player.global_position)

	if is_opened:
		_prompt.visible = dist < 4.0
		_prompt.text = "[ BO'SH SANDIQ ]"
		_prompt.modulate = Color(0.6, 0.6, 0.6, 0.6)
		return

	if dist < 3.2:
		_prompt.visible = true
		_prompt.text = "XAZINA SANDIG'I\n[ E ] - Ochish"
		_prompt.modulate = Color(1.0, 0.88, 0.25)

		# O'yinchi [ E ] yoki interact tugmasini bosganda
		if Input.is_action_just_pressed("interact") or Input.is_key_pressed(KEY_E):
			open_chest(player)
	else:
		_prompt.visible = false


## Sandiqni tantanali ochish va tilla sochish
func open_chest(player: Node3D = null) -> void:
	if is_opened:
		return
	is_opened = true

	Audio.play_chest()
	Audio.play_coin()

	# Qopqoq silliq orqaga ochiladi
	var tween := create_tween()
	tween.tween_property(_lid_pivot, "rotation_degrees:x", -85.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Uchqunlar va nurlar
	FX.sparks(global_position + Vector3(0, 0.7, 0), Vector3.UP, Color(1.0, 0.88, 0.2), 24)

	# Tilla tangalarni otilib chiqishi
	CoinDropScript.spawn_coins(get_tree(), global_position + Vector3(0, 0.7, 0), gold_amount, 5)

	# Xabar bannerini ko'rsatish
	var qsystem = get_tree().get_first_node_in_group("quest_system")
	if qsystem and qsystem.has_signal("banner_requested"):
		qsystem.banner_requested.emit("XAZINA TOPILDI!", "+%d Tilla tanga qo'lga kiritildi!" % gold_amount)
	if qsystem and chest_id == "chest_bandit_outpost" and qsystem.has_method("set_objective_completed"):
		qsystem.set_objective_completed("bandit_outpost", 2)

	chest_opened.emit(chest_id, gold_amount)


## Saqlangan o'yinni yuklaganda ovozsiz ochiq holatga keltirish
func set_opened_silent() -> void:
	is_opened = true
	if _lid_pivot:
		_lid_pivot.rotation_degrees.x = -85.0
	if _prompt:
		_prompt.text = "[ BO'SH SANDIQ ]"
		_prompt.modulate = Color(0.6, 0.6, 0.6, 0.6)
