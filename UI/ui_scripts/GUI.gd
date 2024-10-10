extends CanvasLayer

const HEART_ROW_SIZE = 12
const HEART_OFFSET = 16

@onready var timer = $"../map_timer"
@onready var pause_menu_canvas = $"../pause_menu"
@onready var pause_menu = $"../pause_menu/PauseMenu"

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in mini(player_data.health, 12):
		var new_heart = Sprite2D.new()
		new_heart.texture = $heart.texture
		new_heart.hframes = $heart.hframes
		$heart.add_child(new_heart)
	if player_data.health < 12:
		var empty_hearts = 12 - player_data.health
		while empty_hearts > 0:
			var new_heart = Sprite2D.new()
			new_heart.texture = $heart.texture
			new_heart.hframes = $heart.hframes
			$heart.add_child(new_heart)
			empty_hearts -= 1
			
	$level_number.text = var_to_str(player_data.levels)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$ammo_amount.text = var_to_str(player_data.ammo)
	if timer.time_left >= 90.0:
		$timer_countdown.text = "90.0"
	else:
		$timer_countdown.text = var_to_str(timer.time_left).pad_decimals(1)
		
	if player_data.reached_exit or player_data.player_is_dead:
		timer.paused = true
		
	for heart in $heart.get_children():
		var index = heart.get_index()
		var x = (index % HEART_ROW_SIZE) * HEART_OFFSET
		var y = (index / HEART_ROW_SIZE) * HEART_OFFSET
		heart.position = Vector2(x, y)
		
		var last_heart = floor(player_data.health)
		if index > last_heart:
			heart.frame = 0
		if index == last_heart:
			heart.frame = (player_data.health - last_heart) * 4
		if index < last_heart:
			heart.frame = 4
	if player_data.health > 12:
		$extra_hearts.text = "+" + var_to_str(player_data.health - 12)
	else:
		$extra_hearts.text = ""
		
	$please.text = var_to_str(player_data.pause_active) + var_to_str(player_data.game_mouse)
	
