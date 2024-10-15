extends CanvasLayer

const HEART_ROW_SIZE = 12
const HEART_OFFSET = 16

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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$ammo_amount.text = var_to_str(player_data.ammo)
		
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
		
	if player_data.levels <= 18:
		$level_number.text = var_to_str(player_data.levels)
	elif player_data.levels == 19: 
		$level_number.text = "F1"
	elif player_data.levels == 20:
		$level_number.text = "F2"
	elif player_data.levels == 21:
		$level_number.text = "F3"
	elif player_data.levels == 22:
		$level_number.text = "FINAL"
	
