extends PanelContainer
var tokenizer_script = preload("res://scripts/tokenizer/tokenizer.cs")
var token_api = tokenizer_script.new()
var token_element = preload("res://scenes/tokenizer/token_element.tscn")

@onready var home_button = $vbox/hbox/home_button
@onready var user_input = $vbox/hbox2/input_con/vbox/user_input
@onready var tokenize_button = $vbox/hbox2/tokenize_button
@onready var tokens_list = $vbox/PanelContainer/hsplit/scon/tokens_list
@onready var convert_button = $vbox/hbox3/convert_button
@onready var array_display = $vbox/PanelContainer/hsplit/pcon/vcon/array_display
@onready var copy_button = $vbox/PanelContainer/hsplit/pcon/vcon/hbox/copy_button


var tokens_array:Array = []

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()
		return

func _ready():
	tokenize_button.pressed.connect(tokenize_string)
	convert_button.pressed.connect(convert_tokens)
	copy_button.pressed.connect(copy_output)
	#print( token_api.call("text", "January 1st, 2000") )

func copy_output():
	if(array_display.text.strip_edges().strip_escapes().is_empty()):
		return
	DisplayServer.clipboard_set(array_display.text)


func tokenize_string():
	globals.delete_all_children(tokens_list)
	array_display.text = ""
	var user_string:String = user_input.text.strip_edges().strip_escapes()
	var user_array:PackedStringArray = user_string.split(",")
	
	tokens_array = []
	
	for txt in user_array:
		var current_txt:String = txt.strip_edges().strip_escapes()
		if(current_txt.is_empty()):
			continue
		
		var string_encoded:String = token_api.call("token_encoder", current_txt)
		var string_split:PackedStringArray = string_encoded.split(",")
		var int_encoded:Array = []
		for s in string_split:
			int_encoded.append(int(s))
		
		tokens_array.append( int_encoded )
	
	print(tokens_array)
	for e in range(tokens_array.size()):
		var token_elem = token_element.instantiate()
		token_elem.get_node("hbox/token_text").text = user_array[e]
		tokens_list.add_child(token_elem)

func convert_tokens():
	var full_dictionary:Dictionary = {}
	for t in range(tokens_array.size()):
		print( tokens_list.get_child(t) )
		var bias:int = tokens_list.get_child(t).get_node("hbox/bias_value").value
		for token_row in tokens_array[t]:
			full_dictionary[token_row] = bias
	
	array_display.text = JSON.stringify(full_dictionary).replace("\"","")
	print(full_dictionary)
