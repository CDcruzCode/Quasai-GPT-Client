extends PanelContainer
var openai:OpenAIAPI
var openai_guess:OpenAIAPI
var bot_thinking:bool = false

@onready var start_popup = $start_popup
@onready var start_button = $start_popup/mcon/vbox/start_button
@onready var new_game_button = $vbox/hcon/new_game_button

@onready var message_list = $vbox/hbox/pcon/vbox/pcon/chat_scroll/message_list
@onready var message_box:PackedScene = preload("res://scenes/general_chatting/message_box.tscn")
@onready var chat_scroll = $vbox/hbox/pcon/vbox/pcon/chat_scroll


@onready var user_input = $vbox/hbox/pcon/vbox/input_con/hbox/user_input
@onready var question_button = $vbox/hbox/pcon/vbox/input_con/hbox/vbox/question_button
@onready var guess_button = $vbox/hbox/pcon/vbox/input_con/hbox/vbox/guess_button
@onready var messages_remaining = $vbox/hbox/pcon/vbox/messages_remaining


@onready var categories_button = $start_popup/mcon/vbox/categories_button
@onready var categories_popup = $categories_popup

#Categories
@onready var historical_figures = $categories_popup/VBoxContainer/HFlowContainer/historical_figures
@onready var game_characters = $categories_popup/VBoxContainer/HFlowContainer/game_characters
@onready var influencers = $categories_popup/VBoxContainer/HFlowContainer/influencers
@onready var celebrities = $categories_popup/VBoxContainer/HFlowContainer/celebrities
@onready var cartoon_characters = $categories_popup/VBoxContainer/HFlowContainer/cartoon_characters
@onready var anime_characters = $categories_popup/VBoxContainer/HFlowContainer/anime_characters
@onready var musicians = $categories_popup/VBoxContainer/HFlowContainer/musicians
@onready var artists = $categories_popup/VBoxContainer/HFlowContainer/artists
@onready var movie_characters = $categories_popup/VBoxContainer/HFlowContainer/movie_characters


@onready var loading = $vbox/hcon/loading
@onready var bad_status = preload("res://images/icons/bad_status.png")
@onready var good_status = preload("res://images/icons/good_status.png")
@onready var wait_status = preload("res://images/icons/wait_status.png")
@onready var nil_status = preload("res://images/icons/nil_status.png")

var chat_memory:PackedStringArray = []

var guessing_list:PackedStringArray = []
var chosen_character:String = ""
const START_MESSAGES:int = 20
const START_GUESSES:int = 3
var messages_left:int = 0
var guesses_left:int = 0

var logit_bias:Dictionary = {
	20185: -50, #AI
	3303: -80, #language
	2746: -80, #model
	562: -20, #ass
	10167: -80, #istant
}

func _ready():
	start_popup.hide()
	categories_popup.hide()
	
	start_popup.popup_centered(Vector2i(300, 200) )
	
	question_button.disabled = true
	guess_button.disabled = true
	
	self.tree_exiting.connect(func(): openai.queue_free())
	self.tree_exiting.connect(func(): openai_guess.queue_free())
	
	bot_thinking = true
	loading.texture = wait_status
	
	
	categories_button.pressed.connect(func(): categories_popup.popup_centered(Vector2i(400,200)) )
	
	start_button.pressed.connect(start_game)
	new_game_button.pressed.connect(new_game)
	
	messages_left = START_MESSAGES
	guesses_left = START_GUESSES
	messages_remaining.text = str(messages_left) + " Messages Left | " + str(guesses_left) + " Guesses Left"
	question_button.pressed.connect(ask_question)
	guess_button.pressed.connect(guess_character)
	
	await connect_openai()
	bot_thinking = false
	loading.texture = good_status

func new_game():
	if(!bot_thinking):
		question_button.disabled = true
		guess_button.disabled = true
		start_popup.popup_centered(Vector2i(300, 200))

