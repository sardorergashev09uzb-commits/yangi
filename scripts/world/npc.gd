class_name NPC
extends CharacterBody3D
## Doston qahramonlari NPC: Qultoy Cho'pon, Barchinoy va Karajon.

enum CharacterType { QULTOY, BARCHIN, KARAJON }

@export var character_type := CharacterType.QULTOY
@export var character_name := "Qultoy Cho'pon"

var _prompt: Label3D
var _dialog_box: CanvasLayer
var _talked_once := false


func _ready() -> void:
	add_to_group("npcs")
	collision_layer = 1 << 2 # dushman/NPC qatlami
	collision_mask = 1 # dunyo bilan to'qnashadi

	_build_visuals()
	_build_prompt()


func _build_visuals() -> void:
	var body_mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.35
	cyl.bottom_radius = 0.45
	cyl.height = 1.6
	var bmat := StandardMaterial3D.new()

	if character_type == CharacterType.QULTOY:
		# Qultoy to'ni (Yashil-ko'k to'n)
		bmat.albedo_color = Color(0.2, 0.38, 0.3)
	elif character_type == CharacterType.BARCHIN:
		# Barchinoy atlas ko'ylagi (Zarbof to'q qizil)
		bmat.albedo_color = Color(0.8, 0.15, 0.35)
	elif character_type == CharacterType.KARAJON:
		# Karajon Alp sovuti (Qora po'lat va oltin kamar)
		bmat.albedo_color = Color(0.18, 0.18, 0.22)
		bmat.metallic = 0.8

	cyl.material = bmat
	body_mi.mesh = cyl
	body_mi.position.y = 0.8
	add_child(body_mi)

	# Bosh va salla/bosh kiyim
	var head := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.22
	sph.height = 0.44
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = Color(0.85, 0.72, 0.6)
	head.mesh = sph
	head.material_override = hmat
	head.position.y = 1.75
	add_child(head)

	# Qultoyning oq sallasi va soqoli
	if character_type == CharacterType.QULTOY:
		var turban := MeshInstance3D.new()
		var tcyl := CylinderMesh.new()
		tcyl.top_radius = 0.28
		tcyl.bottom_radius = 0.26
		tcyl.height = 0.22
		var tmat := StandardMaterial3D.new()
		tmat.albedo_color = Color(0.95, 0.95, 0.9)
		turban.mesh = tcyl
		turban.material_override = tmat
		turban.position.y = 1.95
		add_child(turban)

		# Oq soqol
		var beard := MeshInstance3D.new()
		var bcyl := CylinderMesh.new()
		bcyl.top_radius = 0.15
		bcyl.bottom_radius = 0.05
		bcyl.height = 0.35
		beard.mesh = bcyl
		beard.material_override = tmat
		beard.position = Vector3(0, 1.55, 0.18)
		beard.rotation_degrees.x = 25.0
		add_child(beard)

	# Kolliziya
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.45
	shape.height = 1.8
	col.shape = shape
	col.position.y = 0.9
	add_child(col)


func _build_prompt() -> void:
	_prompt = Label3D.new()
	_prompt.text = "%s\n[ E ] - Suhbatlashish" % character_name
	_prompt.font_size = 38
	_prompt.position.y = 2.4
	_prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt.modulate = Color(1.0, 0.88, 0.35)
	add_child(_prompt)


func _physics_process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null or not is_instance_valid(player):
		_prompt.visible = false
		return

	var dist := global_position.distance_to(player.global_position)
	_prompt.visible = dist < 3.8

	if dist < 3.8 and Input.is_action_just_pressed("talk"):
		interact()


