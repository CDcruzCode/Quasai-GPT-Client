extends Node

var openai:OpenAIAPI
var elevenlabs:ElevenLabsAPI
@onready var message_box:PackedScene = preload("res://scenes/general_chatting/message_box.tscn")
@onready var code_message:PackedScene = preload("res://scenes/general_chatting/code_message.tscn")

@onready var user_input:TextEdit = $vbox/hbox/user_input
@onready var chat_log = $vbox/scon/chat_log
@onready var loading = $vbox/hbox/loading
@onready var chat_scroll:ScrollContainer = $vbox/scon
@onready var chat_label = $vbox/pcon/vbox/hbox/chat_label
@onready var clear_chat_button = $vbox/pcon/vbox/hbox2/clear_chat
@onready var send_button = $vbox/hbox/send_button
@onready var regen_button = $vbox/hbox/regen_button
@onready var session_tokens_display = $vbox/pcon/vbox/hbox/session_tokens
@onready var save_chat_popup = $save_chat_popup
@onready var save_chat_name = $save_chat_popup/save_chat_name
@onready var save_chat_button = $vbox/pcon/vbox/hbox2/save_chat_button
@onready var saved_chats_list:OptionButton = $vbox/pcon/vbox/hbox2/saved_chats_list
@onready var home_button = $vbox/pcon/vbox/hbox2/home_button

@onready var config_popup = $config_popup
@onready var config_button = $vbox/pcon/vbox/hbox2/config
@onready var prompt_options = $config_popup/vbox/prompt_options
@onready var max_tokens_input = $config_popup/vbox/max_tokens
@onready var temperature_text = $config_popup/vbox/temperature_text
@onready var temperature_slider = $config_popup/vbox/temperature
@onready var presence_text = $config_popup/vbox/presence_text
@onready var presence_penalty_slider = $config_popup/vbox/presence_penalty
@onready var frequency_text = $config_popup/vbox/frequency_text
@onready var frequency_penalty_slider = $config_popup/vbox/frequency_penalty


@onready var bad_status = preload("res://images/icons/bad_status.png")
@onready var good_status = preload("res://images/icons/good_status.png")
@onready var wait_status = preload("res://images/icons/wait_status.png")
@onready var nil_status = preload("res://images/icons/nil_status.png")
var wait_thread:Thread = Thread.new()

var config = ConfigFile.new()
var MAX_TOKENS:int = 1000
var TEMPERATURE:float = 1.4
var PRESENCE:float = 0.4
var FREQUENCY:float = 1.0
var session_token_total:int = 0
var session_cost:float = 0.0
#USE THE LOGGIT BIAS TO REMOVE OR INCREASE THE PRESENSE OF CERTAIN WORDS. IT CAN EVEN BAN WORDS COMPLETELY FROM BEING GENERATED.
var logit_bias:Dictionary = {
	20185: -50, #AI
	3303: -80, #language
	2746: -80, #model
	562: -20, #ass
	10167: -80 #istant
}

var bot_thinking:bool = false
var chat_memory:PackedStringArray = []
var chat_memory_temp:PackedStringArray = []

#var bot_color:Color = Color(globals.BOT_BUBBLE)
#var user_color:Color = Color(globals.USER_BUBBLE)


var prompt_types:PackedStringArray = []



