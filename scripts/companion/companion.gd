extends PanelContainer
var openai:OpenAIAPI
var openai_user_thread:OpenAIAPI
var openai_bot_thread:OpenAIAPI
var bot_thinking:bool = false
var bot_message:bool = false

@onready var loading:TextureRect = $vbox/hbox/loading
@onready var user_input = $vbox/hbox/user_input
@onready var chat_log_box = $vbox/chat_scroll/chat_log_box
@onready var chat_scroll = $vbox/chat_scroll
@onready var delete_ai_button = $vbox/pcon/vbox/hbox2/delete_ai_button

@onready var bad_status = preload("res://images/icons/bad_status.png")
@onready var good_status = preload("res://images/icons/good_status.png")
@onready var wait_status = preload("res://images/icons/wait_status.png")
@onready var nil_status = preload("res://images/icons/nil_status.png")

@onready var message_box = preload("res://scenes/companion/companion_message_box.tscn")

enum MSG_TYPE {USER, SYSTEM, ASSISTANT}
var basic_info:Dictionary = {}

var chat_log:PackedStringArray = []
var user_notes:String = ""
var bot_notes:String = ""

#USE THE LOGGIT BIAS TO REMOVE OR INCREASE THE PRESENSE OF CERTAIN WORDS. IT CAN EVEN BAN WORDS COMPLETELY FROM BEING GENERATED.
var logit_bias:Dictionary = {
	20185: -50, #AI
	3303: -80, #language
	2746: -80, #model
	562: -20, #ass
	10167: -80 #istant
}

func _ready():
	self.tree_exiting.connect(func(): openai.queue_free(); openai_bot_thread.queue_free(); openai_user_thread.queue_free())
	bot_thinking = true
	loading.texture = bad_status
	
	var basic_info_file = FileAccess.open("user://companion/basic_info.json", FileAccess.READ)
	if(basic_info_file == null):
		get_tree().change_scene_to_file("res://scenes/companion/companion_start.tscn")
		return
	
	user_input.gui_input.connect(user_gui)
	delete_ai_button.pressed.connect(delete_ai_personality)
	
	basic_info = JSON.parse_string( basic_info_file.get_as_text() )
	
	
	var log_file = FileAccess.open("user://companion/chatlog.json", FileAccess.READ)
	await connect_openai()
	
	if(log_file != null):
		load_saved_chat()
	else:
		send_message("", MSG_TYPE.SYSTEM)
	
	var user_notes_file = FileAccess.open("user://companion/user_notes.txt", FileAccess.READ)
	if(user_notes_file != null):
		user_notes = user_notes_file.get_file_as_string("user://companion/user_notes.txt")
	
	var bot_notes_file = FileAccess.open("user://companion/bot_notes.txt", FileAccess.READ)
	if(bot_notes_file != null):
		bot_notes = bot_notes_file.get_file_as_string("user://companion/bot_notes.txt")


func connect_openai():
	await get_tree().process_frame
	openai = await OpenAIAPI.new(get_tree(), "https://api.openai.com/v1/chat/", globals.API_KEY)
	openai.connect("request_success", _on_openai_request_success)
	openai.connect("request_error", _on_openai_request_error)
	
	openai_user_thread = await OpenAIAPI.new(get_tree(), "https://api.openai.com/v1/chat/", globals.API_KEY, "", "HTTP_USER_THREAD")
	openai_user_thread.connect("request_success", _openai_user_thread_success)
	openai_user_thread.connect("request_error", _openai_user_thread_error)
	
	openai_bot_thread = await OpenAIAPI.new(get_tree(), "https://api.openai.com/v1/chat/", globals.API_KEY, "", "HTTP_BOT_THREAD")
	openai_bot_thread.connect("request_success", _openai_bot_thread_success)
	openai_bot_thread.connect("request_error", _openai_bot_thread_error)


