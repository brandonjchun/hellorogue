extends Area2D

enum spikes_states {
	FROZEN,
	MOVE
}

var spikes_state = spikes_states.FROZEN

# Was a _process that re-issued play("spikes") every frame while active. These
# levels place up to 320 spike traps at once, so that was ~19k redundant calls a
# second for an animation that only ever needs starting once.
func _on_timer_timeout():
	spikes_state = spikes_states.MOVE
	$AnimationPlayer.play("spikes")
