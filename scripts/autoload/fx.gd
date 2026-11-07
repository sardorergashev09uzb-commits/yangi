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
