extends Label

func _ready():
	self.text = "Version "+globals.VERSION
	var ver_arr:Array = globals.VERSION.split(".")
	
	#THIS CURRENTLY BLOCKS PROCESSING AND STOPS THE MAIN THREAD WHILE REQUESTING
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
