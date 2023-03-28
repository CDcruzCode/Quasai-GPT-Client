extends PanelContainer
var openai:OpenAIAPI
var bot_thinking:bool = false

@onready var translate_button = $vbox/hcon/translate_button
@onready var og_language_button = $vbox/hsplit/vbox/hbox/og_language_button
@onready var translated_language_button = $vbox/hsplit/vbox2/hbox/translated_language_button
@onready var text_input = $vbox/hsplit/vbox/text_input
@onready var text_display = $vbox/hsplit/vbox2/text_display
@onready var copy_output_button = $vbox/hcon/copy_output_button

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

var supported_languages:PackedStringArray = [
	"Afrikaans",
	"Arabic - عربي",
	"Chinese Simplified - 简体中文",
	"Chinese Traditional - 繁体中文",
	"English",
	"French - Français",
	"German - Deutsch",
	"Hindi - हिन्दी",
	"Japanese - 日本語",
	"Korean - 한국인",
	"Malay - Bahasa Melayu",
	"Spanish - Español",
	"Tamil - தமிழ்",
]

var fun_languages:PackedStringArray = [
	"Aussie - Australian",
	"Binary - 01000010",
	"Hexadecimal - 68 69",
	"Pirate Speak",
	"Shakespearean",
	"UwU Furryspeak"
]

func _ready():
	self.tree_exiting.connect(func(): openai.queue_free())
	bot_thinking = true
	loading.texture = wait_status
	copy_output_button.pressed.connect(copy_output)
	
	text_display.text = ""
	og_language_button.add_item("Detect")
	for l in supported_languages:
		og_language_button.add_item(l)
		translated_language_button.add_item(l)
	
	og_language_button.add_separator("Fun Languages")
	translated_language_button.add_separator("Fun Languages")
	for l in fun_languages:
		og_language_button.add_item(l)
		translated_language_button.add_item(l)
	
	translate_button.pressed.connect(translate_text)
	
	await connect_openai()
	bot_thinking = false
	loading.texture = good_status

func copy_output():
	if(bot_thinking):
		return
	if(text_display.text.strip_edges().strip_escapes().is_empty() || text_display.text == "Awaiting response..."):
		return
	DisplayServer.clipboard_set(text_display.text)

func translate_text():
	if(bot_thinking || text_input.text.strip_edges().is_empty()):
		return
	
	bot_thinking = true
	wait_blink()
	text_display.text = "Awaiting response..."
	
	var chat_array:Array = []
	
	chat_array.append({"role": "system", "content": globals.load_file_as_string("res://scripts/translator/translator_rules.txt")})
	if(og_language_button.get_item_text(og_language_button.selected) == "Detect"):
		chat_array.append({"role": "system", "content": "\nFigure out what the original texts' language is."})
	else:
		chat_array.append({"role": "system", "content": "\nThe input text is in the language:" + og_language_button.get_item_text(og_language_button.selected)})
	chat_array.append({"role": "system", "content": "\nThe language to translate the original text to is:" + translated_language_button.get_item_text(translated_language_button.selected)})
	chat_array.append({"role": "user", "content": text_input.text})
	
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
#	session_tokens += data.usage.total_tokens
#	token_display.text = "Session Tokens: "+str(session_tokens)+" | Est. Cost: $"+str(session_tokens*globals.TOKENS_COST)
#	bot_thinking =false
	
	text_display.text = data.choices[0].message.content
	
	bot_thinking = false
	loading.texture = good_status

func _on_openai_request_error(error_code):
	printerr("Request failed with error code:", error_code)
	text_display.text = globals.parse_api_error(error_code)
	bot_thinking = false
	loading.texture = bad_status
#	generate_button.disabled = false
#	instructions_display.text = globals.parse_api_error(error_code)


var wait_thread:Thread = Thread.new()
func wait_blink():
	while bot_thinking:
		loading.texture = wait_status
		await globals.delay(0.5)
		if(!bot_thinking):
			return
		loading.texture = nil_status
		await globals.delay(0.5)
