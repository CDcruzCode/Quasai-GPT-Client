extends PanelContainer
@onready var msg:RichTextLabel = $vbox/msg
@onready var options_hbox = $vbox/options_hbox
@onready var play_audio = $vbox/options_hbox/play_audio
@onready var copy_button = $vbox/options_hbox/copy_button
@onready var msg_time = $vbox/options_hbox/msg_time

var message_list:ScrollContainer = null

var type:String = ""
var elevenlabs_api = null
var chat_screen = null
const MAX_SIZE:int = 700

func _ready():
	options_hbox.hide()
	self.mouse_entered.connect(func(): options_hbox.show())
	self.mouse_exited.connect(func(): options_hbox.hide())
	
	if(elevenlabs_api != null):
		play_audio.pressed.connect(play_voice_note)
	else:
		play_audio.queue_free()
	
	copy_button.pressed.connect(copy_text)
	max_size()
	
	var current_time = Time.get_datetime_dict_from_system()
	var formatted_hour = str(current_time.hour % 12).pad_zeros(2)
	var formatted_minute = str(current_time.minute).pad_zeros(2)
	var formatted_period
	if current_time.hour >= 12:
		formatted_period = "pm"
	else:
		formatted_period = "am"
	var formatted_time = formatted_hour + ":" + formatted_minute + formatted_period
	msg_time.text = formatted_time

func copy_text():
	DisplayServer.clipboard_set(msg.text)

func max_size() -> void:
	await get_tree().process_frame
	var current_size = msg.get_size()
	if current_size.x > MAX_SIZE:
		msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		msg.custom_minimum_size = Vector2( min(current_size.x, MAX_SIZE), current_size.y)
		msg.size = Vector2(0,0)
	
	if(message_list):
		await get_tree().process_frame
		message_list.scroll_vertical = message_list.get_v_scroll_bar().max_value


func play_voice_note():
	if(elevenlabs_api != null && !chat_screen.bot_thinking):
		chat_screen.bot_thinking = true
		chat_screen.send_button.disabled = true
		chat_screen.wait_thread = Thread.new()
		chat_screen.wait_thread.start(chat_screen.wait_blink)
		
		var voice_message = globals.remove_regex(msg.text, "<.*?>") #Removes any words surrounded by angle brackets <like this> from the voice message.
		chat_screen.elevenlabs.text_to_speech(globals.parse_voice_message(voice_message), globals.SELECTED_VOICE)
