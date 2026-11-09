class_name ResourceNode
extends StaticBody3D
## Dasht bo'ylab joylashgan tabiiy resurs manbalari (Temir rudasi, Qora saksovul, Shifobaxsh giyohlar).
## O'yinchi yaqinlashib [ E ] bosganda yoki qurol bilan zarba berganda resurs olinadi.

signal harvested(node_id: String, res_type: String, amount: int)

enum Type {
	IRON_ORE,   # Tog' temir rudasi (⛏️)
	WOOD,       # Qora saksovul va archa yog'ochi (🪵)
	HERBS       # Dasht giyohlari: isiriq va kiyiko't (🌿)
}

@export var resource_node_id: String = ""
@export var resource_type: Type = Type.IRON_ORE
@export var yield_amount: int = 3
@export var hits_required: int = 2

var current_hits: int = 0
var is_depleted := false

var _prompt: Label3D
var _visual_root: Node3D
var _depleted_mesh: MeshInstance3D


func _ready() -> void:
	add_to_group("resource_nodes")
	collision_layer = 1
	collision_mask = 0

	_build_visuals()
	_build_prompt()


func _build_visuals() -> void:
	_visual_root = Node3D.new()
	add_child(_visual_root)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()

	match resource_type:
		Type.IRON_ORE:
			shape.size = Vector3(1.4, 1.2, 1.4)
			col.position.y = 0.6
			_build_iron_ore_mesh()

		Type.WOOD:
			shape.size = Vector3(1.2, 1.8, 1.2)
			col.position.y = 0.9
			_build_wood_mesh()

		Type.HERBS:
			shape.size = Vector3(1.0, 0.6, 1.0)
			col.position.y = 0.3
			_build_herbs_mesh()

	col.shape = shape
	add_child(col)


func _build_iron_ore_mesh() -> void:
	# Qoyatosh asosi
	var rock := MeshInstance3D.new()
	var rbox := BoxMesh.new()
	rbox.size = Vector3(1.3, 1.0, 1.3)
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(0.24, 0.25, 0.27)
	rmat.roughness = 0.85
	rock.mesh = rbox
	rock.material_override = rmat
	rock.position.y = 0.5
	_visual_root.add_child(rock)

	# Temir va kumush tomirlari (Metallic crystals)
	for i in range(4):
		var crystal := MeshInstance3D.new()
		var cbox := BoxMesh.new()
		cbox.size = Vector3(0.35, 0.5, 0.35)
		var cmat := StandardMaterial3D.new()
		cmat.albedo_color = Color(0.82, 0.86, 0.95)
		cmat.metallic = 0.95
		cmat.roughness = 0.15
		crystal.mesh = cbox
		crystal.material_override = cmat
		crystal.position = Vector3(sin(i * 1.5) * 0.45, 0.6 + (i * 0.1), cos(i * 1.5) * 0.45)
		crystal.rotation_degrees = Vector3(15 * i, 30 * i, 10 * i)
		_visual_root.add_child(crystal)


func _build_wood_mesh() -> void:
	# Qora saksovul tanasi
	var trunk := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.22
	cyl.bottom_radius = 0.35
	cyl.height = 1.6
	var tmat := StandardMaterial3D.new()
	tmat.albedo_color = Color(0.32, 0.20, 0.12)
	tmat.roughness = 0.9
	trunk.mesh = cyl
	trunk.material_override = tmat
	trunk.position.y = 0.8
	_visual_root.add_child(trunk)

	# Quruq shoxlar va sahro archa novdalari
	for angle in [0.0, 70.0, 140.0, 220.0, 300.0]:
		var branch := MeshInstance3D.new()
		var bbox := BoxMesh.new()
		bbox.size = Vector3(0.12, 0.12, 0.8)
		var bmat := StandardMaterial3D.new()
		bmat.albedo_color = Color(0.28, 0.18, 0.10)
		branch.mesh = bbox
		branch.material_override = bmat
		branch.position = Vector3(0, 1.1, 0)
		branch.rotation_degrees.y = angle
		branch.rotation_degrees.x = 25.0
		_visual_root.add_child(branch)


func _build_herbs_mesh() -> void:
	# Isiriq va kiyiko't butasi
	for i in range(5):
		var foliage := MeshInstance3D.new()
		var fbox := BoxMesh.new()
		fbox.size = Vector3(0.25, 0.45, 0.25)
		var fmat := StandardMaterial3D.new()
		fmat.albedo_color = Color(0.22, 0.68, 0.32)
		fmat.roughness = 0.6
		foliage.mesh = fbox
		foliage.material_override = fmat
		foliage.position = Vector3(sin(i * 1.25) * 0.3, 0.25, cos(i * 1.25) * 0.3)
		foliage.rotation_degrees.y = i * 45.0
		foliage.rotation_degrees.z = sin(i) * 15.0
		_visual_root.add_child(foliage)

	# Shifobaxsh tog' gullari (binafsha va tillarang nurlar)
	var flower := MeshInstance3D.new()
	var flbox := BoxMesh.new()
	flbox.size = Vector3(0.2, 0.2, 0.2)
	var flmat := StandardMaterial3D.new()
	flmat.albedo_color = Color(0.9, 0.35, 0.8)
	flmat.emission_enabled = true
	flmat.emission = Color(0.9, 0.35, 0.8)
	flmat.emission_energy_multiplier = 0.8
	flower.mesh = flbox
	flower.material_override = flmat
	flower.position = Vector3(0, 0.45, 0)
	_visual_root.add_child(flower)


