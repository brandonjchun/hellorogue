extends CanvasLayer

const HEART_ROW_SIZE = 12
const HEART_OFFSET = 16

@onready var timer = $"../map_timer"
@onready var pause_menu_canvas = $"../pause_menu"
@onready var pause_menu = $"../pause_menu/PauseMenu"

var bank_label: Label

# Built in code, next to the TIME readout it belongs with, rather than added to
# main_level.tscn -- the hearts above are already assembled this way.
func make_bank_label() -> Label:
	var label := Label.new()
	label.position = Vector2(16, 138)
	label.add_theme_font_size_override("font_size", 24)
	add_child(label)
	return label

# Called when the node enters the scene tree for the first time.
func _ready():
	bank_label = make_bank_label()
	for i in mini(PlayerData.health, 12):
		var new_heart = Sprite2D.new()
		new_heart.texture = $heart.texture
		new_heart.hframes = $heart.hframes
		$heart.add_child(new_heart)
	if PlayerData.health < 12:
		var empty_hearts = 12 - PlayerData.health
		while empty_hearts > 0:
			var new_heart = Sprite2D.new()
			new_heart.texture = $heart.texture
			new_heart.hframes = $heart.hframes
			$heart.add_child(new_heart)
			empty_hearts -= 1
			
	$level_number.text = var_to_str(PlayerData.levels)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$ammo_amount.text = var_to_str(PlayerData.ammo)
	# This used to pin the display at "120.0" for anything above it, to hide the
	# 121s the clock actually starts at. Overclock and Second Wind both push the
	# real number past that, and a player who spent 25 banked seconds on a longer
	# clock has to be able to see the seconds they bought.
	$timer_countdown.text = var_to_str(timer.time_left).pad_decimals(1)
	bank_label.text = "BANK: %.1f" % PlayerData.banked_time

	if PlayerData.reached_exit or PlayerData.player_is_dead:
		timer.paused = true
		
	for heart in $heart.get_children():
		var index = heart.get_index()
		var x = (index % HEART_ROW_SIZE) * HEART_OFFSET
		var y = (index / HEART_ROW_SIZE) * HEART_OFFSET
		heart.position = Vector2(x, y)
		
		# Full or empty, nothing in between. The middle branch here used to read
		# `heart.frame = (health - floor(health)) * 4` for a partial heart, but
		# health is an integer and every source of damage is whole numbers, so
		# that fractional part was always zero and the branch was dead code
		# indistinguishable from the empty case.
		heart.frame = 4 if index < PlayerData.health else 0
	if PlayerData.health > 12:
		$extra_hearts.text = "+" + var_to_str(PlayerData.health - 12)
	else:
		$extra_hearts.text = ""
	
