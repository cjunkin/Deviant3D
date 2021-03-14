extends WorldEnvironment

export (NodePath) var Sunlight

func _ready():
	var sun : DirectionalLight = get_node(Sunlight)
	match G.lighting:
		G.OFF:
			sun.shadow_enabled = false
		G.LOW:
			sun.directional_shadow_mode = DirectionalLight.SHADOW_ORTHOGONAL
		G.MED:
			sun.directional_shadow_mode = DirectionalLight.SHADOW_PARALLEL_2_SPLITS
		G.HIGH:
			sun.directional_shadow_mode = DirectionalLight.SHADOW_PARALLEL_4_SPLITS

	if G.glow != G.OFF:
		environment.glow_enabled = true
