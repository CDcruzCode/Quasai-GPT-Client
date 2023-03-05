extends PanelContainer
@onready var msg = $msg

func _ready():
	self.gui_input.connect(copy_text)

func copy_text(event:InputEvent):
	if event.is_pressed():
		DisplayServer.clipboard_set(msg.text)
