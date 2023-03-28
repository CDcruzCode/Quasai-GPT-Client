extends PanelContainer

@onready var error_message = $mcon/vbox/error_message
@onready var ai_name = $mcon/vbox/scon/vbox/name_box/ai_name
@onready var random_name_button = $mcon/vbox/scon/vbox/name_box/random_name_button

@onready var age_box = $mcon/vbox/scon/vbox/age_box
@onready var age_young = $mcon/vbox/scon/vbox/age_box/age_young
@onready var age_adult = $mcon/vbox/scon/vbox/age_box/age_adult
@onready var age_old = $mcon/vbox/scon/vbox/age_box/age_old

@onready var sex_box = $mcon/vbox/scon/vbox/sex_box
@onready var sex_man = $mcon/vbox/scon/vbox/sex_box/sex_man
@onready var sex_woman = $mcon/vbox/scon/vbox/sex_box/sex_woman

@onready var personality_options = $mcon/vbox/scon/vbox/personality_options

@onready var interests_box = $mcon/vbox/scon/vbox/interests_box

@onready var generate_button = $mcon/vbox/scon/vbox/generate_button


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()
		return

func _ready():
	var file = FileAccess.open("user://companion/basic_info.json", FileAccess.READ)
	if(file != null):
		get_tree().change_scene_to_file("res://scenes/companion/companion.tscn")
		return
	
	personality_options.add_item("Cheerful")
	personality_options.add_item("Sassy")
	personality_options.add_item("Shy")
	personality_options.add_item("Nia")
	
	sex_man.pressed.connect(func(): select_multi_toggle(sex_box, 0))
	sex_woman.pressed.connect(func(): select_multi_toggle(sex_box, 1))
	
	generate_button.pressed.connect(generate_ai)
	
	
	age_young.button_pressed = true
	sex_man.button_pressed = true

func select_multi_toggle(container:Node, selected:int):
	for button in container.get_children():
		if(button is Button):
			button.button_pressed = false
	container.get_child(selected).button_pressed = true



func generate_ai():
	if(ai_name.text.strip_edges().is_empty()):
		error_message.show()
		error_message.text = "Please give your companion a name."
		return
	
	
	var age:int = 0
	if(age_young.button_pressed):
		age = randi_range(18, 30)
	elif(age_adult.button_pressed):
		age = randi_range(31, 60)
	else:
		age = randi_range(61,100)
	
	var sex:String
	if(sex_man.button_pressed):
		sex = "man"
	else:
		sex = "woman"
	
	
	var info_json:Dictionary = {
				"name": ai_name.text.strip_edges(),
				"age": age,
				"sex": sex,
				"personality": personality_options.get_item_text(personality_options.selected)
			}
	globals.save_file("user://companion/basic_info.json", JSON.stringify(info_json))
	
	get_tree().change_scene_to_file("res://scenes/companion/companion.tscn")
