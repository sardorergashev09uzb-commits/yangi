class_name LightMirrorPuzzle
extends Node3D
## 8-bosqich: Qadimiy Nur va Tosh Ko'zgu Boshqotirmasi (Light Beam & Rotatable Mirror Puzzle).
## O'yinchi 3 ta tosh ko'zguni [E] bilan 90 gradusdan aylantirib, quyosh nurini qadimiy runa
## qabul qilgichiga to'g'rilashi kerak. Yechilganda xazina eshigi ochiladi va noyob tumor beriladi.

signal puzzle_solved()

@export var is_solved := false

var _mirrors: Array[Node3D] = []
var _target_angles: Array[float] = [90.0, 180.0, 270.0]
var _current_angles: Array[float] = [0.0, 0.0, 0.0]
var _secret_gate: StaticBody3D
var _gate_open_y := 4.5
var _gate_current_y := 0.0
var _beam_line: MeshInstance3D
var _receiver_crystal: MeshInstance3D
var _relic_chest: Node3D


func _ready() -> void:
	add_to_group("puzzles")
	_build_puzzle_chamber()


func _build_puzzle_chamber() -> void:
	# 1. Nur manbai (Quyosh kristalli qandil)
	var emitter := Node3D.new()
	emitter.position = Vector3(-8.0, 1.6, -6.0)
	var em_mesh := MeshInstance3D.new()
	var esph := SphereMesh.new()
	esph.radius = 0.4
	esph.height = 0.8
	var emat := StandardMaterial3D.new()
	emat.albedo_color = Color(0.9, 0.8, 0.3)
	emat.emission_enabled = true
	emat.emission = Color(1.0, 0.9, 0.4)
	emat.emission_energy_multiplier = 3.0
	esph.material = emat
	em_mesh.mesh = esph
	emitter.add_child(em_mesh)

	var elight := OmniLight3D.new()
	elight.light_color = Color(1.0, 0.95, 0.6)
	elight.light_energy = 2.5
	elight.omni_range = 10.0
	emitter.add_child(elight)
	add_child(emitter)

	# 2. Uchta aylanuvchi tosh ko'zgu
	var mirror_positions := [
		Vector3(-8.0, 0, 4.0),
		Vector3(2.0, 0, 4.0),
		Vector3(2.0, 0, -6.0)
	]

	for i in range(mirror_positions.size()):
		var m_root := Node3D.new()
		m_root.position = mirror_positions[i]

		# Ko'zgu poydevori
		var base := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.4
		cyl.bottom_radius = 0.5
		cyl.height = 1.2
		var bmat := StandardMaterial3D.new()
		bmat.albedo_color = Color(0.3, 0.28, 0.25)
		cyl.material = bmat
		base.mesh = cyl
		base.position.y = 0.6
		m_root.add_child(base)

		# Buriluvchi ko'zgu qismi (Pivot)
		var pivot := Node3D.new()
		pivot.name = "Pivot"
		pivot.position.y = 1.4

		var m_frame := MeshInstance3D.new()
		var fbox := BoxMesh.new()
		fbox.size = Vector3(0.12, 1.2, 0.9)
		var fmat := StandardMaterial3D.new()
		fmat.albedo_color = Color(0.5, 0.4, 0.2) # Bronza ramka
		fbox.material = fmat
		m_frame.mesh = fbox
		pivot.add_child(m_frame)

		# Yarqiroq ko'zgu yuzasi
		var m_glass := MeshInstance3D.new()
		var gbox := BoxMesh.new()
		gbox.size = Vector3(0.04, 1.0, 0.75)
		var gmat := StandardMaterial3D.new()
		gmat.albedo_color = Color(0.85, 0.95, 1.0)
		gmat.metallic = 0.95
		gmat.roughness = 0.05
		gbox.material = gmat
		m_glass.mesh = gbox
		m_glass.position.x = 0.05
		pivot.add_child(m_glass)

		m_root.add_child(pivot)

		# Interaksiya maydoni
		var m_area := Area3D.new()
		m_area.collision_layer = 1 << 0
		m_area.collision_mask = 1 << 1
		var acol := CollisionShape3D.new()
		var ashape := SphereShape3D.new()
		ashape.radius = 2.0
		acol.shape = ashape
		acol.position.y = 1.0
		m_area.add_child(acol)

		var lbl := Label3D.new()
		lbl.text = "[E] Ko'zguni Burish"
		lbl.font_size = 24
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.modulate = Color(0.9, 0.8, 0.2)
		lbl.position = Vector3(0, 2.2, 0)
		lbl.visible = false
		m_area.add_child(lbl)

		var idx := i
		m_area.body_entered.connect(func(_b): if not is_solved: lbl.visible = true)
		m_area.body_exited.connect(func(_b): lbl.visible = false)

		m_root.set_meta("idx", idx)
		m_root.set_meta("pivot", pivot)
		m_root.set_meta("label", lbl)
		add_child(m_root)
		_mirrors.append(m_root)

	# 3. Nur Qabul Qilgich Sensori (Sun Rune Receiver)
	_receiver_crystal = MeshInstance3D.new()
	var rc_box := BoxMesh.new()
	rc_box.size = Vector3(0.8, 0.8, 0.8)
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(0.2, 0.3, 0.5)
	rmat.emission_enabled = true
	rmat.emission = Color(0.1, 0.2, 0.4)
	rc_box.material = rmat
	_receiver_crystal.mesh = rc_box
	_receiver_crystal.position = Vector3(8.0, 1.6, -6.0)
	add_child(_receiver_crystal)

	# 4. Maxfiy Xazina Qabr Eshigi (Secret Iron Gate)
	_secret_gate = StaticBody3D.new()
	_secret_gate.position = Vector3(8.0, 0, 0.0)
	var gmesh := MeshInstance3D.new()
	var gbox := BoxMesh.new()
	gbox.size = Vector3(0.4, 4.0, 3.2)
	var gate_mat := StandardMaterial3D.new()
	gate_mat.albedo_color = Color(0.2, 0.2, 0.22)
	gate_mat.metallic = 0.9
	gbox.material = gate_mat
	gmesh.mesh = gbox
	gmesh.position.y = 2.0
	_secret_gate.add_child(gmesh)

	var gcol := CollisionShape3D.new()
	var gshape := BoxShape3D.new()
	gshape.size = Vector3(0.4, 4.0, 3.2)
	gcol.shape = gshape
	gcol.position.y = 2.0
	_secret_gate.add_child(gcol)
	add_child(_secret_gate)


