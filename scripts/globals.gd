extends Node

const VERSION:String = "0.2.0"
var EXIT_THREAD:bool = false
var EXIT_HTTP:bool = false

var API_KEY:String
var THEME:String = "Default"

var API_KEY_ELEVENLABS:String
var SELECTED_VOICE:String = "21m00Tcm4TlvDq8ikWAM"
var VOICE_ALWAYS_ON:bool = false

var INPUT_TOKENS_COST:float = 0.000002 #PROMPT TOKENS COST
var TOKENS_COST:float = 0.000002 #COMPLETION TOKENS COST
var AI_MODEL:String = "gpt-3.5-turbo"
var TOTAL_TOKENS_USED:int = 0
var TOTAL_TOKENS_COST:float = 0.0

const TEXT_EXTENSIONS:PackedStringArray = [
	"txt"
]

const SCRIPT_EXTENSIONS:PackedStringArray = [
	"js",
	"gd",
	"c",
	"cpp",
	"cs",
	"ts",
	"txt",
	"json",
	"py",
	"rs",
	"rlib"
]


#########################
#CODE SNIPPETS
#########################
func set_new_theme():
	if(load_file_as_string("user://themes/"+THEME+".tres") != "error"):
		get_tree().root.theme = load("user://themes/"+THEME+".tres")
		print("Loaded theme: " + "user://themes/"+THEME+".tres")
		return
	
	printerr("Could not load theme: " + "user://themes/"+THEME+".tres")
	globals.THEME = "Default"
	get_tree().root.theme = load("res://themes/main_themes/Default.tres")



func save_text_file(filepath, content):
	var file = FileAccess.open(filepath, FileAccess.WRITE);
	if file != null:
		file.store_string(content)
		file = null
		return true
	else:
		return false

func load_file_as_string(path)->String:
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

func delete_file(path: String) -> bool:
	var file:DirAccess = DirAccess.open("user://")
	if file.file_exists(path):
		file.remove(path)
		print("File deleted:", path)
		return true
	else:
		print("File does not exist:", path)
		return false

func save_file(path: String, data: String) -> bool:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(data)
		file.close()
		print("data saved to file:", path)
		return true
	else:
		print("Failed to open file for writing:", path)
		return false


func delete_all_children(node):
	for n in node.get_children():
		n.queue_free()

func remove_after_phrase(my_string:String, phrase:String):
	var position = my_string.find(phrase);

	if (position != -1):
		return my_string.left(position);
	
	return my_string

func delay(time:float):
	await get_tree().create_timer(time).timeout

func set_button_by_text(option_button:OptionButton, text:String):
	for i in range(option_button.get_item_count()):
		var item_text = option_button.get_item_text(i)
		if item_text == text:
			option_button.select(i)
			return
	
	option_button.select(0)


func clear_apis(openai:OpenAIAPI = null, elevenlabs:ElevenLabsAPI = null):
	if(openai != null):
		openai.queue_free()
	if(elevenlabs != null): 
		elevenlabs.queue_free()

var parse_voice_list:Array = [
	["[inlinecode]",""],
	["[/inlinecode]",""],
	["[b]", ""],
	["[/b]", ""],
	["=", "equals"],
	[">", ""],
	["<", ""],
	["{", ""],
	["}", ""],
	["[", ""],
	["]", ""],
	[":", ""],
	[";", ""],
	["~", ""],
	["*", ""]
]
func parse_voice_message(msg:String) -> String:
	msg = remove_regex(msg, "<.*?>") #Removes any words surrounded by angle brackets <like this> from the voice message.
	
	for p in parse_voice_list:
		msg = msg.replace(p[0], p[1])
	
	msg = msg.to_ascii_buffer().get_string_from_ascii() #Using this to remove emoji's from message.
	print("[parse_voice_message] OUTPUT: " + msg)
	return msg

# Define the function
func number_suffix(num:int) -> String:
	var lastDigit:int = num % 10
	if lastDigit == 1 and num != 11:
		return str(num) + "st"
	elif lastDigit == 2 and num != 12:
		return str(num) + "nd"
	elif lastDigit == 3 and num != 13:
		return str(num) + "rd"
	else:
		return str(num) + "th"


func remove_regex(text: String, regex_string: String) -> String:
	var regex = RegEx.new()
	regex.compile(regex_string)
	return regex.sub(text, "", true)


func replace_with_bbcode(text: String, o_char:String, bbcode:String) -> String:
	var is_code_block = false
	var replaced_text = ""
	for i in text.length():
		var chara = text[i]
		if chara == o_char:
			is_code_block = !is_code_block
			if is_code_block:
				replaced_text += "["+bbcode+"]"
			else:
				replaced_text += "[/"+bbcode+"]"
		else:
			replaced_text += chara
	return replaced_text


func parse_api_error(error_code:int, short_err:bool = false):
	if(short_err):
		match error_code:
			401:
				return "Invalid API Key"
			400:
				return "Program Issues"
			429:
				return "API Key Issues"
			500:
				return "Server Issues"
			0:
				return "Request timeout"
			_:
				return "Unknown error: " + str(error_code)
	else:
		match error_code:
			401:
				return "Error: " + str(error_code) + " - Invalid API key. Make sure you typed or copied it correctly."
			400:
				return "Error: " + str(error_code) + " - Something was wrong with connecting to the servers. It may be an API Key issue or a program issue..."
			429:
				return "Error: " + str(error_code) + " - OpenAI servers are experiencing high traffic or you have exceeded your quota, check your billing details."
			500:
				return "Error: " + str(error_code) + " - OpenAI servers are experiencing some issues."
			0:
				return "Error: " + str(error_code) + " - Request timed out. Server took too long to respond."
			_:
				return "Unknown error: " + str(error_code)


var tokenizer_script = preload("res://scripts/tokenizer/tokenizer.cs")
var token_api = tokenizer_script.new()
func token_estimate(text:String) -> int:
	var model:String
	match(AI_MODEL):
		"gpt-3.5-turbo":
			model = "gpt-3"
		"gpt-4", "gpt-4-32k":
			model = "gpt-4"
		_:
			model = "gpt-3"
	
	var string_encoded:String = token_api.call("token_encoder", text, model)
	var string_split:PackedStringArray = string_encoded.split(",")
	return string_split.size()

func max_model_tokens() -> int:
	match(AI_MODEL):
		"gpt-3.5-turbo":
			return 4096
		"gpt-4":
			return 8192
		"gpt-4-32k":
			return 32768
		_:
			return 4096