func _on_openai_request_success(data):
	print(data)
	
	globals.TOTAL_TOKENS_USED += data.usage.total_tokens
	globals.TOTAL_TOKENS_COST += (data.usage.prompt_tokens*globals.INPUT_TOKENS_COST) + (data.usage.completion_tokens*globals.TOKENS_COST)
	
	await get_tree().process_frame
	var bot_msg:String = data.choices[0].message.content
	bot_msg = bot_msg.replace("&amp;", "&")
	bot_msg = globals.remove_after_phrase(bot_msg, "<USER>").strip_edges().trim_suffix("[continue]")
	chat_log.append(bot_msg)
	
	var new_msg:MarginContainer = message_box.instantiate()
	new_msg.get_node("message_box").size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	new_msg.get_node("message_box/vbox/msg").text = bot_msg
	new_msg.get_node("message_box").self_modulate = globals.CURRENT_THEME.bot_bubble
	chat_log_box.add_child(new_msg)
	
	if(data.choices[0].message.content.strip_edges().ends_with("[continue]")):
		print("CONTINUE")
		send_message(globals.remove_after_phrase(bot_msg, "<USER>").strip_edges().trim_suffix("[continue]"), MSG_TYPE.ASSISTANT)
	
	globals.save_file("user://companion/chatlog.json", JSON.stringify(chat_log))
	
	await get_tree().process_frame
	var thread_array:Array = []
	if(!chat_log.is_empty()):
		thread_array.append({"role": "system", "content": globals.load_file_as_string("res://scripts/companion/prompts/thread_analysis.txt") })
		thread_array.append({"role": "assistant", "content": chat_log[chat_log.size()-2] })
		thread_array.append({"role": "user", "content": chat_log[chat_log.size()-1] })
		if(bot_notes.strip_edges() != ""):
			thread_array.append({"role": "system", "content": "Here's a bit more information about the user: "+ bot_notes +"\n"})
			thread_array.append({"role": "system", "content": "\nBelow is a list of previous notes gathered about the user. If a new note is similar combine it with the old note to be more concise.\n"})
			thread_array.append({"role": "system", "content": bot_notes})
		
		var thread_data = {
		"model": globals.AI_MODEL,
		"messages": thread_array,
		"temperature": 0.3,
		"presence_penalty": 0.0,
		"frequency_penalty": 0.0,
		"stop": "<USER>",
		"logit_bias": logit_bias
		}
		#await openai_bot_thread.make_request("completions", HTTPClient.METHOD_POST, thread_data)
	
	await get_tree().process_frame
	chat_scroll.scroll_vertical = chat_scroll.get_v_scroll_bar().max_value
	if(wait_thread.is_started()):
		wait_thread.wait_to_finish()
	bot_thinking =false
	loading.texture = good_status
	

func _on_openai_request_error(error_code):
	printerr("Request failed with error code:", error_code)
	wait_thread.wait_to_finish()
	bot_thinking =false
	loading.texture = bad_status
	await get_tree().process_frame
	chat_scroll.scroll_vertical = chat_scroll.get_v_scroll_bar().max_value

var wait_thread:Thread = Thread.new()
func wait_blink():
	while bot_thinking:
		loading.texture = wait_status
		await globals.delay(0.5)
		if(!bot_thinking):
			return
		loading.texture = nil_status
		await globals.delay(0.5)

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


