extends PanelContainer
var openai:OpenAIAPI
var bot_thinking:bool = false

@onready var copy_output_button = $vbox/hcon/copy_ouput_button
@onready var user_input = $vbox/hbox/input_con/VBoxContainer/user_input
@onready var text_display = $vbox/greentext_panel/scon/vbox/hbox/text_display
@onready var text_display_2 = $vbox/greentext_panel/scon/vbox/text_display2
@onready var image_file_label = $vbox/greentext_panel/scon/vbox/hbox/vbox/image_file_label
@onready var greentext_image = $vbox/greentext_panel/scon/vbox/hbox/vbox/img_con/greentext_image

@onready var generate_button = $vbox/hbox/generate_button
@onready var viewport_image = $vbox



@onready var loading = $vbox/hcon/loading
@onready var bad_status = preload("res://images/icons/bad_status.png")
@onready var good_status = preload("res://images/icons/good_status.png")
@onready var wait_status = preload("res://images/icons/wait_status.png")
@onready var nil_status = preload("res://images/icons/nil_status.png")


var is_image:bool = false
var image_request:HTTPRequest = HTTPRequest.new()

var logit_bias:Dictionary = {
	20185: -50, #AI
	3303: -80, #language
	2746: -80, #model
	562: -20, #ass
	10167: -80, #istant
}

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		# destructor logic
		globals.EXIT_THREAD = true
		globals.EXIT_HTTP = true
		if(send_msg_thread.is_started() || send_msg_thread.is_alive()):
			var _err = send_msg_thread.wait_to_finish()
		
		if(wait_thread.is_started() || wait_thread.is_alive()):
			var _err = wait_thread.wait_to_finish()
		globals.EXIT_THREAD = false
		globals.EXIT_HTTP = false


func _ready():
	self.tree_exiting.connect(func(): openai.queue_free())
	bot_thinking = true
	loading.texture = wait_status
	copy_output_button.pressed.connect(copy_output)
	user_input.gui_input.connect(user_gui)
	text_display.text = ""
	text_display_2.text = ""
	image_file_label.text = ""
	greentext_image.hide()
	generate_button.pressed.connect(generate_greentext)
	
	get_tree().root.get_node("greentexter").add_child(image_request)
	image_request.connect("request_completed", _on_request_completed)
	
	
	await connect_openai()
	bot_thinking = false
	loading.texture = good_status

func user_gui(event:InputEvent):
	if event is InputEventKey && event.keycode == KEY_ENTER && event.pressed:
		generate_greentext()


func copy_output():
	if(bot_thinking):
		return
	if(text_display.text.strip_edges().strip_escapes().is_empty() || text_display.text == "Awaiting response..."):
		return
	DisplayServer.clipboard_set(text_display.text + "\n" + text_display_2.text)

func connect_openai():
	await get_tree().process_frame
	openai = OpenAIAPI.new(get_tree(), "https://api.openai.com/v1/chat/", globals.API_KEY)
	openai.connect("request_success_stream", _on_openai_request_success_stream)
	openai.connect("request_error", _on_openai_request_error)


var send_msg_thread:Thread = Thread.new()
func generate_greentext():
	if(bot_thinking || user_input.text.strip_edges().is_empty()):
		return
	
	bot_thinking = true
	generate_button.disabled = true
	
	if(send_msg_thread.is_started() || send_msg_thread.is_alive()):
		print("WAITING TO FINISH")
		var _err = send_msg_thread.wait_to_finish()
	
	if(wait_thread.is_started() || wait_thread.is_alive()):
		print("WAITING TO FINISH")
		globals.EXIT_THREAD = true
		var _err = wait_thread.wait_to_finish()
	globals.EXIT_THREAD = false
	wait_thread = Thread.new()
	wait_thread.start(wait_blink)
	
	text_display.text = "Awaiting response..."
	text_display_2.text = ""
	image_file_label.text = ""
	
	var chat_array:Array = []
	
	chat_array.append({"role": "system", "content": globals.load_file_as_string("res://scripts/greentext/greentext_rules.txt")})
	chat_array.append({"role": "user", "content": user_input.text})
	
	print(chat_array)
	var data = {
	"model": globals.AI_MODEL,
	"messages": chat_array,
	"temperature": 1.1,
	"presence_penalty": 0.0,
	"frequency_penalty": 0.0,
	"logit_bias": logit_bias,
	"max_tokens": globals.max_model_tokens() - globals.token_estimate(JSON.stringify(chat_array))
	}
	
#	openai.make_stream_request("completions", HTTPClient.METHOD_POST, data)
	send_msg_thread = Thread.new()
	send_msg_thread.start(openai.make_stream_request.bind("completions", HTTPClient.METHOD_POST, data, 10.0))
	
	greentext_image.hide()
	greentext_image.texture = null
	is_image = false
	var headers = ["Content-Type: application/json"]
	image_request.request("https://api.imgflip.com/get_memes", headers, HTTPClient.METHOD_GET)



