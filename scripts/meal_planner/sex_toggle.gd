extends Button

func _ready():
	self.toggled.connect(clicked)

func clicked(toggle:bool):
	if(toggle):
		self.text = "Female"
	else:
		self.text = "Male"
