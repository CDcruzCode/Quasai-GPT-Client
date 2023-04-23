extends Label

var thread:Thread = Thread.new()
var notice_popup:PackedScene = preload("res://scenes/components/notice_popup.tscn")
@onready var notif_vbox = $"../../../../notifications/vbox"


func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		# destructor logic
		globals.EXIT_HTTP = true
		var _err = thread.wait_to_finish()
		globals.EXIT_HTTP = false
		pass

func _ready():
	self.text = "Version "+globals.VERSION
	await get_tree().process_frame
	thread.start(get_new_version)

func get_new_version():
	var ver_arr:Array = globals.VERSION.split(".")
	#THIS CURRENTLY BLOCKS PROCESSING AND STOPS THE MAIN THREAD WHILE REQUESTING
	#Hot Fix: Put it in its own thread. This still blocks the main thread when changing scenes.
	var req:String = await httprequest.http_req("s3.amazonaws.com", "/quasai.cdcruz.com/version_check.txt" )
	var req_json:Dictionary
	if(req != ""):
		req_json = JSON.parse_string(req)

	if(req_json.major > int(ver_arr[0]) || req_json.minor > int(ver_arr[1]) || req_json.mini > int(ver_arr[2])):
		print("[Version] Out of date")
		var notif = notice_popup.instantiate()
		notif.message = "A new update is available: version "+str(req_json.major)+"."+str(req_json.minor)+"."+str(req_json.mini)+ "\nVisit [url]https://cdcruz.itch.io/chatgpt-client[/url] to download!"
		notif_vbox.add_child(notif)
