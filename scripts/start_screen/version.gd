extends Label

var thread:Thread = Thread.new()

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		# destructor logic
		thread.wait_to_finish()

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

	if(req_json.major > int(ver_arr[0])):
		print("out of date")
	elif(req_json.minor > int(ver_arr[1])):
		print("out of date")
	elif(req_json.mini > int(ver_arr[2])):
		print("out of date")
