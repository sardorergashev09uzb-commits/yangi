class_name DungeonArea
extends Node3D
## 8-bosqich: Qalmoq Zindoni Ko'p Qavatli Arxitekturasi, O'lim Tuzoqlari va Boshqotirmalar.
## 1-qavat: Qorovullar kazarmasi va zindon dahli;
## 2-qavat: O'lim Tuzoqlari (Aylanuvchi po'lat tig'lar va qadimiy bosim plitalari);
## 3-qavat: Taxt Zali, Muallaq Temir Qafas (Barchinoy saqlanadigan joy);
## Sharqiy Qabr: Nur va Tosh Ko'zgu Boshqotirmasi (Light & Mirror Chamber).

const NPCScript = preload("res://scripts/world/npc.gd")
const EnemyScript = preload("res://scripts/enemies/enemy.gd")
const BladeTrapScript = preload("res://scripts/world/blade_trap.gd")
const PressurePlateScript = preload("res://scripts/world/pressure_plate.gd")
const SuspendedCageScript = preload("res://scripts/world/suspended_cage.gd")
const LightMirrorPuzzleScript = preload("res://scripts/world/light_mirror_puzzle.gd")

var barchin: NPC
var karajon: NPC
var is_rescued := false

var blade_traps: Array[Area3D] = []
var pressure_plates: Array[Area3D] = []
var suspended_cage: Node3D
var mirror_puzzle: Node3D


func _ready() -> void:
	add_to_group("dungeon_areas")
	_build_dungeon()


func _build_dungeon() -> void:
	# 1. Asosiy Zindon Zamin Toshlari (Bazalt plitalar)
	_box(Vector3(0, -0.5, 0), Vector3(44, 1.0, 56), Color(0.12, 0.11, 0.12))

	# Sharqiy Boshqotirma Xonasi Zamini
	_box(Vector3(26, -0.5, 0), Vector3(20, 1.0, 24), Color(0.15, 0.13, 0.14))

	# Tashqi Devorlar (Tosh panjara va zindon devorlari)
	_box(Vector3(-22, 4.0, 0), Vector3(1.0, 8.0, 56), Color(0.18, 0.16, 0.18))
	_box(Vector3(22, 4.0, 20), Vector3(1.0, 8.0, 16), Color(0.18, 0.16, 0.18))
	_box(Vector3(22, 4.0, -20), Vector3(1.0, 8.0, 16), Color(0.18, 0.16, 0.18))
	_box(Vector3(36, 4.0, 0), Vector3(1.0, 8.0, 24), Color(0.18, 0.16, 0.18)) # Sharqiy devor

	# Janubiy kirish darvozasi (Arenadan to'g'ridan-to'g'ri o'tish peshtoqi)
	_box(Vector3(-14.5, 4.0, 28), Vector3(15.0, 8.0, 1.0), Color(0.18, 0.16, 0.18))
	_box(Vector3(14.5, 4.0, 28), Vector3(15.0, 8.0, 1.0), Color(0.18, 0.16, 0.18))
	_box(Vector3(0, 6.5, 28), Vector3(14.0, 3.0, 1.0), Color(0.18, 0.16, 0.18))
	_torch(Vector3(-6.5, 3.5, 27.5))
	_torch(Vector3(6.5, 3.5, 27.5))

	# Shimoliy devor
	_box(Vector3(0, 4.0, -28), Vector3(44, 8.0, 1.0), Color(0.18, 0.16, 0.18))

	# Qorong'u gumbaz shift
	_box(Vector3(0, 8.0, 0), Vector3(44, 0.8, 56), Color(0.08, 0.08, 0.09))
	_box(Vector3(26, 8.0, 0), Vector3(20, 0.8, 24), Color(0.08, 0.08, 0.09))

	# Zindon Ustunlari
	for x in [-12.0, 12.0]:
		for z in [-18.0, -6.0, 6.0, 18.0]:
			_pillar(Vector3(x, 0, z))

	# Mash'allar (Atmosferik qizg'ish olov nuri)
	_torch(Vector3(-21.2, 3.0, -14.0))
	_torch(Vector3(-21.2, 3.0, 14.0))
	_torch(Vector3(21.2, 3.0, -14.0))
	_torch(Vector3(21.2, 3.0, 14.0))
	_torch(Vector3(35.2, 3.0, 0.0))

	# 1-Qavat Soqchilari (Elite nayzachi va qilichchi)
	_spawn_guard(EnemyScript.Kind.SPEAR, Vector3(-5, 0, 20))
	_spawn_guard(EnemyScript.Kind.SWORD, Vector3(5, 0, 20))

	# 2-Qavat: O'lim Tuzoqlari Labirinti (Aylanuvchi pichoqlar va bosim plitalari)
	_build_trap_maze()

	# 3-Qavat: Taxt Zali va Muallaq Qafas
	_build_throne_and_cage()

	# Sharqiy qanot: Nur va Ko'zgu Boshqotirmasi
	_build_mirror_puzzle_room()