var response_msg:String = ""
var has_split:bool = false
func _on_openai_request_success_stream(data):
	#print("START CHUNK PARSE")
	var res_arr:PackedStringArray = data.split("data: ", false)
	var json_parse:JSON = JSON.new()
	
	for item in res_arr:
#		var res_json = JSON.parse_string(item.strip_edges())
		var json_err = json_parse.parse(item.strip_edges())
#		print(json_err)
		var res_json = json_parse.data
		if(json_err == ERR_PARSE_ERROR):
			if(item.strip_edges() == "[DONE]"):
				await get_tree().process_frame
				parse_streamed_message()
				print("FINISH")
				return
		
		if(res_json.has("choices") && res_json.choices[0].has("delta")):
			
			if(res_json.choices[0].delta.has("role")):
				#Role stated, this means its the start of the AI response
				response_msg = ""
				has_split = false
				image_file_label.text = String.humanize_size(randi_range(5000,100000)) + " JPG"
#				print("Role is: "+str(res_json.choices[0].delta.role))
				continue
			
			if(res_json.choices[0].delta.has("content")):
				#print("Content: "+str(res_json.choices[0].delta.content))
				await get_tree().process_frame
				response_msg += str(res_json.choices[0].delta.content)
				if(!has_split):
					var split = split_text(response_msg.replace("\n\n", "\n"))
					text_display.text = split[0]
					text_display_2.text = split[1]
					if(text_display_2.text != ""):
						has_split = true
				else:
					text_display_2.text += str(res_json.choices[0].delta.content)
				continue

func parse_streamed_message():
	#print(response_msg)
	
	var output_tokens:int = globals.token_estimate(response_msg)
	globals.TOTAL_TOKENS_USED += output_tokens
	globals.TOTAL_TOKENS_COST += (output_tokens*globals.INPUT_TOKENS_COST)
#	session_tokens_display.text = "Session Tokens: "+str(session_token_total)+" | Est. Cost: $"+str(session_cost)
	
	var voice_message:String = ""
	
	voice_message += response_msg
	
#	if(elevenlabs != null && globals.VOICE_ALWAYS_ON):
#		print(voice_message)
#		elevenlabs.text_to_speech(globals.parse_voice_message(voice_message), globals.SELECTED_VOICE)
#	else:
#		bot_thinking = false
#		generate_button.disabled = false
#		loading.texture = good_status
	bot_thinking = false
	generate_button.disabled = false
	loading.texture = good_status

func _on_openai_request_error(error_code):
	printerr("Request failed with error code:", error_code)
	bot_thinking = false
	generate_button.disabled = false
	
	if(typeof(error_code) == TYPE_INT):
		text_display.text = globals.parse_api_error(error_code)
	else:
		text_display.text = "Request failed with unknown error: " + str(error_code)
	loading.texture = bad_status
	await get_tree().process_frame

var wait_thread:Thread = Thread.new()
func wait_blink():
	while bot_thinking && !globals.EXIT_THREAD:
		loading.texture = wait_status
		await globals.delay(0.5)
		if(!bot_thinking || globals.EXIT_THREAD):
			print("[WAIT BLINK] EXIT")
			globals.EXIT_THREAD = false
			return OK
		loading.texture = nil_status
		await globals.delay(0.5)


func split_text(input_text:String, split_line:int = 10):
	var lines = input_text.split("\n") # Split the string by line breaks
	
	if(lines.size() < split_line):
		return [input_text.strip_edges(), ""]
	
	var first_section = ""
	var second_section = ""
	
	for index in range(lines.size()):
		if index < split_line:
			first_section += lines[index] + "\n"
		else:
			second_section += lines[index] + "\n"
	
	return [first_section.strip_edges(), second_section.strip_edges()]


var image_type:String = ""
func _on_request_completed(result, _response_code, _headers, body):
	if(result == OK):
		if(is_image):
			var image = Image.new()
			var error
			if(image_type == "png"):
				error = image.load_png_from_buffer(body)
			else: #JPG
				error = image.load_jpg_from_buffer(body)
			if error == OK:
				var texture = ImageTexture.create_from_image(image)
				greentext_image.texture = texture
			greentext_image.show()
		else:
			var meme_list = JSON.parse_string(body.get_string_from_utf8()).data.memes
			var selected_image = meme_list[randi_range(0,99)]
			is_image = true
			image_type = selected_image.url.get_extension()
			image_request.request(selected_image.url, ["Content-Type: image/jpg"], HTTPClient.METHOD_GET)
			print(selected_image)
