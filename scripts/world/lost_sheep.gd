class_name LostSheep
extends CharacterBody3D
## Adashgan Qo'y: Qultoy Cho'ponning yo'qolgan podasi [ E ] bilan qutqariladi.

@export var sheep_id: String = "sheep_1"
var is_rescued := false

var _prompt: Label3D
var _body_mesh: MeshInstance3D
var _head_mesh: MeshInstance3D
var _anim_time := 0.0
var _orig_y := 0.0


func _ready() -> void:
	add_to_group("lost_sheep")
	collision_layer = 1 << 2
	collision_mask = 1
	_orig_y = position.y
	_build_visuals()
	_build_prompt()
	call_deferred("_sync_rescued_state")


func _sync_rescued_state() -> void:
	var qs = get_tree().get_first_node_in_group("quest_system")
	if qs and qs.get("rescued_sheep") != null and qs.rescued_sheep.has(sheep_id):
		is_rescued = true
		_prompt.text = "🐑 Qutqarildi ✓\n(Suruvga qaytdi)"
		_prompt.modulate = Color(0.35, 1.0, 0.45)


func _build_visuals() -> void:
	# 1. Jun tanasi (Fluffy Wool Body)
	_body_mesh = MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.42
	cap.height = 1.1
	var wool_mat := StandardMaterial3D.new()
	wool_mat.albedo_color = Color(0.94, 0.93, 0.88)
	wool_mat.roughness = 0.95
	cap.material = wool_mat
	_body_mesh.mesh = cap
	_body_mesh.rotation_degrees.x = 90.0
	_body_mesh.position.y = 0.55
	add_child(_body_mesh)

	# 2. Bosh (Head)
	_head_mesh = MeshInstance3D.new()
	var head_sph := SphereMesh.new()
	head_sph.radius = 0.22
	head_sph.height = 0.4
	var dark_mat := StandardMaterial3D.new()
	dark_mat.albedo_color = Color(0.18, 0.14, 0.12) # Qo'ng'ir-qora bosh
	dark_mat.roughness = 0.8
	head_sph.material = dark_mat
	_head_mesh.mesh = head_sph
	_head_mesh.position = Vector3(0, 0.65, 0.55)
	add_child(_head_mesh)

	# 3. Quloqlar (Floppy Ears)
	for side in [-1.0, 1.0]:
		var ear := MeshInstance3D.new()
		var ear_box := BoxMesh.new()
		ear_box.size = Vector3(0.08, 0.16, 0.08)
		ear_box.material = dark_mat
		ear.mesh = ear_box
		ear.position = Vector3(side * 0.18, 0.68, 0.5)
		ear.rotation_degrees.z = side * 40.0
		add_child(ear)

	# 4. To'rt oyoq (4 Stubby Legs)
	var leg_coords := [
		Vector3(-0.25, 0.25, 0.35),
		Vector3(0.25, 0.25, 0.35),
		Vector3(-0.25, 0.25, -0.35),
		Vector3(0.25, 0.25, -0.35)
	]
	for lp in leg_coords:
		var leg := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.08
		cyl.bottom_radius = 0.07
		cyl.height = 0.5
		cyl.material = dark_mat
		leg.mesh = cyl
		leg.position = lp
		add_child(leg)

	# 5. Kichik dum (Small Tail)
	var tail := MeshInstance3D.new()
	var tail_sph := SphereMesh.new()
	tail_sph.radius = 0.1
	tail_sph.height = 0.16
	tail_sph.material = wool_mat
	tail.mesh = tail_sph
	tail.position = Vector3(0, 0.6, -0.55)
	add_child(tail)

	# 6. To'qnashuv shakli (Collision Shape)
	var col := CollisionShape3D.new()
	var col_shape := BoxShape3D.new()
	col_shape.size = Vector3(0.9, 0.9, 1.2)
	col.shape = col_shape
	col.position.y = 0.55
	add_child(col)


func _build_prompt() -> void:
	_prompt = Label3D.new()
	_prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt.no_depth_test = true
	_prompt.position = Vector3(0, 1.35, 0)
	_prompt.font_size = 18
	_prompt.outline_size = 6
	_prompt.text = "🐑 Adashgan Qo'y [ E ]\nO'tovga yo'naltirish"
	_prompt.modulate = Color(1.0, 0.9, 0.3)
	_prompt.visible = false
	add_child(_prompt)


func _process(delta: float) -> void:
	_anim_time += delta
	if not is_rescued and _body_mesh:
		# Sekin o't yeyish va nafas olish tebranishi
		_body_mesh.position.y = 0.55 + sin(_anim_time * 2.5) * 0.03

	var player = get_tree().get_first_node_in_group("player")
	if player == null or not is_instance_valid(player):
		_prompt.visible = false
		return

	var dist := global_position.distance_to(player.global_position)
	_prompt.visible = dist < 3.8

	if dist < 3.8 and not is_rescued:
		if Input.is_action_just_pressed("talk") or Input.is_key_pressed(KEY_E):
			rescue()


func rescue() -> void:
	if is_rescued:
		return
	is_rescued = true

	# Qutqarish ovozi va effekti
	Audio.play_coin()
	FX.popup(global_position + Vector3.UP * 1.6, 0.0, Color(0.35, 1.0, 0.45))

	_prompt.text = "🐑 Qutqarildi ✓\n(Suruvga qaytdi)"
	_prompt.modulate = Color(0.35, 1.0, 0.45)

	# Quvonchli sakrash animatsiyasi (Tween)
	var tw := create_tween()
	tw.tween_property(self, "position:y", _orig_y + 0.6, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:y", _orig_y, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "position:y", _orig_y + 0.4, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:y", _orig_y, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Kvest tizimini xabardor qilish
	var qs = get_tree().get_first_node_in_group("quest_system")
	if qs and qs.has_method("record_sheep"):
		qs.record_sheep(sheep_id)