func _build_trap_maze() -> void:
	# Aylanuvchi tig'lar tuzoqlari
	var trap1 := BladeTrapScript.new()
	trap1.position = Vector3(-4.0, 0, 0.0)
	trap1.damage = 22.0
	trap1.rotation_speed = 3.2
	add_child(trap1)
	blade_traps.append(trap1)

	var trap2 := BladeTrapScript.new()
	trap2.position = Vector3(4.0, 0, -8.0)
	trap2.damage = 25.0
	trap2.rotation_speed = -3.8
	add_child(trap2)
	blade_traps.append(trap2)

	# Bosim plitalari
	var plate1 := PressurePlateScript.new()
	plate1.plate_id = "dungeon_plate_north"
	plate1.position = Vector3(0.0, 0, -4.0)
	add_child(plate1)
	pressure_plates.append(plate1)

	var plate2 := PressurePlateScript.new()
	plate2.plate_id = "dungeon_plate_east"
	plate2.position = Vector3(16.0, 0, 0.0)
	add_child(plate2)
	pressure_plates.append(plate2)


func _build_throne_and_cage() -> void:
	# Muallaq temir qafas va chig'ir richagi
	suspended_cage = SuspendedCageScript.new()
	suspended_cage.position = Vector3(0, 0, 14)
	add_child(suspended_cage)

	# Barchinoy NPC
	barchin = NPCScript.new()
	barchin.character_type = NPCScript.CharacterType.BARCHIN
	barchin.character_name = "Barchinoy"
	barchin.position = Vector3(0, 0, 14)
	barchin.rotation_degrees.y = 180.0
	add_child(barchin)

	# Karajon NPC (Qalmoq alp-botiri)
	karajon = NPCScript.new()
	karajon.character_type = NPCScript.CharacterType.KARAJON
	karajon.character_name = "Karajon Botir"
	karajon.position = Vector3(5, 0, 12)
	karajon.rotation_degrees.y = 160.0
	add_child(karajon)


func _build_mirror_puzzle_room() -> void:
	# Sharqiy xonada nur va ko'zgu boshqotirmasi
	mirror_puzzle = LightMirrorPuzzleScript.new()
	mirror_puzzle.position = Vector3(26.0, 0, 0.0)
	add_child(mirror_puzzle)


func _spawn_guard(kind_val: int, pos: Vector3) -> void:
	var e := EnemyScript.new()
	e.kind = kind_val
	e.position = pos
	add_child(e)


func _pillar(pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.5
	cyl.bottom_radius = 0.6
	cyl.height = 8.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.22, 0.22)
	mat.roughness = 0.95
	cyl.material = mat
	mi.mesh = cyl
	mi.position = pos + Vector3(0, 4.0, 0)
	add_child(mi)

	var sb := StaticBody3D.new()
	sb.position = pos
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.6
	shape.height = 8.0
	col.shape = shape
	col.position.y = 4.0
	sb.add_child(col)
	add_child(sb)


func _torch(pos: Vector3) -> void:
	var omni := OmniLight3D.new()
	omni.position = pos
	omni.light_color = Color(1.0, 0.55, 0.2)
	omni.light_energy = 2.5
	omni.omni_range = 14.0
	omni.shadow_enabled = true
	add_child(omni)

	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.3, 0.8, 0.3)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.2, 0.1)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.5, 0.1)
	mat.emission_energy_multiplier = 2.0
	box.material = mat
	mi.mesh = box
	mi.position = pos
	add_child(mi)


func _box(pos: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var sb := StaticBody3D.new()
	sb.position = pos
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	box.material = mat
	mi.mesh = box
	sb.add_child(mi)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	sb.add_child(col)

	add_child(sb)
	return sb