func _build_prompt() -> void:
	_prompt = Label3D.new()
	_prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt.no_depth_test = true
	_prompt.font_size = 18
	_prompt.position = Vector3(0, 1.8, 0)
	_prompt.visible = false
	add_child(_prompt)


func _process(_delta: float) -> void:
	if is_depleted:
		_prompt.visible = false
		return

	var player = get_tree().get_first_node_in_group("player")
	if player == null or not is_instance_valid(player):
		_prompt.visible = false
		return

	var dist_sq := global_position.distance_squared_to(player.global_position)
	if dist_sq < 9.0: # 3 metr masofada
		_prompt.visible = true
		_update_prompt_text()

		if Input.is_action_just_pressed("talk") or Input.is_key_pressed(KEY_E):
			harvest(player)
	else:
		_prompt.visible = false


func _update_prompt_text() -> void:
	match resource_type:
		Type.IRON_ORE:
			_prompt.text = "⛏️ TOG' TEMIR RUDASI\n[ E ] - Qazib olish (%d/%d)" % [current_hits, hits_required]
			_prompt.modulate = Color(0.85, 0.9, 1.0)
		Type.WOOD:
			_prompt.text = "🪵 QORA SAKSOVUL\n[ E ] - Kesish (%d/%d)" % [current_hits, hits_required]
			_prompt.modulate = Color(0.95, 0.75, 0.45)
		Type.HERBS:
			_prompt.text = "🌿 DASHT GIYOHLARI\n[ E ] - Terish"
			_prompt.modulate = Color(0.5, 1.0, 0.6)


## Qurol zarbasi tekkanda chaqiriladi
func take_damage(_amount: float = 1.0) -> void:
	if is_depleted:
		return
	var player = get_tree().get_first_node_in_group("player")
	harvest(player)


func harvest(player: Node) -> void:
	if is_depleted:
		return

	current_hits += 1

	# Vizual tebranish va zarba uchquni
	var hit_pos := global_position + Vector3.UP * 0.8
	var fx_color := Color(0.85, 0.9, 1.0)
	match resource_type:
		Type.IRON_ORE:
			fx_color = Color(1.0, 0.8, 0.3)
			Audio.play_heavy_hit()
		Type.WOOD:
			fx_color = Color(0.7, 0.45, 0.2)
			Audio.play_hit()
		Type.HERBS:
			fx_color = Color(0.3, 1.0, 0.5)
			Audio.play_coin()

	FX.sparks(hit_pos, Vector3.UP, fx_color, 14)

	# Tebranish animatsiyasi
	var t := create_tween()
	t.tween_property(_visual_root, "scale", Vector3(1.15, 0.85, 1.15), 0.08)
	t.tween_property(_visual_root, "scale", Vector3.ONE, 0.12)

	if current_hits >= hits_required:
		_complete_harvest(player)


func _complete_harvest(player: Node) -> void:
	is_depleted = true
	_prompt.visible = false

	var type_str := "iron_ore"
	var name_uz := "Temir rudasi"
	var popup_col := Color(0.8, 0.85, 1.0)

	match resource_type:
		Type.IRON_ORE:
			type_str = "iron_ore"
			name_uz = "⛏️ Tog' Temir Rudasi"
			popup_col = Color(0.85, 0.9, 1.0)
		Type.WOOD:
			type_str = "wood"
			name_uz = "🪵 Qora Saksovul"
			popup_col = Color(0.95, 0.75, 0.45)
		Type.HERBS:
			type_str = "herbs"
			name_uz = "🌿 Dasht Kiyiko'ti"
			popup_col = Color(0.4, 1.0, 0.5)

	if player and player.has_method("add_resource"):
		player.add_resource(type_str, yield_amount)

	# Popup va daraja tovushi
	Audio.play_level_up()
	FX.popup(global_position + Vector3.UP * 1.5, yield_amount, popup_col)

	# Kvest tizimi xabarnomasi
	var qs = get_tree().get_first_node_in_group("quest_system")
	if qs and qs.has_method("emit_signal"):
		qs.banner_requested.emit("RESURS YIG'ILDI!", "+%d %s inventarga qo'shildi" % [yield_amount, name_uz])

	harvested.emit(resource_node_id, type_str, yield_amount)

	# Kichrayib tugash animatsiyasi
	var t := create_tween()
	t.tween_property(_visual_root, "scale", Vector3(0.2, 0.1, 0.2), 0.3)
	t.tween_callback(func():
		_visual_root.visible = false
	)


func set_depleted_silent() -> void:
	is_depleted = true
	current_hits = hits_required
	if _visual_root:
		_visual_root.visible = false
	if _prompt:
		_prompt.visible = false
