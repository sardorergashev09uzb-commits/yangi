class_name AncientBalbal
extends StaticBody3D
## Qadimiy Tosh Balbal: Turkiy ajdodlar xotirasi muhrlangan tosh obida [ E ].

@export var balbal_id: String = "balbal_1"
@export var balbal_name: String = "Qadimiy Tosh Balbal"
var is_communed := false

var _prompt: Label3D
var _pillar_mesh: MeshInstance3D
var _rune_light: OmniLight3D
var _rune_material: StandardMaterial3D


func _ready() -> void:
	add_to_group("ancient_balbals")
	collision_layer = 1
	collision_mask = 0
	_build_monolith()
	_build_prompt()


func _build_monolith() -> void:
	# 1. Asosiy tosh ustun (Weathered Stone Pillar)
	var pillar := CylinderMesh.new()
	pillar.top_radius = 0.45
	pillar.bottom_radius = 0.58
	pillar.height = 3.6
	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.48, 0.45, 0.40)
	stone_mat.roughness = 0.92
	pillar.material = stone_mat

	_pillar_mesh = MeshInstance3D.new()
	_pillar_mesh.mesh = pillar
	_pillar_mesh.position.y = 1.8
	add_child(_pillar_mesh)

	# 2. Ajdodlar qiyofasi (Carved Warrior Face & Helmet)
	var brow := MeshInstance3D.new()
	var brow_box := BoxMesh.new()
	brow_box.size = Vector3(0.55, 0.18, 0.2)
	brow.mesh = brow_box
	brow.position = Vector3(0, 2.75, 0.4)
	add_child(brow)

	var nose := MeshInstance3D.new()
	var nose_box := BoxMesh.new()
	nose_box.size = Vector3(0.14, 0.35, 0.22)
	nose.mesh = nose_box
	nose.position = Vector3(0, 2.5, 0.42)
	add_child(nose)

	var moustache := MeshInstance3D.new()
	var moust_box := BoxMesh.new()
	moust_box.size = Vector3(0.65, 0.12, 0.16)
	moustache.mesh = moust_box
	moustache.position = Vector3(0, 2.25, 0.42)
	add_child(moustache)

	# 3. Sehrli Runik Belgilar (Glowing Turkic Runes)
	_rune_material = StandardMaterial3D.new()
	_rune_material.albedo_color = Color(0.2, 0.8, 1.0)
	_rune_material.emission_enabled = true
	_rune_material.emission = Color(0.25, 0.75, 1.0)
	_rune_material.emission_energy_multiplier = 1.8

	var rune_plate := MeshInstance3D.new()
	var r_plane := BoxMesh.new()
	r_plane.size = Vector3(0.35, 0.7, 0.05)
	r_plane.material = _rune_material
	rune_plate.mesh = r_plane
	rune_plate.position = Vector3(0, 1.6, 0.48)
	add_child(rune_plate)

	# 4. Poydevordagi Muqaddas Guldon / Altar (Stone Base & Altar)
	var altar_box := BoxMesh.new()
	altar_box.size = Vector3(1.4, 0.4, 1.4)
	var altar := MeshInstance3D.new()
	altar.mesh = altar_box
	altar.position.y = 0.2
	add_child(altar)

	# 5. Moviy / Oltin Nur (Mystic Rune Light)
	_rune_light = OmniLight3D.new()
	_rune_light.position = Vector3(0, 1.6, 0.7)
	_rune_light.light_color = Color(0.3, 0.8, 1.0)
	_rune_light.light_energy = 2.0
	_rune_light.omni_range = 6.0
	add_child(_rune_light)

	# 6. Fizik to'siq (Collision Shape)
	var col := CollisionShape3D.new()
	var col_shape := CylinderShape3D.new()
	col_shape.radius = 0.65
	col_shape.height = 3.6
	col.shape = col_shape
	col.position.y = 1.8
	add_child(col)


func _build_prompt() -> void:
	_prompt = Label3D.new()
	_prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt.no_depth_test = true
	_prompt.position = Vector3(0, 3.8, 0)
	_prompt.font_size = 18
	_prompt.outline_size = 6
	_prompt.text = "🗿 %s [ E ]\nAjdodlar ruhidan duo olish" % balbal_name
	_prompt.modulate = Color(0.4, 0.9, 1.0)
	_prompt.visible = false
	add_child(_prompt)


func _process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null or not is_instance_valid(player):
		_prompt.visible = false
		return

	var dist := global_position.distance_to(player.global_position)
	_prompt.visible = dist < 4.2

	if dist < 4.2 and not is_communed:
		if Input.is_action_just_pressed("talk") or Input.is_key_pressed(KEY_E):
			commune()


func commune() -> void:
	if is_communed:
		return
	is_communed = true

	# Tovush va nurlar
	Audio.play_level_up()
	FX.popup(global_position + Vector3.UP * 3.0, 0.0, Color(0.3, 0.9, 1.0))
	FX.sparks(global_position + Vector3.UP * 1.6, Vector3.UP, Color(0.3, 0.9, 1.0), 18)

	# Ranglarni oltin-muqaddas rangga aylantirish
	if _rune_material:
		_rune_material.emission = Color(1.0, 0.85, 0.25)
		_rune_material.emission_energy_multiplier = 3.5
	if _rune_light:
		_rune_light.light_color = Color(1.0, 0.85, 0.25)
		_rune_light.light_energy = 4.0

	_prompt.text = "🗿 %s ✓\n(Ajdodlar ruhi qo'llab-quvvatladi)" % balbal_name
	_prompt.modulate = Color(1.0, 0.85, 0.25)

	# O'yinchiga qadimgi kuch va shifo berish
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		if player.has_method("heal_hp"):
			player.heal_hp(35.0)
		elif player.has_method("heal"):
			player.heal(35.0)
		else:
			player.health = minf(player.health + 35.0, 100.0)
		if "stamina" in player:
			var max_s: Variant = player.get("max_stamina")
			player.stamina = float(max_s) if max_s != null else 100.0

	# Kvest tizimini xabardor qilish
	var qs = get_tree().get_first_node_in_group("quest_system")
	if qs and qs.has_method("record_balbal"):
		qs.record_balbal(balbal_id)