func _ready():
	self.tree_exiting.connect(func(): globals.clear_apis(openai, elevenlabs) )
	
	bot_thinking = true
	user_input.gui_input.connect(user_gui)
	loading.texture = wait_status
	config_popup.hide()
	reload_chats_list()
	saved_chats_list.item_selected.connect(load_saved_chat)
	
	config_button.pressed.connect(open_config)
	config_popup.confirmed.connect(save_config)
	clear_chat_button.pressed.connect(clear_chat)
	send_button.pressed.connect(func(): send_message(user_input.text); await get_tree().process_frame; user_input.text = "")
	regen_button.pressed.connect(regen_message)
	save_chat_button.pressed.connect(func(): save_chat_popup.popup_centered())
	save_chat_popup.confirmed.connect(save_new_chat)
	$config_popup/vbox/processor_folder.pressed.connect(func(): OS.shell_open(ProjectSettings.globalize_path("user://prompts")))
	$quit_popup.confirmed.connect(on_save_quit)
	$quit_popup.canceled.connect(func(): get_tree().quit())
	
	await get_tree().process_frame
	prompt_types = globals.list_folders_in_directory("user://prompts/")
	for p in prompt_types:
		prompt_options.add_item(p)
	
	prompt_options.item_selected.connect(func(_i): clear_chat(); chat_label.text = "Chat Type: " + prompt_options.get_item_text(prompt_options.selected))
	chat_label.text = "Chat Type: " + prompt_options.get_item_text(prompt_options.selected)
	
	$config_popup/vbox/temperature.value_changed.connect(func(value): $config_popup/vbox/temperature_text.text = "Temperature - " + str(value))
	$config_popup/vbox/presence_penalty.value_changed.connect(func(value): $config_popup/vbox/presence_text.text = "Presence - " + str(value))
	$config_popup/vbox/frequency_penalty.value_changed.connect(func(value): $config_popup/vbox/frequency_text.text = "Frequency - " + str(value))
	session_tokens_display.text = "Session Tokens: "+str(session_token_total)+" | Est. Cost: $"+str(session_token_total*0.002)
	
	if(!load_config()):
		config_popup.popup_centered()
		return
	
	connect_openai()
	bot_thinking = false
	loading.texture = good_status

func connect_openai():
	await get_tree().process_frame
	openai = OpenAIAPI.new(get_tree(), "https://api.openai.com/v1/chat/", globals.API_KEY)
	#print("openai connected")
	openai.connect("request_success_stream", _on_openai_request_success_stream)
	openai.connect("request_error", _on_openai_request_error)
	
	
	if(elevenlabs != null):
		elevenlabs.queue_free()
		elevenlabs = null
	await get_tree().process_frame
	if(!globals.API_KEY_ELEVENLABS.is_empty()):
		elevenlabs = ElevenLabsAPI.new(get_tree(), globals.API_KEY_ELEVENLABS)
		elevenlabs.request_success.connect(_on_elevenlabs_success)
		elevenlabs.request_error.connect(_on_elevenlabs_error)


func _on_elevenlabs_success(data):
	elevenlabs.play_audio(data)
	bot_thinking = false
	send_button.disabled = false
	await get_tree().process_frame
	loading.texture = good_status

func _on_elevenlabs_error(error_code):
	printerr(globals.parse_api_error(error_code))
	bot_thinking = false
	send_button.disabled = false
	await get_tree().process_frame
	loading.texture = bad_status



var response_msg:String = ""
var response_box:MarginContainer
var response_id:String = ""
func _on_openai_request_success_stream(data):
#	print("START CHUNK PARSE")
	var res_arr:PackedStringArray = data.split("data: ", false)
	var json_parse:JSON = JSON.new()
	
	for item in res_arr:
#		var res_json = JSON.parse_string(item.strip_edges())
		var json_err = json_parse.parse(item.strip_edges())
#		print(json_err)
		var res_json = json_parse.data
		if(json_err == ERR_PARSE_ERROR):
			if(item.strip_edges() == "[DONE]"):
				await get_tree().process_frame
				parse_streamed_message()
				print("FINISH")
				return
		
		if(res_json.has("choices") && res_json.choices[0].has("delta")):
			response_id = str(res_json.id)
			
			if(res_json.choices[0].delta.has("role")):
				#Role stated, this means its the start of the AI response
				response_msg = ""
#				print("Role is: "+str(res_json.choices[0].delta.role))
				print(str(res_json))
				response_box = message_box.instantiate()
				response_box.get_node("message_box").size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
				response_box.get_node("message_box/vbox/msg").text = response_msg
				response_box.get_node("message_box").message_list = chat_scroll
				response_box.get_node("message_box").theme_type_variation = StringName("bot_bubble")
				response_box.get_node("message_box").elevenlabs_api = elevenlabs
				response_box.get_node("message_box").chat_screen = self
				response_box.get_node("message_box").type = "bot"
				response_box.get_node("message_box").msg_id = response_id
				chat_log.add_child(response_box)
				continue
			
			if(res_json.choices[0].delta.has("content")):
