class_name Game
extends Level

onready var BossHP := $HUD/BossStats/BossHP
var tween := Tween.new()

func _ready():
	add_child(tween)
	
	# Enemies
#	enemies.resize(num_enemies)
#	var enemy_s := load(enemy_path)
#	for i in range(num_enemies):
#		var e : Enemy = enemy_s.instance()
#		e.set_network_master(1)
#		enemies.append(e)
#		e.name = G.ENEMY + str(i)
		
#	spawn_bull(0)
#	spawn_arrowhead()
#	spawn_arrowhead()
	

	# If we pressed Host
	if is_network_master():
		
		# Generate random asteroids
		randomize()
		G.TERRAIN_SEED = randi() % 2048
		gen_asteroids(G.TERRAIN_SEED)

		get_node(enemy_spawn_time).start(spawn_time)
		
		# Land
		$Land.gen_terrain(G.TERRAIN_SEED)
		
		# Spawn worm boss
		var worm: Worm = load(worm_path).instance()
		add_child(worm)
		worm.Head.translation = Vector3(0, 360, -850)
		worm.Head.rotation.y = -PI
		worm.set_target(players[0]) # FIXME SYNC UP PROPERLY WORM
		bosses.append(worm)
		worm.set_network_master(get_tree().get_network_unique_id())
		BossHP.max_value = worm.Head.hp
	# Else send a network request to get host's data
	else:
		request_current_data()
	G._on_ViewSlider_value_changed(G.ViewSlider.value)

func update_boss_hp(hp: int) -> void:
#	BossHP.value = hp
	tween.interpolate_property(BossHP, "value", BossHP.value, hp, .25, Tween.TRANS_CIRC)
	tween.start()

func hide_boss_stats() -> void:
	$HUD/BossStats.hide()
	
#func spawn_bull(num : int) -> void:
#	var bull_s := load("res://scn/Actor/Enemy/Bull.tscn")
#	var b : Bull = bull_s.instance()
#	b.set_network_master(1)
#	enemies.append(b)
#	if num == 0:
#		b.speed = 0
#		b.translation = Vector3(0, 50, 110)
#	else:
#		b.translation = Vector3(0, 50, 100)
#	b.name = G.ENEMY + str(num_enemies)
#	add_child(b)
#	b.set_target(G.current_player)
	
func spawn_arrowhead() -> void:
	var arrow_s := load("res://scn/Actor/Enemy/arrow/arrow.tscn")
	var a : Arrow = arrow_s.instance()
	a.translation = Vector3(0, 100, 0)
	a.set_network_master(1)
	enemies.append(a)
	num_enemies += 1
	a.name = G.ENEMY + str(num_enemies)
	
#	add_child(a)
#	a.set_target(G.current_player)
	
