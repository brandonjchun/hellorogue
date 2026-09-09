extends GutTest

# The shop's rules, tested against a bare ShopMenu with no scene attached.
# None of the methods here touch the @onready node references, so they can be
# exercised without building the panel. The panel itself is covered by
# test_shop_menu_ui.gd.

const NON_REPEATABLE := ["cull", "bandolier", "second_wind"]

var shop: ShopMenu


func before_each():
	PlayerData.reset_run()
	shop = autofree(ShopMenu.new())


func after_all():
	PlayerData.reset_run()


func _item(id: String) -> Dictionary:
	for item in ShopMenu.ITEMS:
		if item["id"] == id:
			return item
	fail_test("no shop item with id '%s'" % id)
	return {}


# --- item table integrity -------------------------------------------------

func test_every_item_has_the_keys_the_shop_reads():
	for item in ShopMenu.ITEMS:
		for key in ["id", "name", "cost", "desc", "repeatable"]:
			assert_true(item.has(key),
				"item %s is missing '%s'" % [item.get("id", "?"), key])


func test_item_ids_are_unique():
	var seen := {}
	for item in ShopMenu.ITEMS:
		var id: String = item["id"]
		assert_false(seen.has(id), "duplicate shop item id '%s'" % id)
		seen[id] = true


func test_every_item_costs_something():
	for item in ShopMenu.ITEMS:
		assert_gt(float(item["cost"]), 0.0,
			"item %s is free" % item["id"])


func test_every_item_has_a_name_and_a_description():
	for item in ShopMenu.ITEMS:
		assert_ne(String(item["name"]), "", "item %s has no name" % item["id"])
		assert_ne(String(item["desc"]), "", "item %s has no description" % item["id"])


func test_the_cheapest_item_is_reachable_within_one_full_bank():
	# If nothing were affordable at the starting cap, the shop could never open.
	var cheapest := INF
	for item in ShopMenu.ITEMS:
		cheapest = minf(cheapest, float(item["cost"]))
	assert_lt(cheapest, PlayerData.STARTING_BANK_CAP,
		"no item is affordable even with a full starting bank")


# --- repeatable vs one-per-run -------------------------------------------
#
# `repeatable` is what the item table claims; `_sold_out()` is what the shop
# actually enforces. These two tests pin them to each other in both directions,
# so adding an item without wiring it into _sold_out() fails here rather than
# letting the player buy Second Wind seven times.

func test_non_repeatable_items_are_the_ones_sold_out_tracks():
	PlayerData.cull_next = true
	PlayerData.bandolier_next = true
	PlayerData.second_wind = true

	for item in ShopMenu.ITEMS:
		if item["repeatable"]:
			continue
		assert_true(shop._sold_out(item["id"]),
			"item %s is one-per-run but nothing marks it held" % item["id"])


func test_repeatable_items_never_report_as_sold_out():
	PlayerData.cull_next = true
	PlayerData.bandolier_next = true
	PlayerData.second_wind = true

	for item in ShopMenu.ITEMS:
		if not item["repeatable"]:
			continue
		assert_false(shop._sold_out(item["id"]),
			"repeatable item %s was marked held" % item["id"])


func test_the_non_repeatable_set_is_what_we_expect():
	var found: Array = []
	for item in ShopMenu.ITEMS:
		if not item["repeatable"]:
			found.append(item["id"])
	found.sort()
	var expected := NON_REPEATABLE.duplicate()
	expected.sort()
	assert_eq(found, expected)


func test_nothing_is_sold_out_at_the_start_of_a_run():
	for item in ShopMenu.ITEMS:
		assert_false(shop._sold_out(item["id"]),
			"item %s was already held on a fresh run" % item["id"])


func test_an_unknown_id_is_never_sold_out():
	assert_false(shop._sold_out("no_such_item"))


# --- stock filtering ------------------------------------------------------

func test_an_empty_filter_sells_everything():
	shop._allowed = []
	assert_eq(shop._stock().size(), ShopMenu.ITEMS.size())


func test_a_filter_restricts_the_shelf():
	shop._allowed = ["medkit"]
	var stock := shop._stock()
	assert_eq(stock.size(), 1)
	assert_eq(stock[0]["id"], "medkit")


func test_a_filter_of_unknown_ids_sells_nothing():
	shop._allowed = ["not_a_real_item"]
	assert_eq(shop._stock().size(), 0)


func test_the_arena_stock_is_something_the_shop_actually_sells():
	# The intermissions pass ARENA_STOCK straight through to open(). A typo
	# there would produce an empty shelf rather than an error.
	for id in ArenaLevel.ARENA_STOCK:
		assert_not_null(_item(id), "ARENA_STOCK lists unknown item '%s'" % id)


func test_the_arena_only_sells_health():
	assert_eq(ArenaLevel.ARENA_STOCK, ["medkit"],
		"the boss run-up is supposed to sell health and nothing else")


# --- affordability --------------------------------------------------------

