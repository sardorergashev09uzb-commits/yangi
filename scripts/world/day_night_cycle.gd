class_name DayNightCycle
extends Node
## 12-bosqich: Boysun Dashtida real vaqtli Kun va Tun almashinuvi.
## Quyosh aylanishi, ranglar (tong, tush, shom, tun), yulduzlar va tuman dinamikasi.

@export var day_length_seconds := 360.0 # To'liq kun/tun davri: 6 daqiqa
@export var is_paused := false

var time_of_day := 0.28 # 0.0 - yarim tun, 0.25 - tong, 0.5 - tush, 0.75 - shom

var sun: DirectionalLight3D
var env: Environment
var sky_mat: ProceduralSkyMaterial


func _ready() -> void:
	add_to_group("day_night_cycle")


func setup(p_sun: DirectionalLight3D, p_env: Environment, p_sky_mat: ProceduralSkyMaterial) -> void:
	sun = p_sun
	env = p_env
	sky_mat = p_sky_mat
	_update_lighting(0.0)


func _process(delta: float) -> void:
	if is_paused or sun == null or env == null or sky_mat == null:
		return

	# Vaqt o'tishi
	time_of_day += delta / day_length_seconds
	if time_of_day >= 1.0:
		time_of_day -= 1.0

	_update_lighting(delta)


func _update_lighting(_delta: float) -> void:
	# Quyosh burchagi (X o'qi bo'yicha aylanish: -90 tush, 90 yarim tun)
	var sun_angle := (time_of_day * 360.0) - 90.0
	sun.rotation_degrees = Vector3(sun_angle, -35.0, 0.0)

	# Quyosh ufqdan balandligi (-1.0 dan 1.0 gacha)
	var sun_height := sin(time_of_day * TAU - PI * 0.5)

	if sun_height > 0.0:
		# KUNDUZ / TONG / SHOM
		var day_factor := clampf(sun_height * 2.5, 0.0, 1.0)
		sun.light_energy = lerpf(0.1, 1.35, day_factor)
		sun.shadow_enabled = true

		# Ufqqa yaqinlashganda oltin/qizg'ish shom nuri
		var sunset_factor := clampf(1.0 - absf(sun_height), 0.0, 1.0)
		var noon_color := Color(1.0, 0.94, 0.84)
		var dusk_color := Color(1.0, 0.65, 0.35)
		sun.light_color = noon_color.lerp(dusk_color, sunset_factor * 0.8)

		# Osmon ranglari
		sky_mat.sky_top_color = Color(0.15, 0.35, 0.68).lerp(Color(0.2, 0.45, 0.75), day_factor)
		sky_mat.sky_horizon_color = Color(0.9, 0.55, 0.3).lerp(Color(0.85, 0.75, 0.6), day_factor)
		sky_mat.ground_horizon_color = sky_mat.sky_horizon_color

		# Tuman va Volumetric Fog
		env.fog_light_color = Color(0.85, 0.65, 0.45).lerp(Color(0.8, 0.76, 0.68), day_factor)
		env.fog_density = lerpf(0.0035, 0.002, day_factor)
		if env.volumetric_fog_enabled:
			env.volumetric_fog_albedo = Color(0.9, 0.7, 0.5).lerp(Color(0.86, 0.82, 0.74), day_factor)
			env.volumetric_fog_density = lerpf(0.012, 0.008, day_factor)
			sun.light_volumetric_fog_energy = lerpf(0.8, 1.8, day_factor)
	else:
		# TUN (Oydin kecha)
		var night_factor := clampf(-sun_height * 2.0, 0.0, 1.0)
		sun.light_energy = lerpf(0.08, 0.18, night_factor)
		# Oy nuri (kumushrang-ko'k)
		sun.light_color = Color(0.45, 0.55, 0.75)
		sun.shadow_enabled = true

		# Tungi osmon va yulduzlar ko'rinishi
		sky_mat.sky_top_color = Color(0.02, 0.03, 0.06)
		sky_mat.sky_horizon_color = Color(0.06, 0.08, 0.14)
		sky_mat.ground_horizon_color = Color(0.04, 0.05, 0.08)

		# Tungi tuman va Volumetric Fog
		env.fog_light_color = Color(0.08, 0.1, 0.16)
		env.fog_density = 0.004
		if env.volumetric_fog_enabled:
			env.volumetric_fog_albedo = Color(0.06, 0.08, 0.14)
			env.volumetric_fog_density = 0.012
			sun.light_volumetric_fog_energy = 0.3
