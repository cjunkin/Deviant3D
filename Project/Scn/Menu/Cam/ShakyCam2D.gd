extends Camera2D

export var hori := .4
export var vert := .8
export (float) var magnitude : float = 3
export (float) var duration : float = .3
export (float, EASE) var DAMP_EASING : float = 1

func _ready() -> void:
	$Duration.wait_time = duration
	set_physics_process(false)

func _on_Duration_timeout() -> void:
	set_physics_process(false)
	self.offset = Vector2.ZERO

func startShake(mag: float = magnitude, dur := duration, easing := DAMP_EASING) -> void:
	set_physics_process(true)
	self.magnitude = mag
	self.duration = dur
	self.DAMP_EASING = easing
	$Duration.start()

func _physics_process(_delta: float) -> void:
	var damping = ease($Duration.time_left / $Duration.wait_time, DAMP_EASING)
	self.offset = Vector2(
		rand_range(-magnitude, magnitude) * damping,
		rand_range(-magnitude, magnitude) * damping)

func _input(event: InputEvent) -> void:
	var mp = get_local_mouse_position()
	position = lerp(position, Vector2(mp.x * hori, mp.y * vert), .01)
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.is_pressed():
		startShake()
		get_parent().ClickAnim.play("Click") # TODO: make this more general


