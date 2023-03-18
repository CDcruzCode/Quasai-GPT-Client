extends PanelContainer
@onready var writing_style_option = $vbox/hcon/writing_style_option
@onready var proofread_button = $vbox/hcon/proofread_button
@onready var home_button = $vbox/hcon/home_button
@onready var copy_text_button = $vbox/hcon/copy_text_button
@onready var summarize_button = $vbox/hcon/summarize_button
@onready var sentiment_button = $vbox/hcon/sentiment_button
@onready var loading = $vbox/hcon/loading

@onready var text_input = $vbox/vsplit/hsplit/text_input
@onready var text_display = $vbox/vsplit/hsplit/text_display
@onready var changes_paragraph = $vbox/vsplit/vbox/changes_paragraph

@onready var token_estimation = $vbox/vsplit/vbox/hcon/token_estimation
@onready var session_tokens_display = $vbox/vsplit/vbox/hcon/session_tokens_display


@onready var bad_status = preload("res://images/icons/bad_status.png")
@onready var good_status = preload("res://images/icons/good_status.png")
@onready var wait_status = preload("res://images/icons/wait_status.png")
@onready var nil_status = preload("res://images/icons/nil_status.png")

var bot_thinking:bool = false
var session_tokens:int = 0
var session_cost:float = 0.0
var openai:OpenAIAPI
var logit_bias:Dictionary = {
	20185: -50, #AI
	3303: -80, #language
	2746: -80, #model
	562: -20, #ass
	10167: -80 #istant
}

func _ready():
	get_tree().get_root().files_dropped.connect(_files_dropped)
	bot_thinking = true
	text_display.text = ""
	changes_paragraph.text = ""
	token_estimation.text = "Token Estimation: 0 | "
	session_tokens_display.text = "Session Tokens: 0 | Est. Cost: $0.0"
	
	writing_style_option.add_item("Maintain Original Style")
	writing_style_option.add_separator("Professional Styles")
	writing_style_option.add_item("Neutral")
	writing_style_option.add_item("Corporate")
	writing_style_option.add_item("Advertisement")
	writing_style_option.add_item("Social Media Post")
	writing_style_option.add_item("Lawyer Speak")
	writing_style_option.add_item("Academic")
	writing_style_option.add_separator("Fun Styles")
	writing_style_option.add_item("Casual")
	writing_style_option.add_item("Pirate")
	writing_style_option.add_item("Sensual")
	writing_style_option.add_item("UwU Speak")
	
	proofread_button.pressed.connect(proofread_text)
	summarize_button.pressed.connect(summarize_text)
	sentiment_button.pressed.connect(sentiment_text)
	
	copy_text_button.pressed.connect(copy_output)
	text_input.text_changed.connect(func(): token_estimation.text = "Token Estimation: " + str((globals.token_estimate(text_input.text)*2)+200) + " | ")
	await connect_openai()
	bot_thinking = false
	loading.texture = good_status


func writing_styles():
	match writing_style_option.get_item_text(writing_style_option.selected):
		"Neutral":
			return {"role": "system", "content": globals.load_file_as_string("res://scripts/proofreader/proofreader_prompts/neutral.txt")}
		"Casual":
			return {"role": "system", "content": globals.load_file_as_string("res://scripts/proofreader/proofreader_prompts/casual.txt")}
		"Corporate":
			return {"role": "system", "content": globals.load_file_as_string("res://scripts/proofreader/proofreader_prompts/corporate.txt")}
		"Sensual":
			return {"role": "system", "content": globals.load_file_as_string("res://scripts/proofreader/proofreader_prompts/sensual.txt")}
		"Advertisement":
			return {"role": "system", "content": globals.load_file_as_string("res://scripts/proofreader/proofreader_prompts/advertisement.txt")}
		"Pirate":
			return {"role": "system", "content": globals.load_file_as_string("res://scripts/proofreader/proofreader_prompts/pirate.txt")}
		"Social Media Post":
			return {"role": "system", "content": globals.load_file_as_string("res://scripts/proofreader/proofreader_prompts/social.txt")}
		"Lawyer Speak":
			return {"role": "system", "content": globals.load_file_as_string("res://scripts/proofreader/proofreader_prompts/lawyer.txt")}
		"UwU Speak":
			return {"role": "system", "content": globals.load_file_as_string("res://scripts/proofreader/proofreader_prompts/uwu.txt")}
		"Academic":
			return {"role": "system", "content": globals.load_file_as_string("res://scripts/proofreader/proofreader_prompts/academic.txt")}
		_:
			return {"role": "system", "content": globals.load_file_as_string("res://scripts/proofreader/proofreader_prompts/maintain.txt")}

