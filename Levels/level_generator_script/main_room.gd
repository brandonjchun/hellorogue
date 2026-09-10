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

# Difficulty tier: one per three floors, counting from zero on level 1.
#
# There used to be three different formulas for this in this file -- borders and
# walk length off floor((levels - 1) / 3), music off int(levels / 3.0), and the
# enemy roster off raw `levels` -- so level 3 was simultaneously size-tier 0,
# music-tier 1 and enemy-tier 1. The roster gates stay on raw `levels` because
# that is what reads at the call site ("enemy 3 arrives at level 12"); the two
# that are genuinely per-tier now share this.
static func tier(level: int) -> int:
	return int(floor((level - 1) / 3.0))

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

# The eight neighbours a tile's appearance depends on, as the peering bits a
# TileData exposes them under and as the matching coordinate offsets. The two
# arrays are index-paired and must stay that way. y+ is down.
const NEIGHBOUR_BITS := [
	TileSet.CELL_NEIGHBOR_RIGHT_SIDE, TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
	TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
	TileSet.CELL_NEIGHBOR_LEFT_SIDE, TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER,
	TileSet.CELL_NEIGHBOR_TOP_SIDE, TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
]
const NEIGHBOUR_OFFSETS := [
	Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1),
	Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
]

# neighbourhood_key() for a cell with the wall terrain on all eight sides -- the
# interior of the map. Eight base-8 digits of 1, which is (8**8 - 1) / 7;
# GDScript has no octal literal to write it more plainly.
const ALL_SOLID := 2396745

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

# Ceiling on roaming enemies for one floor.
#
# The spawn counts are open-ended in `levels`: at level 18 the passes ask for up
# to 90 + 72 + 2x36 + 2x54 enemies, every one of them a CharacterBody2D running
# move_and_slide() from _process. ArenaLevel has had max_live_enemies since the
# wave-spawn fix landed; the procedural floors never got the same treatment.
# Hazards are not charged against this -- see spawn_enemies().
const MAX_FLOOR_ENEMIES := 160

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
# Tile lookup table for the tile set in use, built once per floor by paint_walls.
var _patterns := {}

var player_spawn_cell := Vector2.ZERO
var exit_room := {}

# Tile-space footprints of the special rooms, so the roaming passes can be kept
# out of them. Roaming enemies used to be able to spawn inside a sealed ambush:
# they are not registered with it, so they do not hold the door shut, but the
# player gets locked in with more than the room was built to hold.
var reserved_rects: Array[Rect2] = []

var _enemies_spawned := 0

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
	# Cleared here rather than trusting whatever set it.
	#
	# The only writer that ever cleared this was reset_run(), and the death path
	# calls that and then immediately re-asserts the flag so the outgoing level
	# can pick the restart scene. Nothing put it back down afterwards, so every
	# floor loaded after a death ran with player_is_dead still true: GUI._process
	# reads it to pause the floor clock, and player.target_mouse() returns early
	# on it, so the clock never ran and the gun never aimed again.
	PlayerData.player_is_dead = false
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

	PlayerData.sound_selecter = clampi(tier(PlayerData.levels), 0, LEVEL_THEMES.size() - 1)
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
	# Annotated rather than inferred: borders_growth_per_tier is an untyped
	# @export, so `:=` here is a hard parse error in 4.2 and the whole script
	# fails to load.
	var growth: float = borders_growth_per_tier * tier(PlayerData.levels)
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

	var floor_tier := tier(PlayerData.levels)
	var start := Vector2(3 + floor_tier, 5 + floor_tier)
	if not borders.has_point(start):
		start = borders.position + Vector2.ONE

	walker = WalkerRoom.new(start, borders)
	map = walker.walk(600 + 900 * floor_tier)
	floor_lookup = walker.get_floor_lookup()

	# Annotated rather than inferred: generate_level takes `tilemap` untyped, so
	# get_used_rect() reads as Variant here and `:=` is a hard parse error.
	var authored_rect: Rect2i = tilemap.get_used_rect()
	var all_cells: Array = tilemap.get_used_cells(ground_layer)
	tilemap.clear()

	# `map` is an Array. Testing membership with map.has() scanned it linearly
	# for every authored cell -- roughly 88k cells x ~14k entries, which is
	# where the first multi-second freeze on level load came from. The walker now
	# hands back a Dictionary so this is a hash lookup instead.
	var solid := {}
	for tile in all_cells:
		if not floor_lookup.has(Vector2(tile.x, tile.y)):
			solid[tile] = true

	paint_walls(tilemap, solid, authored_rect)
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

