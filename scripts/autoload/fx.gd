extends Node
## Umumiy effektlar: hit-stop (zarba paytida vaqtni sekinlatish).

var _stopping := false

func hit_stop(duration: float, slow := 0.05) -> void:
	if _stopping:
		return
	_stopping = true
	Engine.time_scale = slow
	# 4-parametr: real vaqtda hisoblaydi (time_scale ta'sir qilmaydi)
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
	_stopping = false


func popup(world_pos: Vector3, amount: float, color := Color(1.0, 0.9, 0.3)) -> void:
	var l := Label3D.new()
	l.text = str(int(amount))
	l.font_size = 72
	l.modulate = color
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	get_tree().current_scene.add_child(l)
	l.global_position = world_pos + Vector3(randf_range(-0.3, 0.3), 0.0, 0.0)
	var t := l.create_tween()
	t.tween_property(l, "global_position:y", l.global_position.y + 0.9, 0.7)
	t.parallel().tween_property(l, "modulate:a", 0.0, 0.7)
	t.tween_callback(l.queue_free)