#				print("Content: "+str(res_json.choices[0].delta.content))
				await get_tree().process_frame
				response_msg += str(res_json.choices[0].delta.content)
				var current_text:String = globals.replace_with_bbcode(response_msg.strip_edges(), "`", "inlinecode")
				current_text = globals.replace_with_bbcode(current_text.strip_edges(), "*","b")
				response_box.get_node("message_box/vbox/msg").text = current_text
				response_box.get_node("message_box").max_size()
				continue

func parse_streamed_message():
	print(response_msg)
	
	var output_tokens:int = globals.token_estimate(response_msg)
	session_token_total += output_tokens
	session_cost += (output_tokens*globals.INPUT_TOKENS_COST)
	globals.TOTAL_TOKENS_USED += output_tokens
	globals.TOTAL_TOKENS_COST += (output_tokens*globals.INPUT_TOKENS_COST)
	session_tokens_display.text = "Session Tokens: "+str(session_token_total)+" | Est. Cost: $"+str(session_cost)
	response_box.get_node("message_box").tooltip_text = str(output_tokens) + " Tokens"
	response_box.get_node("message_box").msg_id = response_id
	
	response_msg = response_msg.replace("&amp;", "&")
	response_msg = globals.remove_after_phrase(response_msg, "<USER>").strip_edges()
	chat_memory.append(response_msg)
	chat_memory_temp.append(response_msg)
	
	var voice_message:String = ""
	var reply_array:PackedStringArray = response_msg.split("```")
	
	if(reply_array.size() > 1):
		response_box.queue_free()
		
		var is_code:bool = false
		if(response_msg.strip_edges().begins_with("```")):
			is_code = true
		for line in reply_array:
			if(is_code):
				is_code = false
				var new_msg:MarginContainer = code_message.instantiate()
				new_msg.get_node("message_box").size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
				new_msg.get_node("message_box/vbox/code_box").text = line.strip_edges()
				new_msg.get_node("message_box").message_list = chat_scroll
				new_msg.get_node("message_box").self_modulate = "1b1b22"
				new_msg.get_node("message_box").type = "bot"
				new_msg.get_node("message_box").tooltip_text = str(output_tokens) + " Tokens"
				new_msg.get_node("message_box").msg_id = response_id
				chat_log.add_child(new_msg)
			else:
				is_code = true
				voice_message += line.strip_edges()
				
				var current_text:String = globals.replace_with_bbcode(line.strip_edges(), "`", "inlinecode")
				current_text = globals.replace_with_bbcode(current_text.strip_edges(), "**","b")
				
				var new_msg:MarginContainer = message_box.instantiate()
				new_msg.get_node("message_box").size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
				new_msg.get_node("message_box/vbox/msg").text = current_text
				new_msg.get_node("message_box").message_list = chat_scroll
				new_msg.get_node("message_box").theme_type_variation = StringName("bot_bubble")
				new_msg.get_node("message_box").elevenlabs_api = elevenlabs
				new_msg.get_node("message_box").chat_screen = self
				new_msg.get_node("message_box").type = "bot"
				new_msg.get_node("message_box").tooltip_text = str(output_tokens) + " Tokens"
				new_msg.get_node("message_box").msg_id = response_id
				chat_log.add_child(new_msg)
	else:
		voice_message += response_msg
	
	if(elevenlabs != null && globals.VOICE_ALWAYS_ON):
		print(voice_message)
		elevenlabs.text_to_speech(globals.parse_voice_message(voice_message), globals.SELECTED_VOICE)
	else:
		bot_thinking = false
		regen_button.disabled = false
		send_button.disabled = false
		loading.texture = good_status

func load_config():
	
	var err = config.load("user://settings.cfg")
	if err != OK:
		return false
	
	globals.API_KEY = config.get_value("Settings", "API_KEY")
	if(config.get_value("Settings", "MAX_TOKENS") != null):
		MAX_TOKENS = config.get_value("Settings", "MAX_TOKENS")
	if(config.get_value("Settings", "TEMPERATURE") != null):
		TEMPERATURE = config.get_value("Settings", "TEMPERATURE")
	if(config.get_value("Settings", "PRESENCE") != null):
		PRESENCE = config.get_value("Settings", "PRESENCE")
	if(config.get_value("Settings", "FREQUENCY") != null):
		FREQUENCY = config.get_value("Settings", "FREQUENCY")
		save_config()
	
	max_tokens_input.value = MAX_TOKENS
	temperature_slider.value = TEMPERATURE
	presence_penalty_slider.value = PRESENCE
	frequency_penalty_slider.value = FREQUENCY
	print("config loaded")
	
	return true

