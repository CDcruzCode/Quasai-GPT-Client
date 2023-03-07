extends PanelContainer
@onready var writing_style_option = $vbox/hcon/writing_style_option
@onready var proofread_button = $vbox/hcon/proofread_button
@onready var home_button = $vbox/hcon/home_button

@onready var text_input = $vbox/vsplit/hsplit/text_input
@onready var text_display = $vbox/vsplit/hsplit/text_display
@onready var changes_paragraph = $vbox/vsplit/vbox/changes_paragraph

var openai:OpenAIAPI
var logit_bias:Dictionary = {
	20185: -50, #AI
	3303: -80, #language
	2746: -80, #model
	562: -20, #ass
	10167: -80 #istant
}

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()
		return

func _ready():
	text_display.text = ""
	changes_paragraph.text = ""
	
	writing_style_option.add_item("Maintain Original Style")
	writing_style_option.add_item("Neutral")
	writing_style_option.add_item("Casual")
	writing_style_option.add_item("Corporate")
	writing_style_option.add_item("Romantic")
	
	proofread_button.pressed.connect(proofread_text)
	text_display.gui_input.connect(copy_output)
	home_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/start_screen/start_screen.tscn"))
	
	connect_openai()


func proofread_text():
	text_display.text = "Awaiting response..."
	changes_paragraph.text = ""
	var chat_array:Array = []
	match writing_style_option.get_item_text(writing_style_option.selected):
		"Neutral":
			chat_array.append({"role": "system", "content": globals.load_file_as_string("res://scripts/internal_prompts/proofreader_prompts/neutral.txt")})
		"Casual":
			chat_array.append({"role": "system", "content": globals.load_file_as_string("res://scripts/internal_prompts/proofreader_prompts/casual.txt")})
		_:
			chat_array.append({"role": "system", "content": globals.load_file_as_string("res://scripts/internal_prompts/proofreader_prompts/maintain.txt")})
	
	chat_array.append({"role": "user", "content": text_input.text})
	print(chat_array)
	var data = {
	"model": "gpt-3.5-turbo",
	"messages": chat_array,
	"temperature": 1.0,
	"presence_penalty": 0.0,
	"frequency_penalty": 0.0,
	"stream": false,
	"logit_bias": logit_bias
	}
	
	openai.make_request("completions", HTTPClient.METHOD_POST, data)

func copy_output(event:InputEvent):
	if event.is_pressed():
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
	var text:PackedStringArray = data.choices[0].message.content.split(":CHANGES:", false, 1)
	text_display.text = text[0].strip_edges()
	if(text.size() > 1):
		changes_paragraph.text = text[1].strip_edges()
	else:
		changes_paragraph.text = "<No change information provided>"

func _on_openai_request_error(error_code):
	printerr("Request failed with error code:", error_code)
	text_display.text = globals.parse_api_error(error_code)
