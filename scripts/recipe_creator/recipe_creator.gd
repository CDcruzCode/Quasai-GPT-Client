extends PanelContainer

@onready var ingredients_con = $VBoxContainer/hsplit/ingredients_con
@onready var ingredients_display = $VBoxContainer/hsplit/ingredients_con/vbox/ingredients_display
@onready var instructions_display = $VBoxContainer/hsplit/instructions_box/vbox/instructions_display
@onready var writing_style_options = $VBoxContainer/hbox3/writing_style_options
@onready var metric_toggle = $VBoxContainer/hbox3/metric_toggle
@onready var vegan_toggle = $VBoxContainer/hbox3/vegan_toggle

@onready var user_input = $VBoxContainer/hbox/input_con/VBoxContainer/user_input
@onready var serving_size = $VBoxContainer/hbox/input_con2/VBoxContainer/serving_size
@onready var generate_button = $VBoxContainer/hbox/generate_button
@onready var copy_ingredients = $VBoxContainer/hsplit/ingredients_con/vbox/hbox/copy_ingredients
@onready var copy_instructions = $VBoxContainer/hsplit/instructions_box/vbox/hbox/copy_instructions

@onready var save_button = $VBoxContainer/hbox3/save_button
@onready var save_dialog:FileDialog = $save_dialog

@onready var loading = $VBoxContainer/hbox3/loading
@onready var bad_status = preload("res://images/icons/bad_status.png")
@onready var good_status = preload("res://images/icons/good_status.png")
@onready var wait_status = preload("res://images/icons/wait_status.png")
@onready var nil_status = preload("res://images/icons/nil_status.png")

@onready var token_display = $VBoxContainer/hbox2/token_display

var bot_thinking:bool = false
var session_tokens:int = 0
var session_cost:float = 0.0
var openai:OpenAIAPI
var logit_bias:Dictionary = {
	20185: -50, #AI
	3303: -80, #language
	2746: -80, #model
	562: -20, #ass
	10167: -80, #istant
	43993: -100,
	1268: -100,
	41222: -100
}

func _ready():
	self.tree_exiting.connect(func(): openai.queue_free())
	loading.texture = wait_status
	
	generate_button.pressed.connect(generate_recipe)
	user_input.gui_input.connect(user_gui)
	save_button.pressed.connect(func(): save_dialog.popup_centered(Vector2i(700, 500)))
	save_dialog.hide()
	save_dialog.add_filter("*.txt")
	save_dialog.file_selected.connect(export_to_txt)
	
	copy_ingredients.pressed.connect(func(): copy_output(true))
	copy_instructions.pressed.connect(func(): copy_output(false))
	
	token_display.text = "Session Tokens: 0 | Est. Cost: $0.0"
	
	writing_style_options.add_item("Basic")
	writing_style_options.add_item("ELI5 - Detailed")
	writing_style_options.add_item("Restaurant Style - Expensive")
	writing_style_options.add_item("Homemade Style - From Scratch")
	writing_style_options.add_item("Fast & Cheap")
	
	await connect_openai()
	bot_thinking = false
	loading.texture = good_status

func user_gui(event:InputEvent):
	if event is InputEventKey && event.keycode == KEY_ENTER && event.pressed:
		generate_recipe()

func copy_output(box:bool):
	if(bot_thinking):
		return
	if(instructions_display.text.strip_edges().strip_escapes().is_empty() || instructions_display.text == "Awaiting response..." || instructions_display.text == "<Failed to generate instructions, try again>"):
		return
	
	if(box):
		DisplayServer.clipboard_set(ingredients_display.text)
	else:
		DisplayServer.clipboard_set(instructions_display.text)



func writing_style():
	match writing_style_options.get_item_text(writing_style_options.selected):
		"ELI5 - Detailed":
			return {"role": "system", "content": globals.load_file_as_string("res://scripts/recipe_creator/eli5.txt")}
		"Restaurant Style - Expensive":
			return {"role": "system", "content": globals.load_file_as_string("res://scripts/recipe_creator/restaurant.txt")}
		"Homemade Style - From Scratch":
			return {"role": "system", "content": globals.load_file_as_string("res://scripts/recipe_creator/homemade.txt")}
		"Fast & Cheap":
			return {"role": "system", "content": globals.load_file_as_string("res://scripts/recipe_creator/fast.txt")}
		_: #BASIC
			return {"role": "system", "content": ""}



