extends PanelContainer
@onready var msg:RichTextLabel = $vbox/msg
var message_list:ScrollContainer = null

const MAX_SIZE:int = 700

func _ready():
	self.gui_input.connect(copy_text)
	max_size()

func copy_text(event:InputEvent):
	if event.is_pressed():
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
