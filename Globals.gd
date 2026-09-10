extends Node

var camera = null


# Parents a short-lived world node -- a bullet, a hit effect, an enemy drop --
# to the level it was created in.
#
# All of these used to go to get_tree().root, which is the Window: a *sibling*
# of the level scene, not part of it. Nothing there is freed by a scene change,
# so every projectile, effect and drop that outlived its floor carried into the
# next one at the same world coordinates, and kept accumulating for the whole
# session. The projectiles were given a MAX_LIFETIME timer to bound the damage;
# this removes the cause instead.
#
# Falls back to the root when there is no current scene -- mid-change, or under
# the test harness, where nodes are parented to the running test.
func spawn_transient(node: Node) -> void:
	var host: Node = get_tree().current_scene
	if host == null or not host.is_inside_tree():
		host = get_tree().root
	host.add_child(node)
