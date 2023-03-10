extends PanelContainer

@export var icon = preload("res://images/icons/general_chat_icon.png")
@onready var mode_image = $vbox/mode_image
@onready var mode_name = $vbox/mode_name
@export var mode_display_name:String
@export var scene:PackedScene

func _ready():
	mode_image.texture = icon
	mode_name.text = mode_display_name
	self.gui_input.connect(gui)
	self.mouse_entered.connect(func(): self.self_modulate = self.self_modulate.lightened(0.1))
	self.mouse_exited.connect(func(): self.self_modulate = globals.CURRENT_THEME.container)

func gui(event:InputEvent):
	if(event is InputEventMouseButton && event.is_pressed() && event.button_index == 1):
		print(event)
		get_tree().change_scene_to_packed(scene)
