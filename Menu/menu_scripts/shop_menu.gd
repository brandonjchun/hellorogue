extends CanvasLayer

class_name ShopMenu

# The between-floor shop. Currency is banked time: seconds the player did not
# spend on earlier floors. Everything here is paid for by having rushed
# something earlier, which is the whole point -- the clock stops being a leash
# and starts being income.
#
# Items are data. Adding or removing one is a line in ITEMS plus a branch in
# apply(); nothing else in the file knows what any particular item does.

signal closed

const ITEMS := [
	{
		"id": "medkit",
		"name": "MED-KIT",
		"cost": 10.0,
		"desc": "+2 health",
		"repeatable": true,
	},
	{
		"id": "ammo",
		"name": "AMMO CRATE",
		"cost": 10.0,
		"desc": "+15 rounds",
		"repeatable": true,
	},
	{
		"id": "overclock",
		"name": "OVERCLOCK",
		"cost": 25.0,
		"desc": "next floor starts with +40s (cannot be re-banked)",
		"repeatable": true,
	},
	{
		"id": "vault",
		"name": "VAULT EXPANSION",
		"cost": 40.0,
		"desc": "+60s bank capacity, permanent",
		"repeatable": true,
	},
	{
		"id": "cull",
		"name": "CULLING ORDER",
		"cost": 35.0,
		"desc": "next floor spawns 30% fewer enemies",
		"repeatable": false,
	},
	{
		"id": "bandolier",
		"name": "BANDOLIER",
		"cost": 30.0,
		"desc": "next floor: every enemy drop is worth double",
		"repeatable": false,
	},
	{
		"id": "second_wind",
		"name": "SECOND WIND",
		"cost": 60.0,
		"desc": "once: a clock that hits zero refills to 60s instead of ending the run",
		"repeatable": false,
	},
]

const MEDKIT_HEALTH := 2
const AMMO_ROUNDS := 15
const OVERCLOCK_SECONDS := 40.0
const VAULT_SECONDS := 60.0

@onready var bank_label: Label = $Panel/Layout/bank
@onready var item_list: VBoxContainer = $Panel/Layout/items
@onready var leave_button: Button = $Panel/Layout/leave

# Item ids this visit is allowed to sell. Empty means all of them; the
# intermissions pass ["medkit"].
var _allowed: Array = []
var _theme_before := ""

func _ready() -> void:
	visible = false
	leave_button.pressed.connect(close)

# `allowed` restricts the stock for this visit.
#
# Returns false without opening when the player cannot afford anything, which is
# the common case for someone who never rushes a floor. They would get a panel
# every third floor listing only things they cannot have; the BANK readout on
# the HUD is what teaches the mechanic, not this. Callers must handle false by
# continuing to the next floor themselves.
func open(allowed: Array = []) -> bool:
	_allowed = allowed
	if not can_afford_anything():
		return false

	PlayerData.shop_open = true
	PlayerData.game_mouse = false
	get_tree().paused = true

	_theme_before = ThemePlayer.current_theme
	ThemePlayer.play_only("ninetales")

	_build()
	visible = true
	return true

func can_afford_anything() -> bool:
	for item in _stock():
		if not _sold_out(item["id"]) and PlayerData.banked_time >= float(item["cost"]):
			return true
	return false

func close() -> void:
	visible = false
	PlayerData.shop_open = false
	PlayerData.game_mouse = true
	get_tree().paused = false
	ThemePlayer.play_only(_theme_before)
	closed.emit()

# --- stock ---

func _stock() -> Array:
	if _allowed.is_empty():
		return ITEMS
	var filtered: Array = []
	for item in ITEMS:
		if _allowed.has(item["id"]):
			filtered.append(item)
	return filtered

# Whether a one-per-floor item is already held. Held items stay on the shelf as
# a disabled "HELD" row instead of vanishing: a shop whose contents change shape
# between visits is harder to read than one where the same row says what you own.
func _sold_out(id: String) -> bool:
	match id:
		"cull": return PlayerData.cull_next
		"bandolier": return PlayerData.bandolier_next
		"second_wind": return PlayerData.second_wind
		_: return false

func _build() -> void:
	# _build() runs from inside a button's own `pressed` handler, so the old rows
	# cannot be free()d outright. Detaching them first still gets them off screen
	# this frame -- queue_free() alone would leave the previous shelf drawn
	# underneath the new one until the end of the frame.
	for child in item_list.get_children():
		item_list.remove_child(child)
		child.queue_free()

	for item in _stock():
		var button := Button.new()
		button.custom_minimum_size = Vector2(560, 52)
		button.add_theme_font_size_override("font_size", 18)
		button.text = "%s  -  %ds\n%s" % [item["name"], int(item["cost"]), item["desc"]]
		button.disabled = _sold_out(item["id"]) \
			or PlayerData.banked_time < float(item["cost"])
		if _sold_out(item["id"]):
			button.text = "%s  -  HELD\n%s" % [item["name"], item["desc"]]
		button.pressed.connect(_on_item_pressed.bind(item))
		item_list.add_child(button)

	_refresh_bank()

func _refresh_bank() -> void:
	bank_label.text = "BANKED TIME: %.1fs   /   %ds cap" \
		% [PlayerData.banked_time, int(PlayerData.bank_cap)]

func _on_item_pressed(item: Dictionary) -> void:
	var cost := float(item["cost"])
	if PlayerData.banked_time < cost or _sold_out(item["id"]):
		return
	PlayerData.banked_time -= cost
	apply(String(item["id"]))
	# Prices do not change, but affordability does, so the whole shelf is rebuilt
	# rather than just the row that was clicked.
	_build()

# The only place that knows what an item id means.
func apply(id: String) -> void:
	match id:
		"medkit":
			PlayerData.health += MEDKIT_HEALTH
			ThemePlayer.play_heal()
		"ammo":
			PlayerData.ammo += AMMO_ROUNDS
			ThemePlayer.play_ammo()
		"overclock":
			PlayerData.bonus_time_next += OVERCLOCK_SECONDS
		"vault":
			PlayerData.bank_cap += VAULT_SECONDS
		"cull":
			PlayerData.cull_next = true
		"bandolier":
			PlayerData.bandolier_next = true
		"second_wind":
			PlayerData.second_wind = true
		_:
			push_warning("ShopMenu: unknown item id '%s'" % id)
