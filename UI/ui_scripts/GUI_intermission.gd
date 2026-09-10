extends CanvasLayer

const HEART_ROW_SIZE = 12
const HEART_OFFSET = 16

var bank_label: Label

# Called when the node enters the scene tree for the first time.
func _ready():
	# These rooms have no clock, but the bank still has to be readable: what the
	# player is holding here is exactly what the health exchange at the exit will
	# let them spend.
	bank_label = Label.new()
	bank_label.position = Vector2(16, 98)
	bank_label.add_theme_font_size_override("font_size", 24)
	add_child(bank_label)

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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$ammo_amount.text = var_to_str(PlayerData.ammo)
	bank_label.text = "BANK: %.1f" % PlayerData.banked_time


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
		
	if PlayerData.levels <= 18:
		$level_number.text = var_to_str(PlayerData.levels)
	elif PlayerData.levels == 19: 
		$level_number.text = "F1"
	elif PlayerData.levels == 20:
		$level_number.text = "F2"
	elif PlayerData.levels == 21:
		$level_number.text = "F3"
	elif PlayerData.levels == 22:
		$level_number.text = "FINAL"
	