# Lays the solid rock back down, terrain-matching only the cells that can show.
#
# set_cells_terrain_connect costs roughly 100us per cell, and the authored block
# is ~88k cells, so matching all of them was 8.9 of the 9 seconds every floor
# load used to stall for. It does not need to: a solid cell whose eight
# neighbours are all solid can only ever resolve to the one fully-surrounded
# tile, whatever the rest of the map does. 87,480 of the 87,743 authored solid
# cells were exactly that tile.
#
# So only two sets need matching -- the rock that touches carved floor, and the
# outer edge of the block, which borders nothing. Everything between them is
# filled directly. That is a few thousand matched cells instead of eighty-eight
# thousand, for a tilemap that comes out identical.
func paint_walls(tilemap: TileMap, solid: Dictionary, authored_rect: Rect2i) -> void:
	var frontier := {}

	# Rock that borders open floor, found by growing out from the carved cells.
	# Walking the carved set is what keeps this cheap: there are a few thousand
	# of those against ~88k solid cells, and only they can create an edge.
	for cell in floor_lookup:
		var carved := Vector2i(cell)
		for offset in NEIGHBOUR_OFFSETS:
			var neighbour: Vector2i = carved + offset
			if solid.has(neighbour):
				frontier[neighbour] = true

	var patterns := terrain_patterns(tilemap.tile_set)
	var fill: Array = patterns.get(ALL_SOLID, [])
	# An empty or unrecognised tile set. Match everything rather than painting
	# the map with nothing.
	var can_fill := not fill.is_empty()
	_patterns = patterns
	# The common case is one candidate, and picking at random per cell over ~85k
	# cells is not free, so that case skips the roll entirely.
	var only: Array = fill[0] if can_fill else []

	var low := authored_rect.position
	var high := authored_rect.position + authored_rect.size - Vector2i.ONE
	for cell in solid:
		# The block edge has no neighbours outside it, so its tiles are edge
		# tiles and it has to be matched like the carved frontier.
		if cell.x <= low.x or cell.x >= high.x or cell.y <= low.y or cell.y >= high.y:
			frontier[cell] = true
		elif not can_fill:
			frontier[cell] = true
		elif not frontier.has(cell):
			var tile: Array = only if fill.size() == 1 else fill.pick_random()
			tilemap.set_cell(ground_layer, cell, tile[0], tile[1], tile[2])

	match_frontier(tilemap, solid, frontier)

# Gives every frontier cell the tile that actually fits it.
#
# This replaces set_cells_terrain_connect for the frontier. That call was still
# 271ms for 1,587 cells -- 171us each, worse per cell than when it was handed all
# 88k -- because it expands the cells it is given with all of their neighbours and
# then constraint-solves that whole scattered region.
#
# None of that search is needed. Which tile a wall cell wants is a pure function
# of the eight cells around it, so it is a table lookup. Dropping the solver is
# also what makes the tiling exact rather than approximate: the propagation
# between neighbouring decisions is precisely what used to push compromise tiles
# inward across rock that plainly wanted the surrounded tile.
func match_frontier(tilemap: TileMap, solid: Dictionary, frontier: Dictionary) -> void:
	if _patterns.is_empty():
		# Unrecognised tile set. Fall back to the engine matcher, slow but not our
		# problem to second-guess.
		tilemap.set_cells_terrain_connect(
			ground_layer, frontier.keys(), ground_layer, ground_layer, false)
		return

	for cell in frontier:
		var candidates: Array = _patterns.get(neighbourhood_key(cell, solid), [])
		if candidates.is_empty():
			# The tile set has nothing for this shape -- a one-cell spur, a
			# diagonal pinch. It renders 48 of the 256 possible neighbourhoods, so
			# a few hundred cells a floor land here and take the closest thing.
			candidates = closest_patterns(cell, solid)
			if candidates.is_empty():
				continue
		var tile: Array = candidates[0] if candidates.size() == 1 else candidates.pick_random()
		tilemap.set_cell(ground_layer, cell, tile[0], tile[1], tile[2])

# The eight neighbours of `cell` encoded as one integer, in NEIGHBOUR_BITS order.
#
# Each neighbour contributes its terrain index plus one, so empty (-1) encodes as
# 0 and the wall terrain as 1. Base 8 leaves room for a tile set with several
# terrains without the digits colliding.
func neighbourhood_key(cell: Vector2i, solid: Dictionary) -> int:
	var key := 0
	for offset in NEIGHBOUR_OFFSETS:
		key = key * 8 + (1 if solid.has(cell + offset) else 0)
	return key

# The tiles matching the most of a cell's eight neighbours, for the shapes the
# tile set cannot render exactly. Scanning the whole table is fine: there are 48
# entries and only a few hundred cells a floor ever get here.
func closest_patterns(cell: Vector2i, solid: Dictionary) -> Array:
	var wanted: Array[int] = []
	for offset in NEIGHBOUR_OFFSETS:
		wanted.append(1 if solid.has(cell + offset) else 0)

	var best: Array = []
	var best_score := -1
	for key in _patterns:
		var score := 0
		var digits: int = key
		# Walk the digits back out, least significant first, so compare from the
		# end of `wanted`.
		for i in range(NEIGHBOUR_OFFSETS.size() - 1, -1, -1):
			if digits % 8 == wanted[i]:
				score += 1
			digits /= 8
		if score > best_score:
			best_score = score
			best = _patterns[key]
	return best