func save_config():
	config.set_value("Settings", "API_KEY", globals.API_KEY)
	config.set_value("Settings", "MAX_TOKENS", max_tokens_input.value)
	config.set_value("Settings", "TEMPERATURE", temperature_slider.value)
	config.set_value("Settings", "PRESENCE", presence_penalty_slider.value)
	config.set_value("Settings", "FREQUENCY", frequency_penalty_slider.value)
	config.save("user://settings.cfg")
	
	MAX_TOKENS = max_tokens_input.value
	TEMPERATURE = temperature_slider.value
	PRESENCE = presence_penalty_slider.value
	FREQUENCY = frequency_penalty_slider.value


func _on_openai_request_error(error_code):
	printerr("Request failed with error code:", error_code)
	bot_thinking = false
	regen_button.disabled = false
	send_button.disabled = false
	
	var new_msg:MarginContainer = message_box.instantiate()
	new_msg.get_node("message_box").size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if(typeof(error_code) == TYPE_INT):
		new_msg.get_node("message_box/vbox/msg").text = globals.parse_api_error(error_code)
	else:
		new_msg.get_node("message_box/vbox/msg").text = "Request failed with unknown error: " + str(error_code)
	new_msg.get_node("message_box").theme_type_variation = StringName("error_bubble")
	chat_log.add_child(new_msg)
	loading.texture = bad_status
	await get_tree().process_frame
	chat_scroll.scroll_vertical = chat_scroll.get_v_scroll_bar().max_value as int

#On ENTER pressed, send message instead of adding a new line.
var CTRL_KEY:bool = false
func user_gui(event:InputEvent):
	if event is InputEventKey:
		if event.keycode == KEY_CTRL || event.keycode == KEY_SHIFT:
			if event.pressed:
				CTRL_KEY = true
			else:
				CTRL_KEY = false
		
		if(CTRL_KEY && event.keycode == KEY_ENTER && event.is_pressed()):
			user_input.text += "\n"
			user_input.set_caret_column(user_input.get_last_full_visible_line()+1)
			user_input.set_caret_line(user_input.get_last_full_visible_line()+1)
		
		if !CTRL_KEY && event.keycode == KEY_ENTER && event.is_pressed() && !bot_thinking:
			send_message(user_input.text)
			await get_tree().process_frame
			user_input.text = ""


var send_msg_thread:Thread = Thread.new()

