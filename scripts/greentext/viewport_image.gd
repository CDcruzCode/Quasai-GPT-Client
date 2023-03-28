extends Node

@export var viewport_path:Node = null
@onready var hcon = $hcon
@onready var hbox = $hbox

var target_viewport:Viewport
func _ready():
	if viewport_path:
		target_viewport = viewport_path
	else:
		target_viewport = get_tree().root.get_viewport()

func save_to(path):
	hcon.hide()
	hbox.hide()
	await RenderingServer.frame_post_draw
	target_viewport.get_texture().get_image().save_png(path)
	hcon.show()
	hbox.show()
