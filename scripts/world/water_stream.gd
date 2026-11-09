class_name WaterStream
extends Node3D
## Boysun Vohasidagi tog' buloq daryosi (Boysun Soyi) va qadimiy yog'och ko'prik.

const StreamWaterShader = preload("res://shaders/stream_water.gdshader")


func _ready() -> void:
	_build_stream()
	_build_wooden_bridge()
	_build_river_stones()


func _build_stream() -> void:
	# 1. Daryo o'zani (Suv yuzasi tekisligi)
	var water_mesh := PlaneMesh.new()
	water_mesh.size = Vector2(4.8, 105.0)
	water_mesh.subdivide_width = 8
	water_mesh.subdivide_depth = 32

	var mat := ShaderMaterial.new()
	mat.shader = StreamWaterShader
	water_mesh.material = mat

	var mi := MeshInstance3D.new()
	mi.mesh = water_mesh
	# Daryo boshlang'ich o'tov va bozor oralig'ida shimoldan janubga oqadi
	mi.position = Vector3(15.5, 0.04, 25.0)
	add_child(mi)

	# 2. Daryo ostidagi toshli o'zan tubi
	var bed := StaticBody3D.new()
	bed.position = Vector3(15.5, -0.25, 25.0)
	var bmesh := BoxMesh.new()
	bmesh.size = Vector3(5.2, 0.5, 105.0)
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.28, 0.24, 0.20)
	bmat.roughness = 0.95
	bmesh.material = bmat

	var bmi := MeshInstance3D.new()
	bmi.mesh = bmesh
	bed.add_child(bmi)

	var bcol := CollisionShape3D.new()
	var bshape := BoxShape3D.new()
	bshape.size = bmesh.size
	bcol.shape = bshape
	bed.add_child(bcol)
	add_child(bed)


func _build_wooden_bridge() -> void:
	# Daryo ustidan Alpomish o'tovi va Chorsu bozorini bog'lovchi yog'och ko'prik
	var bridge_pos := Vector3(15.5, 0.12, 4.0)

	# 1. Asosiy pol to'sinlari (Deck planks)
	var deck := StaticBody3D.new()
	deck.position = bridge_pos
	var dmesh := BoxMesh.new()
	dmesh.size = Vector3(6.4, 0.22, 3.8)
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(0.42, 0.28, 0.15)
	dmat.roughness = 0.88
	dmesh.material = dmat

	var dmi := MeshInstance3D.new()
	dmi.mesh = dmesh
	deck.add_child(dmi)

	var dcol := CollisionShape3D.new()
	var dshape := BoxShape3D.new()
	dshape.size = dmesh.size
	dcol.shape = dshape
	deck.add_child(dcol)
	add_child(deck)

	# 2. Ko'prik panjaralari (Railings)
	for side in [-1.75, 1.75]:
		var rail := StaticBody3D.new()
		rail.position = bridge_pos + Vector3(0.0, 0.55, side)
		var rmesh := BoxMesh.new()
		rmesh.size = Vector3(6.2, 0.14, 0.14)
		rmesh.material = dmat
		var rmi := MeshInstance3D.new()
		rmi.mesh = rmesh
		rail.add_child(rmi)

		for px in [-2.5, 0.0, 2.5]:
			var post := MeshInstance3D.new()
			var pbox := BoxMesh.new()
			pbox.size = Vector3(0.16, 0.9, 0.16)
			pbox.material = dmat
			post.mesh = pbox
			post.position = Vector3(px, -0.15, 0)
			rail.add_child(post)

		add_child(rail)


func _build_river_stones() -> void:
	# Daryo qirg'oqlaridagi silliq daryo toshlari (Pebbles & Boulders)
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.48, 0.44, 0.40)
	smat.roughness = 0.65

	var rng := RandomNumberGenerator.new()
	rng.seed = 98765

	for z in range(-25, 75, 5):
		for side in [-2.6, 2.6]:
			if z > 1 and z < 7:
				continue # Ko'prik ostida tosh qo'ymaymiz
			var rock := StaticBody3D.new()
			var r_offset := rng.randf_range(-0.5, 0.5)
			rock.position = Vector3(15.5 + side + r_offset, 0.1, float(z) + rng.randf_range(-1.0, 1.0))

			var s := rng.randf_range(0.35, 0.8)
			var rmesh := SphereMesh.new()
			rmesh.radius = s
			rmesh.height = s * 1.3
			rmesh.material = smat

			var rmi := MeshInstance3D.new()
			rmi.mesh = rmesh
			rock.add_child(rmi)

			var rcol := CollisionShape3D.new()
			var rshape := SphereShape3D.new()
			rshape.radius = s
			rcol.shape = rshape
			rock.add_child(rcol)
			add_child(rock)
