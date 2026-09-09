extends GutTest

# The shop panel itself, built from the real scene. This is where the rules in
# test_shop_menu.gd meet the buttons the player actually clicks: a row that is
# enabled when it should not be is a purchase the player cannot afford.

const SHOP_SCENE := preload("res://Menu/shop_menu.tscn")

var shop: ShopMenu


func before_each():
	PlayerData.reset_run()
	shop = add_child_autofree(SHOP_SCENE.instantiate())


func after_each():
	# open() pauses the tree. Nothing here awaits, so a pause cannot stall a
	# test -- but it must not leak into the next one either.
	get_tree().paused = false
	PlayerData.reset_run()


func _rows() -> Array:
	return shop.item_list.get_children()


func _row_for(id: String) -> Button:
	var stock: Array = shop._stock()
	for i in stock.size():
		if stock[i]["id"] == id:
			return _rows()[i] as Button
	fail_test("no row for '%s'" % id)
	return null


func _cost(id: String) -> float:
	for item in ShopMenu.ITEMS:
		if item["id"] == id:
			return float(item["cost"])
	return 0.0


# --- building the shelf ---------------------------------------------------

func test_the_panel_starts_hidden():
	assert_false(shop.visible, "the shop was visible before it was opened")


func test_the_shelf_has_one_row_per_item():
	shop._build()
	assert_eq(_rows().size(), ShopMenu.ITEMS.size())


func test_a_filtered_shelf_has_one_row_per_stocked_item():
	shop._allowed = ["medkit"]
	shop._build()
	assert_eq(_rows().size(), 1)


func test_rebuilding_does_not_leave_the_old_shelf_behind():
	# _build() runs from inside a button's own pressed handler, so the old rows
	# are detached before being freed. Rebuilding twice must not stack them.
	shop._build()
	shop._build()
	assert_eq(_rows().size(), ShopMenu.ITEMS.size(),
		"a rebuilt shelf kept rows from the previous build")


func test_the_bank_readout_shows_the_banked_time():
	PlayerData.banked_time = 42.5
	shop._build()
	assert_string_contains(shop.bank_label.text, "42.5")


func test_the_bank_readout_shows_the_cap():
	PlayerData.bank_cap = 180.0
	shop._build()
	assert_string_contains(shop.bank_label.text, "180")


# --- what is clickable ----------------------------------------------------

func test_a_broke_player_can_click_nothing():
	PlayerData.banked_time = 0.0
	shop._build()
	for row in _rows():
		assert_true(row.disabled, "row '%s' was clickable with an empty bank" % row.text)


func test_a_rich_player_can_click_everything():
	PlayerData.banked_time = 10000.0
	shop._build()
	for row in _rows():
		assert_false(row.disabled, "row '%s' was blocked with a full bank" % row.text)


func test_only_what_the_player_can_afford_is_clickable():
	PlayerData.banked_time = 30.0
	shop._build()
	var stock: Array = shop._stock()
	for i in stock.size():
		var affordable: bool = float(stock[i]["cost"]) <= 30.0
		assert_eq(not (_rows()[i] as Button).disabled, affordable,
			"row %s was in the wrong state at 30s banked" % stock[i]["id"])


func test_a_held_item_is_shown_as_held_and_blocked():
	PlayerData.banked_time = 10000.0
	PlayerData.second_wind = true
	shop._build()
	var row := _row_for("second_wind")
	assert_true(row.disabled, "a held item was still clickable")
	assert_string_contains(row.text, "HELD")


func test_a_held_item_keeps_its_row_rather_than_vanishing():
	PlayerData.banked_time = 10000.0
	PlayerData.cull_next = true
	shop._build()
	assert_eq(_rows().size(), ShopMenu.ITEMS.size(),
		"a held item was removed from the shelf instead of being marked HELD")


# --- buying ---------------------------------------------------------------

