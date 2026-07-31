extends ArenaLevel

# Second intermission: a crowd level. A large pack is placed on the exit at the
# start, then waves keep arriving on the spawner markers.

const SPIKE_RESERVE := 3
const OPENING_PACK := 40

var spike_markers: Array = []

func _ready() -> void:
	level_number = 20
	theme_track = "magma"
	wave_sizes = [10, 8, 4, 6]
	super._ready()

	enemy_markers = collect_markers("enemy_spawner")
	spike_markers = enemy_markers.duplicate()

	spawn_opening_pack()

func spawn_opening_pack() -> void:
	# Deliberately stacked on the exit: the level is about fighting your way to
	# the door, not finding it. The original called add_child twice per instance,
	# which spawned the one enemy and then logged an error for the second call.
	for i in OPENING_PACK:
		var enemy := enemy_scene_for(randi_range(0, 3)).instantiate() as Node2D
		enemy.position = exit.position
		add_child(enemy)

func _on_spikes_timer_timeout() -> void:
	spawn_random_spike(spike_markers, SPIKE_RESERVE)
