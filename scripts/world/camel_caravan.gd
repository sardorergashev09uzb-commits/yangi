class_name CamelCaravan
extends Node3D
## Buyuk Ipak Yo'li tuyalar karvoni va Sahro qaroqchilari pistirmasi (Living Caravan & Ambush Event).
## Karvon dasht bo'ylab Boysun bozori sari harakatlanadi.

const EnemyScript = preload("res://scripts/enemies/enemy.gd")
const CoinDropScript = preload("res://scripts/world/coin_drop.gd")

signal ambush_started
signal ambush_defeated
signal caravan_arrived

@export var move_speed := 2.2
@export var waypoints: Array[Vector3] = [
	Vector3(65.0, 0.0, 65.0),
	Vector3(48.0, 0.0, 48.0), # Pistirma nuqtasi (Ambush Point)
	Vector3(34.0, 0.0, 26.0),
	Vector3(31.0, 0.0, 10.0)  # Chorsu Bozori (Final stop)
]

var current_waypoint_idx := 0
var is_ambush_active := false
var ambush_completed := false
var has_arrived := false

var _camels: Array[Node3D] = []
var _guard: Node3D
var _prompt: Label3D
var _ambush_enemies: Array[Node] = []
var _walk_cycle := 0.0
var _bell_timer := 0.0


func _ready() -> void:
	add_to_group("caravan")
	_build_caravan()
	_build_prompt()

	if waypoints.size() > 0:
		global_position = waypoints[0]


func _build_caravan() -> void:
	# 1. Soqchi va Karvonboshi yetakchi
	_guard = Node3D.new()
	_guard.position = Vector3(0, 0, 0)
	_build_guard_mesh(_guard)
	add_child(_guard)

	# 2. Birinchi Katta Tuya (Leader Camel)
	var camel1 := Node3D.new()
	camel1.position = Vector3(0, 0, -3.2)
	_build_camel_mesh(camel1, Color(0.76, 0.62, 0.42), Color(0.8, 0.2, 0.2)) # Qizil xurjun
	add_child(camel1)
	_camels.append(camel1)

	# 3. Ikkinchi Yuk Tuyasi (Second Pack Camel)
	var camel2 := Node3D.new()
	camel2.position = Vector3(0, 0, -6.8)
	_build_camel_mesh(camel2, Color(0.72, 0.58, 0.38), Color(0.2, 0.4, 0.75)) # Ko'k xurjun
	add_child(camel2)
	_camels.append(camel2)


func _build_guard_mesh(parent: Node3D) -> void:
	var body := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.25
	cyl.bottom_radius = 0.35
	cyl.height = 1.7
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.45, 0.35) # To'q yashil to'n
	body.mesh = cyl
	body.material_override = mat
	body.position.y = 0.85
	parent.add_child(body)

	# Salla (Turban)
	var turban := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.28
	sph.height = 0.45
	var tmat := StandardMaterial3D.new()
	tmat.albedo_color = Color(0.95, 0.92, 0.85)
	turban.mesh = sph
	turban.material_override = tmat
	turban.position.y = 1.85
	parent.add_child(turban)

	# Nayza (Spear)
	var spear := MeshInstance3D.new()
	var scyl := CylinderMesh.new()
	scyl.top_radius = 0.03
	scyl.bottom_radius = 0.04
	scyl.height = 2.6
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.4, 0.25, 0.15)
	spear.mesh = scyl
	spear.material_override = smat
	spear.position = Vector3(0.4, 1.3, 0.2)
	spear.rotation_degrees.x = 15.0
	parent.add_child(spear)


