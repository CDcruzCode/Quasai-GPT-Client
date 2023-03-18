extends Button

func _ready():
	self.pressed.connect(func(): OS.shell_open("https://github.com/dluc/openai-tools"))