func proofread_text():
	if(bot_thinking):
		return
	bot_thinking = true
	wait_thread = Thread.new()
	wait_thread.start(wait_blink)
	text_display.text = "Awaiting response..."
	changes_paragraph.text = ""
	var chat_array:Array = []
	
	chat_array.append(writing_styles())
	if(writing_style_option.get_item_text(writing_style_option.selected) != "UwU Speak"):
		chat_array.append({"role": "system", "content": globals.load_file_as_string("res://scripts/proofreader/proofreader_prompts/rules.txt")})
	chat_array.append({"role": "system", "content": "\nBelow is the original text sent by the user."})
	chat_array.append({"role": "user", "content": text_input.text})
	print(chat_array)
	var data = {
	"model": globals.AI_MODEL,
	"messages": chat_array,
	"temperature": 1.0,
	"presence_penalty": 0.0,
	"frequency_penalty": 0.0,
	"stream": false,
	"logit_bias": logit_bias
	}
	
	openai.make_request("completions", HTTPClient.METHOD_POST, data)

func summarize_text():
	if(bot_thinking):
		return
	bot_thinking = true
	wait_thread = Thread.new()
	wait_thread.start(wait_blink)
	text_display.text = "Awaiting response..."
	changes_paragraph.text = ""
	var chat_array:Array = []
	chat_array.append({"role": "system", "content": globals.load_file_as_string("res://scripts/proofreader/proofreader_prompts/summarize.txt")})
	chat_array.append(writing_styles())
	
	chat_array.append({"role": "user", "content": text_input.text})
	print(chat_array)
	var data = {
	"model": globals.AI_MODEL,
	"max_tokens": 200,
	"messages": chat_array,
	"temperature": 0.8,
	"presence_penalty": 0.0,
	"frequency_penalty": 0.0,
	"stream": false,
	"logit_bias": logit_bias
	}
	
	openai.make_request("completions", HTTPClient.METHOD_POST, data)

func sentiment_text():
	if(bot_thinking):
		return
	bot_thinking = true
	wait_thread = Thread.new()
	wait_thread.start(wait_blink)
	text_display.text = "Awaiting response..."
	changes_paragraph.text = ""
	var chat_array:Array = []
	chat_array.append({"role": "system", "content": globals.load_file_as_string("res://scripts/proofreader/proofreader_prompts/sentiment_checker.txt")})
	
	chat_array.append({"role": "user", "content": text_input.text})
	print(chat_array)
	var data = {
	"model": globals.AI_MODEL,
	"max_tokens": 200,
	"messages": chat_array,
	"temperature": 0.8,
	"presence_penalty": 0.0,
	"frequency_penalty": 0.0,
	"stream": false,
	"logit_bias": logit_bias
	}
	
	openai.make_request("completions", HTTPClient.METHOD_POST, data)


func copy_output():
	if(bot_thinking):
		return
	if(text_display.text.strip_edges().strip_escapes().is_empty() || text_display.text == "Awaiting response..."):
		return
	DisplayServer.clipboard_set(text_display.text)



func connect_openai():
	await get_tree().process_frame
	openai = OpenAIAPI.new(get_tree(), "https://api.openai.com/v1/chat/", globals.API_KEY)
	#print("openai connected")
	openai.connect("request_success", _on_openai_request_success)
	openai.connect("request_error", _on_openai_request_error)

func _on_openai_request_success(data):
	print(data)
	globals.TOTAL_TOKENS_USED += data.usage.total_tokens
	globals.TOTAL_TOKENS_COST += (data.usage.prompt_tokens*globals.INPUT_TOKENS_COST) + (data.usage.completion_tokens*globals.TOKENS_COST)
	session_tokens += data.usage.total_tokens
	session_cost += (data.usage.prompt_tokens*globals.INPUT_TOKENS_COST) + (data.usage.completion_tokens*globals.TOKENS_COST)
	session_tokens_display.text = "Session Tokens: "+str(session_tokens)+" | Est. Cost: $"+str( session_cost )
	var text:PackedStringArray = data.choices[0].message.content.split("<changes>", false, 1)
	text_display.text = text[0].strip_edges()
	if(text.size() > 1):
		changes_paragraph.text = text[1].strip_edges()
	else:
		changes_paragraph.text = "<No change information provided>"
	bot_thinking =false
	loading.texture = good_status

func _on_openai_request_error(error_code):
	printerr("Request failed with error code:", error_code)
	text_display.text = globals.parse_api_error(error_code)
	bot_thinking =false
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




func _files_dropped(files):
	print(files)
	var start:bool = true
	for f in files:
		var file:String = f
		if( globals.TEXT_EXTENSIONS.has(file.get_extension()) ):
			if(start):
				text_input.text = ""
				start = false
			text_input.text += globals.load_file_as_string(file)
		else:
			printerr("Invalid file type dropped: " + file)
	token_estimation.text = "Token Estimation: " + str((globals.token_estimate(text_input.text)*2)+200) + " | "
