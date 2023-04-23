class_name OpenAIAPI extends Node

var tree:SceneTree
var api_base_url:String
var api_key:String
var api_org:String

var http_request:HTTPRequest

var streaming:bool = false

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		# destructor logic
		if(http_request != null):
			http_request.cancel_request()
			http_request.queue_free()
		print("[OpenAIAPI] DELETE API")

func _init(tree_scene:SceneTree, api_base_url2:String, api_key2:String, api_org2:String = "", node_name:String = "OPENAI_HTTPREQUEST"):
	print("[OpenAIAPI] Init" )
	tree = tree_scene
	
	#This is a hotfix to delete any HTTPRequest Node that was left over from a previous init of this API class.
#	if(tree.root.get_node_or_null(node_name) != null):
#		tree.root.get_node(node_name).queue_free()
#	if(tree.root.get_node_or_null(node_name+"2") != null):
#		tree.root.get_node(node_name+"2").queue_free()
	
	http_request = HTTPRequest.new()
	tree.root.add_child(http_request)
	http_request.name = node_name
	http_request.use_threads = false
	
	
	#await tree.process_frame
	http_request.connect("request_completed", _on_request_completed)
	
	self.api_base_url = api_base_url2
	self.api_key = api_key2
	self.api_org = api_org2

func _on_request_completed(_result, response_code, _headers, body):
	print("[OpenAIAPI] Request completed.")
	print(str(http_request.get_http_client_status()))
	if response_code == 200:
#		if(streaming):
##			emit_signal("request_success_stream", body)
#			print(body)
#		else:
#			var data = JSON.parse_string(body.get_string_from_utf8())
#			emit_signal("request_success", data)
		if(!streaming):
			var data = JSON.parse_string(body.get_string_from_utf8())
			emit_signal("request_success", data)
	else:
		emit_signal("request_error", response_code)
	

func make_request(endpoint: String, method: HTTPClient.Method, data: Dictionary, timeout:float = 40.0):
	streaming = false
	http_request.timeout = timeout
	#var headers = {"Authorization": "Bearer " + api_key}
	var headers = [
	"Content-Type: application/json",
	"Authorization: Bearer " + api_key,
	"OpenAI-Organization: " + api_org]
	var url = api_base_url + endpoint
	
	data.stream = false
	http_request.request(url, headers, method, JSON.stringify(data))
	print("[OpenAIAPI] make_request sent")


#func make_stream_request(endpoint: String, method: HTTPClient.Method, data: Dictionary, timeout:float = 40.0):
#	streaming = true
#	var headers = [
#	"Content-Type: application/json",
#	"Authorization: Bearer " + api_key,
#	"OpenAI-Organization: " + api_org]
#	var url = api_base_url + endpoint
#
#	data.stream = true
#	print(data)
#	print( http_request.request(url, headers, method, JSON.stringify(data)) )
#	print("[OpenAIAPI] make_request_stream sent")



#We could not parse the JSON body of your request. (HINT: This likely means you aren't using your HTTP library correctly. The OpenAI API expects a JSON payload, but what was sent was not valid JSON. If you have trouble figuring out how to fix this, please send an email to support@openai.com and include any relevant code you'd like help with.)

func make_stream_request(endpoint: String, method: HTTPClient.Method, data: Dictionary, timeout:float = 10.0):
	streaming = true
	http_request.timeout = timeout
	
	var err = 0
	var http = HTTPClient.new() # Create the Client.
	
	err = http.connect_to_host("https://api.openai.com", -1) # Connect to host/port.
	assert(err == OK) # Make sure connection is OK.
	
	# Wait until resolved and connected.
	while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
		http.poll()
		
		print("[OPENAIAPI] HTTP Connecting...")
		if not OS.has_feature("web"):
			OS.delay_msec(50)
		else:
			await get_tree().process_frame
	
	print( "[OPENAIAPI] HTTP Status: " + str(http.get_status()) )
	assert(http.get_status() == HTTPClient.STATUS_CONNECTED) # Check if the connection was made successfully.
	
	data.stream = true
	# Some headers
	var headers = [
	"Content-Type: application/json",
	"Authorization: Bearer " + api_key,
	"OpenAI-Organization: " + api_org]
	
	print(JSON.stringify(data))
	
	err = http.request(method, api_base_url+endpoint, headers, JSON.stringify(data) ) # Request a page from the site (this one was chunked..)
	assert(err == OK) # Make sure all is OK.
	
	while http.get_status() == HTTPClient.STATUS_REQUESTING:
		# Keep polling for as long as the request is being processed.
		http.poll()
		print("[OPENAIAPI] HTTP Requesting...")
		if OS.has_feature("web"):
			# Synchronous HTTP requests are not supported on the web,
			# so wait for the next main loop iteration.
			await get_tree().process_frame
		else:
			OS.delay_msec(50)
	
	assert(http.get_status() == HTTPClient.STATUS_BODY or http.get_status() == HTTPClient.STATUS_CONNECTED) # Make sure request finished well.
	
#	print("response? ", http.has_response()) # Site might not have a response.
	
	if http.has_response():
		# If there is a response...
		
		headers = http.get_response_headers_as_dictionary() # Get response headers.
		print("code: ", http.get_response_code()) # Show response code.
		print("**headers:\\n", headers) # Show headers.
	
		# Getting the HTTP Body
		print(http.is_response_chunked())
		if http.is_response_chunked():
				# Does it use chunks?
			print("[OPENAIAPI] Response is Chunked!")
			
			while http.get_status() == HTTPClient.STATUS_BODY:
				# While there is body left to be read
				http.poll()
				# Get a chunk.
				var chunk = http.read_response_body_chunk()
				if chunk.size() == 0:
					if not OS.has_feature("web"):
						# Got nothing, wait for buffers to fill a bit.
						OS.delay_usec(1000)
					else:
						await get_tree().process_frame
				else:
					print(chunk.get_string_from_utf8())
					emit_signal("request_success_stream", chunk.get_string_from_utf8())
		else:
			var rb = PackedByteArray() # Array that will hold the data.
			
			while http.get_status() == HTTPClient.STATUS_BODY:
				if(globals.EXIT_HTTP):
					globals.EXIT_HTTP = false
					return ""
				# While there is body left to be read
				http.poll()
				# Get a chunk.
				var chunk = http.read_response_body_chunk()
				if chunk.size() == 0:
					if not OS.has_feature("web"):
						# Got nothing, wait for buffers to fill a bit.
						OS.delay_usec(1000)
					else:
						await get_tree().process_frame
				else:
					rb = rb + chunk # Append to read buffer.
				
			var res = JSON.parse_string(rb.get_string_from_ascii())
			emit_signal("request_error", res)
		# Done!
	print("DONE HTTP")
	return OK


signal request_success(data)
signal request_success_stream(data)
signal request_error(error_code)