func send_message(msg:String, system_msg:MSG_TYPE = MSG_TYPE.USER):
	bot_thinking = true
	wait_thread = Thread.new()
	wait_thread.start(wait_blink)
	
	if(system_msg == MSG_TYPE.USER):
		if(msg.strip_edges().is_empty()):
			return
		
		var new_msg:MarginContainer = message_box.instantiate()
		new_msg.get_node("message_box").size_flags_horizontal = Control.SIZE_SHRINK_END
		new_msg.get_node("message_box/vbox/msg").text = msg
		new_msg.get_node("message_box").self_modulate = globals.CURRENT_THEME.user_bubble
		chat_log_box.add_child(new_msg)
		
		chat_log.append("<USER> "+msg)
	
	if(system_msg == MSG_TYPE.ASSISTANT):
		if(msg.strip_edges().is_empty()):
			return
		
		chat_log.append(msg)
	
	var thread_array:Array = []
	if(!chat_log.is_empty()):
		thread_array.append({"role": "system", "content": globals.load_file_as_string("res://scripts/companion/prompts/thread_analysis.txt") })
		#thread_array.append({"role": "assistant", "content": chat_log[chat_log.size()-2] })
		thread_array.append({"role": "user", "content": chat_log[chat_log.size()-1] })
	
	
	var chat_array:Array = []
	chat_array.append({"role": "system", "content": globals.load_file_as_string("res://scripts/companion/prompts/rules.txt").replace("<SEX>", basic_info.sex).replace("<NAME>", basic_info.name).replace("<AGE>", str(basic_info.age))   })
	chat_array.append({"role": "system", "content": "\nThe current date and time in format YYYY-MM-DD HH:MM:SS is: " + str(Time.get_datetime_string_from_system(false,true)) + "\n"})
	chat_array.append({"role": "system", "content": "The current time in 24hr format is: " + Time.get_time_string_from_system() + "\n"})
	chat_array.append({"role": "system", "content": "Your name is: " + basic_info.get("name") + "\n"})
	chat_array.append({"role": "system", "content": "Your age is: " + str(basic_info.get("age")) + " and you will act your age.\n"})
	chat_array.append({"role": "system", "content": "Your personality type is " + get_personality(basic_info.personality) + "\n"})
	chat_array.append({"role": "system", "content": "Here's a bit more information about "+basic_info.name+"'s personality:"+bot_notes+"\n"})
	if(user_notes.strip_edges() != ""):
		chat_array.append({"role": "system", "content": "Here's a bit more information about the user:\n"+ user_notes +"\n"})
		thread_array.append({"role": "system", "content": "\nBelow is a list of previous notes gathered about the user. If a new note is similar combine it with the old note to be more concise.\n"+user_notes+"\n"})
	
	
	chat_array.append({"role": "system", "content": "Below is your conversation with the user. Please continue the conversation.\n\n"})
	
	for m in chat_log:
		if(m.strip_edges().begins_with("<USER>")):
			chat_array.append({"role": "user", "content": m.strip_edges().trim_prefix("<USER>")})
		else:
			chat_array.append({"role": "assistant", "content": m.strip_edges()})
	
	if(chat_log.is_empty()):
		chat_array.append({"role": "system", "content": "This is the start of the conversation so please introduce yourself to the user. Write a paragraph to get the conversation going!"})
	
	print(chat_array)
	var data = {
	"model": globals.AI_MODEL,
	"messages": chat_array,
	"temperature": 1.1,
	"presence_penalty": 0.0,
	"frequency_penalty": 0.0,
	"stop": "<USER>",
	"logit_bias": logit_bias
	}
	
	await get_tree().process_frame
	chat_scroll.scroll_vertical = chat_scroll.get_v_scroll_bar().max_value
	openai.make_request("completions", HTTPClient.METHOD_POST, data)
	
	if(chat_log.is_empty()):
		return
	
	await get_tree().process_frame
	var thread_data = {
	"model": globals.AI_MODEL,
	"messages": thread_array,
	"temperature": 0.3,
	"presence_penalty": 0.0,
	"frequency_penalty": 0.0,
	"stop": "<USER>",
	"logit_bias": logit_bias
	}
	await openai_user_thread.make_request("completions", HTTPClient.METHOD_POST, thread_data)




