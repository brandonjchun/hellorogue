extends ArenaLevel

# Third intermission: red spikes are placed on every spawner marker up front, so
# the whole floor is hazardous and the fight happens in the gaps between them.

const OPENING_PACK := 20

func _ready() -> void:
	level_number = 21
	theme_track = "skytowersummit"
	wave_sizes = [12, 10, 6, 8]
	super._ready()

	enemy_markers = collect_markers("enemy_spawner")

	place_redspikes()
	spawn_opening_pack()

func place_redspikes() -> void:
	# Was 35 copy-pasted instantiate/position/add_child triplets.
	for marker in enemy_markers:
		var spikes := redspikes_scene.instantiate() as Node2D
		spikes.position = marker.position
		add_child(spikes)

func spawn_opening_pack() -> void:
	# Stacked on the exit, same as the previous intermission. The original ran
	# add_child three times per instance; only the first did anything.
	for i in OPENING_PACK:
		var enemy := enemy_scene_for(randi_range(0, 3)).instantiate() as Node2D
		enemy.position = exit.position
		add_child(enemy)
