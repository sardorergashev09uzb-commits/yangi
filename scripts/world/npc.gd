class_name NPC
extends CharacterBody3D
## Doston qahramonlari NPC: Qultoy Cho'pon, Barchinoy va Karajon.

enum CharacterType { QULTOY, BARCHIN }

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
	else:
		# Barchinoy atlas ko'ylagi (Qizil-binafsha)
		bmat.albedo_color = Color(0.7, 0.2, 0.45)

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
				{
					"speaker": "Qultoy Cho'pon",
					"text": "Assalomu alaykum, botirim Hakimbek! Ko'zimga o't tushsin, naqadar ulug' pahlavon bo'lib voyaga yetibsan!"
				},
				{
					"speaker": "Qultoy Cho'pon",
					"text": "Eshitdingmi, amaking Boysari o'n ming uyli el bilan Qalmoq yurtiga ketgan edi. U yerda go'zal Barchinoy qizimiz boshiga musibat tushibdi!"
				},
				{
					"speaker": "Qultoy Cho'pon",
					"text": "Qalmoq podshohi va to'rt alpi Barchinni zo'rlik bilan olmoqchi. Lekin qizimiz: 'Menga teng bo'lsa, Boysundan Hakimbek kelsin, 14 botmon kamonimni tortsin, Boychiborni poygada o'zdirsin!' deb shart qo'ydi."
				},
				{
					"speaker": "Alpamish (Tanlov)",
					"text": "Qultoy ota, bu xabarni eshitib yuragim o'rtandi...",
					"choices": [
						"Adolat va ehtirom: 'Barchinoyning sha'nini saqlayman, elga tinchlik olib kelaman!'",
						"Jangovar shiddat: 'Qalmoq alplari haddidan oshibdi! Yoyim va qilichim bilan ularni yakson qilaman!'"
					]
				},
				{
					"speaker": "Qultoy Cho'pon",
					"text": "Omin, xudo yo'lingni ochsin! Boychibor tulporing o'tov yonida shay turibdi. Avval uni minib dasht bo'ylab sinab ko'r, so'ng Shimoliy Qal'a sari yo'l ol!"
				}
			]
		else:
			lines = [
				{
					"speaker": "Qultoy Cho'pon",
					"text": "Harakat qil, botirim! Boychiborga minib, dashtdagi Qoyali Dev va Shimoldagi Surxayil darvozasini och!"
				}
			]

	if not dbox.dialog_finished.is_connected(_on_dialog_done):
		dbox.dialog_finished.connect(_on_dialog_done, CONNECT_ONE_SHOT)

	dbox.start_dialog(lines)


func _on_dialog_done(choice_index: int) -> void:
	_talked_once = true
	var qsystem = get_tree().get_first_node_in_group("quest_system")
	if qsystem and qsystem.has_method("complete_quest"):
		qsystem.complete_quest("qultoy")
