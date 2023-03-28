extends PanelContainer

@onready var user_input = $vbox/hbox/input_con/vbox/user_input
@onready var paragraph_amount = $vbox/hbox/input_con2/vbox/paragraph_amount
@onready var generate_button = $vbox/hbox/generate_button
@onready var story_paragraph:PackedScene = preload("res://scenes/story_writer/story_paragraph.tscn")
@onready var story_list = $vbox/story_panel/mcon/scon/story_list
@onready var writing_style_options = $vbox/hbox/input_con3/vbox/writing_style_options

@onready var loading = $vbox/hcon/loading
@onready var bad_status = preload("res://images/icons/bad_status.png")
@onready var good_status = preload("res://images/icons/good_status.png")
@onready var wait_status = preload("res://images/icons/wait_status.png")
@onready var nil_status = preload("res://images/icons/nil_status.png")

var bot_thinking:bool = false
var session_tokens:int = 0
var session_cost:float = 0.0
var openai:OpenAIAPI
var elevenlabs:ElevenLabsAPI

var logit_bias:Dictionary = {
	20185: -50, #AI
	3303: -80, #language
	2746: -80, #model
	562: -20, #ass
	10167: -80, #istant
}


var current_paragraph:int = 1
const writing_styles:PackedStringArray = [
	"Basic",
	"Short Story",
	"Fiction",
	"Non-Fiction",
	"Children's Book",
	"Literary Fiction",
	"Epic Narrative",
	"Folklore",
	"Fairy Tale",
	"Thriller",
	"Erotic Literature",
	"Mystery",
	"Noir",
	"Romantic",
	"Lovecraftian",
	"Science Fantasy",
	"Space Opera",
	"Superhero",
	"True Crime",
	"Melodrama",
	"Manga",
	"Hentai"
]

func _ready():
	bot_thinking = true
	loading.texture = wait_status
	self.tree_exiting.connect(func(): globals.clear_apis(openai, elevenlabs))
	generate_button.pressed.connect(func(): generate_story(true))
	
	writing_styles.sort()
	for i in writing_styles:
		writing_style_options.add_item(i)
	
	await connect_openai()
	bot_thinking = false
	loading.texture = good_status

func connect_openai():
	await get_tree().process_frame
	openai = await OpenAIAPI.new(get_tree(), "https://api.openai.com/v1/chat/", globals.API_KEY)
	openai.connect("request_success", _on_openai_request_success)
	openai.connect("request_error", _on_openai_request_error)

func _on_openai_request_success(data):
	print(data)
	globals.TOTAL_TOKENS_USED += data.usage.total_tokens
	globals.TOTAL_TOKENS_COST += (data.usage.prompt_tokens*globals.INPUT_TOKENS_COST) + (data.usage.completion_tokens*globals.TOKENS_COST)
	session_tokens += data.usage.total_tokens
	session_cost += (data.usage.prompt_tokens*globals.INPUT_TOKENS_COST) + (data.usage.completion_tokens*globals.TOKENS_COST)
#	token_display.text = "Session Tokens: "+str(session_tokens)+" | Est. Cost: $"+str(session_cost)
	
	var para = story_paragraph.instantiate()
	para.get_node("mcon/vbox/story_text").text = data.choices[0].message.content
	story_list.add_child(para)
	
	
	current_paragraph += 1
	if(paragraph_amount.value >= current_paragraph):
		generate_story()
		return
	
	
	bot_thinking =false
	wait_thread.wait_to_finish()
	loading.texture = good_status

func _on_openai_request_error(error_code):
	bot_thinking =false
	printerr("Request failed with error code:", error_code)
	loading.texture = bad_status
#	generate_button.disabled = false
#	instructions_display.text = globals.parse_api_error(error_code)

var wait_thread:Thread = Thread.new()
func wait_blink():
	while bot_thinking:
		loading.texture = wait_status
		await globals.delay(0.5)
		if(!bot_thinking):
			return
		loading.texture = nil_status
		await globals.delay(0.5)


func generate_story(starting:bool = false):
	if(starting && bot_thinking):
		return
	if(user_input.text.strip_edges().is_empty()):
		return
	
	bot_thinking = true
	
	if(starting):
		current_paragraph = 1
		globals.delete_all_children(story_list)
	await get_tree().process_frame
	
	
	if(!wait_thread.is_started()):
		wait_thread = Thread.new()
		wait_thread.start(wait_blink)
	
	var chat_array:Array = []
	chat_array.append({"role": "system", "content": globals.load_file_as_string("res://scripts/story_writer/writer_rules.txt")})
	chat_array.append({"role": "system", "content": "\nIt must be "+str(paragraph_amount.value)+" paragraphs long but you will write it in parts."})
	chat_array.append({"role": "system", "content": "\nYou need to write the "+globals.number_suffix(current_paragraph)+" paragraph out of "+str(paragraph_amount.value)})
	chat_array.append({"role": "system", "content": "\nThe writing style is " + writing_style_options.get_item_text(writing_style_options.selected)})
	chat_array.append({"role": "system", "content": "\nThe story premise is " + user_input.text})
	
	if(current_paragraph > 1):
		chat_array.append({"role": "system", "content": "\nBelow is a few previous paragraphs to continue from:\n"})
		
		var full_paras:PackedStringArray = []
		for c in story_list.get_children():
			full_paras.append(c.get_node("mcon/vbox/story_text").text)
		var last_paras:PackedStringArray = []
		if(story_list.get_child_count() > 5):
			last_paras = full_paras.slice(full_paras.size()-4, full_paras.size()-1)
		else:
			last_paras = full_paras.duplicate()
#		last_paras.reverse()
		for p in last_paras:
			chat_array.append({"role": "assistant", "content": p})
	
	if(story_list.get_child_count() >= paragraph_amount.value-1):
		chat_array.append({"role": "system", "content": "\nIMPORTANT: This is the last paragraph so you need to end the story now.\n"})
	
	print(chat_array)
	var data = {
	"model": globals.AI_MODEL,
	"messages": chat_array,
	"temperature": 1.1,
	"presence_penalty": 0.0,
	"frequency_penalty": 0.0,
	"max_tokens": 500,
	"stream": false,
	"logit_bias": logit_bias
	}
	
	openai.make_request("completions", HTTPClient.METHOD_POST, data)


#
#func export_to_txt(path:String):
#	print(path)
#	if(user_input.text.is_empty() || ingredients_display.text.is_empty() || instructions_display.text.is_empty()):
#		printerr("Cannot save recipe as text inputs are empty.")
#		return
#
#	var full_doc:String = ""
#	full_doc += user_input.text.to_upper() + "\nA recipe generated by GPT Playground\n"
#	full_doc += "Serving Size: " + str(serving_size.value) + "\n\n"
#	full_doc += "[Ingredients]\n\n" + ingredients_display.text + "\n\n"
#	full_doc += "[Instructions]\n\n" + instructions_display.text
#
#	globals.save_text_file(path, full_doc)
