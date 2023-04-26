extends MarginContainer

@onready var close_button = $pcon/hbox/close_button
@onready var popup_text = $pcon/hbox/popup_text
@onready var indicator = $pcon/hbox/indicator

var message:String = ""
var msg_color:Color = Color.LIME_GREEN

var tween:Tween

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		# destructor logic
		tween.kill()

func _ready():
	tween = get_tree().create_tween()
	tween.tween_property(self, "modulate", Color(1,1,1,0), 3).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(self.queue_free)
	tween.pause()
	self.gui_input.connect(on_hover)
	
	popup_text.meta_clicked.connect(func(meta): OS.shell_open(str(meta)))
	close_button.pressed.connect(func(): self.queue_free(); tween.kill() )
	popup_text.text = message
	indicator.color = msg_color
	
	
	await globals.delay(2.0)
	tween.play()

func on_hover(_event:InputEvent):
	self.modulate = Color(1,1,1,0.98)
	if(tween):
		tween.kill()
	
	tween = get_tree().create_tween()
	tween.tween_property(self, "modulate", Color(1,1,1,0), 3).set_trans(Tween.TRANS_QUAD)
	
	tween.tween_callback(self.queue_free)
