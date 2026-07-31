extends Node2D

@onready var player_scene = preload("res://Entities/Scenes/Player/player.tscn")
@onready var exit_scene = preload("res://interactables/scenes/exit.tscn")
@onready var enemy1_scene = preload("res://Entities/Scenes/Enemies/enemy_1.tscn")
@onready var enemy2_scene = preload("res://Entities/Scenes/Enemies/enemy_2.tscn")
@onready var enemy3_scene = preload("res://Entities/Scenes/Enemies/enemy_3.tscn")
@onready var enemy4_scene = preload("res://Entities/Scenes/Enemies/enemy_4.tscn")
@onready var enemy5_scene = preload("res://Entities/Scenes/Enemies/enemy_5.tscn")
@onready var silverspikes_scene = preload("res://interactables/scenes/dead_area.tscn")
@onready var redspikes_scene = preload("res://interactables/scenes/redspikes.tscn")
@onready var ammo_scene = preload("res://interactables/scenes/ammo_1.tscn")
@onready var health_scene = preload("res://interactables/scenes/health_1.tscn")
@onready var shrine_scene = preload("res://interactables/scenes/shrine.tscn")
@onready var shop_scene = preload("res://Menu/shop_menu.tscn")
@onready var main_level = $"."
@onready var gui = $GUI

var lev = PlayerData.levels - 1
@onready var pause_menu_canvas = $pause_menu
@onready var pause_menu = $pause_menu/PauseMenu
@onready var main_mouse_icon = $pause_menu/main_mouse_icon

@onready var loading_screen_canvas = $loading_screen_canvas
@onready var loading_screen = $loading_screen_canvas/loading_screen
@onready var animation = $loading_screen_canvas/loading_screen/animation
@onready var loading_anim = $loading_screen_canvas/loading_screen/anim
@onready var loading_anim2 = $loading_screen_canvas/loading_screen/loading

@onready var tilemap_water = $TileMap3
@onready var tilemap_mix = $TileMap
@onready var tilemap_hell = $TileMap2
@onready var ground = $ground
@onready var ground2 = $ground2
@onready var ground3 = $ground3

const TILE_SIZE := 16

# Base playfield, and how much it grows per 3-level difficulty tier.
@export var base_borders := Rect2(1, 1, 200, 100)
@export var borders_growth_per_tier := 40

# Cells of solid rock kept between the playfield and the edge of the authored
# tile block. Without this the walker can carve right up to the edge and leave
# an opening the player can walk out through.
const WALL_MARGIN := 2

# Music tier -> ThemePlayer track name. Index is PlayerData.sound_selecter.
const LEVEL_THEMES := ["makuhita", "silentchasm", "steel", "lapis", "blazepeak",
	"sinister"]

var borders: Rect2
var walker
var map
var floor_lookup := {}
var ground_layer = 0
var change_scenes_once = 0
var loading_screen_timeout = false

# How much of a wave Culling Order leaves standing.
const CULL_MULTIPLIER := 0.7

# Special rooms to try for. Fewer are placed when the walk did not produce
# enough large, well-separated stamps -- see SpecialRoomPicker.
const SPECIAL_ROOM_TARGET := 3
# Pickups in a treasure cache, and how far out from the room's centre they ring.
const TREASURE_ITEMS := 6
const TREASURE_RADIUS := 26.0
# Ambush party size at level 1, before the per-tier growth.
const AMBUSH_BASE := 4

var shop: ShopMenu
var _time_banked = false

# Captured as they are placed so special rooms can be kept clear of both. The
# spawn cell has to be recorded here because instance_player() pops it off the
# front of `map`, which is the walker's own step_history -- by the time anything
# else asks, step_history.front() is the second cell of the walk, not the spawn.
var player_spawn_cell := Vector2.ZERO
var exit_room := {}