func _openai_user_thread_success(data):
	await get_tree().process_frame
	print("USER THREAD")
	globals.TOTAL_TOKENS_USED += data.usage.total_tokens
	globals.TOTAL_TOKENS_COST += (data.usage.prompt_tokens*globals.INPUT_TOKENS_COST) + (data.usage.completion_tokens*globals.TOKENS_COST)
	
	print(data.choices[0].message.content)
	if(data.choices[0].message.content.strip_edges().strip_escapes() == "[nothing]" || data.choices[0].message.content.strip_edges().strip_escapes().is_empty()):
		return

	user_notes = "" #CLEARING TO FORGET ALL MEMORIES AND HOPEFULLY THE NEW MEMORIES INCLUDE SOME OLD ONES
	user_notes = data.choices[0].message.content.strip_edges()
	globals.save_file("user://companion/user_notes.txt", user_notes)

func _openai_user_thread_error(err):
	print(err)



func _openai_bot_thread_success(data):
	await get_tree().process_frame
	print("BOT THREAD")
	globals.TOTAL_TOKENS_USED += data.usage.total_tokens
	globals.TOTAL_TOKENS_COST += (data.usage.prompt_tokens*globals.INPUT_TOKENS_COST) + (data.usage.completion_tokens*globals.TOKENS_COST)
	
	print(data.choices[0].message.content)
	if(data.choices[0].message.content.strip_edges().strip_escapes() == "[nothing]" || data.choices[0].message.content.strip_edges().strip_escapes().is_empty()):
		return
	
	bot_notes = "" #CLEARING TO FORGET ALL MEMORIES AND HOPEFULLY THE NEW MEMORIES INCLUDE SOME OLD ONES
	bot_notes = data.choices[0].message.content.strip_edges()
	globals.save_file("user://companion/bot_notes.txt", bot_notes)

func _openai_bot_thread_error(err):
	print(err)






func get_personality(personality:String):
	match personality:
		"Cheerful":
			return globals.load_file_as_string("res://scripts/companion/prompts/cheerful.txt")
		"Sassy":
			return globals.load_file_as_string("res://scripts/companion/prompts/sassy.txt")
		"Shy":
			return globals.load_file_as_string("res://scripts/companion/prompts/shy.txt")
		_:
			return

func delete_ai_personality():
	await globals.delete_file("user://companion/chatlog.json")
	await globals.delete_file("user://companion/user_notes.txt")
	await globals.delete_file("user://companion/bot_notes.txt")
	if( await globals.delete_file("user://companion/basic_info.json") ):
		get_tree().change_scene_to_file("res://scenes/companion/companion_start.tscn")
	else:
		printerr("Could not delete file.")



func load_saved_chat():
	bot_thinking = true
	loading.texture = wait_status
	
	var file = FileAccess.open("user://companion/chatlog.json", FileAccess.READ)
	if(file.get_error() != OK):
		return
	chat_log = JSON.parse_string(file.get_as_text())
	
	#chat_memory = chat_json.get("chat_log")
	for msg in chat_log:
		if(msg.strip_edges().begins_with("<USER>")):
			var new_msg = message_box.instantiate()
			new_msg.get_node("message_box").size_flags_horizontal = Control.SIZE_SHRINK_END
			new_msg.get_node("message_box/vbox/msg").text = msg.strip_edges().trim_prefix("<USER> ")
			new_msg.get_node("message_box").self_modulate = globals.CURRENT_THEME.user_bubble
			chat_log_box.add_child(new_msg)
		else:
			var new_msg:MarginContainer = message_box.instantiate()
			new_msg.get_node("message_box").size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			new_msg.get_node("message_box/vbox/msg").text = msg.strip_edges()
			new_msg.get_node("message_box").self_modulate = globals.CURRENT_THEME.bot_bubble
			chat_log_box.add_child(new_msg)
	
	await get_tree().process_frame
	await get_tree().process_frame
	chat_scroll.scroll_vertical = chat_scroll.get_v_scroll_bar().max_value
	
	bot_thinking = false
	loading.texture = good_status
