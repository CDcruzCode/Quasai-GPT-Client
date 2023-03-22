class_name OpenAIAPI extends Node

var tree:SceneTree
var api_base_url:String
var api_key:String
var api_org:String

var http_request:HTTPRequest

var streaming:bool = false

func _init(tree_scene:SceneTree, api_base_url2:String, api_key2:String, api_org2:String = ""):
	tree = tree_scene
	http_request = HTTPRequest.new()
	http_request.use_threads = true
	
	tree.root.add_child(http_request)
	#await tree.process_frame
	http_request.connect("request_completed", _on_request_completed)
	
	self.api_base_url = api_base_url2
	self.api_key = api_key2
	self.api_org = api_org2

func _on_request_completed(_result, response_code, _headers, body):
	print("[OpenAIAPI] Request completed.")
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
	print( http_request.request(url, headers, method, JSON.stringify(data)) )
	print("[OpenAIAPI] Sent msg.")


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
	print("[OpenAIAPI] Stream msg sent.")


signal request_success(data)
signal request_success_stream(data)
signal request_error(error_code)