func send_message(msg:String):
	if(globals.API_KEY == "" || globals.API_KEY == null):
		var new_msg:MarginContainer = message_box.instantiate()
		new_msg.get_node("message_box").size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		new_msg.get_node("message_box/vbox/msg").text = "You have not provided an API key. Please open the config menu and add one. For more information and to generate your API key visit openai.com."
		new_msg.get_node("message_box").self_modulate = Color.DARK_RED
		chat_log.add_child(new_msg)
		return
	
	if(msg.strip_escapes().is_empty()):
		return
	
	var input_tokens:int = globals.token_estimate(msg)
	if((input_tokens+MAX_TOKENS) >= globals.max_model_tokens()):
		var new_msg:MarginContainer = message_box.instantiate()
		new_msg.get_node("message_box").size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		new_msg.get_node("message_box/vbox/msg").text = "Your message is too long! It is "+str(input_tokens)+" Tokens. The current model can only accept a total of "+str(globals.max_model_tokens())+" Tokens and requires "+str(MAX_TOKENS)+" free tokens to be able to respond to your message.\nThis means your message can only be "+str(globals.max_model_tokens()-MAX_TOKENS)+" Tokens in length."
		new_msg.get_node("message_box").theme_type_variation = StringName("error_bubble")
		chat_log.add_child(new_msg)
		return
	
	
	
	if(send_msg_thread.is_started() || send_msg_thread.is_alive()):
		print("WAITING TO FINISH")
		var err = send_msg_thread.wait_to_finish()
		print(err)
	
	
	bot_thinking = true
	regen_button.disabled = true
	send_button.disabled = true
	
	
	session_token_total += input_tokens
	session_cost += (input_tokens*globals.INPUT_TOKENS_COST)
	globals.TOTAL_TOKENS_USED += input_tokens
	globals.TOTAL_TOKENS_COST += (input_tokens*globals.INPUT_TOKENS_COST)
	session_tokens_display.text = "Session Tokens: "+str(session_token_total)+" | Est. Cost: $"+str(session_cost)
	
	if(wait_thread.is_started() || wait_thread.is_alive()):
		print("WAITING TO FINISH")
		globals.EXIT_THREAD = true
		var _err = wait_thread.wait_to_finish()
		print("WAIT_THREAD finished")
	globals.EXIT_THREAD = false
	wait_thread = Thread.new()
	wait_thread.start(wait_blink)
	print("USER MSG: "+msg)
	var chat_array:Array = []
	
	chat_memory.append("<USER> "+msg)
	chat_memory_temp.append("<USER> "+msg)
	limit_chat_memory()
	
	var new_msg = message_box.instantiate()
	new_msg.get_node("message_box").size_flags_horizontal = Control.SIZE_SHRINK_END
	new_msg.get_node("message_box/vbox/msg").text = msg
	new_msg.get_node("message_box").message_list = chat_scroll
	new_msg.get_node("message_box").chat_screen = self
#	new_msg.get_node("message_box").self_modulate = user_color
	new_msg.get_node("message_box").theme_type_variation = StringName("user_bubble")
	new_msg.get_node("message_box").tooltip_text = str(globals.token_estimate(msg)) + " Tokens"
	new_msg.get_node("message_box").type = "user"
	new_msg.get_node("message_box").msg_id = chat_memory.size() - 1 #Minus 1 because we need the position of the message in the array and array starts at 0
	chat_log.add_child(new_msg)
	
	var temp_logit_bias = logit_bias
	var preprocessor = globals.load_file_as_string("user://prompts/" + prompt_options.get_item_text(prompt_options.selected))
	var json_data:JSON = JSON.new()
	var err = json_data.parse(preprocessor)
	if(err == OK): #If preprocessor is in JSON format
		chat_array.append({"role": "system", "content": json_data.data.prompt})
		if(json_data.data.logit_bias):
			#Unsure if this is working correctly as the Key values are Strings instead of Integers
			temp_logit_bias = json_data.data.logit_bias
	else: #NOT JSON PREPROCESSOR
		chat_array.append({"role": "system", "content": preprocessor})
	
	for m in chat_memory_temp:
		if(m.strip_edges().begins_with("<USER>")):
			chat_array.append({"role": "user", "content": m.strip_edges()})
		else:
			chat_array.append({"role": "assistant", "content": m.strip_edges()})
	
	var data = {
	"model": globals.AI_MODEL,
	"messages": chat_array,
	"max_tokens": MAX_TOKENS,
	"temperature": TEMPERATURE,
	"presence_penalty": PRESENCE,
	"frequency_penalty": FREQUENCY,
	"stop": "<USER>",
	"logit_bias": temp_logit_bias
	}
	
#	openai.make_request("completions", HTTPClient.METHOD_POST, data, 60.0)
	
	send_msg_thread = Thread.new()
	send_msg_thread.start(openai.make_stream_request.bind("completions", HTTPClient.METHOD_POST, data))


func clear_chat(set_none:bool = true):
	if(set_none):
		saved_chats_list.select(0)
	globals.delete_all_children(chat_log)
	chat_memory.clear()
	chat_memory_temp.clear()