# Called when the node enters the scene tree for the first time.
func _ready():
	# One-floor purchases are consumed the moment their floor loads, so they
	# cannot leak into the floor after it. This has to happen before
	# generate_level(), which reads cull_active while spawning.
	PlayerData.floor_bonus_time = PlayerData.bonus_time_next
	PlayerData.bonus_time_next = 0.0
	PlayerData.cull_active = PlayerData.cull_next
	PlayerData.cull_next = false
	PlayerData.bandolier_active = PlayerData.bandolier_next
	PlayerData.bandolier_next = false
	# Shrines set haste_active directly, mid-floor. Overwriting it here is what
	# stops a boon found on this floor carrying into the next one.
	PlayerData.haste_active = PlayerData.haste_next
	PlayerData.haste_next = false

	$loading_screen_timer.wait_time = randf_range(1.5, 2.5)
	PlayerData.hurt_ready = true
	PlayerData.reached_exit = false
	PlayerData.game_active = true
	# The boss room sets this true and nothing ever cleared it. Because it is a
	# static it survived scene changes, so every procedural level after a boss
	# visit silently ran with boss-room enemy aggression and a 0.1s player
	# invulnerability window.
	PlayerData.final_level = false
	randomize()
	if PlayerData.levels < 6:
		generate_level(tilemap_water)
		ground2.visible = false
	elif PlayerData.levels >= 6 and PlayerData.levels < 12:
		tilemap_water.tile_set = tilemap_mix.tile_set
		generate_level(tilemap_water)
	elif PlayerData.levels >= 12:
		tilemap_water.tile_set = tilemap_hell.tile_set
		generate_level(tilemap_water)

	PlayerData.sound_selecter = clampi(int(PlayerData.levels / 3.0), 0, LEVEL_THEMES.size() - 1)
	# Selecting the track is level-load state, not per-frame state. This used to
	# run a seven-branch play/stop cascade inside _process, 60 times a second.
	ThemePlayer.play_only(LEVEL_THEMES[PlayerData.sound_selecter])

	start_floor_clock($map_timer.wait_time + PlayerData.floor_bonus_time)

	shop = shop_scene.instantiate()
	add_child(shop)
	shop.closed.connect(on_shop_closed)

	pause_menu.exit_pause_menu.connect(on_exit_pause_menu)
	pause_menu.enter_pause_menu.connect(on_enter_pause_menu)

# Both timers are driven from one place because the warning has to track the
# clock: Overclock and Second Wind both change how long the floor runs for, and
# a fixed "wait_time - 10" computed once in _ready would fire at the wrong
# moment -- or, on a 60s Second Wind refill, have fired already.
func start_floor_clock(duration: float) -> void:
	$map_timer.start(duration)
	$time_running_out_timer.start(maxf(1.0, duration - 10.0))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if PlayerData.reached_exit:
		$map_timer.paused = true
		$time_running_out_timer.paused = true
		bank_floor_time()

	if PlayerData.shop_pending:
		PlayerData.shop_pending = false
		# The exit handed the run to us instead of the loading screen, so a shop
		# that declines to open has to hand it back.
		if not shop.open():
			PlayerData.toggle_loading_screen = true

	if PlayerData.reached_exit or PlayerData.toggle_loading_screen:
		PlayerData.hurt_ready = false

	if PlayerData.toggle_loading_screen:
		main_level.visible = false
		gui.visible = false
		pause_menu.visible = false
		if loading_screen_canvas.layer < 4:
			loading_screen_canvas.layer = 4
			loading_screen_canvas.visible = true
			loading_screen.visible = true
			loading_screen.z_index = 10
			animation.z_index = 12
			animation.visible = true
			PlayerData.hurt_ready = false
			loading_anim.play("fly")
			loading_anim2.play("loading")
			$loading_screen_timer.start()

		if change_scenes_once == 0 and loading_screen_timeout:
			$next_level_timer.start()
			change_scenes_once += 1
			PlayerData.toggle_loading_screen = false
			PlayerData.reset_button_hit = false

# The walker must never carve outside the authored block of wall tiles. The
# playfield grew 40 cells per tier while the authored block stayed fixed, so
# from level 15 on the walk ran off the end of it: no wall tiles had ever been
# placed out there, nothing got drawn, and the player could stroll off the map.
func compute_borders(tilemap: TileMap) -> Rect2:
	# Annotated rather than inferred: `lev` derives from the untyped PlayerData.levels,
	# so `:=` here is a hard parse error in 4.2 and the whole script fails to load.
	var growth: float = borders_growth_per_tier * floor(lev / 3.0)
	var desired := Rect2(base_borders.position,
		base_borders.size + Vector2(growth, growth))

	var authored := Rect2(tilemap.get_used_rect()).grow(-WALL_MARGIN)
	var clamped := desired.intersection(authored)

	if clamped.size.x < 1 or clamped.size.y < 1:
		push_error("main_room: tilemap has no usable authored area; using base borders")
		return base_borders
	return clamped

