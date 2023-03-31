extends PanelContainer
@onready var msg:RichTextLabel = $vbox/msg
@onready var options_hbox = $vbox/options_hbox
@onready var play_audio = $vbox/options_hbox/play_audio
@onready var copy_button = $vbox/options_hbox/copy_button
@onready var msg_time = $vbox/options_hbox/msg_time

var timer:Timer = null

var message_list:ScrollContainer = null

const MAX_SIZE:int = 700

func _ready():
	options_hbox.hide()
	self.mouse_entered.connect(start_timer)
	self.mouse_exited.connect(stop_timer)
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


func start_timer():
	timer = Timer.new()
	timer.autostart = true
	timer.one_shot = true
	get_tree().root.add_child(timer)
	await timer.timeout
	timer.queue_free()
	timer = null
	options_hbox.show()

func stop_timer():
	if timer != null:
		timer.queue_free()
		timer = null
	options_hbox.hide()


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
