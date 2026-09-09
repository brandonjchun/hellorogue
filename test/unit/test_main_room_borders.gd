extends GutTest

# compute_borders() decides how much of the authored tile block the walker is
# allowed to carve. It is the one piece of main_room that can be tested without
# building the whole level: it takes a TileMap and returns a Rect2.
#
# The bug it exists to prevent: the playfield grows 40 cells per difficulty tier
# while the authored block of wall tiles stays fixed, so from level 15 on the
# walk ran off the end of it. No wall tiles had ever been placed out there,
# nothing got drawn, and the player could walk off the map.

const MainRoom := preload("res://Levels/level_generator_script/main_room.gd")
const WALL_MARGIN := 2


func before_each():
	PlayerData.reset_run()


func after_all():
	PlayerData.reset_run()


# A TileMap whose used rect spans (0,0) to (width-1, height-1). Only the two
# corner cells are set -- get_used_rect() is a bounding box, so that is enough
# and it keeps the fixture cheap.
func _tilemap(width: int, height: int) -> TileMap:
	var source := TileSetAtlasSource.new()
	source.texture = ImageTexture.create_from_image(
		Image.create(16, 16, false, Image.FORMAT_RGBA8))
	source.texture_region_size = Vector2i(16, 16)
	source.create_tile(Vector2i.ZERO)

	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(16, 16)
	tile_set.add_source(source, 0)

	var map: TileMap = autofree(TileMap.new())
	map.tile_set = tile_set
	map.set_cell(0, Vector2i.ZERO, 0, Vector2i.ZERO)
	map.set_cell(0, Vector2i(width - 1, height - 1), 0, Vector2i.ZERO)
	return map


# `lev` is read from PlayerData at construction, so the level has to be set
# before the node is made.
func _room(levels: int) -> Node2D:
	PlayerData.levels = levels
	return autofree(MainRoom.new())


func _authored(map: TileMap) -> Rect2:
	return Rect2(map.get_used_rect()).grow(-WALL_MARGIN)


# --- the containment invariant -------------------------------------------

func test_borders_stay_inside_the_authored_block_at_the_first_level():
	var map := _tilemap(300, 200)
	var borders: Rect2 = _room(1).compute_borders(map)
	assert_true(_authored(map).encloses(borders),
		"borders %s escaped the authored area %s" % [borders, _authored(map)])


func test_borders_are_clamped_once_the_playfield_outgrows_the_tiles():
	# Level 16 wants a 400x300 playfield out of a 300x200 block of tiles.
	var map := _tilemap(300, 200)
	var borders: Rect2 = _room(16).compute_borders(map)
	var authored := _authored(map)

	assert_true(authored.encloses(borders),
		"the walker was allowed to carve past the last wall tile")
	assert_true(borders.end.x <= authored.end.x, "borders ran off the right edge")
	assert_true(borders.end.y <= authored.end.y, "borders ran off the bottom edge")


func test_borders_stay_inside_the_authored_block_at_every_level():
	var map := _tilemap(300, 200)
	var authored := _authored(map)
	for levels in range(1, 25):
		var borders: Rect2 = _room(levels).compute_borders(map)
		assert_true(authored.encloses(borders),
			"level %d carved outside the authored area: %s" % [levels, borders])


func test_borders_never_touch_the_outermost_tiles():
	# WALL_MARGIN is what keeps a ring of solid rock between the playfield and
	# the edge of the block.
	var map := _tilemap(300, 200)
	var borders: Rect2 = _room(20).compute_borders(map)
	var used := Rect2(map.get_used_rect())
	assert_true(borders.position.x >= used.position.x + WALL_MARGIN)
	assert_true(borders.position.y >= used.position.y + WALL_MARGIN)
	assert_true(borders.end.x <= used.end.x - WALL_MARGIN)
	assert_true(borders.end.y <= used.end.y - WALL_MARGIN)


# --- usability of the result ---------------------------------------------

func test_the_result_is_always_big_enough_to_walk_in():
	# generate_level() falls back to `borders.position + Vector2.ONE` when its
	# preferred start is out of bounds, and WalkerRoom asserts that its start is
	# inside. A playfield thinner than two cells would trip that assert.
	var map := _tilemap(300, 200)
	for levels in range(1, 25):
		var borders: Rect2 = _room(levels).compute_borders(map)
		assert_true(borders.has_point(borders.position + Vector2.ONE),
			"level %d produced a playfield too thin for the fallback start" % levels)


func test_the_playfield_grows_with_the_difficulty_tier():
	# A block big enough that nothing is clamped, so growth is observable.
	var map := _tilemap(2000, 2000)
	var tier0: Rect2 = _room(1).compute_borders(map)
	var tier1: Rect2 = _room(4).compute_borders(map)
	var tier2: Rect2 = _room(7).compute_borders(map)

	assert_gt(tier1.size.x, tier0.size.x, "the playfield did not grow at tier 1")
	assert_gt(tier2.size.x, tier1.size.x, "the playfield did not grow at tier 2")


func test_the_playfield_does_not_grow_within_a_tier():
	var map := _tilemap(2000, 2000)
	assert_eq(_room(1).compute_borders(map), _room(3).compute_borders(map),
		"levels inside one tier produced different playfields")


# --- degenerate input -----------------------------------------------------

func test_a_tilemap_with_no_usable_area_falls_back_to_the_base_playfield():
	# Smaller than twice the margin, so there is nothing left after grow().
	var map := _tilemap(1, 1)
	var room := _room(1)
	assert_eq(room.compute_borders(map), room.base_borders,
		"a degenerate tilemap did not fall back to the base playfield")


func test_a_tilemap_barely_larger_than_the_margin_still_returns_something_usable():
	var map := _tilemap(10, 10)
	var borders: Rect2 = _room(1).compute_borders(map)
	assert_gt(borders.size.x, 0.0)
	assert_gt(borders.size.y, 0.0)
