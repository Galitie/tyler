extends Map

signal pushCrate
signal eatFood

@onready var camera = get_parent().get_node("Camera2D")
var love_note_prompt = Game.Prompt.new("OMG write Tyler a love note!!!", "love_note_submitted", "countdown", 60.0, false, {"big": "私の心を動かしてくださいdokidoki"})

const food_to_eat = 7
var eaten_food = 0

func init():
	camera.SetTarget(get_parent().characters[Game.HOST_IP])
	get_parent().ResumeWorld()
	Game.SendPromptToUsers(get_parent().world_prompt, false)

func _ready():
	Game.bgm_player.play()
	connect("pushCrate", _pushCrate)
	connect("eatFood", _eatFood)
	set_process(false)

func update(delta):
	if Input.is_action_just_pressed("restart"):
		get_parent().emit_signal("portal_entered", $RestartPortal.next_map, $RestartPortal.next_map_cell_position)
		
func _eatFood(character, object):
	if !eaten_food:
		Game.SendPromptToUsers(love_note_prompt, true)
	eaten_food += 1
	if eaten_food >= food_to_eat:
		$Portal.locked = false
		$Portal2.locked = false

func _pushCrate(character, object):
	var direction = Vector2i(0, 0)
	match character.direction:
		"north":
			direction = Vector2i(0, -1)
		"south":
			direction = Vector2i(0, 1)
		"east":
			direction = Vector2i(1, 0)
		"west":
			direction = Vector2i(-1, 0)
	var destination = object.cell_position + direction
	var tile_data = get_cell_tile_data(Game.collision_layer, destination)
	if tile_data:
		return
	for interactable in get_tree().get_nodes_in_group("interactables"):
		if interactable.cell_position == destination:
			return
	object.SetCellPosition(destination, false)