func regen_message():
	if(bot_thinking || chat_memory.is_empty()):
		return
	
	bot_thinking = true
	send_button.disabled = true
	regen_button.disabled = true
	
	if(send_msg_thread.is_started() || send_msg_thread.is_alive()):
		print("WAITING TO FINISH")
		var err = send_msg_thread.wait_to_finish()
	
	if(wait_thread.is_started() || wait_thread.is_alive()):
		print("WAITING TO FINISH")
		globals.EXIT_THREAD = true
		var _err = wait_thread.wait_to_finish()
	globals.EXIT_THREAD = false
	wait_thread = Thread.new()
	wait_thread.start(wait_blink)
	
	chat_memory.remove_at(chat_memory.size()-1)
	while(true):
		var current_child:Node = chat_log.get_child(chat_log.get_child_count() - 1)
		if( current_child != null && current_child.get_node("message_box").type == "bot"):
			current_child.queue_free()
			await get_tree().process_frame
		else:
			break
	
	
	print(chat_memory)
	var chat_array:Array = []
	chat_array.append({"role": "system", "content": "When writing code. Encapsulate the code with ``` and state the language of the code at the beginning in square brackets like [javascript]"})
	chat_array.append({"role": "system", "content": globals.load_file_as_string("user://prompts/" + prompt_options.get_item_text(prompt_options.selected))})
	
	for m in chat_memory:
		if(m.strip_edges().begins_with("<USER>")):
			chat_array.append({"role": "user", "content": m.strip_edges()})
		else:
			chat_array.append({"role": "assistant", "content": m.strip_edges()})
	
	var data = {
	"model": globals.AI_MODEL,
	"messages": chat_array,
	"max_tokens": MAX_TOKENS,
	"temperature": TEMPERATURE,
	"presence_penalty": PRESENCE,
	"frequency_penalty": FREQUENCY,
	"stop": "<USER>",
	"logit_bias": logit_bias
	}
	send_msg_thread = Thread.new()
	send_msg_thread.start(openai.make_stream_request.bind("completions", HTTPClient.METHOD_POST, data))


func save_new_chat():
	var chat_name:String = save_chat_name.text.strip_edges()
	if(chat_name.is_empty() || !chat_name.is_valid_filename()):
		return
	
	if(chat_memory.is_empty()):
		return
	
	overwrite_save(chat_name)
	
	reload_chats_list(chat_name)

func reload_chats_list(new_select:String = "<none>"):
	var dir = DirAccess.open("user://saved_conversations")
	if(!dir.dir_exists("user://saved_conversations")):
		return
	
	var chat_list:PackedStringArray = globals.list_folders_in_directory("user://saved_conversations")
	
	saved_chats_list.clear()
	saved_chats_list.add_item("<none>", 0)
	for a in chat_list:
		saved_chats_list.add_item(a)
	
	globals.set_button_by_text(saved_chats_list, new_select)

func open_config():
	if(!bot_thinking):
		config_popup.popup_centered()

func load_saved_chat(id:int):
	if(bot_thinking):
		return
	if(id == 0):
		clear_chat(false)
		return
	
	bot_thinking = true
	loading.texture = wait_status
	
	var selected_name:String = saved_chats_list.get_item_text(id)
	clear_chat(false)
	var file = FileAccess.open("user://saved_conversations/"+selected_name, FileAccess.READ)
	if(file.get_error() != OK):
		return
	var chat_json:Dictionary = JSON.parse_string(file.get_as_text())
	
	globals.set_button_by_text(prompt_options, chat_json.get("pre-processor"))
	chat_label.text = "Chat Type: " + prompt_options.get_item_text(prompt_options.selected)
	
	chat_memory = chat_json.get("chat_log")
	for msg in chat_memory:
		print(msg)
		
		if(msg.strip_edges().begins_with("<USER>")):
			var new_msg = message_box.instantiate()
			new_msg.get_node("message_box").size_flags_horizontal = Control.SIZE_SHRINK_END
			new_msg.get_node("message_box/vbox/msg").text = msg.strip_edges().trim_prefix("<USER> ")
#			new_msg.get_node("message_box").self_modulate = user_color
			new_msg.get_node("message_box").theme_type_variation = StringName("user_bubble")
			chat_log.add_child(new_msg)
		else:
			var reply_array:PackedStringArray = msg.split("```")
			print(reply_array)
			if(reply_array.size() > 1):
				
				var is_code:bool = false
				if(response_msg.strip_edges().begins_with("```")):
					is_code = true
				for line in reply_array:
					if(is_code):
						is_code = false
						var new_msg:MarginContainer = code_message.instantiate()
						new_msg.get_node("message_box").size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
						new_msg.get_node("message_box/vbox/code_box").text = line.strip_edges()
						new_msg.get_node("message_box").message_list = chat_scroll
						new_msg.get_node("message_box").self_modulate = "1b1b22"
						new_msg.get_node("message_box").type = "bot"
