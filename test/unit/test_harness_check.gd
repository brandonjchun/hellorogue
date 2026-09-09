extends GutTest

func test_harness_runs():
	assert_eq(2 + 2, 4, "GUT is wired up")

func test_project_classes_are_visible():
	assert_not_null(WalkerRoom, "WalkerRoom class_name resolves from a test")
	assert_not_null(PlayerData, "PlayerData class_name resolves from a test")

func test_autoloads_are_available():
	assert_not_null(ThemePlayer, "ThemePlayer autoload is live during tests")
