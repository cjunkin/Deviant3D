extends WorldEnvironment

export (NodePath) var Sunlight
const bloom_amt := .05

func _ready() -> void:
	var all_off := true
	var sun : DirectionalLight = get_node(Sunlight)
	print(G.shadows)
	match G.shadows:
		G.OFF:
			sun.shadow_enabled = false
		G.LOW:
#			sun.shadow_enabled = false
			sun.directional_shadow_mode = DirectionalLight.SHADOW_ORTHOGONAL
			all_off = false
		G.MED:
			sun.directional_shadow_mode = DirectionalLight.SHADOW_PARALLEL_2_SPLITS
			all_off = false
		G.HIGH:
			sun.directional_shadow_mode = DirectionalLight.SHADOW_PARALLEL_4_SPLITS
			all_off = false

	match G.ssao:
		G.OFF:
			environment.ssao_enabled = false
		G.LOW:
			environment.ssao_enabled = false
		G.MED:
			environment.ssao_quality = Environment.SSAO_QUALITY_LOW
		G.HIGH:
			environment.ssao_quality = Environment.SSAO_QUALITY_MEDIUM

	# Enable glow
	environment.glow_enabled = G.glow != G.OFF
	# If glow is enabled, turn all_off to false
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
	
	# Only turn off adjustments if set to potato
	if !all_off:
		environment.adjustment_enabled = true
