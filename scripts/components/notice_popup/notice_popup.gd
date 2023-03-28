extends MarginContainer

@onready var close_button = $pcon/hbox/close_button
@onready var popup_text = $pcon/hbox/popup_text
@onready var indicator = $pcon/hbox/indicator

var message:String = ""
var msg_color:Color = Color.LIME_GREEN

func _ready():
	popup_text.meta_clicked.connect(func(meta): OS.shell_open(str(meta)))
	close_button.pressed.connect(func(): self.queue_free() )
	popup_text.text = message
	indicator.color = msg_color
