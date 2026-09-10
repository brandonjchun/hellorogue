extends GutTest

# The wall painter, against the real authored tile block.
#
# main_room used to hand every solid cell to set_cells_terrain_connect. That call
# costs ~100us per cell and the authored block is ~88k cells, which was 8.9 of
# the 9 seconds every floor load stalled for -- a hard freeze between floors,
# because generation runs in the incoming level's _ready(), after the outgoing
# level's loading screen is already gone.
#
# paint_walls only terrain-matches cells that can show an edge: rock touching
# carved floor, and the outer rim of the block. Everything between is filled with
# the one tile a fully-surrounded cell can resolve to. These tests pin both the
# cost and the correctness, since the whole optimisation rests on that claim
# about surrounded cells.
#
# Needs Sprites/ (tools/stub_assets.py will do) -- pending without it.

const LEVEL_PATH := "res://Levels/main_level.tscn"

# Peering-bit order, paired with the coordinate offsets below. y+ is down.
const BITS := [
	TileSet.CELL_NEIGHBOR_RIGHT_SIDE, TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
	TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
	TileSet.CELL_NEIGHBOR_LEFT_SIDE, TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER,
	TileSet.CELL_NEIGHBOR_TOP_SIDE, TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
]
const OFFSETS := [
	Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1),
	Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
]

# The whole-block match measured 7.4-8.9s; the table lookup measures 53-77ms.
# Loose enough not to fail on slower hardware, tight enough that handing the
# whole block to the engine matcher again fails here rather than shipping.
#
# Reverting only the *matcher* (engine solver on the frontier alone, ~280ms) does
# not trip this on fast hardware -- test_the_tiles_match_the_walls_they_sit_in is
# what catches that, and it catches it on correctness rather than on a stopwatch.
const BUDGET_MS := 1000

# The painter is exact, so the bar is exactness rather than a tolerance.
#
# Every frontier cell gets the tile whose eight peering bits equal its eight real
# neighbours. The only cells that end up with a tile that does not fit are the
# ones the tile set has nothing for -- it renders 48 of the 256 possible
# neighbourhoods -- and those are counted independently below. So the number of
# wrong cells should equal that floor and not exceed it by one.
#
# For reference, the engine matcher lands at 1.6-1.8x the floor on the frontier
# alone and 8-11x when handed the whole block: its propagation between
# neighbouring decisions is what pushes compromise tiles into rock that plainly
# wants the surrounded tile.

var _room: Node2D
var _tilemap: TileMap
var _solid: Dictionary
var _authored: Rect2i


func before_each():
	PlayerData.reset_run()
	_room = null


func after_each():
	if is_instance_valid(_room):
		_room.free()
	PlayerData.reset_run()


# Builds a carved map and paints it, without booting the level: the script is
# attached but _ready() never runs, so this is paint_walls on the real authored
# block and nothing else.
func _paint(level_number := 1) -> bool:
	var packed = load(LEVEL_PATH)
	if packed == null:
		pending("needs Sprites/ -- run tools/stub_assets.py")
		return false
	_room = packed.instantiate()
	_tilemap = _room.get_node("TileMap3")
	_authored = _tilemap.get_used_rect()
	var all_cells := _tilemap.get_used_cells(0)

	# Seeded so the numbers below are reproducible rather than a new map each run.
	seed(20250910 + level_number)
	PlayerData.levels = level_number
	var tier: int = _room.tier(level_number)
	var borders := Rect2(Rect2i(_authored)).grow(-float(_room.WALL_MARGIN)).intersection(
		Rect2(Vector2(1, 1), Vector2(200 + 40 * tier, 100 + 40 * tier)))
	var walker = WalkerRoom.new(borders.position + Vector2.ONE, borders)
	walker.walk(600 + 900 * tier)
	_room.floor_lookup = walker.get_floor_lookup()

	_solid = {}
	for tile in all_cells:
		if not _room.floor_lookup.has(Vector2(tile.x, tile.y)):
			_solid[tile] = true

	_tilemap.clear()
	_room.paint_walls(_tilemap, _solid, _authored)
	return true


