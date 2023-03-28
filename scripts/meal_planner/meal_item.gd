extends PanelContainer

var parent:Node = null
var meal_type:String = ""
@onready var regen_meal_button = $mcon/vbox/hbox/regen_meal_button

func _ready():
	regen_meal_button.hide()
	
	self.mouse_entered.connect(func(): regen_meal_button.show())
	self.mouse_exited.connect(func(): regen_meal_button.hide())
	
	regen_meal_button.pressed.connect(func(): parent.refresh_meal(self))

