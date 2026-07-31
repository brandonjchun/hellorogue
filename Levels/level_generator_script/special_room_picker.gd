extends RefCounted

class_name SpecialRoomPicker

# Chooses which of the walker's stamps are usable as discrete special rooms.
#
# WalkerRoom.rooms is not a list of distinct spaces. place_room() fires once at
# the start and again at every direction change -- every 7 steps -- with sizes
# from 1x1 up to 10x10, all stamped along a path that doubles back on itself.
# Most entries therefore overlap their neighbours heavily and a good number are
# swallowed whole by a larger stamp laid down moments later.
#
# Picking at random from that list gets you three descriptions of the same
# physical space, or a 2x1 "room" with nowhere to put anything. This filters it
# down to stamps that are big enough to read as rooms, far enough apart to be
# separate spaces, and actually carved rather than clipped away by the borders.

# A stamp has to be at least this many tiles on both axes to qualify. Below 5x5
# there is no room around the contents to fight in, and a sealed ambush becomes
# a corridor the player cannot dodge inside.
const MIN_ROOM_SIZE := 5

# Tiles of clearance required between chosen rooms, and between a chosen room
# and anything excluded. Without it two stamps that merely fail to overlap still
# read as one lumpy space.
const SEPARATION := 2

# The tile-space footprint a stamp actually carved.
#
# Mirrors WalkerRoom.place_room(): the stamp is centred on room.position and its
# top-left corner is floored, so this has to floor identically or the rect
# drifts half a tile off the cells that were really carved.
static func tile_rect(room: Dictionary) -> Rect2:
	return Rect2((room.position - room.size / 2).floor(), room.size)

# Whether the stamp survived contact with the borders.
#
# place_room() skips any cell outside `borders`, so a stamp near the edge of the
# playfield is carved only in part -- the rest is still solid rock. Testing the
# centre and the four corners is enough to tell a whole room from a clipped one,
# and every test is an O(1) hit on the walker's lookup Dictionary rather than a
# scan of the carved-cell array.
static func is_fully_carved(rect: Rect2, floor_lookup: Dictionary) -> bool:
	var far := rect.position + rect.size - Vector2.ONE
	var probes := [
		rect.get_center().floor(),
		rect.position,
		Vector2(far.x, rect.position.y),
		Vector2(rect.position.x, far.y),
		far,
	]
	for cell in probes:
		if not floor_lookup.has(cell):
			return false
	return true

# Returns up to `count` well-separated rooms, in no particular order.
#
# Returning fewer is a normal outcome, not a failure: a walk that happened to
# turn often in a small area genuinely has no three large discrete rooms in it.
# There is deliberately no fallback to arbitrary floor cells -- a "special room"
# placed on open floor has no walls, so an ambush would seal nothing and a
# treasure pile would just be loose pickups in a corridor.
static func select(rooms: Array, excluded: Array, count: int,
		floor_lookup: Dictionary, min_size := MIN_ROOM_SIZE) -> Array:
	var candidates: Array = []
	for room in rooms:
		if room.size.x < min_size or room.size.y < min_size:
			continue
		var rect: Rect2 = tile_rect(room)
		if not is_fully_carved(rect, floor_lookup):
			continue
		# Grown once here so the same margin serves both tests below; growing
		# both sides of a comparison would silently double the gap.
		if _touches_any(rect.grow(SEPARATION), excluded):
			continue
		candidates.append(room)

	candidates.shuffle()

	var chosen: Array = []
	var taken_rects: Array = []
	for room in candidates:
		if chosen.size() >= count:
			break
		var padded: Rect2 = tile_rect(room).grow(SEPARATION)
		if _touches_any(padded, taken_rects):
			continue
		chosen.append(room)
		taken_rects.append(tile_rect(room))
	return chosen

static func _touches_any(rect: Rect2, others: Array) -> bool:
	for other in others:
		if rect.intersects(other):
			return true
	return false
