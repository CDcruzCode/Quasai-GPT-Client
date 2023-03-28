extends PanelContainer
var openai:OpenAIAPI
var openai_item:OpenAIAPI
var bot_thinking:bool = false

@onready var meal_item:PackedScene = preload("res://scenes/meal_planner/meal_item.tscn")
@onready var generate_button:Button = $vbox/hbox/vbox/generate_button
@onready var lifestyle_options = $vbox/hbox/info_inputs/vbox/hbox/lifestyle_options
@onready var age_value = $vbox/hbox/info_inputs/vbox/hbox/age_value
@onready var sex_toggle = $vbox/hbox/info_inputs/vbox/hbox/sex_toggle
@onready var allergies_input = $vbox/hbox/info_inputs/vbox/HBoxContainer/allergies_input
@onready var diet_options = $vbox/diet_inputs/vbox/hbox/diet_options
@onready var gluten_check = $vbox/diet_inputs/vbox/hbox/gluten_check
@onready var lactose_check = $vbox/diet_inputs/vbox/hbox/lactose_check
@onready var kosher_check = $vbox/diet_inputs/vbox/hbox/kosher_check
@onready var plan_display = $vbox/plan_con/scon/plan_display
@onready var plan_reason_options = $vbox/diet_inputs/vbox/hbox/plan_reason_options

@onready var save_button = $vbox/meal_header/vbox/save_button
@onready var save_dialog = $save_dialog

@onready var loading = $vbox/hbox/vbox/loading
@onready var bad_status = preload("res://images/icons/bad_status.png")
@onready var good_status = preload("res://images/icons/good_status.png")
@onready var wait_status = preload("res://images/icons/wait_status.png")
@onready var nil_status = preload("res://images/icons/nil_status.png")

var logit_bias:Dictionary = {
	20185: -50, #AI
	3303: -80, #language
	2746: -80, #model
	562: -20, #ass
	10167: -80, #istant
}

func _ready():
	self.tree_exiting.connect(func(): openai.queue_free(); openai_item.queue_free())
	bot_thinking = true
	loading.texture = wait_status
	
	save_button.pressed.connect(func(): save_dialog.popup_centered(Vector2i(700, 500)))
	save_dialog.hide()
	save_dialog.add_filter("*.txt")
	save_dialog.file_selected.connect(export_to_txt)

	generate_button.pressed.connect(generate_mealplan)
	
	lifestyle_options.add_item("Active")
	lifestyle_options.add_item("Sedentary")
	lifestyle_options.add_item("Gym Junkie")
	lifestyle_options.add_item("Unhealthy")
	
	diet_options.add_item("Basic Diet")
	diet_options.add_item("American Diet")
	diet_options.add_item("French Diet")
	diet_options.add_item("Intermittent Fasting")
	diet_options.add_item("Indian Diet")
	diet_options.add_item("Italian Diet")
	diet_options.add_item("Japanese Diet")
	diet_options.add_item("Ketogenic Diet")
	diet_options.add_item("Low Carb Diet")
	diet_options.add_item("Low Fat Diet")
	diet_options.add_item("Mediterranean Diet")
	diet_options.add_item("Mexican Diet")
	diet_options.add_item("Paleo Diet")
	diet_options.add_item("Pescatarian Diet")
	diet_options.add_item("Vegan Diet")
	diet_options.add_item("Vegetarian Diet")
	
	plan_reason_options.add_item("Maintain weight")
	plan_reason_options.add_item("Lose weight")
	plan_reason_options.add_item("Gain weight")
	plan_reason_options.add_item("Become leaner")
	
	
	await connect_openai()
	bot_thinking = false
	loading.texture = good_status


#func copy_output():
#	if(bot_thinking):
#		return
#	if(text_display.text.strip_edges().strip_escapes().is_empty() || text_display.text == "Awaiting response..."):
#		return
#	DisplayServer.clipboard_set(text_display.text + "\n" + text_display_2.text)

func connect_openai():
	await get_tree().process_frame
	openai = await OpenAIAPI.new(get_tree(), "https://api.openai.com/v1/chat/", globals.API_KEY)
	openai.connect("request_success", _on_openai_request_success)
	openai.connect("request_error", _on_openai_request_error)
	
	openai_item = await OpenAIAPI.new(get_tree(), "https://api.openai.com/v1/chat/", globals.API_KEY, "", "HTTP_MEAL_ITEM")
	openai_item.connect("request_success", _item_request_success)
	openai_item.connect("request_error", _item_request_error)


func generate_mealplan():
	if(bot_thinking):
		return
	
	bot_thinking = true
	generate_button.disabled = true
	wait_blink()
