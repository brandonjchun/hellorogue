extends Node

# Autoloaded audio manager. Every AudioStreamPlayer child is addressable by its
# node name; the ones not listed in SFX are treated as background themes.
#
# This replaced 38 hand-written play/stop function pairs. Levels used to select
# their track by calling one play function plus six stop functions -- every
# frame, from _process. play_only() does the whole job in one call.

const SFX := ["heal", "ammo", "e1_death", "e2_death", "e3_death", "e4_death",
	"e3_bullet", "e4_bullet"]

var _players := {}
var _themes: Array[String] = []

# The track play_only() last selected, so callers that interrupt the music (the
# pause menu) can put it back afterwards.
var current_theme := ""

func _ready() -> void:
	for child in get_children():
		if child is AudioStreamPlayer:
			_players[child.name] = child
			if not SFX.has(String(child.name)):
				_themes.append(String(child.name))

# Plays `theme` and pauses every other theme. Passing "" silences all of them.
func play_only(theme: String) -> void:
	current_theme = theme
	for name in _themes:
		var player: AudioStreamPlayer = _players[name]
		if name == theme:
			# Resuming needs stream_paused cleared explicitly. A paused player
			# still reports playing == true, so the old `if not playing: play()`
			# guard saw a "playing" track and did nothing -- the track stayed
			# silent for the rest of the run once it had been stopped once.
			player.stream_paused = false
			if not player.playing:
				player.play()
		elif player.playing:
			player.stream_paused = true

func stop_all() -> void:
	play_only("")

func play_sfx(sfx: String) -> void:
	if _players.has(sfx):
		_players[sfx].play()
	else:
		push_warning("ThemePlayer: no AudioStreamPlayer named '%s'" % sfx)

# --- SFX shorthands, kept because they read better at the call site ---

func play_heal() -> void:
	play_sfx("heal")

func play_ammo() -> void:
	play_sfx("ammo")

func play_e1_death() -> void:
	play_sfx("e1_death")

func play_e2_death() -> void:
	play_sfx("e2_death")

func play_e3_bullet() -> void:
	play_sfx("e3_bullet")

func play_e4_bullet() -> void:
	play_sfx("e4_bullet")

# NOTE: these two are crossed over, and were in the original too -- enemy 3's
# death plays the e4 clip and vice versa. Preserved deliberately so the game
# still sounds the way it shipped; swap the two bodies if the node names are
# the things that are right and the mapping is what's wrong.
func play_e3_death() -> void:
	play_sfx("e4_death")

func play_e4_death() -> void:
	play_sfx("e3_death")
