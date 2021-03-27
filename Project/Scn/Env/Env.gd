extends WorldEnvironment

export (NodePath) var Sunlight
const bloom_amt := .05

func _ready() -> void:
	var all_off := true
	var sun : DirectionalLight = get_node(Sunlight)

	match G.shadows:
		G.OFF:
			sun.shadow_enabled = false
		G.LOW:
			sun.shadow_enabled = false
#			sun.directional_shadow_mode = DirectionalLight.SHADOW_ORTHOGONAL
			all_off = false
		G.MED:
			sun.directional_shadow_mode = DirectionalLight.SHADOW_PARALLEL_2_SPLITS
			all_off = false
		G.HIGH:
			sun.directional_shadow_mode = DirectionalLight.SHADOW_PARALLEL_4_SPLITS
			all_off = false

	environment.glow_enabled = G.glow != G.OFF
	all_off = all_off and !environment.glow_enabled

	match G.bloom:
		G.LOW:
			environment.glow_bloom = 0
			all_off = false
		G.MED:
			environment.glow_bloom = bloom_amt
			environment.glow_bicubic_upscale = false
			all_off = false
		G.HIGH:
			environment.glow_bloom = bloom_amt
			environment.glow_bicubic_upscale = true
			all_off = false
	
	if !all_off:
		environment.adjustment_enabled = true
