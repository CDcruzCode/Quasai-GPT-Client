class_name ElevenLabsAPI extends Node

var tree:SceneTree
var api_key:String
var voice:String = "21m00Tcm4TlvDq8ikWAM"

var http_request:HTTPRequest

func _init(tree_scene:SceneTree):
	tree = tree_scene
	http_request = HTTPRequest.new()
	tree.root.add_child(http_request)
	http_request.connect("request_completed", _on_request_completed)

func _on_request_completed(_result, response_code, _headers, body):
	print("[ElevenLabsAPI] Request completed.")
	print(body)
	if response_code == 200:
		emit_signal("request_success", body) #Returns a poolByteArray
	else:
		emit_signal("request_error", response_code)

func make_request(data: Dictionary):
	#var headers = {"Authorization": "Bearer " + api_key}
	var headers = [
	"Content-Type: application/json",
	"xi-api-key:" + api_key,
	"Accept: audio/mpeg"
	]
	
	var url = "https://api.elevenlabs.io/v1/text-to-speech/"+ voice
	print( http_request.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(data)) )
	print("[ElevenLabsAPI] Sent msg.")


signal request_success(data)
signal request_success_stream(data)
signal request_error(error_code)