# Every tile in the tile set, grouped by the exact neighbourhood it fits.
#
# Keys are neighbourhood_key() values; values are lists of
# [source_id, atlas_coords, alternative_tile]. Lists rather than single tiles
# because a tile set usually offers several interchangeable tiles per shape --
# that is its decorative variation, and picking among them at random is what the
# engine matcher does too.
func terrain_patterns(tile_set: TileSet) -> Dictionary:
	var by_pattern := {}
	if tile_set == null:
		return by_pattern
	for i in tile_set.get_source_count():
		var source_id := tile_set.get_source_id(i)
		var source := tile_set.get_source(source_id) as TileSetAtlasSource
		if source == null:
			continue
		for t in source.get_tiles_count():
			var coords := source.get_tile_id(t)
			for a in source.get_alternative_tiles_count(coords):
				var alt := source.get_alternative_tile_id(coords, a)
				var data := source.get_tile_data(coords, alt)
				if data == null or data.terrain != ground_layer:
					continue
				var key := 0
				for bit in NEIGHBOUR_BITS:
					key = key * 8 + (data.get_terrain_peering_bit(bit) + 1)
				if not by_pattern.has(key):
					by_pattern[key] = []
				by_pattern[key].append([source_id, coords, alt])
	return by_pattern

# Every tile that terrain matching could pick for a cell surrounded on all eight
# sides, as [source_id, atlas_coords, alternative_tile] triples.
#
# Asked of the tile set rather than hardcoded, because the three visual themes
# swap tile_set wholesale and the same atlas coordinate means something different
# in each. A tile qualifies when it is in the wall terrain and all eight of its
# peering bits are that terrain too -- which is exactly the constraint set an
# interior cell produces.
#
# There is usually one, but the mid-run "mix" theme is two atlas sources in one
# tile set and has two: 1:(1,1) and 2:(1,1). Terrain matching picks among equal
# candidates at random, so the rock interior there is a blend of both textures.
# Returning all of them is what keeps that blend instead of flattening the
# interior to whichever one happened to be found first.
func surrounded_tiles(tile_set: TileSet) -> Array:
	return terrain_patterns(tile_set).get(ALL_SOLID, [])

# Picks a carved floor cell and converts it to world space.
# The old call was `map.pick_random() * borders.position * TILE_SIZE`, which only
# behaved because borders.position happened to be (1, 1) -- any other origin
# would have scaled every spawn by it.
func random_floor_position() -> Vector2:
	return map.pick_random() * TILE_SIZE

# A carved cell that is not inside a special room.
#
# Falls back to an unfiltered pick after ATTEMPTS tries rather than looping until
# it finds one: on a small floor whose rooms happen to cover much of the carved
# space an unbounded retry is a hang, and one enemy in the wrong room is a much
# smaller problem than a frozen level load.
const PLACEMENT_ATTEMPTS := 12

func random_open_position() -> Vector2:
	if reserved_rects.is_empty():
		return random_floor_position()
	for _i in PLACEMENT_ATTEMPTS:
		var cell: Vector2 = map.pick_random()
		var clear := true
		for rect in reserved_rects:
			if rect.has_point(cell):
				clear = false
				break
		if clear:
			return cell * TILE_SIZE
	return random_floor_position()

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
		var room: Dictionary = chosen[i]
		# Grown by one so a roaming enemy cannot spawn flush against the outside
		# of an ambush wall and end up inside it when the barrier goes up.
		reserved_rects.append(SpecialRoomPicker.tile_rect(room).grow(1.0))
		builders[i].call(room)

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
	# Only enemies are budgeted. The spike passes come through with cullable
	# false, and a floor that quietly stopped laying hazards once the enemy count
	# filled up would be a difficulty cliff nothing on screen explains.
	if cullable:
		count = mini(count, maxi(0, MAX_FLOOR_ENEMIES - _enemies_spawned))
		_enemies_spawned += count
	for i in range(count):
		var enemy = scene.instantiate()
		enemy.position = random_open_position() if cullable else random_floor_position()
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

	# A full reset, not just the level counter.
	#
	# This used to set `levels = 1` and nothing else, so health, ammo, the bank,
	# the purchased bank_cap and every pending one-floor flag survived the clock
	# running out. Since the shop's currency *is* banked seconds, that made
	# timing out the cheapest move in the game: push to a high tier, let the
	# clock go, and start again at level 1 with the whole bank and an expanded
	# vault intact.
	PlayerData.reset_run()
	PlayerData.toggle_loading_screen = true

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
