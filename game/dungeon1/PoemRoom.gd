extends Map

signal chestOpened
signal map_poem_entry
signal talkedToGatekeeper
signal moveGatekeeper

const max_chests = 4
var chests_opened = 0
var poem = []
var moved = false

func _ready():
	connect("chestOpened", _chestOpened)
	connect("map_poem_entry", _poemEntry)
	connect("talkedToGatekeeper", _talkedToGatekeeper)
	connect("moveGatekeeper", _moveGatekeeper)
	set_process(false)

func _chestOpened(character, object):
	if !chests_opened:
		var poem_prompt = Game.Prompt.new("Think of a poetic line that ends in \"ing\"", "map_poem_entry", "countdown", 30.0, false, {"big": "Roses are red..."})
		Game.SendPromptToUsers(poem_prompt)
		
	chests_opened += 1
	
	match chests_opened:
		1:
			object.messages.append(Message.new("", "You found a[color=yellow] blank scrap of paper..."))
		2:
			object.messages.append(Message.new("", "You found another[color=yellow] scrap of paper."))
		3:
			object.messages.append(Message.new("", "One more[color=yellow] scrap of paper."))
		4:
			object.messages.append(Message.new("", "You got the last[color=yellow] scrap of paper!"))

func _poemEntry(packet):
	poem.append(packet["bigInputValue"])
	Game.SendPromptToUser(get_parent().world_prompt, packet["userIP"])

func _talkedToGatekeeper(character, object):
	if !moved && chests_opened == max_chests:
		var dialogue : Array[Resource] = []
		for line in poem:
			var message = Message.new("Gatekeeper", line)
			dialogue.append(message)
		dialogue.append(Message.new("Gatekeeper", "Wow!"))
		dialogue.append(Message.new("Gatekeeper", "The tears just won't stop."))
		dialogue.append(Message.new("Gatekeeper", "I'm inspired -- truly."))
		dialogue.append(Message.new("Gatekeeper", "You shall pass.", "moveGatekeeper", Message.SignalTiming.DISAPPEAR))
		object.messages = dialogue
		moved = true

func _moveGatekeeper(message_args):
	$Gatekeeper.SetCellPosition($Gatekeeper.cell_position + Vector2i(1, 0), false)
	var dialogue : Array[Resource] = []
	dialogue.append(Message.new("Gatekeeper", "That was so moving."))
	dialogue.append(Message.new("Gatekeeper", "Like, I'm all the way over here now!"))
	$Gatekeeper.messages = dialogue