#	text_display.text = "Awaiting response..."
	globals.delete_all_children(plan_display)
	
	var box:Label = Label.new()
	box.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.text = "Awaiting response... Please be aware that meal plans take longer to generate due to the size of the message."
	plan_display.add_child(box)
	plan_display.columns = 1
	
	
	var chat_array:Array = []
	
	chat_array.append({"role": "system", "content": globals.load_file_as_string("res://scripts/meal_planner/planner_rules.txt")})
	chat_array.append({"role": "system", "content": "\nAll meals should provide the best nutrients for a person aged "+str(age_value.value)})
	var sex:String = "male"
	if(sex_toggle.button_pressed):
		sex = "female"
	chat_array.append({"role": "system", "content": "\nChoose meals that work best for a "+sex})
	chat_array.append({"role": "system", "content": "\nThe user's lifestyle is: "+lifestyle_options.get_item_text(lifestyle_options.selected)})
	chat_array.append({"role": "system", "content": "\nThe user's has the following allegies: "+allergies_input.text+"\nIt is very important to exclude the ingredients the user is allergic to."})
	chat_array.append({"role": "system", "content": "\nThe meal plan must follow a "+diet_options.get_item_text(diet_options.selected).trim_suffix(" Diet")+ " diet."})
	chat_array.append({"role": "system", "content": "\nThe goal for this meal plan is to help the user "+plan_reason_options.get_item_text(plan_reason_options.selected)})
	
	
	print(chat_array)
	var data = {
	"model": globals.AI_MODEL,
	"messages": chat_array,
	"temperature": 1.1,
	"presence_penalty": 0.0,
	"frequency_penalty": 0.0,
	"stop": ["Note:","note:"],
	"max_tokens": 1000,
	"stream": false,
	"logit_bias": logit_bias
	}
	
	openai.make_request("completions", HTTPClient.METHOD_POST, data, 80.0)



func _on_openai_request_success(data):
	globals.delete_all_children(plan_display)
	print(data)
	globals.TOTAL_TOKENS_USED += data.usage.total_tokens
	globals.TOTAL_TOKENS_COST += (data.usage.prompt_tokens*globals.INPUT_TOKENS_COST) + (data.usage.completion_tokens*globals.TOKENS_COST)
	
	#var remove_start:PackedStringArray = data.choices[0].message.content.strip_edges().split("|", false, 1)
	#print(remove_start[0])
	var prefix:String = data.choices[0].message.content.strip_edges().get_slice("|", 0)
	var split:PackedStringArray = data.choices[0].message.content.strip_edges().trim_prefix(prefix).replace("*","").replace("\r","").replace("\n\n","\n").split("\n", false)
	
	var r_count:int = 0
	var c_count:int = 0
	for r in split:
		c_count = 0
		if(r_count > 4):
			break
		
		for c in r.trim_prefix("|").strip_escapes().split("|", false):
			if(c.strip_edges().begins_with("-") || c.strip_edges().begins_with(":")):
				continue
			
			
			var box:PanelContainer = meal_item.instantiate()
			if(r_count == 0):
				box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
				box.get_node("mcon/vbox/meal_text").size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
				box.get_node("mcon/vbox/meal_text").size_flags_vertical = VERTICAL_ALIGNMENT_CENTER
				box.get_node("mcon/vbox/meal_text").autowrap_mode = TextServer.AUTOWRAP_OFF
			
			if(r_count == 0 || c_count == 0):
				box.set_script(null)
				box.get_node("mcon/vbox/hbox").queue_free()
				box.self_modulate = Color("#438221")
			else:
				if(r_count == 1):
					box.meal_type = "Breakfast"
				elif(r_count == 2):
					box.meal_type = "Lunch"
				else:
					box.meal_type = "Dinner"
				box.parent = self
				box.self_modulate = Color("#4D5057")
			
			box.get_node("mcon/vbox/meal_text").text = c.strip_edges().replace("<br>", "\n")
			plan_display.add_child(box)
			
			c_count += 1
		
		r_count += 1
	
	
	plan_display.columns = 8
	generate_button.disabled = false
	bot_thinking = false
	loading.texture = good_status
	
	if(plan_display.get_child_count() < 3):
		globals.delete_all_children(plan_display)
		plan_display.columns = 1
		var box:Label = Label.new()
		box.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.text = "The AI did not follow the correct format. Please try again."
		plan_display.add_child(box)

