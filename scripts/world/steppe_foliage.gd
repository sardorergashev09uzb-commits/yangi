class_name SteppeFoliage
extends Node3D
## Boysun dashtidagi shamolda hilpiraydigan minglab maysalar va dasht lolalari.
## MultiMeshInstance3D orqali 1 ta draw call'da yuqori unumdorlik bilan ishlaydi.

const GrassShader = preload("res://shaders/foliage_grass.gdshader")

@export var grass_count := 2600

var _mm_inst: MultiMeshInstance3D


func _ready() -> void:
	_build_grass_foliage()


func _build_grass_foliage() -> void:
	_mm_inst = MultiMeshInstance3D.new()
	_mm_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# 1. 2 ta kesishgan yupqa tekislik (Cross-quad grass blade)
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# 1-tekislik (X bo'yicha)
	st.set_uv(Vector2(0, 1))
	st.add_vertex(Vector3(-0.2, 0.0, 0.0))
	st.set_uv(Vector2(1, 1))
	st.add_vertex(Vector3(0.2, 0.0, 0.0))
	st.set_uv(Vector2(0.5, 0))
	st.add_vertex(Vector3(0.0, 0.85, 0.0))

	# 2-tekislik (Z bo'yicha kesishgan)
	st.set_uv(Vector2(0, 1))
	st.add_vertex(Vector3(0.0, 0.0, -0.2))
	st.set_uv(Vector2(1, 1))
	st.add_vertex(Vector3(0.0, 0.0, 0.2))
	st.set_uv(Vector2(0.5, 0))
	st.add_vertex(Vector3(0.0, 0.85, 0.0))

	st.generate_normals()
	mesh = st.commit()

	# 2. Materialni ulash
	var mat := ShaderMaterial.new()
	mat.shader = GrassShader
	_mm_inst.material_override = mat

	# 3. MultiMesh parametrlarini o'rnatish
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = grass_count

	var rng := RandomNumberGenerator.new()
	rng.seed = 12345

	var valid_idx := 0
	for i in range(grass_count):
		var pos := Vector3(
			rng.randf_range(-85.0, 105.0),
			0.0,
			rng.randf_range(-35.0, 105.0)
		)

		# Ichki maydonlarni o'tlardan tozalash:
		# a) Boshlang'ich mashg'ulot tosh maydoni
		if absf(pos.x) < 14.0 and pos.z > -16.0 and pos.z < 14.0:
			continue
		# b) Shimoliy Surxayil arenasi
		if pos.z < -45.0:
			continue
		# c) Qaroqchilar istehkomi
		if pos.x > 67.0 and pos.x < 83.0 and pos.z > 46.0 and pos.z < 65.0:
			continue
		# d) Chorsu bozori rastalari
		if pos.x > 18.0 and pos.x < 36.0 and pos.z > -2.0 and pos.z < 12.0:
			continue

		# O'tning o'lchami va burilishi
		var s := rng.randf_range(0.75, 1.25)
		var rot_y := rng.randf_range(0.0, TAU)
		var t := Transform3D()
		t = t.scaled(Vector3(s, s * rng.randf_range(0.9, 1.2), s))
		t = t.rotated(Vector3.UP, rot_y)
		t.origin = pos

		mm.set_instance_transform(valid_idx, t)
		valid_idx += 1

	mm.visible_instance_count = valid_idx
	_mm_inst.multimesh = mm
	add_child(_mm_inst)
