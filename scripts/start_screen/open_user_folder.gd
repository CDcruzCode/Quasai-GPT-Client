extends Button

func _ready():
	self.pressed.connect(func(): OS.shell_open(ProjectSettings.globalize_path("user://")))
