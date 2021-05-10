class_name ShakyCam
extends Camera

export var maxYaw : float = 25.0
export var maxPitch : float = 25.0
export var maxRoll : float = 25.0
export var shakeReduction : float = 1.0

var stress : float = 0.0
var shake : float = 0.0


var n := OpenSimplexNoise.new()
var camera_rotation_reset := Vector3()

func _ready() -> void:
	enable_toon()

func _physics_process(delta: float) -> void:
#	if stress > 0:
#		rotation_degrees = Vector3(randf(), randf(), randf()) * stress * 3
#		stress = clamp(stress - delta, 0.0, 1.0)
	
	if stress == 0.0:
		camera_rotation_reset = rotation_degrees
#		set_physics_process(false)
	rotation_degrees = process_shake(camera_rotation_reset, delta)

func process_shake(angle_center : Vector3, delta : float) -> Vector3:
	shake = stress * stress * delta * 60
	stress = clamp(stress - (shakeReduction * delta), 0.0, 1.0)
	var newRotate = Vector3(
		maxYaw * shake * get_noise(randi(), delta),
		maxPitch * shake * get_noise(randi(), delta + 1.0),
		maxRoll * shake * get_noise(randi(), delta + 2.0)
	)
	return angle_center + newRotate

func get_noise(noise_seed : int, time : float) -> float:
	n.seed = noise_seed
	n.octaves = 4
	n.period = 20.0
	n.persistence = 0.8
	return n.get_noise_1d(time)

func add_stress(amount : float, max_amt := 1.0) -> void:
#	set_physics_process(true)
	stress += amount
	stress = clamp(stress, 0.0, max_amt)

func enable_toon(on := G.toon_shader != G.OFF) -> void:
	$HUD/Shader.visible = on

export (StreamTexture) var laser := preload("res://Gfx/2D/laser.png")
export (StreamTexture) var rocket := preload("res://Gfx/2D/rocket.png")

func set_weapon_txt(weapon: String) -> void:
	match weapon:
		G.LASER:
			$HUD/Margin/Icon.texture = laser
			$HUD/Margin.modulate = Color("bf15ffff")
#			$HUD/Margin/Weapon.text = "Laser"
		G.ROCKET:
			$HUD/Margin/Icon.texture = rocket
			$HUD/Margin.modulate = Color("bfffc20d")
#			$HUD/Margin/Weapon.text = "Rocket"
