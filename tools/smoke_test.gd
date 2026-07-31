extends Node

## Headless smoke test: proves every script compiles and every scene can be
## built. Run it with tools/smoke.sh -- it is not part of the game.
##
## Pass --deep to also add each scene to the tree, which runs _ready() and
## catches null node references that plain instantiation misses.

const SKIP_DIRS := ["res://.godot", "res://tools"]

var _failures: Array[String] = []
var _scenes_ok := 0
var _scripts_ok := 0


func _ready() -> void:
	var deep := "--deep" in OS.get_cmdline_user_args()

	for path in _find_files("res://", ".gd"):
		_check_script(path)
	for path in _find_files("res://", ".tscn"):
		_check_scene(path, deep)

	print("")
	print("scripts compiled: %d" % _scripts_ok)
	print("scenes built:     %d%s" % [_scenes_ok, " (deep)" if deep else ""])

	if _failures.is_empty():
		print("SMOKE TEST PASSED")
		quit_with(0)
		return

	print("")
	for failure in _failures:
		printerr("SMOKE FAILURE: %s" % failure)
	print("SMOKE TEST FAILED (%d)" % _failures.size())
	quit_with(1)


func quit_with(code: int) -> void:
	get_tree().quit(code)


func _check_script(path: String) -> void:
	var script := load(path)
	if script == null:
		_failures.append("script failed to compile: %s" % path)
		return
	if script is GDScript and not script.can_instantiate() and script.get_instance_base_type() == "":
		_failures.append("script has no usable base type: %s" % path)
		return
	_scripts_ok += 1


func _check_scene(path: String, deep: bool) -> void:
	var packed := load(path)
	if packed == null:
		_failures.append("scene failed to load: %s" % path)
		return
	if not packed is PackedScene:
		_failures.append("not a PackedScene: %s" % path)
		return

	var instance: Node = packed.instantiate()
	if instance == null:
		_failures.append("scene failed to instantiate: %s" % path)
		return

	if deep:
		# _ready() runs on add_child, so a bad get_node() surfaces here.
		add_child(instance)
		remove_child(instance)

	instance.queue_free()
	_scenes_ok += 1


func _find_files(root: String, suffix: String) -> Array[String]:
	var found: Array[String] = []
	var pending: Array[String] = [root]

	while not pending.is_empty():
		var dir_path: String = pending.pop_back()
		if dir_path in SKIP_DIRS:
			continue

		var dir := DirAccess.open(dir_path)
		if dir == null:
			continue

		dir.list_dir_begin()
		var name := dir.get_next()
		while name != "":
			if name.begins_with("."):
				name = dir.get_next()
				continue
			var full := dir_path.path_join(name) if dir_path != "res://" else "res://" + name
			if dir.current_is_dir():
				pending.append(full)
			elif name.ends_with(suffix):
				found.append(full)
			name = dir.get_next()
		dir.list_dir_end()

	found.sort()
	return found