func _on_openai_request_error(error_code):
	generate_button.disabled = false
	printerr("Request failed with error code:", error_code)
	globals.delete_all_children(plan_display)
	var box:Label = Label.new()
	box.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.text = globals.parse_api_error(error_code)
	plan_display.add_child(box)
	plan_display.columns = 1
	bot_thinking = false
	loading.texture = bad_status

var wait_thread:Thread = Thread.new()
func wait_blink():
	while bot_thinking:
		loading.texture = wait_status
		await globals.delay(0.5)
		if(!bot_thinking):
			return
		loading.texture = nil_status
		await globals.delay(0.5)



var current_item:Node = null
func refresh_meal(item:Node):
	if(bot_thinking):
		return
	print("REFRESHING MEAL")
	bot_thinking = true
	generate_button.disabled = true
	wait_blink()
	current_item = item
	current_item.get_node("mcon/vbox/meal_text").text = "Generating a new meal..."
	current_item.self_modulate = Color("#26282B")
	
	var chat_array:Array = []
	
	chat_array.append({"role": "system", "content": globals.load_file_as_string("res://scripts/meal_planner/item_rules.txt")})
	chat_array.append({"role": "system", "content": "\nAll meals should provide the best nurients for a person aged "+str(age_value.value)})
	chat_array.append({"role": "system", "content": "\nThe user's has the following allegies: "+allergies_input.text+"\nIt is very important to exclude the ingredients the user is allergic to."})
	chat_array.append({"role": "system", "content": "\nThe meals must follow a "+diet_options.get_item_text(diet_options.selected).trim_suffix(" Diet")+ " diet."})
	chat_array.append({"role": "system", "content": "\nThis meal must be suitable for " + item.meal_type})
	
	print(chat_array)
	var data = {
	"model": globals.AI_MODEL,
	"messages": chat_array,
	"temperature": 1.1,
	"presence_penalty": 0.0,
	"frequency_penalty": 0.0,
	"stop": ["Note:","note:"],
	"max_tokens": 200,
	"stream": false,
	"logit_bias": logit_bias
	}
	
	openai_item.make_request("completions", HTTPClient.METHOD_POST, data, 40.0)


func _item_request_success(data):
	print(data)
	globals.TOTAL_TOKENS_USED += data.usage.total_tokens
	globals.TOTAL_TOKENS_COST += (data.usage.prompt_tokens*globals.INPUT_TOKENS_COST) + (data.usage.completion_tokens*globals.TOKENS_COST)
	
	current_item.self_modulate = Color("#4D5057")
	current_item.get_node("mcon/vbox/meal_text").text = data.choices[0].message.content.strip_edges()
	bot_thinking = false
	generate_button.disabled = false
	loading.texture = good_status

func _item_request_error(error_code):
	printerr("Request failed with error code:", error_code)
	current_item.self_modulate = Color("#4D5057")
	current_item.get_node("mcon/vbox/meal_text").text = globals.parse_api_error(error_code)
	bot_thinking = false
	generate_button.disabled = false
	loading.texture = bad_status






func export_to_txt(path:String):
	if(plan_display.get_child_count() < 3):
		printerr("Cannot save plan as text inputs are empty.")
		return
	
	var full_doc:String = ""
	full_doc += "A meal plan generated by GPT Playground\n\n"
	
	var child_arr:PackedStringArray = []
	for i in plan_display.get_children():
		child_arr.append(i.get_node("mcon/vbox/meal_text").text)
	var plan_array:Array = array_to_2d(child_arr, 8)

	var rows = transpose(plan_array)
	
	var r_count:int = 0
	var c_count:int = 0
	for r in rows:
		if(r_count == 0):
			r_count += 1
			continue
		
		c_count = 0
		for c in r:
			match(c_count):
				1: full_doc += "Breakfast: " + c + "\n"
				2: full_doc += "Lunch: " + c + "\n"
				3: full_doc += "Dinner: " + c + "\n"
				_: full_doc += c + "\n"
			c_count += 1
		
		full_doc += "\n\n"
		r_count += 1
	
	globals.save_text_file(path, full_doc)


func transpose(array):
	var transpose_array = []
	for i in range(array.size()):
		for j in range(array[i].size()):
			if j >= transpose_array.size():
				transpose_array.append([])
			transpose_array[j].append(array[i][j])
	return transpose_array

func array_to_2d(str_array: PackedStringArray, num_columns: int) -> Array:
	var result:Array = []
	var current_row:PackedStringArray = []
	
	for i in range(str_array.size()):
		current_row.append(str_array[i])
		
		if (i + 1) % num_columns == 0:
			result.append(current_row)
			current_row = []
	
	if current_row.size() > 0:
		result.append(current_row)
	
	return result
