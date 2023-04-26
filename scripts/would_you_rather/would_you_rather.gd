extends PanelContainer
var openai:OpenAIAPI
var bot_thinking:bool = false

@onready var ai_question = $vbox/hbox/pcon/vbox/ai_question
@onready var generate_button = $vbox/hbox/pcon/vbox/generate_button
@onready var option_1_button = $vbox/hbox/pcon/vbox/hbox/option_1_button
@onready var option_1_text = $vbox/hbox/pcon/vbox/hbox/option_1_button/option_1_text
@onready var option_2_button = $vbox/hbox/pcon/vbox/hbox/option_2_button
@onready var option_2_text = $vbox/hbox/pcon/vbox/hbox/option_2_button/option_2_text


@onready var loading = $vbox/hcon/loading
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


var previous_questions:PackedStringArray = []
const question_categories:PackedStringArray = [
	"Pop Culture",
	"Space",
	"Nature",
	"City Living",
	"Food",
	"Drinks",
	"Challenges",
	"Sport",
	"Video Games",
	"Dating",
	"Relationships",
	"Movies",
	"TV Shows",
	"Social Media",
	"Fashion",
	"Superpowers",
	"Politics",
	"Erotic",
	"Mature Content",
	"Apocalypse",
	"Science",
	"Fantasy",
	"Superhero",
	"Supervillan",
	"Drugs",
	"Alcohol",
	"Technology",
	"AI",
	"Animals",
	"Counties",
	"Vacation",
	"Ocean",
	"Weather",
	"People",
	"Music",
	"Money",
	"Personality",
	"Apperance",
	"Makeup",
	"Disease",
	"Being Famous"
]

func _ready():
	self.tree_exiting.connect(func(): openai.queue_free())
	bot_thinking = true
	loading.texture = wait_status
	generate_button.pressed.connect(generate_wyr)
#	option_1_button.gui_input.connect(_option_1_gui)
#	option_2_button.gui_input.connect(_option_2_gui)
	
	ai_question.text = "Click the 'Next Question' button to begin!"
	
	await connect_openai()
	bot_thinking = false
	loading.texture = good_status


#func _option_1_gui(event:InputEvent)->void:
#	if event is InputEventMouseButton:
#		if event.button_index == MOUSE_BUTTON_LEFT:
#			if event.pressed:
#				print("Button was pressed!")
#
#func _option_2_gui(event:InputEvent)->void:
#	if event is InputEventMouseButton:
#		if event.button_index == MOUSE_BUTTON_LEFT:
#			if event.pressed:
#				print("Button was pressed!")


func connect_openai():
	await get_tree().process_frame
	openai = OpenAIAPI.new(get_tree(), "https://api.openai.com/v1/chat/", globals.API_KEY)
	openai.connect("request_success", _on_openai_request_success)
	openai.connect("request_error", _on_openai_request_error)


func generate_wyr():
	if(bot_thinking):
		return
	
	ai_question.text = "Generating question..."
	
	bot_thinking = true
	wait_thread = Thread.new()
	wait_thread.start(wait_blink)
	generate_button.disabled = true
	
	var chat_array:Array = []
	
	chat_array.append({"role": "system", "content": globals.load_file_as_string("res://scripts/would_you_rather/wyr_rules.txt")})
	chat_array.append({"role": "system", "content": "\nQuestion category is "+question_categories[randi_range(0, question_categories.size()-1)]})
	
	if(!previous_questions.is_empty()):
		chat_array.append({"role": "system", "content": "\nBelow are some previous questions you asked. Avoid repeating these questions:"})
		for q in previous_questions:
			chat_array.append({"role": "assistant", "content": "\n"+q})
	if(previous_questions.size()>10):
		previous_questions.remove_at(0)
	
	
	print(chat_array)
	var data = {
	"model": globals.AI_MODEL,
	"messages": chat_array,
	"temperature": 1.1,
	"presence_penalty": 0.0,
	"frequency_penalty": 0.0,
	"stream": false,
	"logit_bias": logit_bias
	}
	
	openai.make_request("completions", HTTPClient.METHOD_POST, data, 20.0)

func _on_openai_request_success(data):
	#print(data)
	globals.TOTAL_TOKENS_USED += data.usage.total_tokens
	globals.TOTAL_TOKENS_COST += (data.usage.prompt_tokens*globals.INPUT_TOKENS_COST) + (data.usage.completion_tokens*globals.TOKENS_COST)
	
	var res:PackedStringArray = data.choices[0].message.content.split("\n")
	var correct_format:int = 0
	for i in res.size():
		print(res[i])
		if(res[i].to_lower().strip_edges().begins_with("[question]")):
			ai_question.text = res[i].strip_edges().trim_prefix("[question]")
			previous_questions.append(ai_question.text)
			correct_format += 1
		if(res[i].to_lower().strip_edges().begins_with("[option1]")):
			option_1_text.text = res[i].strip_edges().trim_prefix("[option1]")
			correct_format += 1
		if(res[i].to_lower().strip_edges().begins_with("[option2]")):
			option_2_text.text = res[i].strip_edges().trim_prefix("[option2]")
			correct_format += 1
	
	if(correct_format != 3):
		ai_question.text = "<Incorrect format generated. Try Again.>"
		option_1_text.text = ""
		option_2_text.text = ""
	
	
	bot_thinking = false
	loading.texture = good_status
	
	generate_button.disabled = false

func _on_openai_request_error(error_code):
	printerr("Request failed with error code:", error_code)
	ai_question.text = globals.parse_api_error(error_code)
	
	bot_thinking = false
	loading.texture = bad_status
	
	generate_button.disabled = false

var wait_thread:Thread = Thread.new()
func wait_blink():
	while bot_thinking && !globals.EXIT_THREAD:
		loading.texture = wait_status
		await globals.delay(0.5)
		if(!bot_thinking || globals.EXIT_THREAD):
			print("EXIT")
			globals.EXIT_THREAD = false
			return
		loading.texture = nil_status
		await globals.delay(0.5)