func generate_recipe():
	if(bot_thinking):
		return
	bot_thinking = true
	generate_button.disabled = true
	wait_thread = Thread.new()
	wait_thread.start(wait_blink)
	
	instructions_display.text = "Awaiting response..."
	ingredients_display.text = ""
	var chat_array:Array = []
	
	chat_array.append({"role": "system", "content": globals.load_file_as_string("res://scripts/recipe_creator/main.txt")})
	
	if(metric_toggle.button_pressed):
		chat_array.append({"role": "system", "content": "You will provide all measurements in metric and celcius. Use British English terms when explaining instructions and ingredients."})
	else:
		chat_array.append({"role": "system", "content": "You will provide all measurements in imperial and fahrenheit. Use American English terms when explaining instructions and ingredients."})
	
	chat_array.append({"role": "user", "content": user_input.text + "\nFor " + str(serving_size.value) + " servings.\n"})
	
	chat_array.append(writing_style())
	
	if(vegan_toggle.button_pressed):
		chat_array.append({"role": "user", "content": "the following recipe must be vegan friendly and must not contain any meat based products."})
	
	print(chat_array)
	var data = {
	"model": globals.AI_MODEL,
	"messages": chat_array,
	"temperature": 0.3,
	"presence_penalty": 0.0,
	"frequency_penalty": 0.0,
	"stream": false,
	"logit_bias": logit_bias
	}
	
	openai.make_request("completions", HTTPClient.METHOD_POST, data)




func connect_openai():
	await get_tree().process_frame
	openai = await OpenAIAPI.new(get_tree(), "https://api.openai.com/v1/chat/", globals.API_KEY)
	openai.connect("request_success", _on_openai_request_success)
	openai.connect("request_error", _on_openai_request_error)

func _on_openai_request_success(data):
	print(data)
	globals.TOTAL_TOKENS_USED += data.usage.total_tokens
	globals.TOTAL_TOKENS_COST += (data.usage.prompt_tokens*globals.INPUT_TOKENS_COST) + (data.usage.completion_tokens*globals.TOKENS_COST)
	session_tokens += data.usage.total_tokens
	session_cost += (data.usage.prompt_tokens*globals.INPUT_TOKENS_COST) + (data.usage.completion_tokens*globals.TOKENS_COST)
	token_display.text = "Session Tokens: "+str(session_tokens)+" | Est. Cost: $"+str(session_cost)
	bot_thinking =false
	loading.texture = good_status
	
	var result:PackedStringArray = data.choices[0].message.content.split("[instructions]", false, 1)
	
	generate_button.disabled = false
	if(result.size() > 1):
		ingredients_display.text = result[0].strip_edges().trim_prefix("[ingredients]").trim_prefix("[Ingredients]").strip_edges()
		instructions_display.text = result[1].strip_edges().trim_prefix("[instructions]").trim_prefix("[Instructions]").strip_edges()
		return
	
	result = data.choices[0].message.content.split("[Instructions]", false, 1)
	if(result.size() > 1):
		ingredients_display.text = result[0].strip_edges().trim_prefix("[Ingredients]").trim_prefix("[ingredients]").strip_edges()
		instructions_display.text = result[1].strip_edges().trim_prefix("[Instructions]").trim_prefix("[instructions]").strip_edges()
		return
	else:
		instructions_display.text = "<Failed to generate instructions, try again>"
		return

func _on_openai_request_error(error_code):
	bot_thinking = false
	printerr("Request failed with error code:", error_code)
	generate_button.disabled = false
	instructions_display.text = globals.parse_api_error(error_code)
	loading.texture = bad_status
	wait_thread.wait_to_finish()





func export_to_txt(path:String):
	print(path)
	if(user_input.text.is_empty() || ingredients_display.text.is_empty() || instructions_display.text.is_empty()):
		printerr("Cannot save recipe as text inputs are empty.")
		return
	
	var full_doc:String = ""
	full_doc += user_input.text.to_upper() + "\nA recipe generated by GPT Playground\n"
	full_doc += "Serving Size: " + str(serving_size.value) + "\n\n"
	full_doc += "[Ingredients]\n\n" + ingredients_display.text + "\n\n"
	full_doc += "[Instructions]\n\n" + instructions_display.text
	
	globals.save_text_file(path, full_doc)


var wait_thread:Thread = Thread.new()
func wait_blink():
	while bot_thinking:
		loading.texture = wait_status
		await globals.delay(0.5)
		if(!bot_thinking):
			return
		loading.texture = nil_status
		await globals.delay(0.5)