func _build_camel_mesh(parent: Node3D, skin_col: Color, saddle_col: Color) -> void:
	var c_mat := StandardMaterial3D.new()
	c_mat.albedo_color = skin_col
	c_mat.roughness = 0.85

	# Tana (Camel Body)
	var body := MeshInstance3D.new()
	var bbox := BoxMesh.new()
	bbox.size = Vector3(1.1, 1.3, 2.2)
	body.mesh = bbox
	body.material_override = c_mat
	body.position.y = 1.6
	parent.add_child(body)

	# O'rkach (Hump)
	var hump := MeshInstance3D.new()
	var hbox := BoxMesh.new()
	hbox.size = Vector3(0.85, 0.9, 1.1)
	hump.mesh = hbox
	hump.material_override = c_mat
	hump.position = Vector3(0, 2.4, 0.1)
	parent.add_child(hump)

	# Bo'yin va Bosh (Neck & Head)
	var neck := MeshInstance3D.new()
	var nbox := BoxMesh.new()
	nbox.size = Vector3(0.4, 1.1, 0.5)
	neck.mesh = nbox
	neck.material_override = c_mat
	neck.position = Vector3(0, 2.3, 1.1)
	neck.rotation_degrees.x = -30.0
	parent.add_child(neck)

	var head := MeshInstance3D.new()
	var hdbox := BoxMesh.new()
	hdbox.size = Vector3(0.45, 0.45, 0.75)
	head.mesh = hdbox
	head.material_override = c_mat
	head.position = Vector3(0, 2.9, 1.45)
	parent.add_child(head)

	# 4 ta Oyoq (Legs)
	for lx in [-0.42, 0.42]:
		for lz in [-0.75, 0.75]:
			var leg := MeshInstance3D.new()
			var lcyl := CylinderMesh.new()
			lcyl.top_radius = 0.12
			lcyl.bottom_radius = 0.1
			lcyl.height = 1.3
			leg.mesh = lcyl
			leg.material_override = c_mat
			leg.position = Vector3(lx, 0.65, lz)
			parent.add_child(leg)

	# Yuk xurjunlari va Ipak toylari (Saddle & Cargo packs)
	var pack_mat := StandardMaterial3D.new()
	pack_mat.albedo_color = saddle_col
	for s in [-1.0, 1.0]:
		var pack := MeshInstance3D.new()
		var pbox := BoxMesh.new()
		pbox.size = Vector3(0.4, 0.8, 1.4)
		pack.mesh = pbox
		pack.material_override = pack_mat
		pack.position = Vector3(s * 0.7, 1.6, 0.1)
		parent.add_child(pack)

	# Qo'ng'iroqcha (Bell on neck)
	var bell := MeshInstance3D.new()
	var bcyl := CylinderMesh.new()
	bcyl.top_radius = 0.08
	bcyl.bottom_radius = 0.14
	bcyl.height = 0.22
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.9, 0.78, 0.25)
	bmat.metallic = 0.9
	bell.mesh = bcyl
	bell.material_override = bmat
	bell.position = Vector3(0, 1.8, 1.1)
	parent.add_child(bell)


func _build_prompt() -> void:
	_prompt = Label3D.new()
	_prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt.no_depth_test = true
	_prompt.font_size = 18
	_prompt.position = Vector3(0, 3.4, 0)
	_prompt.modulate = Color(1.0, 0.85, 0.4)
	add_child(_prompt)


func _process(delta: float) -> void:
	_update_prompt()

	if is_ambush_active:
		_check_ambush_progress()
		return

	if has_arrived:
		return

	_move_along_waypoints(delta)


func _update_prompt() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null or not is_instance_valid(player):
		_prompt.visible = false
		return

	var dist := global_position.distance_to(player.global_position)
	if dist < 6.0:
		_prompt.visible = true
		if not ambush_completed:
			_prompt.text = "BUYUK IPAK YO'LI KARVONI\n«Sahro qaroqchilaridan xavotirdamiz...»"
		elif has_arrived:
			_prompt.text = "BUYUK IPAK YO'LI KARVONI\n«Boysun bozoriga omon yetib keldik, tashakkur!»"
		else:
			_prompt.text = "BUYUK IPAK YO'LI KARVONI\n«Karvon xavfsiz davom etmoqda»"
	else:
		_prompt.visible = false