func generate_level(tilemap):
	# get_used_rect() has to be read before clear() wipes the authored block.
	borders = compute_borders(tilemap)

	var start := Vector2(3 + floor(lev / 3.0), 5 + floor(lev / 3.0))
	if not borders.has_point(start):
		start = borders.position + Vector2.ONE

	walker = WalkerRoom.new(start, borders)
	map = walker.walk(int(600 + 900 * floor(lev / 3.0)))
	floor_lookup = walker.get_floor_lookup()

	var all_cells: Array = tilemap.get_used_cells(ground_layer)
	tilemap.clear()

	# `map` is an Array. Testing membership with map.has() scanned it linearly
	# for every authored cell -- roughly 88k cells x ~14k entries, which is
	# where the multi-second freeze on level load came from. The walker now
	# hands back a Dictionary so this is a hash lookup instead.
	var using_cells: Array = []
	for tile in all_cells:
		if not floor_lookup.has(Vector2(tile.x, tile.y)):
			using_cells.append(tile)

	tilemap.set_cells_terrain_connect(ground_layer, using_cells, ground_layer, ground_layer, false)
	# set_cells_terrain_path used to run here as well, over the same cells. It
	# treats its argument as an ordered path, which is meaningless for an
	# unordered cell soup, and it doubled the cost of the most expensive call
	# in level generation.

	instance_player()
	instance_exit()
	instance_special_rooms()
	if PlayerData.levels >= 0:
		instance_enemy1()
	if PlayerData.levels >= 3:
		instance_silverspikes()
		instance_enemy2()
	if PlayerData.levels >= 3 and PlayerData.levels < 6:
		instance_enemy1()
		instance_enemy2()
	if PlayerData.levels >= 6:
		instance_enemy4()
		instance_redspikes()
	if PlayerData.levels >= 9 and PlayerData.levels < 12:
		instance_enemy1()
		instance_enemy2()
	if PlayerData.levels >= 12:
		instance_enemy3()
	if PlayerData.levels >= 15:
		instance_enemy3()
		instance_enemy4()

# Picks a carved floor cell and converts it to world space.
# The old call was `map.pick_random() * borders.position * TILE_SIZE`, which only
# behaved because borders.position happened to be (1, 1) -- any other origin
# would have scaled every spawn by it.
func random_floor_position() -> Vector2:
	return map.pick_random() * TILE_SIZE

func instance_player():
	var player = player_scene.instantiate()
	add_child(player)
	player_spawn_cell = map.pop_front()
	player.position = player_spawn_cell * TILE_SIZE

func instance_exit():
	var exit = exit_scene.instantiate()
	add_child(exit)
	# Read once and kept. get_end_room() does not mutate `rooms` -- it used to
	# pop_back(), which made two calls disagree -- so asking twice would be
	# harmless, but the whole end room is needed below, not just its centre.
	exit_room = walker.get_end_room()
	exit.position = exit_room.position * TILE_SIZE

# --- special rooms ---

# Turns the walker's own room stamps into treasure caches, ambushes and shrines.
#
# Nothing new is carved: these are placed inside spaces the generator already
# made, which is why the picker has to reject stamps that overlap each other. If
# it returns fewer than SPECIAL_ROOM_TARGET, fewer get built -- there is no
# fallback onto open floor, because a room with no walls is not a room.
func instance_special_rooms() -> void:
	var excluded := [
		Rect2(player_spawn_cell, Vector2.ONE),
		SpecialRoomPicker.tile_rect(exit_room),
	]
	var chosen := SpecialRoomPicker.select(
		walker.rooms, excluded, SPECIAL_ROOM_TARGET, floor_lookup)

	# Shuffled so which room becomes which type varies, and so a floor that only
	# fits two specials does not always drop the same one.
	var builders := [build_treasure_room, build_ambush_room, build_shrine_room]
	builders.shuffle()

	for i in chosen.size():
		builders[i].call(chosen[i] as Dictionary)

func room_centre_world(room: Dictionary) -> Vector2:
	return SpecialRoomPicker.tile_rect(room).get_center() * TILE_SIZE

# A ring of pickups that do not expire. Ordinary drops clear themselves after
# five seconds; a cache the player has not found yet must not.
func build_treasure_room(room: Dictionary) -> void:
	var centre := room_centre_world(room)
	for i in TREASURE_ITEMS:
		var scene: PackedScene = health_scene if i % 2 == 0 else ammo_scene
		var pickup = scene.instantiate()
		pickup.despawns = false
		pickup.position = centre + Vector2.RIGHT.rotated(TAU * i / TREASURE_ITEMS) * TREASURE_RADIUS
		add_child(pickup)

# Enemies waiting inside, and a barrier that drops when they are dead.
#
# The party deliberately ignores Culling Order. The room stays shut until it is
# cleared, so thinning it would only make the trap open sooner -- it would read
# as a discount on the set-piece rather than as fewer things to fight. Culling
# thins the roaming population, which is where the player feels it.
func build_ambush_room(room: Dictionary) -> void:
	var rect := SpecialRoomPicker.tile_rect(room)

	var ambush := AmbushRoom.new()
	ambush.position = rect.get_center() * TILE_SIZE
	ambush.setup(rect.size * TILE_SIZE)
	add_child(ambush)

	var party := AMBUSH_BASE + int(PlayerData.levels / 3.0)
	# Inset by one so nobody spawns embedded in the wall the barrier lines up on.
	var inner := rect.grow(-1.0)
	for i in party:
		var enemy = ambush_enemy_scene().instantiate()
		enemy.position = Vector2(
			randf_range(inner.position.x, inner.end.x),
			randf_range(inner.position.y, inner.end.y)) * TILE_SIZE
		add_child(enemy)
		ambush.register_enemy(enemy)

