extends Node2D

signal start_state
signal end_state
signal emote
signal sent_text
signal battle_entry
signal user_reconnected
signal user_disconnected

@onready var camera = $Camera2D
@onready var battle_info = $Camera2D/CanvasLayer/Control/BattleInfo
@onready var drop_box = $Camera2D/CanvasLayer/Control/DropBox
@onready var cursor = $Camera2D/CanvasLayer/Control/DropBox/Cursor
@onready var enemy = $Enemy
@onready var move_effects = $MoveEffects

var battle_music = load("res://battle/battle.mp3")
var victory_music = load("res://battle/victory.mp3")

class Move:
	var ip
	var name
	
	func _init(_ip, _name):
		ip = _ip
		name = _name

var moves = []
var cursor_position = 0
var turn = 0
var max_turns = Game.users.size() - 1

var enemy_info = null
var party_turn = false
var battle_over = false

func _ready():
	Game.bgm_player.stream = battle_music
	Game.bgm_player.play()
	enemy.texture = enemy_info.texture
	
	connect("start_state", _startState)
	connect("end_state", _endState)
	connect("emote", _emote)
	connect("sent_text", _sentText)
	connect("battle_entry", _battleEntry)
	connect("user_disconnected", _userDisconnected)
	connect("user_reconnected", _userReconnected)
	
	camera.make_current()
	await get_tree().create_timer(0.8).timeout
	battle_info.Show("It's a " + enemy_info.enemy_name + "!", "", null, true)
	await get_tree().create_timer(2.5).timeout
	battle_info.Hide()
	await get_tree().create_timer(0.8).timeout
	PartyTurn()
	
func _process(delta):
	if drop_box.visible:
		if Input.is_action_just_pressed("move_down"):
			cursor_position += 1
			if cursor_position > moves.size() - 1:
				cursor_position = 0
		elif Input.is_action_just_pressed("move_up"):
			cursor_position -= 1
			if cursor_position < 0:
				cursor_position = moves.size() - 1
		cursor.position.y = 10 + (19 * cursor_position)
		if Input.is_action_just_pressed("interact"):
			drop_box.visible = false
			battle_info.hide()
			await get_tree().create_timer(0.8).timeout
			battle_info.Show("Tyler used " + moves[cursor_position].name + "!!!", "", null, true)
			await get_tree().create_timer(2.0).timeout
			var move = move_effects.get_children().pick_random()
			# var move = move_effects.get_node("Twomp")
			var moveSound = move.get_child(0,true)
			moveSound.play()
			move.emitting = true
			$Enemy/AnimationPlayer.play("onhit")
			get_node("RandomDamage").playAnimation()
			battle_info.Hide()
			await get_tree().create_timer(1.5).timeout
			turn += 1
			if turn >= max_turns:
				EndBattle(delta)
			else:
				EnemyTurn()
	elif battle_over:
		if Input.is_action_just_pressed("interact"):
			UI.transition.get_node("AnimationPlayer").play("fade_out")
			await get_tree().create_timer(0.4).timeout
			Game.ChangeState(self, Game.previous_state)
			UI.transition.get_node("AnimationPlayer").play("fade_in")

func PartyTurn():
	party_turn = true
	moves.clear()
	battle_info.Show("The party is thinking about their next move...", "", null, true)
	var battle_prompt = Game.Prompt.new("Think of a powerful move that will help Tyler in battle!", "battle_entry", "countdown", 30.0, false, {"small": "Megaflare"})
	Game.SendPromptToUsers(battle_prompt)
	
	for user in Game.users:
		if Game.users[user].connection_status == Client.CONNECTION_STATUS.OFFLINE:
			moves.append(Move.new(Game.users[user].ip, "*blushes*"))
			CheckAllMovesSubmitted()
	
func EnemyTurn():
	battle_info.Show("The " + enemy_info.enemy_name + " attacks!", "", null, true)
	await get_tree().create_timer(2.0).timeout
	battle_info.Hide()
	await get_tree().create_timer(1.0)
	PartyTurn()
	
func _sentText(packet):
	emit_signal(packet["context"], packet)
	
func _emote(packet):
	pass
	
func _userReconnected(packet):
	Game.SendPromptToUser(Game.wait_prompt, packet["userIP"])
	
func _userDisconnected(packet):
	if party_turn:
		for move in moves:
			if move.ip == packet["userIP"]:
				return
		moves.append(Move.new(packet["userIP"], "*blushes*"))
		CheckAllMovesSubmitted()

func _battleEntry(packet):
	moves.append(Move.new(packet["userIP"], packet["smallInputValue"]))
	Game.SendPromptToUser(Game.wait_prompt, packet["userIP"])
	CheckAllMovesSubmitted()
		
func CheckAllMovesSubmitted():
	if moves.size() == Game.users.size() - 1:
		battle_info.SetText(true, "Choose your favorite attack, Tyler!")
		for option in drop_box.get_child(0).get_children():
			option.text = ""
		for i in range(0, moves.size(), 1):
			drop_box.get_child(0).get_child(i).text = moves[i].name
		drop_box.visible = true
		party_turn = false
		
func EndBattle(delta):
	enemy.get_node("AnimationPlayer").play("dead")
	await get_tree().create_timer(1.4).timeout
	Game.bgm_player.stop()
	var final_blow_user = Game.users[moves[cursor_position].ip]
	DisplayServer.tts_speak(final_blow_user.catchphrase, final_blow_user.voice_id, 50.0, final_blow_user.character_data.voice_pitch)
	UI.message_box.Show(final_blow_user.catchphrase, final_blow_user.character_data.name, final_blow_user.character_data.icon_region, true)
	await get_tree().create_timer(3.0).timeout
	UI.message_box.Hide()
	Game.bgm_player.stream = victory_music
	Game.bgm_player.play()
	battle_info.Show("Tyler and company are victorious!")
	battle_over = true

func _startState():
	pass

func _endState():
	queue_free()
	get_parent().remove_child(self)
