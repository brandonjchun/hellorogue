extends ArenaLevel

# First intermission: a spike arena. Spikes creep across the floor on a timer
# while enemy waves spawn, so the safe standing room shrinks over time.

# Markers left unconverted, so the room never fills completely.
const SPIKE_RESERVE := 100

var spike_markers: Array = []

func _ready() -> void:
	level_number = 19
	theme_track = "grand"
	wave_sizes = [8, 6, 2, 4]
	super._ready()

	# Both lists come from the same 320 Marker2D children. They used to be two
	# separate hand-typed 300-element literals -- 940 lines of this file.
	spike_markers = collect_markers("spikes")
	enemy_markers = spike_markers.duplicate()

	$spikes_timer.start()

func _on_spikes_timer_timeout() -> void:
	spawn_random_spike(spike_markers, SPIKE_RESERVE)