#						new_msg.get_node("message_box").tooltip_text = str(output_tokens) + " Tokens"
#						new_msg.get_node("message_box").msg_id = response_id
						chat_log.add_child(new_msg)
					else:
						is_code = true
						
						var current_text:String = globals.replace_with_bbcode(line.strip_edges(), "`", "inlinecode")
						current_text = globals.replace_with_bbcode(current_text.strip_edges(), "**","b")
						
						var new_msg:MarginContainer = message_box.instantiate()
						new_msg.get_node("message_box").size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
						new_msg.get_node("message_box/vbox/msg").text = current_text
						new_msg.get_node("message_box").message_list = chat_scroll
						new_msg.get_node("message_box").theme_type_variation = StringName("bot_bubble")
						new_msg.get_node("message_box").elevenlabs_api = elevenlabs
						new_msg.get_node("message_box").chat_screen = self
						new_msg.get_node("message_box").type = "bot"
#						new_msg.get_node("message_box").tooltip_text = str(output_tokens) + " Tokens"
#						new_msg.get_node("message_box").msg_id = response_id
						chat_log.add_child(new_msg)
			else:
				var new_msg:MarginContainer = message_box.instantiate()
				new_msg.get_node("message_box").size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
				new_msg.get_node("message_box/vbox/msg").text = msg
				new_msg.get_node("message_box").message_list = chat_scroll
				new_msg.get_node("message_box").theme_type_variation = StringName("bot_bubble")
				new_msg.get_node("message_box").elevenlabs_api = elevenlabs
				new_msg.get_node("message_box").chat_screen = self
				new_msg.get_node("message_box").type = "bot"
#				new_msg.get_node("message_box").tooltip_text = str(output_tokens) + " Tokens"
#				new_msg.get_node("message_box").msg_id = response_id
				chat_log.add_child(new_msg)
	await get_tree().process_frame
	chat_scroll.scroll_vertical = chat_scroll.get_v_scroll_bar().max_value as int
	
	bot_thinking = false
	loading.texture = good_status




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

func limit_chat_memory():
	var total_tokens:int = 0
	
	for m in chat_memory_temp:
		total_tokens += globals.token_estimate(m)
	if((total_tokens+MAX_TOKENS) >= globals.max_model_tokens()):
		chat_memory_temp.remove_at(0)
		limit_chat_memory()


#########################
#QUITTING CODE
#########################
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if(saved_chats_list.selected == 0):
			save_config()
			get_tree().quit()
			return
		
		$quit_popup.popup_centered()
	
	if what == NOTIFICATION_PREDELETE:
		# destructor logic
		globals.EXIT_THREAD = true
		globals.EXIT_HTTP = true
		if(send_msg_thread.is_started() || send_msg_thread.is_alive()):
			var _err = send_msg_thread.wait_to_finish()
		
		if(wait_thread.is_started() || wait_thread.is_alive()):
			var _err = wait_thread.wait_to_finish()
		globals.EXIT_THREAD = false
		globals.EXIT_HTTP = false


func on_save_quit():
	save_config()
	if(chat_memory.is_empty()):
		get_tree().quit()
		return
	print("save quit")
	var chat_name:String = saved_chats_list.get_item_text(saved_chats_list.selected)
	overwrite_save(chat_name)
	get_tree().quit()

func overwrite_save(chat_name:String):
	var dir = DirAccess.open("user://saved_conversations")
	if(dir.file_exists("user://saved_conversations"+chat_name)):
		return
	
	var file:FileAccess = FileAccess.open("user://saved_conversations/"+chat_name, FileAccess.WRITE)
	if(file != null):
		var chat_json:Dictionary = {
			"pre-processor": prompt_options.get_item_text(prompt_options.selected),
			"chat_log": chat_memory
		}
		file.store_string(JSON.stringify(chat_json))
	else:
		printerr("Chat did not save")

