extends Node
## Global o'yin sozlamalari va qiyinlik darajalari:
## - OSON (Story): kamroq zarar oladi, ko'proq zarar yetkazadi
## - ODDIY (Normal): dostonning standart muvozanati
## - ALP (Hard): dushmanlar shafqatsiz, yuqori zarar, kamroq xato kechiriladi

enum Difficulty { EASY, NORMAL, HARD }

signal difficulty_changed(level: Difficulty)

var difficulty: Difficulty = Difficulty.NORMAL:
	set(val):
		if difficulty != val:
			difficulty = val
			difficulty_changed.emit(difficulty)

const NAMES := {
	Difficulty.EASY: "Oson (Sayr)",
	Difficulty.NORMAL: "Oddiy (Doston)",
	Difficulty.HARD: "Alp (Sinov)"
}

# Multiplikatorlar: [dushman zarari, dushman salomatligi, o'yinchi zarari]
const MULTIPLIERS := {
	Difficulty.EASY:   {"enemy_dmg": 0.65, "enemy_hp": 0.8,  "player_dmg": 1.25},
	Difficulty.NORMAL: {"enemy_dmg": 1.0,  "enemy_hp": 1.0,  "player_dmg": 1.0},
	Difficulty.HARD:   {"enemy_dmg": 1.45, "enemy_hp": 1.25, "player_dmg": 0.9},
}


func get_mult(key: String) -> float:
	return MULTIPLIERS[difficulty].get(key, 1.0)


func get_difficulty_name() -> String:
	return NAMES.get(difficulty, "Oddiy")


func cycle_difficulty() -> Difficulty:
	match difficulty:
		Difficulty.EASY:
			difficulty = Difficulty.NORMAL
		Difficulty.NORMAL:
			difficulty = Difficulty.HARD
		Difficulty.HARD:
			difficulty = Difficulty.EASY
	return difficulty