func rotate_mirror(idx: int) -> void:
	if is_solved or idx < 0 or idx >= _mirrors.size():
		return
	_current_angles[idx] = fmod(_current_angles[idx] + 90.0, 360.0)
	var pivot: Node3D = _mirrors[idx].get_meta("pivot")
	if pivot:
		pivot.rotation_degrees.y = _current_angles[idx]

	Audio.play_hit()
	FX.sparks(_mirrors[idx].global_position + Vector3.UP * 1.4, Vector3.UP, Color(0.8, 0.9, 1.0), 12)
	_check_solution()


func _check_solution() -> void:
	var matches := true
	for i in range(_target_angles.size()):
		if absf(_current_angles[i] - _target_angles[i]) > 1.0:
			matches = false
			break

	if matches and not is_solved:
		solve_puzzle()


func solve_puzzle() -> void:
	if is_solved:
		return
	is_solved = true

	# Ko'zgularni to'g'ri holatga sinxronlashtirish
	for i in range(_target_angles.size()):
		_current_angles[i] = _target_angles[i]
		var pivot: Node3D = _mirrors[i].get_meta("pivot")
		if pivot:
			pivot.rotation_degrees.y = _target_angles[i]
		var lbl: Label3D = _mirrors[i].get_meta("label")
		if lbl:
			lbl.visible = false

	# Sensor kristallini yoritish
	if _receiver_crystal and _receiver_crystal.mesh.material:
		var mat := _receiver_crystal.mesh.material as StandardMaterial3D
		mat.albedo_color = Color(0.2, 0.9, 1.0)
		mat.emission = Color(0.3, 0.9, 1.0)
		mat.emission_energy_multiplier = 4.0

	# Maxfiy xazina xonasida oltin va tumor berish
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("add_gold"):
		player.add_gold(150)

	Audio.play_level_up()
	FX.shockwave_ring(global_position + Vector3(8.0, 0.2, 0.0), 6.0, Color(0.3, 0.9, 1.0), 0.5)
	FX.impact_burst(global_position + Vector3(8.0, 2.0, -6.0), Color(0.4, 1.0, 0.8), 30)

	puzzle_solved.emit()


func _physics_process(delta: float) -> void:
	if is_solved and _gate_current_y < _gate_open_y:
		_gate_current_y = move_toward(_gate_current_y, _gate_open_y, 4.0 * delta)
		if _secret_gate:
			_secret_gate.position.y = _gate_current_y
			if _gate_current_y >= _gate_open_y:
				_secret_gate.set_collision_layer_value(1, false)