func test_a_broke_player_can_afford_nothing():
	PlayerData.banked_time = 0.0
	assert_false(shop.can_afford_anything())


func test_one_second_under_the_cheapest_item_is_not_enough():
	PlayerData.banked_time = float(_item("medkit")["cost"]) - 0.01
	assert_false(shop.can_afford_anything())


func test_exactly_the_price_is_enough():
	# The check is `>=`. A player who banked exactly 10s should get the shop.
	PlayerData.banked_time = float(_item("medkit")["cost"])
	assert_true(shop.can_afford_anything())


func test_a_filtered_shelf_judges_affordability_on_its_own_stock():
	shop._allowed = ["second_wind"]
	PlayerData.banked_time = float(_item("medkit")["cost"])
	assert_false(shop.can_afford_anything(),
		"affordability was judged against items this visit does not sell")


func test_held_items_do_not_count_as_affordable():
	# A player who owns Second Wind and has 60s banked, on a shelf that sells
	# only Second Wind, has nothing to buy -- the shop must not open.
	shop._allowed = ["second_wind"]
	PlayerData.second_wind = true
	PlayerData.banked_time = 100.0
	assert_false(shop.can_afford_anything())


func test_open_declines_when_there_is_nothing_to_buy():
	# Documented contract: callers must handle false by continuing to the next
	# floor themselves. This returns before touching the scene tree.
	PlayerData.banked_time = 0.0
	assert_false(shop.open(), "the shop opened with an unaffordable shelf")


func test_declining_to_open_does_not_flag_the_shop_as_open():
	PlayerData.banked_time = 0.0
	shop.open()
	assert_false(PlayerData.shop_open,
		"a shop that declined to open still blocked the pause menu")


# --- apply() --------------------------------------------------------------

func test_medkit_grants_health():
	var before: int = PlayerData.health
	shop.apply("medkit")
	assert_eq(PlayerData.health, before + ShopMenu.MEDKIT_HEALTH)


func test_ammo_grants_rounds():
	var before: int = PlayerData.ammo
	shop.apply("ammo")
	assert_eq(PlayerData.ammo, before + ShopMenu.AMMO_ROUNDS)


func test_overclock_banks_time_for_the_next_floor_only():
	shop.apply("overclock")
	assert_eq(PlayerData.bonus_time_next, ShopMenu.OVERCLOCK_SECONDS)
	assert_eq(PlayerData.floor_bonus_time, 0.0,
		"Overclock took effect on the current floor instead of the next one")


func test_overclock_stacks():
	shop.apply("overclock")
	shop.apply("overclock")
	assert_eq(PlayerData.bonus_time_next, ShopMenu.OVERCLOCK_SECONDS * 2)


func test_vault_raises_the_cap_without_granting_time():
	var cap: float = PlayerData.bank_cap
	var banked: float = PlayerData.banked_time
	shop.apply("vault")
	assert_eq(PlayerData.bank_cap, cap + ShopMenu.VAULT_SECONDS)
	assert_eq(PlayerData.banked_time, banked, "Vault handed out free seconds")


func test_vault_stacks():
	shop.apply("vault")
	shop.apply("vault")
	assert_eq(PlayerData.bank_cap,
		PlayerData.STARTING_BANK_CAP + ShopMenu.VAULT_SECONDS * 2)


func test_cull_arms_the_next_floor_not_this_one():
	shop.apply("cull")
	assert_true(PlayerData.cull_next)
	assert_false(PlayerData.cull_active,
		"Culling Order thinned the floor the player was standing on")


func test_bandolier_arms_the_next_floor_not_this_one():
	shop.apply("bandolier")
	assert_true(PlayerData.bandolier_next)
	assert_false(PlayerData.bandolier_active)


func test_second_wind_is_held_until_it_is_spent():
	shop.apply("second_wind")
	assert_true(PlayerData.second_wind)


func test_an_unknown_id_changes_nothing():
	var health: int = PlayerData.health
	var ammo: int = PlayerData.ammo
	var cap: float = PlayerData.bank_cap
	var banked: float = PlayerData.banked_time

	shop.apply("definitely_not_an_item")

	assert_eq(PlayerData.health, health)
	assert_eq(PlayerData.ammo, ammo)
	assert_eq(PlayerData.bank_cap, cap)
	assert_eq(PlayerData.banked_time, banked)


func test_every_item_in_the_table_is_handled_by_apply():
	# apply() falls through to a push_warning for ids it does not know. This
	# walks the real table and asserts each one changes something, which is what
	# catches an item added to ITEMS but never wired into apply().
	for item in ShopMenu.ITEMS:
		PlayerData.reset_run()
		var before := _run_state()
		shop.apply(String(item["id"]))
		assert_ne(_run_state(), before,
			"buying %s had no effect at all" % item["id"])


func _run_state() -> Array:
	return [
		PlayerData.health,
		PlayerData.ammo,
		PlayerData.bank_cap,
		PlayerData.bonus_time_next,
		PlayerData.cull_next,
		PlayerData.bandolier_next,
		PlayerData.second_wind,
	]