func _move_along_waypoints(delta: float) -> void:
	if current_waypoint_idx >= waypoints.size():
		has_arrived = true
		caravan_arrived.emit()
		return

	var target := waypoints[current_waypoint_idx]
	var dir := (target - global_position)
	dir.y = 0.0
	var dist := dir.length()

	# Yo'nalish burchagi
	if dist > 0.1:
		var target_rot := atan2(-dir.x, -dir.z)
		rotation.y = lerp_angle(rotation.y, target_rot, 4.0 * delta)
		global_position += dir.normalized() * (move_speed * delta)

		# Yurish animatsiyasi (Tuya va soqchi tebranishi)
		_walk_cycle += delta * 3.5
		var bob := sin(_walk_cycle) * 0.08
		for c in _camels:
			c.position.y = bob
		if _guard:
			_guard.position.y = -bob

		# Qo'ng'iroq tovushi davri
		_bell_timer += delta
		if _bell_timer > 3.0:
			_bell_timer = 0.0
			Audio.play_coin()

	if dist < 1.2:
		# Pistirma nuqtasiga yetganda
		if current_waypoint_idx == 1 and not ambush_completed:
			_trigger_ambush()
			return

		current_waypoint_idx += 1


func _trigger_ambush() -> void:
	is_ambush_active = true
	ambush_started.emit()

	Audio.play_boss_slam()
	FX.camera_shake(0.35)

	var qs = get_tree().get_first_node_in_group("quest_system")
	if qs and qs.has_method("emit_signal"):
		qs.banner_requested.emit("QAROQCHILAR PISTIRMASI!", "Sahro qaroqchilari karvonga hujum qildi! Himoya qiling!")

	# 3 ta Qaroqchi dushmanni chaqirish
	var spawn_points := [
		global_position + Vector3(8.0, 0.0, 4.0),
		global_position + Vector3(-8.0, 0.0, 5.0),
		global_position + Vector3(4.0, 0.0, -8.0)
	]
	var kinds := [EnemyScript.Kind.SWORD, EnemyScript.Kind.SPEAR, EnemyScript.Kind.ARCHER]

	_ambush_enemies.clear()
	for i in range(spawn_points.size()):
		var enemy = EnemyScript.new()
		enemy.kind = kinds[i]
		enemy.position = spawn_points[i]
		get_tree().current_scene.add_child(enemy)
		_ambush_enemies.append(enemy)
		FX.dust(spawn_points[i], 12, 1.2)


func _check_ambush_progress() -> void:
	var alive_count := 0
	for e in _ambush_enemies:
		if is_instance_valid(e) and not e.is_queued_for_deletion():
			if e.get("state") != EnemyScript.State.DEAD:
				alive_count += 1

	if alive_count == 0:
		_complete_ambush()


func _complete_ambush() -> void:
	is_ambush_active = false
	ambush_completed = true
	current_waypoint_idx += 1

	Audio.play_victory()
	FX.impact_burst(global_position + Vector3.UP * 1.5, Color(1.0, 0.85, 0.2), 30)

	# O'yinchiga mukofot: +80 Tilla va XP
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("add_gold"):
		player.add_gold(80)

	var prog = get_tree().get_first_node_in_group("progression")
	if prog and prog.has_method("add_xp"):
		prog.add_xp(150)

	# 80 tilla tangalar yerga sachraydi
	CoinDropScript.spawn_coins(get_tree(), global_position + Vector3.UP * 1.2, 80, 8)

	var qs = get_tree().get_first_node_in_group("quest_system")
	if qs and qs.has_method("complete_quest"):
		qs.complete_quest("caravan")
	if qs and qs.has_method("emit_signal"):
		qs.banner_requested.emit("KARVON QUTQARILDI!", "Karvonboshi sizga 80 tilla va mukofot hadya etdi!")

	ambush_defeated.emit()


func set_ambush_completed_silent() -> void:
	ambush_completed = true
	is_ambush_active = false
	current_waypoint_idx = waypoints.size() - 1
	if waypoints.size() > 0:
		global_position = waypoints[current_waypoint_idx]
	has_arrived = true