# Mirrors the roster generate_level() draws from at this depth.
func ambush_enemy_scene() -> PackedScene:
	var roster: Array[PackedScene] = [enemy1_scene]
	if PlayerData.levels >= 3:
		roster.append(enemy2_scene)
	if PlayerData.levels >= 6:
		roster.append(enemy4_scene)
	if PlayerData.levels >= 12:
		roster.append(enemy3_scene)
	return roster.pick_random()

func build_shrine_room(room: Dictionary) -> void:
	var shrine = shrine_scene.instantiate()
	shrine.position = room_centre_world(room)
	add_child(shrine)

# `cullable` is false for the spike passes: Culling Order is sold as thinning the
# enemies, and quietly halving the hazards as well would make it strictly better
# than it reads.
func spawn_enemies(scene: PackedScene, count: int, cullable := true) -> void:
	if cullable and PlayerData.cull_active:
		count = maxi(1, int(round(count * CULL_MULTIPLIER)))
	for i in range(count):
		var enemy = scene.instantiate()
		enemy.position = random_floor_position()
		add_child(enemy)

func instance_enemy1():
	spawn_enemies(enemy1_scene, randi_range(maxi(1, PlayerData.levels), maxi(2, PlayerData.levels * 5)))

func instance_enemy2():
	spawn_enemies(enemy2_scene, randi_range(maxi(1, PlayerData.levels), maxi(3, PlayerData.levels * 4)))

func instance_enemy3():
	spawn_enemies(enemy3_scene, randi_range(maxi(1, PlayerData.levels), maxi(5, PlayerData.levels * 2)))

func instance_enemy4():
	spawn_enemies(enemy4_scene, randi_range(maxi(1, PlayerData.levels), maxi(4, PlayerData.levels * 3)))

func instance_enemy5():
	spawn_enemies(enemy5_scene, 1)

func instance_silverspikes():
	spawn_enemies(silverspikes_scene, randi_range(PlayerData.levels, 2 * PlayerData.levels), false)

func instance_redspikes():
	spawn_enemies(redspikes_scene, randi_range(PlayerData.levels, 2 * PlayerData.levels), false)

# Deposits what is left on the clock into the bank.
#
# Bonus seconds bought at the shop are subtracted first. They are pressure
# relief for one floor, not currency: banking them would mean Overclock refunded
# 40s for the 25s it cost, and the only wrong answer would be not buying it.
func bank_floor_time() -> void:
	if _time_banked:
		return
	_time_banked = true
	var earned = maxf(0.0, $map_timer.time_left - PlayerData.floor_bonus_time)
	PlayerData.banked_time = minf(PlayerData.banked_time + earned, PlayerData.bank_cap)

func on_shop_closed() -> void:
	# The exit deliberately did not set this, so the run waits on the shop
	# rather than loading the next floor out from under it.
	PlayerData.toggle_loading_screen = true

func _on_timer_timeout():
	# Second Wind turns the one moment the clock could still end a run into
	# another 60 seconds. Those seconds are booked as bonus time so they cannot
	# be banked -- surviving on the refill should not also pay out.
	if PlayerData.second_wind:
		PlayerData.second_wind = false
		PlayerData.floor_bonus_time += PlayerData.SECOND_WIND_SECONDS
		start_floor_clock(PlayerData.SECOND_WIND_SECONDS)
		return

	PlayerData.toggle_loading_screen = true
	PlayerData.levels = 1
	PlayerData.reached_exit = false

func _on_next_level_timer_timeout():
	main_level.visible = true
	gui.visible = true
	pause_menu.visible = true
	loading_screen_canvas.layer = -2
	loading_screen_canvas.visible = false
	loading_screen.visible = false
	PlayerData.hurt_ready = false
	loading_screen.z_index = -2
	PlayerData.toggle_loading_screen = false
	change_scenes_once = 0

func on_exit_pause_menu():
	pause_menu_canvas.visible = false
	pause_menu.visible = false
	main_mouse_icon.visible = false
	pause_menu_canvas.layer = -4

func on_enter_pause_menu():
	pause_menu_canvas.visible = true
	pause_menu.visible = true
	main_mouse_icon.visible = true
	pause_menu_canvas.layer = 4

func _on_time_running_out_timer_timeout():
	$time_running_out.play()

func _on_loading_screen_timer_timeout():
	loading_screen_timeout = true
	loading_screen.load_next_scene()
