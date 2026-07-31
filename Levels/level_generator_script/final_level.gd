extends ArenaLevel

# Boss room. The boss summons escorts on its own timer, and both the escort size
# and the summon rate ramp up as its health drops.

const SPIKE_RESERVE := 5
const BOSS_START_HEALTH := 500

# boss_health floor -> [min summon delay, max summon delay, extra escorts]
const BOSS_PHASES := [
	[400, 15.0, 20.0, 2],
	[300, 10.0, 15.0, 4],
	[200, 7.5, 12.5, 6],
	[100, 5.0, 10.0, 8],
	[1, 3.0, 8.0, 10],
]

@onready var boss_spawn: Marker2D = $boss_spawn
@onready var boss_enemy_spawner: Timer = $boss_enemy_spawner

var boss
var spike_markers: Array = []
var spawn_increaser := 2

func _ready() -> void:
	level_number = 22
	theme_track = "final"
	wave_sizes = [10, 8, 2, 4]
	is_final_level = true
	super._ready()

	spike_markers = collect_markers("spikes")
	enemy_markers = collect_markers("enemy_spawn")

	spawn_boss()
	$spikes_timer.start()

func _process(delta: float) -> void:
	super._process(delta)
	if PlayerData.player_is_dead:
		PlayerData.boss_health = BOSS_START_HEALTH

func spawn_boss() -> void:
	boss = enemy5_scene.instantiate()
	boss.position = boss_spawn.position
	add_child(boss)

# Phase lookup used to live in _process, which meant re-rolling the summon timer
# 60 times a second. It also opened with a stray `if boss_health >= 400` before
# starting a fresh `if/elif` chain at >= 300, so at full health both branches ran
# and the >= 400 phase was overwritten on the same frame it was chosen.
func apply_boss_phase() -> void:
	if PlayerData.boss_health <= 0:
		boss_enemy_spawner.paused = true
		return
	for phase in BOSS_PHASES:
		if PlayerData.boss_health >= phase[0]:
			boss_enemy_spawner.wait_time = randf_range(phase[1], phase[2])
			spawn_increaser = phase[3]
			return

func _on_spikes_timer_timeout() -> void:
	spawn_random_spike(spike_markers, SPIKE_RESERVE)

func _on_boss_enemy_spawner_timeout() -> void:
	apply_boss_phase()
	if PlayerData.boss_health <= 0:
		return
	summon_escorts(enemy1_scene, 4 + spawn_increaser)
	summon_escorts(enemy2_scene, 3 + spawn_increaser)
	summon_escorts(enemy3_scene, 1 + spawn_increaser)
	summon_escorts(enemy4_scene, 2 + spawn_increaser)

func summon_escorts(scene: PackedScene, count: int) -> void:
	for i in count:
		if _live_enemies >= max_live_enemies:
			return
		var enemy := scene.instantiate() as Node2D
		enemy.position = boss.position + Vector2(randi_range(-64, 64), randi_range(-64, 64))
		_live_enemies += 1
		enemy.tree_exited.connect(_on_enemy_freed)
		add_child(enemy)
