class_name DungeonArea
extends Node3D
## 11-bosqich: Qalmoq Zindoni ichki maydoni (Chilbir qoyalari, mash'allar,
## zindon soqchilari va Barchinoy hamda Karajon qahramonlari).

const NPCScript = preload("res://scripts/world/npc.gd")
const EnemyScript = preload("res://scripts/enemies/enemy.gd")

var barchin: NPC
var karajon: NPC
var is_rescued := false


func _ready() -> void:
	add_to_group("dungeon_areas")
	_build_dungeon()


func _build_dungeon() -> void:
	# Zindon zamin toshi (qora bazalt tosh)
	_box(Vector3(0, -0.5, 0), Vector3(36, 1.0, 48), Color(0.12, 0.11, 0.12))

	# Devorlar (Tosh panjara va zindon qal'asi)
	_box(Vector3(-18, 4.0, 0), Vector3(1.0, 8.0, 48), Color(0.18, 0.16, 0.18))
	_box(Vector3(18, 4.0, 0), Vector3(1.0, 8.0, 48), Color(0.18, 0.16, 0.18))
	# Janubiy kirish darvozasi (Arenadan to'g'ridan-to'g'ri o'tish uchun 14 metrli peshtoq)
	_box(Vector3(-12.5, 4.0, 24), Vector3(11.0, 8.0, 1.0), Color(0.18, 0.16, 0.18))
	_box(Vector3(12.5, 4.0, 24), Vector3(11.0, 8.0, 1.0), Color(0.18, 0.16, 0.18))
	_box(Vector3(0, 6.5, 24), Vector3(14.0, 3.0, 1.0), Color(0.18, 0.16, 0.18))
	_torch(Vector3(-6.5, 3.5, 23.5))
	_torch(Vector3(6.5, 3.5, 23.5))
	_box(Vector3(0, 4.0, -24), Vector3(36, 8.0, 1.0), Color(0.18, 0.16, 0.18))

	# Shift (Tepadan qorong'u gumbaz)
	_box(Vector3(0, 8.0, 0), Vector3(36, 0.8, 48), Color(0.08, 0.08, 0.09))

	# Zindon ustunlari (Zanjirlar bilan)
	for x in [-8.0, 8.0]:
		for z in [-12.0, 0.0, 12.0]:
			_pillar(Vector3(x, 0, z))

	# Mash'allar (Qizg'ish olov nuri)
	_torch(Vector3(-17.2, 3.0, -10.0))
	_torch(Vector3(17.2, 3.0, -10.0))
	_torch(Vector3(-17.2, 3.0, 10.0))
	_torch(Vector3(17.2, 3.0, 10.0))

	# Zindon soqchilari (Elite elit nayzachi va qilichchi)
	_spawn_guard(EnemyScript.Kind.SPEAR, Vector3(-4, 0, -6))
	_spawn_guard(EnemyScript.Kind.SWORD, Vector3(4, 0, -6))

	# Barchinoy NPC
	barchin = NPCScript.new()
	barchin.character_type = NPCScript.CharacterType.BARCHIN
	barchin.character_name = "Barchinoy"
	barchin.position = Vector3(0, 0, 14)
	barchin.rotation_degrees.y = 180.0
	add_child(barchin)

	# Karajon NPC (Do'stlashgan qalmoq alp-botiri)
	karajon = NPCScript.new()
	karajon.character_type = NPCScript.CharacterType.KARAJON # maxsus mat bilan
	karajon.character_name = "Karajon Botir"
	karajon.position = Vector3(5, 0, 12)
	karajon.rotation_degrees.y = 160.0
	add_child(karajon)


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

	# Olov tutqichi
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
