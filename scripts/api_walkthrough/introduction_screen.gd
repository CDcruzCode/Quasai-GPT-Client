extends PanelContainer
@onready var api_key_input = $mcon/vcon/api_key_input
@onready var api_error = $mcon/vcon/api_error
@onready var continue_button = $mcon/vcon/continue_button

var config = ConfigFile.new()
var openai:OpenAIAPI

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()
		return

func _ready():
	continue_button.disabled = false
	api_error.hide()
	api_key_input.editable = false
	await copy_prompts_folder()
	var dir = DirAccess.open("user://")
	dir.make_dir("user://saved_conversations")
	
	if(load_config()):
		get_tree().change_scene_to_file("res://scenes/start_screen.tscn")
	
	
	continue_button.pressed.connect(connect_openai)
	
	api_key_input.editable = true

func copy_prompts_folder():
	var file_list = globals.list_folders_in_directory("res://scripts/prompts")
	
	var dir = DirAccess.open("user://")
	var destination_folder_path = "user://prompts/"
	await get_tree().process_frame
	dir.make_dir("user://prompts")
	for f in file_list:
		dir.copy("res://scripts/prompts/"+f, destination_folder_path+f)
#		if success == OK:
#			print("Folder copied successfully!")
#		else:
#			print("Error copying folder.")


func load_config():
	var err = config.load("user://settings.cfg")
	if err != OK:
		printerr(err)
		return false
	return true

func save_config(data):
	print(data)
	config.set_value("Settings", "API_KEY", api_key_input.text.strip_edges())
	config.set_value("Settings", "MAX_TOKENS", 1000)
	config.set_value("Settings", "TEMPERATURE", 1.0)
	config.set_value("Settings", "PRESENCE", 0.0)
	config.set_value("Settings", "FREQUENCY", 0.0)
	config.save("user://settings.cfg")
	
	get_tree().change_scene_to_file("res://scenes/start_screen.tscn")

func connect_openai():
	if(api_key_input.text.strip_edges().is_empty()):
		api_error.text = "Error: API key input is empty."
		api_error.show()
		return
	
	continue_button.disabled = true
	await get_tree().process_frame
	openai = OpenAIAPI.new(get_tree(), "https://api.openai.com/v1/chat/", api_key_input.text.strip_edges())
	openai.request_success.connect(save_config)
	openai.request_error.connect(req_err)
	
	var data = {
	"model": "gpt-3.5-turbo",
	"messages": [{"role": "system", "content": "ping"}],
	"max_tokens": 1,
	"temperature": 0.0,
	"presence_penalty": 2.0,
	"frequency_penalty": 2.0,
	"stop": "",
	"stream": false
	}
	
	openai.make_request("completions", HTTPClient.METHOD_POST, data)

func req_err(error_code):
	continue_button.disabled = false
	api_error.show()
	match error_code:
		401:
			api_error.text = "Error: " + str(error_code) + " - Invalid API key. Make sure you typed or copied it correctly."
		400:
			api_error.text = "Error: " + str(error_code) + " - Something was wrong with connecting to the servers. It could be a program issue..."
		429:
			api_error.text = "Error: " + str(error_code) + " - OpenAI servers are experiencing high traffic or you have exeeced your quota, check your billing details."
		500:
			api_error.text = "Error: " + str(error_code) + " - OpenAI servers are experiencing some issues."
		_:
			api_error.text = "Unknown error: " + str(error_code)