func interact() -> void:
	var dbox = get_tree().get_first_node_in_group("dialog_box")
	if dbox == null:
		return

	var lines: Array[Dictionary] = []
	if character_type == CharacterType.QULTOY:
		if not _talked_once:
			lines = [
				{"speaker": "Qultoy Cho'pon", "text": "Assalomu alaykum, botirim Hakimbek! Ko'zimga o't tushsin, naqadar ulug' pahlavon bo'lib voyaga yetibsan!"},
				{"speaker": "Qultoy Cho'pon", "text": "Eshitdingmi, amaking Boysari o'n ming uyli el bilan Qalmoq yurtiga ketgan edi. U yerda go'zal Barchinoy qizimiz boshiga musibat tushibdi!"},
				{"speaker": "Qultoy Cho'pon", "text": "Qalmoq podshohi va to'rt alpi Barchinni zo'rlik bilan olmoqchi. Lekin qizimiz: 'Menga teng bo'lsa, Boysundan Hakimbek kelsin, 14 botmon kamonimni tortsin!' deb shart qo'ydi."},
				{"speaker": "Alpamish (Tanlov)", "text": "Qultoy ota, bu xabarni eshitib yuragim o'rtandi...", "choices": ["Adolat: 'Barchinoy sha'nini asrayman!'", "Jang: 'Qalmoq alplarini tor-mor qilaman!'"]},
				{"speaker": "Qultoy Cho'pon", "text": "Omin! Boychibor shay. Dashtdagi Dev va Shimoliy arenadagi Surxayil Alpni yengib, Zindonga yo'l ol!"}
			]
		else:
			lines = [{"speaker": "Qultoy Cho'pon", "text": "Harakat qil, botirim! Surxayil Alp mag'lub bo'lgach, Qalmoq Zindoni darvozasi ochiladi!"}]

	elif character_type == CharacterType.BARCHIN:
		lines = [
			{"speaker": "Barchinoy", "text": "Hakimbek! Jonim pahlavoni! Bilardim, va'dangda turib Boysundan meni izlab kelishingni bilardim!"},
			{"speaker": "Barchinoy", "text": "Surxayil va Qalmoq lashkarlari meni bu qorong'u zindonga bandi qilgan edi. Sen kelib Qo'ng'irot sha'nini tiklading!"},
			{"speaker": "Alpamish (Tanlov)", "text": "Barchinim, endi xavf ortda qoldi!", "choices": ["'El-yurtimiz Boysunga qaytamiz, to'y tomosha qilamiz!'", "'Qalmoq eli bilan abadiy sulh va do'stlik tuzamiz!'"]},
			{"speaker": "Barchinoy", "text": "Karajon botir ham biz tomonga o'tdi. Endi Boysun eli tinch va omon bo'lsin!"}
		]

	elif character_type == CharacterType.KARAJON:
		lines = [
			{"speaker": "Karajon Botir", "text": "Alp Alpomish! Men Karajonman — Qalmoq alpi edim, lekin sening mardliging va kuchingni ko'rib qoyil qoldim!"},
			{"speaker": "Karajon Botir", "text": "Surxayil kabi nohaqlik tarafdori emasman. Men sen bilan qiyomatli do'st (qon qardosh) bo'lishga qasamyod qilaman!"},
			{"speaker": "Alpamish", "text": "Do'stlik qo'lini cho'zgan mardga Alpomishning quchog'i hamisha ochiq, Karajon birodar!"}
		]

	if not dbox.dialog_finished.is_connected(_on_dialog_done):
		dbox.dialog_finished.connect(_on_dialog_done, CONNECT_ONE_SHOT)

	dbox.start_dialog(lines)


func _on_dialog_done(choice_index: int) -> void:
	_talked_once = true
	var qsystem = get_tree().get_first_node_in_group("quest_system")
	if qsystem and qsystem.has_method("complete_quest"):
		if character_type == CharacterType.QULTOY:
			qsystem.complete_quest("qultoy")
		elif character_type == CharacterType.BARCHIN:
			qsystem.complete_quest("rescue_barchin")
		elif character_type == CharacterType.KARAJON:
			qsystem.complete_quest("karajon_oath")