func start_game():
	categories_popup.hide()
	chat_memory.clear()
	globals.delete_all_children(message_list)
	
	
	reload_guessing_list()
	
	chosen_character = guessing_list[randi_range(0, guessing_list.size()-1)]
	print(chosen_character)
	
	messages_left = START_MESSAGES
	guesses_left = START_GUESSES
	messages_remaining.text = str(messages_left) + " Messages Left | " + str(guesses_left) + " Guesses Left"
	
	start_popup.hide()
	question_button.disabled = false
	guess_button.disabled = false
	
	var new_msg = message_box.instantiate()
	new_msg.get_node("message_box").size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	new_msg.get_node("message_box/vbox/msg").text = "Round begin! Ask questions to try and find out who the AI is."
	new_msg.get_node("message_box").message_list = chat_scroll
	new_msg.get_node("message_box").chat_screen = self
	new_msg.get_node("message_box").theme_type_variation = StringName("success_bubble")
	new_msg.get_node("message_box").MAX_SIZE = 500
	new_msg.get_node("message_box").disable_options = true
	message_list.add_child(new_msg)

func connect_openai():
	await get_tree().process_frame
	openai = OpenAIAPI.new(get_tree(), "https://api.openai.com/v1/chat/", globals.API_KEY)
	openai.connect("request_success", _on_openai_request_success)
	openai.connect("request_error", _on_openai_request_error)
	
	openai_guess = OpenAIAPI.new(get_tree(), "https://api.openai.com/v1/chat/", globals.API_KEY)
	openai_guess.connect("request_success", _on_guess_return)
	openai_guess.connect("request_error", _on_openai_request_error)

func reload_guessing_list():
	guessing_list.clear()
	
	if(historical_figures.button_pressed):
		guessing_list.append_array(globals.load_file_as_string("res://scripts/ai_pretender/guess_lists/historical_figures.txt").replace("\r", "").split("\n", false))
	if(game_characters.button_pressed):
		guessing_list.append_array(globals.load_file_as_string("res://scripts/ai_pretender/guess_lists/game_characters.txt").replace("\r", "").split("\n", false))
	if(influencers.button_pressed):
		guessing_list.append_array(globals.load_file_as_string("res://scripts/ai_pretender/guess_lists/influencers.txt").replace("\r", "").split("\n", false))
	if(celebrities.button_pressed):
		guessing_list.append_array(globals.load_file_as_string("res://scripts/ai_pretender/guess_lists/celebrities.txt").replace("\r", "").split("\n", false))
	if(cartoon_characters.button_pressed):
		guessing_list.append_array(globals.load_file_as_string("res://scripts/ai_pretender/guess_lists/cartoon_characters.txt").replace("\r", "").split("\n", false))
	if(anime_characters.button_pressed):
		guessing_list.append_array(globals.load_file_as_string("res://scripts/ai_pretender/guess_lists/anime_characters.txt").replace("\r", "").split("\n", false))
	if(musicians.button_pressed):
		guessing_list.append_array(globals.load_file_as_string("res://scripts/ai_pretender/guess_lists/movie_characters.txt").replace("\r", "").split("\n", false))
	if(artists.button_pressed):
		guessing_list.append_array(globals.load_file_as_string("res://scripts/ai_pretender/guess_lists/movie_characters.txt").replace("\r", "").split("\n", false))
	if(movie_characters.button_pressed):
		guessing_list.append_array(globals.load_file_as_string("res://scripts/ai_pretender/guess_lists/movie_characters.txt").replace("\r", "").split("\n", false))



