extends Node

var openai
@onready var message_box:PackedScene = preload("res://message_box.tscn")
@onready var user_input:TextEdit = $vbox/hbox/user_input
@onready var chat_log = $vbox/scon/chat_log
@onready var loading = $vbox/hbox/loading
@onready var chat_scroll:ScrollContainer = $vbox/scon
@onready var chat_label = $vbox/PanelContainer/hbox2/chat_label

@onready var config_popup = $config_popup
@onready var config_button = $vbox/PanelContainer/hbox2/config
@onready var prompt_options = $config_popup/vbox/prompt_options
@onready var max_tokens = $config_popup/vbox/max_tokens
@onready var temperature_text = $config_popup/vbox/temperature_text
@onready var temperature = $config_popup/vbox/temperature
@onready var presence_text = $config_popup/vbox/presence_text
@onready var presence_penalty = $config_popup/vbox/presence_penalty
@onready var frequency_text = $config_popup/vbox/frequency_text
@onready var frequency_penalty = $config_popup/vbox/frequency_penalty

var bot_thinking:bool = false
var chat_memory:PackedStringArray = []

var bot_color:Color = Color("F5515F")
var user_color:Color = Color("5D8EAC")


var prompt_types:PackedStringArray = [
	"general_prompt",
	"proofreader"
]

func _ready():
	await get_tree().process_frame
	openai = await OpenAIAPI.new(get_tree(), "https://api.openai.com/v1/chat/", load_file_as_string("res://API_KEY.txt"))
	
	print("start")
	openai.connect("request_success", _on_openai_request_success)
	openai.connect("request_error", _on_openai_request_error)
	
	user_input.gui_input.connect(user_gui)
	loading.hide()
	config_popup.hide()
	
	config_button.pressed.connect(func(): config_popup.popup_centered())
	prompt_options.item_selected.connect(func(): chat_label.text = "Chat Type: " + prompt_options.get_item_text(prompt_options.selected))
	for p in prompt_types:
		prompt_options.add_item(p)
	prompt_options.select(0)

func _on_openai_request_success(data):
	print("Request succeeded:", data)
	#print(data.choices[0].message.content)
	var reply:String = data.choices[0].message.content.strip_edges()
	reply = reply.replace("&amp;", "&")
	
	
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

func _on_openai_request_error(error_code):
	print("Request failed with error code:", error_code)

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
	
	chat_memory.append("<USER> "+msg)
	
	
	var new_msg = message_box.instantiate()
	new_msg.get_node("message_box").size_flags_horizontal = Control.SIZE_SHRINK_END
	new_msg.get_node("message_box/msg").text = msg
	new_msg.get_node("message_box").self_modulate = user_color
	chat_log.add_child(new_msg)
	
	
	var pre_msg = load_prompt(prompt_options.get_item_text(prompt_options.selected))
	for m in chat_memory:
		pre_msg += m + "\n"
	
	
	var data = {
	"model": model,
	"messages": [{"role": role, "content": pre_msg}],
	"temperature": 1.0,
	"presence_penalty": 0.4,
	"frequency_penalty": 1.0,
	"stream": false
	}
	print(pre_msg)
	openai.make_request("completions", HTTPClient.METHOD_POST, data)



func load_prompt(prompt):
	var file = FileAccess.open("res://scripts/prompts/" + prompt + ".txt", FileAccess.READ)
	var content : String
	if file != null:
		content = file.get_as_text()
		file = null
		return content
	else:
		return "error"
		#return "[load_file_as_string] FILE DID NOT OPEN"


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
