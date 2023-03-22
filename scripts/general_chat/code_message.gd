extends PanelContainer
@onready var msg:CodeEdit = $vbox/code_box
var message_list:ScrollContainer = null
@onready var copy_code_button = $vbox/HBoxContainer/copy_code

const MAX_SIZE:int = 700

func _ready():
	copy_code_button.pressed.connect(func(): DisplayServer.clipboard_set(msg.text))
