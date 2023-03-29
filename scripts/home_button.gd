extends Button

@export var custom_save:bool = false

func _ready():
	globals.EXIT_THREAD = false
	self.pressed.connect(func(): globals.EXIT_THREAD = true; get_tree().change_scene_to_file("res://scenes/start_screen/start_screen.tscn"))

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST && !custom_save:
		print("QUITTING")
		globals.EXIT_THREAD = true
		await get_tree().process_frame
#		var root_parent = self.get_parent().get_parent().get_parent()
#		if(root_parent.wait_thread != null):
#			root_parent.wait_thread = null
		save_config()
		get_tree().quit()
		return


func save_config():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err != OK:
		printerr(err)
		return false
	
	config.set_value("Settings", "API_KEY", globals.API_KEY)
	config.set_value("Settings", "MODEL", globals.AI_MODEL)
#	config.set_value("Settings", "MAX_TOKENS", globals.MAX_TOKENS)
#	config.set_value("Settings", "TEMPERATURE", globals.TEMPERATURE)
#	config.set_value("Settings", "PRESENCE", globals.PRESENCE)
#	config.set_value("Settings", "FREQUENCY", globals.FREQUENCY)
	
	config.set_value("Stats", "TOTAL_TOKENS_USED", globals.TOTAL_TOKENS_USED)
	config.set_value("Stats", "TOTAL_TOKENS_COST", globals.TOTAL_TOKENS_COST)
	config.save("user://settings.cfg")
	print("SAVED CONFIG")
