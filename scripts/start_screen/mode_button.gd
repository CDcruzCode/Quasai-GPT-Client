extends Button

@export var mode_icon = preload("res://images/icons/general_chat_icon.png")
@onready var mode_image = $vbox/mode_image
@onready var mode_name = $vbox/mode_name
@export var mode_display_name:String
@export var scene:PackedScene

func _ready():
	mode_image.texture = mode_icon
	mode_name.text = mode_display_name
	self.pressed.connect(func(): get_tree().change_scene_to_packed(scene))
