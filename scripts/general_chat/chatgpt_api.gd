class_name OpenAIAPI extends Node

var tree:SceneTree
var api_base_url:String
var api_key:String
var api_org:String

var http_request:HTTPRequest

func _init(tree_scene:SceneTree, api_base_url2:String, api_key2:String, api_org2:String = ""):
	tree = tree_scene
	http_request = HTTPRequest.new()
	tree.root.add_child(http_request)
	#await tree.process_frame
	http_request.connect("request_completed", _on_request_completed)
	
	self.api_base_url = api_base_url2
	self.api_key = api_key2
	self.api_org = api_org2

func _on_request_completed(_result, response_code, _headers, body):
	print("[OpenAIAPI] Request completed.")
	if response_code == 200:
		var data = JSON.parse_string(body.get_string_from_utf8())
		emit_signal("request_success", data)
	else:
		emit_signal("request_error", response_code)

func make_request(endpoint: String, method: HTTPClient.Method, data: Dictionary):
	#var headers = {"Authorization": "Bearer " + api_key}
	var headers = [
	"Content-Type: application/json",
	"Authorization: Bearer " + api_key,
	"OpenAI-Organization: " + api_org]
	var url = api_base_url + endpoint

	print( http_request.request(url, headers, method, JSON.stringify(data)) )
	print("[OpenAIAPI] Sent msg.")


signal request_success(data)
signal request_error(error_code)