# How many painted cells hold a tile that does not expect the terrain its eight
# real neighbours actually have. Every one of those is a visible seam.
func _cells_with_a_wrong_tile() -> int:
	var tile_set := _tilemap.tile_set
	var wrong := 0
	for cell in _solid:
		var source_id: int = _tilemap.get_cell_source_id(0, cell)
		if source_id < 0:
			wrong += 1
			continue
		var source := tile_set.get_source(source_id) as TileSetAtlasSource
		var data := source.get_tile_data(
			_tilemap.get_cell_atlas_coords(0, cell),
			_tilemap.get_cell_alternative_tile(0, cell))
		for i in BITS.size():
			var expected: int = 0 if _solid.has(cell + OFFSETS[i]) else -1
			if data.get_terrain_peering_bit(BITS[i]) != expected:
				wrong += 1
				break
	return wrong


# How many cells have a neighbourhood the tile set cannot render exactly. This is
# the floor: no algorithm gets below it, and it is what the count above is judged
# against.
func _cells_no_tile_could_satisfy() -> int:
	var tile_set := _tilemap.tile_set
	var renderable := {}
	for i in tile_set.get_source_count():
		var source := tile_set.get_source(tile_set.get_source_id(i)) as TileSetAtlasSource
		if source == null:
			continue
		for t in source.get_tiles_count():
			var coords := source.get_tile_id(t)
			for a in source.get_alternative_tiles_count(coords):
				var data := source.get_tile_data(
					coords, source.get_alternative_tile_id(coords, a))
				if data == null or data.terrain != 0:
					continue
				var pattern := []
				for bit in BITS:
					pattern.append(data.get_terrain_peering_bit(bit))
				renderable[str(pattern)] = true

	var impossible := 0
	for cell in _solid:
		var wanted := []
		for offset in OFFSETS:
			wanted.append(0 if _solid.has(cell + offset) else -1)
		if not renderable.has(str(wanted)):
			impossible += 1
	return impossible


func _assert_tiling_is_exact(level_number: int) -> void:
	var wrong := _cells_with_a_wrong_tile()
	var unavoidable := _cells_no_tile_could_satisfy()
	assert_eq(wrong, unavoidable,
		("level %d: %d of %d cells hold a tile that does not match their " +
		"neighbours, but only %d of them have a shape the tile set cannot " +
		"render -- the matcher is approximating where it could be exact") %
		[level_number, wrong, _solid.size(), unavoidable])


# --- the whole point ------------------------------------------------------

func test_painting_a_floor_is_not_a_multi_second_stall():
	var packed = load(LEVEL_PATH)
	if packed == null:
		pending("needs Sprites/ -- run tools/stub_assets.py")
		return
	# Timed on its own so the walk and the authored-cell read are not counted.
	_room = packed.instantiate()
	_tilemap = _room.get_node("TileMap3")
	_authored = _tilemap.get_used_rect()
	var all_cells := _tilemap.get_used_cells(0)
	var walker = WalkerRoom.new(Vector2(3, 5), Rect2(Vector2(1, 1), Vector2(200, 100)))
	walker.walk(600)
	_room.floor_lookup = walker.get_floor_lookup()
	_solid = {}
	for tile in all_cells:
		if not _room.floor_lookup.has(Vector2(tile.x, tile.y)):
			_solid[tile] = true
	_tilemap.clear()

	var started := Time.get_ticks_msec()
	_room.paint_walls(_tilemap, _solid, _authored)
	var elapsed := Time.get_ticks_msec() - started
	assert_lt(elapsed, BUDGET_MS,
		"painting took %dms -- the whole-block terrain match is back" % elapsed)


func test_every_solid_cell_gets_a_tile():
	if not _paint(): return
	assert_eq(_tilemap.get_used_cells(0).size(), _solid.size(),
		"the painted tilemap and the solid set disagree, so the map has holes")


func test_no_carved_cell_was_painted_over():
	if not _paint(): return
	for cell in _room.floor_lookup:
		assert_eq(_tilemap.get_cell_source_id(0, Vector2i(cell)), -1,
			"carved floor at %s was painted solid" % cell)


func test_the_tiles_match_the_walls_they_sit_in():
	if not _paint(): return
	_assert_tiling_is_exact(1)


