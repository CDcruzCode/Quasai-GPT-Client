extends Node

var API_KEY:String
const TOKENS_COST:float = 0.000002

var CURRENT_THEME:Dictionary = {
	"bg": "262730",
	"container": "353642",
	"banner": "1b1b22",
	"user_bubble": "1982c4",
	"bot_bubble": "E9006D",
	"button": "white"
}

#########################
#CODE SNIPPETS
#########################
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



func set_button_by_text(option_button:OptionButton, text:String):
	for i in range(option_button.get_item_count()):
		var item_text = option_button.get_item_text(i)
		if item_text == text:
			option_button.select(i)
			return
	
	option_button.select(0)


func parse_api_error(error_code:int):
	match error_code:
		401:
			return "Error: " + str(error_code) + " - Invalid API key. Make sure you typed or copied it correctly."
		400:
			return "Error: " + str(error_code) + " - Something was wrong with connecting to the servers. It could be a program issue..."
		429:
			return "Error: " + str(error_code) + " - OpenAI servers are experiencing high traffic or you have exeeced your quota, check your billing details."
		500:
			return "Error: " + str(error_code) + " - OpenAI servers are experiencing some issues."
		_:
			return "Unknown error: " + str(error_code)
