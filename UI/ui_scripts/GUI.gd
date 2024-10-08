extends CanvasLayer

const HEART_ROW_SIZE = 12
const HEART_OFFSET = 16

@onready var timer = $"../Timer"

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in player_data.health:
		var new_heart = Sprite2D.new()
		new_heart.texture = $heart.texture
		new_heart.hframes = $heart.hframes
		$heart.add_child(new_heart)
	$level_number.text = var_to_str(player_data.levels)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$ammo_amount.text = var_to_str(player_data.ammo)
	$timer_countdown.text = var_to_str(timer.time_left).pad_decimals(1)
	
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
