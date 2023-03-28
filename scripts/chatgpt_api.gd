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
	http_request.use_threads = true
	
	
	#await tree.process_frame
	http_request.connect("request_completed", _on_request_completed)
	
	self.api_base_url = api_base_url2
	self.api_key = api_key2
	self.api_org = api_org2

func _on_request_completed(_result, response_code, _headers, body):
	print("[OpenAIAPI] Request completed.")
	print(str(http_request.get_http_client_status()))
	if response_code == 200:
		if(streaming):
			emit_signal("request_success_stream", body)
		else:
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


func make_stream_request(endpoint: String, method: HTTPClient.Method, data: Dictionary):
	streaming = true
	var headers = [
	"Content-Type: text/event-stream",
	"Authorization: Bearer " + api_key,
	"OpenAI-Organization: " + api_org]
	var url = api_base_url + endpoint
	
	data.stream = true
	print(data)
	print( http_request.request(url, headers, method, JSON.stringify(data)) )
	print("[OpenAIAPI] make_request_stream sent")


signal request_success(data)
signal request_success_stream(data)
signal request_error(error_code)