func test_it_holds_up_on_the_largest_floor():
	# The tier that grows the playfield and the walk the most, so the frontier is
	# at its most convoluted and the solver has the most compromises to make.
	if not _paint(18): return
	assert_eq(_tilemap.get_used_cells(0).size(), _solid.size(),
		"the largest floor came out with holes in it")
	_assert_tiling_is_exact(18)


func test_it_holds_up_mid_run_where_the_theme_is_two_tile_sets():
	if not _paint(12): return
	_assert_tiling_is_exact(12)


# --- the claim the optimisation rests on ----------------------------------

func test_a_fully_surrounded_cell_has_exactly_one_right_tile():
	# If a tile set ever offered two *different* tiles for rock surrounded on all
	# eight sides, filling with one of them would be a choice rather than the
	# answer -- and this would be the test that says so.
	var packed = load(LEVEL_PATH)
	if packed == null:
		pending("needs Sprites/ -- run tools/stub_assets.py")
		return
	_room = packed.instantiate()
	for node_name in ["TileMap3", "TileMap", "TileMap2"]:
		var tilemap: TileMap = _room.get_node(node_name)
		var tiles: Array = _room.surrounded_tiles(tilemap.tile_set)
		assert_gt(tiles.size(), 0,
			"%s has no tile for fully surrounded rock" % node_name)
		# The mid-run "mix" theme is two atlas sources in one tile set, so it
		# legitimately has two -- both are the same picture of solid rock.
		for tile in tiles:
			assert_eq(tile[1], Vector2i(1, 1),
				"%s: surrounded tile at unexpected atlas coords %s" % [node_name, tile[1]])


func test_surrounded_tiles_survives_a_missing_tile_set():
	_room = load(LEVEL_PATH).instantiate() if load(LEVEL_PATH) != null else null
	if _room == null:
		pending("needs Sprites/ -- run tools/stub_assets.py")
		return
	assert_eq(_room.surrounded_tiles(null).size(), 0,
		"a null tile set should yield no fill candidates, not an error")


# --- shapes the tile set has no tile for ----------------------------------

func test_unrenderable_shapes_still_get_a_tile():
	# A one-cell spur or a diagonal pinch has a neighbourhood the tile set cannot
	# render. Those cells must still come out solid -- leaving them empty would be
	# a hole in the wall the player can walk through.
	if not _paint(12): return
	assert_gt(_cells_no_tile_could_satisfy(), 0,
		"this floor has no unrenderable shapes, so the fallback is untested here")
	for cell in _solid:
		assert_gte(_tilemap.get_cell_source_id(0, cell), 0,
			"solid cell %s was left empty" % cell)


func test_the_fallback_picks_the_closest_shape_not_an_arbitrary_one():
	if not _paint(12): return
	var tile_set := _tilemap.tile_set
	# Built once. Annotated rather than inferred: _room is a Node2D, so anything
	# read off it is a Variant and `:=` is a hard parse error here.
	var patterns: Dictionary = _room.terrain_patterns(tile_set)
	var checked := 0
	for cell in _solid:
		var wanted := []
		for offset in OFFSETS:
			wanted.append(0 if _solid.has(cell + offset) else -1)
		# Only look at cells whose exact shape is missing from the tile set.
		if patterns.has(_room.neighbourhood_key(cell, _solid)):
			continue
		var source := tile_set.get_source(
			_tilemap.get_cell_source_id(0, cell)) as TileSetAtlasSource
		var data := source.get_tile_data(
			_tilemap.get_cell_atlas_coords(0, cell),
			_tilemap.get_cell_alternative_tile(0, cell))
		var matched := 0
		for i in BITS.size():
			if data.get_terrain_peering_bit(BITS[i]) == wanted[i]:
				matched += 1
		# Eight bits, no exact tile, so at most seven can match. Anything below
		# half would mean the fallback grabbed something unrelated.
		assert_gte(matched, 4,
			"fallback at %s matched only %d of 8 neighbours" % [cell, matched])
		checked += 1
		if checked >= 40:
			break
	assert_gt(checked, 0, "no unrenderable cells were found to check")
