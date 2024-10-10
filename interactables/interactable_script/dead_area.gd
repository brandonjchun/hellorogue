extends Area2D

enum spikes_states {
	FROZEN,
	MOVE
}

var spikes_state = spikes_states.FROZEN

func _process(delta):
	if spikes_state == spikes_states.MOVE:
		$AnimationPlayer.play("spikes")

func _on_timer_timeout():
	spikes_state = spikes_states.MOVE