func test_buying_deducts_exactly_the_cost():
	PlayerData.banked_time = 100.0
	shop._build()
	shop._on_item_pressed(_stock_item("medkit"))
	assert_eq(PlayerData.banked_time, 100.0 - _cost("medkit"))


func test_buying_applies_the_effect():
	PlayerData.banked_time = 100.0
	var health: int = PlayerData.health
	shop._build()
	shop._on_item_pressed(_stock_item("medkit"))
	assert_eq(PlayerData.health, health + ShopMenu.MEDKIT_HEALTH)


func test_buying_twice_deducts_twice():
	PlayerData.banked_time = 100.0
	shop._build()
	shop._on_item_pressed(_stock_item("medkit"))
	shop._on_item_pressed(_stock_item("medkit"))
	assert_eq(PlayerData.banked_time, 100.0 - _cost("medkit") * 2.0)


func test_an_unaffordable_purchase_is_refused():
	PlayerData.banked_time = 1.0
	var health: int = PlayerData.health
	shop._build()
	shop._on_item_pressed(_stock_item("medkit"))
	assert_eq(PlayerData.banked_time, 1.0, "the bank was charged for a refused purchase")
	assert_eq(PlayerData.health, health, "a refused purchase still granted its effect")


func test_the_bank_never_goes_negative_however_hard_it_is_pushed():
	PlayerData.banked_time = 100.0
	shop._build()
	for i in 40:
		for item in ShopMenu.ITEMS:
			shop._on_item_pressed(item)
	assert_true(PlayerData.banked_time >= 0.0,
		"the bank went negative at %f" % PlayerData.banked_time)


func test_a_held_item_cannot_be_bought_again():
	PlayerData.banked_time = 1000.0
	shop._build()
	shop._on_item_pressed(_stock_item("second_wind"))
	var after_first: float = PlayerData.banked_time

	shop._on_item_pressed(_stock_item("second_wind"))
	assert_eq(PlayerData.banked_time, after_first,
		"a one-per-run item was sold twice")


func test_buying_refreshes_what_is_still_affordable():
	# Prices do not change but affordability does, so the whole shelf rebuilds.
	PlayerData.banked_time = _cost("medkit")
	shop._build()
	assert_false(_row_for("medkit").disabled, "the only affordable row was blocked")

	shop._on_item_pressed(_stock_item("medkit"))
	assert_true(_row_for("medkit").disabled,
		"the shelf still offered an item the player could no longer afford")


# --- opening and closing --------------------------------------------------

func test_open_succeeds_when_something_is_affordable():
	PlayerData.banked_time = 1000.0
	assert_true(shop.open(), "the shop refused to open with a full bank")
	assert_true(shop.visible)
	assert_true(PlayerData.shop_open)


func test_open_pauses_the_game():
	PlayerData.banked_time = 1000.0
	shop.open()
	assert_true(get_tree().paused, "the shop opened without pausing the floor")


func test_close_unpauses_and_clears_the_flag():
	PlayerData.banked_time = 1000.0
	shop.open()
	shop.close()
	assert_false(get_tree().paused, "the game stayed paused after the shop closed")
	assert_false(PlayerData.shop_open)
	assert_false(shop.visible)


func test_close_announces_itself():
	# The level listens for this to hand the run to the loading screen. Without
	# it the run stops dead on a closed shop.
	watch_signals(shop)
	shop.close()
	assert_signal_emitted(shop, "closed")


func test_close_restores_the_track_that_was_playing():
	ThemePlayer.play_only("makuhita")
	PlayerData.banked_time = 1000.0
	shop.open()
	assert_eq(ThemePlayer.current_theme, "ninetales", "the shop did not take over the music")
	shop.close()
	assert_eq(ThemePlayer.current_theme, "makuhita",
		"the floor's track was not restored after the shop closed")


func _stock_item(id: String) -> Dictionary:
	for item in ShopMenu.ITEMS:
		if item["id"] == id:
			return item
	fail_test("no item '%s'" % id)
	return {}