func ask_question():
	if(bot_thinking || user_input.text.strip_edges().is_empty() || guesses_left == 0):
		return
	
	if(messages_left <= 0):
		user_input.text = ""
		var new_msg = message_box.instantiate()
		new_msg.get_node("message_box").size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		new_msg.get_node("message_box/vbox/msg").text = "You're out of questions, make your best guess!"
		new_msg.get_node("message_box").message_list = chat_scroll
		new_msg.get_node("message_box").chat_screen = self
		new_msg.get_node("message_box").theme_type_variation = StringName("error_bubble")
		new_msg.get_node("message_box").MAX_SIZE = 500
		new_msg.get_node("message_box").disable_options = true
		message_list.add_child(new_msg)
		return
	
	bot_thinking = true
	question_button.disabled = true
	guess_button.disabled = true
	
	if(wait_thread.is_started() || wait_thread.is_alive()):
		globals.EXIT_THREAD = true
		var _err = wait_thread.wait_to_finish()
	globals.EXIT_THREAD = false
	wait_thread = Thread.new()
	wait_thread.start(wait_blink)
	
	var new_msg = message_box.instantiate()
	new_msg.get_node("message_box").size_flags_horizontal = Control.SIZE_SHRINK_END
	new_msg.get_node("message_box/vbox/msg").text = user_input.text.strip_edges()
	new_msg.get_node("message_box").message_list = chat_scroll
	new_msg.get_node("message_box").chat_screen = self
	new_msg.get_node("message_box").theme_type_variation = StringName("user_bubble")
	new_msg.get_node("message_box").MAX_SIZE = 500
	new_msg.get_node("message_box").disable_options = true
	message_list.add_child(new_msg)
	
	chat_memory.append(user_input.text.strip_edges())
	
	var chat_array:Array = []

	chat_array.append({"role": "system", "content": globals.load_file_as_string("res://scripts/ai_pretender/ai_pretender_rules.txt").replace("<NAME>", chosen_character.replace("(","").replace(")",""))})
	
	for m in chat_memory:
		if(m.strip_edges().begins_with("<USER>")):
			chat_array.append({"role": "user", "content": m})
		else:
			chat_array.append({"role": "assistant", "content": m})
	
	print(chat_array)
	var data = {
	"model": globals.AI_MODEL,
	"messages": chat_array,
	"temperature": 1.0,
	"presence_penalty": 0.0,
	"frequency_penalty": 0.0,
	"stream": false,
	"logit_bias": logit_bias,
	"max_tokens": 100
	}

	openai.make_request("completions", HTTPClient.METHOD_POST, data)
	user_input.text = ""
	messages_left = messages_left - 1
	messages_remaining.text = str(messages_left) + " Messages Left | " + str(guesses_left) + " Guesses Left"
	


func guess_character():
	if(bot_thinking || user_input.text.strip_edges().is_empty()):
		return
	
	if(guesses_left <= 0):
		return
	
	bot_thinking = true
	question_button.disabled = true
	guess_button.disabled = true
	
	var chat_array:Array = []
	chat_array.append({"role": "system", "content": "Does the following user message include a match for the exact name in brackets "+ chosen_character +". Mispellings are allowed. If it does match, reply only with Y if it does not match reply with N"})
	chat_array.append({"role": "user", "content": user_input.text.strip_edges()})
	print(chat_array)
	
	var data = {
	"model": globals.AI_MODEL,
	"messages": chat_array,
	"temperature": 0.0,
	"presence_penalty": 0.0,
	"frequency_penalty": 0.0,
	"stream": false,
	"logit_bias": logit_bias,
	"max_tokens": 1
	}
	
	openai_guess.make_request("completions", HTTPClient.METHOD_POST, data, 20.0)
	user_input.text = ""
	guesses_left = guesses_left - 1
	messages_remaining.text = str(messages_left) + " Messages Left | " + str(guesses_left) + " Guesses Left"

