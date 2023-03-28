extends RichTextLabel

func _ready():
	self.meta_clicked.connect(func(meta): OS.shell_open(str(meta)))
