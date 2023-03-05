extends Node

var openai
@onready var message_box:PackedScene = preload("res://message_box.tscn")
@onready var user_input:TextEdit = $vbox/hbox/user_input
@onready var chat_log = $vbox/scon/chat_log
@onready var loading = $vbox/hbox/loading
@onready var chat_scroll:ScrollContainer = $vbox/scon
@onready var chat_label = $vbox/PanelContainer/hbox2/chat_label
@onready var clear_chat_button = $vbox/PanelContainer/hbox2/clear_chat
@onready var regen_button = $vbox/hbox/regen

@onready var config_popup = $config_popup
@onready var config_button = $vbox/PanelContainer/hbox2/config
@onready var api_key_input = $config_popup/vbox/api_key
@onready var prompt_options = $config_popup/vbox/prompt_options
@onready var max_tokens_input = $config_popup/vbox/max_tokens
@onready var temperature_text = $config_popup/vbox/temperature_text
@onready var temperature_slider = $config_popup/vbox/temperature
@onready var presence_text = $config_popup/vbox/presence_text
@onready var presence_penalty_slider = $config_popup/vbox/presence_penalty
@onready var frequency_text = $config_popup/vbox/frequency_text
@onready var frequency_penalty_slider = $config_popup/vbox/frequency_penalty

var config = ConfigFile.new()
var API_KEY:String
var MAX_TOKENS:int = 1000
var TEMPERATURE:float = 1.4
var PRESENCE:float = 0.4
var FREQUENCY:float = 1.0

var bot_thinking:bool = false
var chat_memory:PackedStringArray = []

var bot_color:Color = Color("F5515F")
var user_color:Color = Color("5D8EAC")


var prompt_types:PackedStringArray = []

func _ready():
	copy_prompts_folder()
	
	user_input.gui_input.connect(user_gui)
	loading.hide()
	config_popup.hide()
	
	config_button.pressed.connect(func(): config_popup.popup_centered())
	config_popup.confirmed.connect(save_config)
	clear_chat_button.pressed.connect(clear_chat)
	regen_button.pressed.connect(regen_message)
	$config_popup/vbox/processor_folder.pressed.connect(func(): OS.shell_open(ProjectSettings.globalize_path("user://prompts")))
	
	await get_tree().process_frame
	prompt_types = list_folders_in_directory("user://prompts/")
	for p in prompt_types:
		prompt_options.add_item(p)
	
	prompt_options.item_selected.connect(func(_i): clear_chat(); chat_label.text = "Chat Type: " + prompt_options.get_item_text(prompt_options.selected))
	chat_label.text = "Chat Type: " + prompt_options.get_item_text(prompt_options.selected)
	
	
	if(!load_config()):
		config_popup.popup_centered()
		return
	
	connect_openai()

func connect_openai():
	await get_tree().process_frame
	openai = OpenAIAPI.new(get_tree(), "https://api.openai.com/v1/chat/", API_KEY)
	#print("openai connected")
	openai.connect("request_success", _on_openai_request_success)
	openai.connect("request_error", _on_openai_request_error)


func _on_openai_request_success(data):
	print("Request succeeded:", data)
	#print(data.choices[0].message.content)
	var reply:String = data.choices[0].message.content
	reply = reply.replace("&amp;", "&")
	reply = remove_after_phrase(reply, "<USER>").strip_edges()
	
	
	var new_msg:PanelContainer = message_box.instantiate()
	new_msg.get_node("message_box").size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	new_msg.get_node("message_box/msg").text = reply
	new_msg.get_node("message_box").self_modulate = bot_color
	chat_log.add_child(new_msg)
	loading.hide()
	await get_tree().process_frame
	chat_scroll.scroll_vertical = chat_scroll.get_v_scroll_bar().max_value
	bot_thinking = false
	chat_memory.append(reply)

func load_config():
	
	var err = config.load("user://settings.cfg")
	if err != OK:
		return false
	
	API_KEY = config.get_value("Settings", "API_KEY")
	MAX_TOKENS = config.get_value("Settings", "MAX_TOKENS")
	TEMPERATURE = config.get_value("Settings", "TEMPERATURE")
	PRESENCE = config.get_value("Settings", "PRESENCE")
	FREQUENCY = config.get_value("Settings", "FREQUENCY")
	
	api_key_input.text = API_KEY
	max_tokens_input.value = MAX_TOKENS
	temperature_slider.value = TEMPERATURE
	presence_penalty_slider.value = PRESENCE
	frequency_penalty_slider.value = FREQUENCY
	print("config loaded")
	return true

func save_config():
	config.set_value("Settings", "API_KEY", api_key_input.text)
	config.set_value("Settings", "MAX_TOKENS", max_tokens_input.value)
	config.set_value("Settings", "TEMPERATURE", temperature_slider.value)
	config.set_value("Settings", "PRESENCE", presence_penalty_slider.value)
	config.set_value("Settings", "FREQUENCY", frequency_penalty_slider.value)
	config.save("user://settings.cfg")
	
	if(openai == null):
		API_KEY = api_key_input.text
		MAX_TOKENS = max_tokens_input.value
		TEMPERATURE = temperature_slider.value
		PRESENCE = presence_penalty_slider.value
		FREQUENCY = frequency_penalty_slider.value
		connect_openai()



