extends PanelContainer

@onready var home_button = $vbox/hcon/home_button
@onready var generate_button = $vbox/hbox/generate_button
@onready var token_display = $vbox/HBoxContainer/token_display
@onready var positive_display = $vbox/positive_con/vbox/positive_display
@onready var negative_display = $vbox/negative_con/vbox/negative_display
@onready var user_input = $vbox/hbox/input_con/VBoxContainer/user_input

@onready var copy_positive = $vbox/positive_con/vbox/hbox/copy_positive
@onready var copy_negative = $vbox/negative_con/vbox/hbox/copy_negative

var openai:OpenAIAPI
var bot_thinking:bool = false
var session_token_total = 0
var logit_bias:Dictionary = {
	20185: -50, #AI
	3303: -80, #language
	2746: -80, #model
	562: -20, #ass
	10167: -80, #istant,
	13: -100, #full stop
	25: -100, #colon
	26: -100, #;
	30: -100, #?
	9: -100, #*
	0: -100, #!
	31: -100, #@
	2: -100, #hashtag
	3: -100, #$
	4: -100, #%
	61: -100, #^
	5: -100, #&
	10: -100, #+
	28: -100, #=
	93: -100, #~
	63: -100, #`
	27: -100, #<
	29: -100, #>
	14: -100, #/
	91: -100, #|
	59: -100, #\
	58: -100, #open [ bracket
	60: -100, #close ] bracket
	7: -100, #open ( bracket
	8: -100, #close ) bracket
	1: -100, #"
	6: -100, #'
}

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()
		return


func _ready():
	generate_button.pressed.connect(generate_prompt)
	home_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/start_screen/start_screen.tscn"))
	user_input.gui_input.connect(user_gui)
	
	copy_positive.pressed.connect(func(): copy_text(true))
	copy_negative.pressed.connect(func(): copy_text(false))
	
	token_display.text = "Session Tokens: 0 | Est. Cost: $0.0"
	connect_openai()

func connect_openai():
	await get_tree().process_frame
	openai = OpenAIAPI.new(get_tree(), "https://api.openai.com/v1/chat/", globals.API_KEY)
	#print("openai connected")
	openai.connect("request_success", _on_openai_request_success)
	openai.connect("request_error", _on_openai_request_error)


func _on_openai_request_success(data):
	session_token_total += data.usage.total_tokens
	token_display.text = "Session Tokens: "+str(session_token_total)+" | Est. Cost: $"+str(session_token_total*globals.TOKENS_COST)
	var reply:String = data.choices[0].message.content
	print(reply)
	reply = reply.replace("&amp;", "&")
	var msg_split:PackedStringArray = reply.split("{negative}")
	positive_display.text = msg_split[0].strip_edges()
	if(msg_split.size() > 1):
		negative_display.text = msg_split[1].strip_edges()
	else:
		negative_display.text = "<no negative prompt provided>"
	bot_thinking = false
	generate_button.disabled = false


func _on_openai_request_error(error_code):
	printerr("Request failed with error code:", error_code)
	bot_thinking = false
	generate_button.disabled = false


func user_gui(event:InputEvent):
	if event is InputEventKey && event.keycode == KEY_ENTER && event.pressed:
		generate_prompt()


func generate_prompt():
	if(bot_thinking || user_input.text.strip_edges().is_empty()):
		return
	bot_thinking = true
	generate_button.disabled = true
	positive_display.text = "Awaiting response..."
	negative_display.text = ""
	var chat_array:Array = []
	
	chat_array.append({"role": "system", "content": globals.load_file_as_string("res://scripts/image_prompter/prompter.txt")})

	chat_array.append({"role": "user", "content": user_input.text})
	print(chat_array)
	var data = {
	"model": "gpt-3.5-turbo",
	"messages": chat_array,
	"temperature": 1.2,
	"presence_penalty": 0.5,
	"frequency_penalty": 0.5,
	"max_tokens": 200,
	"logit_bias": logit_bias
	}
	
	openai.make_request("completions", HTTPClient.METHOD_POST, data)



func copy_text(positive:bool):
	if(bot_thinking):
		return
	if(positive):
		if(positive_display.text.strip_edges().strip_escapes().is_empty() || positive_display.text == "Awaiting response..."):
			return
		DisplayServer.clipboard_set(positive_display.text)
	else:
		if(negative_display.text.strip_edges().strip_escapes().is_empty() || negative_display.text == "<no negative prompt provided>"):
			return
		DisplayServer.clipboard_set(negative_display.text)