func _on_guess_return(data):
	
	globals.TOTAL_TOKENS_USED += data.usage.total_tokens
	globals.TOTAL_TOKENS_COST += (data.usage.prompt_tokens*globals.INPUT_TOKENS_COST) + (data.usage.completion_tokens*globals.TOKENS_COST)
	
	var response = data.choices[0].message.content.strip_escapes()
	print(data.choices[0].message.content)
	bot_thinking = false
	
	if(response == "Y"):
		var new_msg = message_box.instantiate()
		new_msg.get_node("message_box").size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		new_msg.get_node("message_box/vbox/msg").text = "You're correct! I am " + chosen_character.replace("(","").replace(")","")
		new_msg.get_node("message_box").message_list = chat_scroll
		new_msg.get_node("message_box").chat_screen = self
		new_msg.get_node("message_box").theme_type_variation = StringName("success_bubble")
		new_msg.get_node("message_box").MAX_SIZE = 500
		new_msg.get_node("message_box").disable_options = true
		message_list.add_child(new_msg)
		return
	
	if(guesses_left <= 0):
		var new_msg = message_box.instantiate()
		new_msg.get_node("message_box").size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		new_msg.get_node("message_box/vbox/msg").text = "You are incorrect. That was your final guess, so game over! The correct answer was "+chosen_character.replace("(","").replace(")","")
		new_msg.get_node("message_box").message_list = chat_scroll
		new_msg.get_node("message_box").chat_screen = self
		new_msg.get_node("message_box").theme_type_variation = StringName("error_bubble")
		new_msg.get_node("message_box").MAX_SIZE = 500
		new_msg.get_node("message_box").disable_options = true
		message_list.add_child(new_msg)
		
		return
	elif (response == "N"):
		var new_msg = message_box.instantiate()
		new_msg.get_node("message_box").size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		new_msg.get_node("message_box/vbox/msg").text = "You are incorrect, try again! Writing the full name may be required."
		new_msg.get_node("message_box").message_list = chat_scroll
		new_msg.get_node("message_box").chat_screen = self
		new_msg.get_node("message_box").theme_type_variation = StringName("error_bubble")
		new_msg.get_node("message_box").MAX_SIZE = 500
		new_msg.get_node("message_box").disable_options = true
		message_list.add_child(new_msg)
		
		question_button.disabled = false
		guess_button.disabled = false
		return
	
	var new_msg = message_box.instantiate()
	new_msg.get_node("message_box").size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	new_msg.get_node("message_box/vbox/msg").text = "An error occurred, try asking again. You do not lose a guess."
	new_msg.get_node("message_box").message_list = chat_scroll
	new_msg.get_node("message_box").chat_screen = self
	new_msg.get_node("message_box").theme_type_variation = StringName("error_bubble")
	new_msg.get_node("message_box").MAX_SIZE = 500
	new_msg.get_node("message_box").disable_options = true
	message_list.add_child(new_msg)
	
	question_button.disabled = false
	guess_button.disabled = false
	
	guesses_left = guesses_left + 1
	messages_remaining.text = str(messages_left) + " Messages Left | " + str(guesses_left) + " Guesses Left"


func _on_openai_request_success(data):
	globals.TOTAL_TOKENS_USED += data.usage.total_tokens
	globals.TOTAL_TOKENS_COST += (data.usage.prompt_tokens*globals.INPUT_TOKENS_COST) + (data.usage.completion_tokens*globals.TOKENS_COST)
	
	var response = data.choices[0].message.content.replace(chosen_character, "<Character>")
	chat_memory.append(response.strip_edges())
	print(response)
	
	var new_msg = message_box.instantiate()
	new_msg.get_node("message_box").size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	new_msg.get_node("message_box/vbox/msg").text = response
	new_msg.get_node("message_box").message_list = chat_scroll
	new_msg.get_node("message_box").chat_screen = self
	new_msg.get_node("message_box").theme_type_variation = StringName("bot_bubble")
	new_msg.get_node("message_box").MAX_SIZE = 500
	new_msg.get_node("message_box").disable_options = true
	message_list.add_child(new_msg)
	
	bot_thinking = false
	loading.texture = good_status
	question_button.disabled = false
	guess_button.disabled = false

func _on_openai_request_error(error_code):
	printerr("Request failed with error code:", error_code)
#	text_display.text = globals.parse_api_error(error_code)
	var new_msg = message_box.instantiate()
	new_msg.get_node("message_box").size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	new_msg.get_node("message_box/vbox/msg").text = globals.parse_api_error(error_code)
	new_msg.get_node("message_box").message_list = chat_scroll
	new_msg.get_node("message_box").chat_screen = self
	new_msg.get_node("message_box").theme_type_variation = StringName("error_bubble")
	new_msg.get_node("message_box").MAX_SIZE = 500
	new_msg.get_node("message_box").disable_options = true
	message_list.add_child(new_msg)
	
	bot_thinking = false
	loading.texture = bad_status
	question_button.disabled = false
	guess_button.disabled = false

var wait_thread:Thread = Thread.new()
func wait_blink():
	while bot_thinking && !globals.EXIT_THREAD:
		loading.texture = wait_status
		await globals.delay(0.5)
		if(!bot_thinking || globals.EXIT_THREAD):
			print("[WAIT BLINK] EXIT")
			globals.EXIT_THREAD = false
			return OK
		loading.texture = nil_status
		await globals.delay(0.5)