func _on_openai_request_error(error_code):
	printerr("Request failed with error code:", error_code)
	bot_thinking = false
	var new_msg:PanelContainer = message_box.instantiate()
	new_msg.get_node("message_box").size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	new_msg.get_node("message_box/msg").text = "An error occurred. Error Code: " + str(error_code)
	new_msg.get_node("message_box").self_modulate = Color.DARK_RED
	chat_log.add_child(new_msg)
	loading.hide()
	await get_tree().process_frame
	chat_scroll.scroll_vertical = chat_scroll.get_v_scroll_bar().max_value

#On ENTER pressed, send message instead of adding a new line.
func user_gui(event:InputEvent):
	if event is InputEventKey:
		if event.keycode == KEY_ENTER && event.is_pressed() && !bot_thinking:
			send_message(user_input.text)
			await get_tree().process_frame
			user_input.text = ""


func send_message(msg:String, role:String = "user", model:String = "gpt-3.5-turbo" ):
	bot_thinking = true
	loading.show()
	print("USER MSG: "+msg)
	var chat_array:Array = []
	
	chat_memory.append("\n<USER> "+msg)
	
	
	var new_msg = message_box.instantiate()
	new_msg.get_node("message_box").size_flags_horizontal = Control.SIZE_SHRINK_END
	new_msg.get_node("message_box/msg").text = msg
	new_msg.get_node("message_box").self_modulate = user_color
	chat_log.add_child(new_msg)
	
	
#	var pre_msg = load_file_as_string("res://scripts/prompts/" + prompt_options.get_item_text(prompt_options.selected))
#	for m in chat_memory:
#		pre_msg += m + "\n"
	chat_array.append({"role": "system", "content": load_file_as_string("user://prompts/" + prompt_options.get_item_text(prompt_options.selected))})
	for m in chat_memory:
		if(m.strip_edges().begins_with("<USER>")):
			chat_array.append({"role": "user", "content": m.strip_edges()})
		else:
			chat_array.append({"role": "assistant", "content": m.strip_edges()})
	
	var data = {
	"model": model,
	"messages": chat_array,
	"max_tokens": MAX_TOKENS,
	"temperature": TEMPERATURE,
	"presence_penalty": PRESENCE,
	"frequency_penalty": FREQUENCY,
	"stop": "<USER>",
	"stream": false
	}
	print(chat_array)
	openai.make_request("completions", HTTPClient.METHOD_POST, data)
	
	await get_tree().process_frame
	chat_scroll.scroll_vertical = chat_scroll.get_v_scroll_bar().max_value


func clear_chat():
	delete_all_children(chat_log)
	chat_memory.clear()

func regen_message(role:String = "user", model:String = "gpt-3.5-turbo"):
	bot_thinking = true
	loading.show()
	chat_memory.remove_at(chat_memory.size()-1)
	chat_log.get_child(chat_log.get_child_count() - 1).queue_free()
	
	var pre_msg = load_file_as_string("user://prompts/" + prompt_options.get_item_text(prompt_options.selected))
	for m in chat_memory:
		pre_msg += m + "\n"
	
	var data = {
	"model": model,
	"messages": [{"role": role, "content": pre_msg}],
	"max_tokens": MAX_TOKENS,
	"temperature": TEMPERATURE,
	"presence_penalty": PRESENCE,
	"frequency_penalty": FREQUENCY,
	"stop": "<USER>",
	"stream": false
	}
	openai.make_request("completions", HTTPClient.METHOD_POST, data)










func load_file_as_string(path):
	var file = FileAccess.open(path, FileAccess.READ)
	var content : String
	if file != null:
		content = file.get_as_text()
		file = null
		return content
	else:
		return "error"
		#return "[load_file_as_string] FILE DID NOT OPEN"

func list_folders_in_directory(path):
	var files:PackedStringArray = []
	var dir = DirAccess.open(path)
	if dir != null:
		dir.list_dir_begin()
		while true:
			var file = dir.get_next()
			if file == "":
				break
			elif !file.begins_with("."):
				files.append(file)
		dir.list_dir_end()
	return files

func delete_all_children(node):
	for n in node.get_children():
		n.queue_free()

func remove_after_phrase(my_string:String, phrase:String):
	var position = my_string.find(phrase);

	if (position != -1):
		return my_string.left(position);
	
	return my_string


func copy_prompts_folder():
	var file_list = list_folders_in_directory("res://scripts/prompts")
	
	var dir = DirAccess.open("user://")
	var destination_folder_path = "user://prompts/"
	await get_tree().process_frame
	dir.make_dir("user://prompts")
	for f in file_list:
		var success = dir.copy("res://scripts/prompts/"+f, destination_folder_path+f)
#		if success == OK:
#			print("Folder copied successfully!")
#		else:
#			print("Error copying folder.")

