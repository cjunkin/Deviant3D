extends WorldEnvironment

export (NodePath) var Sunlight

func _ready():
	var sun : DirectionalLight = get_node(Sunlight)
	match G.shadows:
		G.OFF:
			sun.shadow_enabled = false
		G.LOW:
			sun.directional_shadow_mode = DirectionalLight.SHADOW_ORTHOGONAL
		G.MED:
			sun.directional_shadow_mode = DirectionalLight.SHADOW_PARALLEL_2_SPLITS
		G.HIGH:
			sun.directional_shadow_mode = DirectionalLight.SHADOW_PARALLEL_4_SPLITS

	environment.glow_enabled = G.glow != G.OFF

	match G.bloom:
		G.OFF:
			environment.glow_bloom = 0
		G.LOW:
			environment.glow_bloom = .1
			environment.glow_bicubic_upscale = false
		G.MED:
			environment.glow_bloom = .1
			environment.glow_bicubic_upscale = true
		G.HIGH:
			environment.glow_bloom = .1
			environment.glow_bicubic_upscale = true
