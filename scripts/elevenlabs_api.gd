class_name ElevenLabsAPI extends Node

var tree:SceneTree
var api_key:String

var http_request:HTTPRequest
var audio_player:AudioStreamPlayer
var http_list_voices:HTTPRequest

var CURRENT_FUNC:FUNCTION = FUNCTION.list_voices
enum FUNCTION {
	list_voices,
	text_to_speech
}

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		# destructor logic
		if(audio_player != null):
			audio_player.queue_free()
		if(http_request != null):
			http_request.queue_free()
		if(http_list_voices != null):
			http_list_voices.queue_free()
		print("[ElevenLabsAPI] DELETE API")

func _init(tree_scene:SceneTree, api_key_input:String, node_name:String = "ELEVENLABS_HTTPREQUEST", audio_name:String = "ELEVENLABS_AUDIO"):
	print("[ElevenLabsAPI] Init")
	tree = tree_scene
	api_key = api_key_input
	
	http_request = HTTPRequest.new()
	tree.root.add_child(http_request)
	http_request.name = node_name
	http_request.use_threads = true
	
	http_request.connect("request_completed", _on_request_completed)
	
	
	
	audio_player = AudioStreamPlayer.new()
	audio_player.name = audio_name
	tree.root.add_child(audio_player)

func play_audio(data:PackedByteArray):
	var sample = AudioStreamMP3.new()
	sample.data = data
	audio_player.stream = sample
	audio_player.play()

func _on_request_completed(_result, response_code, _headers, body):
	print("[ElevenLabsAPI] Request completed.")

	if response_code == 200:
		match CURRENT_FUNC:
			FUNCTION.text_to_speech:
				emit_signal("request_success", body) #Returns a poolByteArray
			_:
				emit_signal("request_success", body) #Returns a poolByteArray
	else:
		emit_signal("request_error", response_code)


func list_voices():
	if(http_list_voices == null):
		http_list_voices = HTTPRequest.new()
		http_list_voices.name = "ELEVENLABS_LIST_VOICES"
		http_list_voices.connect("request_completed", _list_voices_complete)
		tree.root.add_child(http_list_voices)
	
	CURRENT_FUNC = FUNCTION.list_voices
	var headers = [
	"Content-Type: application/json",
	"xi-api-key:" + api_key
	]
	http_list_voices.request("https://api.elevenlabs.io/v1/voices", headers, HTTPClient.METHOD_GET, "" )

func _list_voices_complete(_result, response_code, _headers, body):
	if response_code == 200:
		if(http_list_voices != null):
			http_list_voices.queue_free()
		
		var res = JSON.parse_string(body.get_string_from_utf8())
		var voice_arr:Array = []
		for r in res.voices:
			voice_arr.append({"name": r.name, "voice_id": r.voice_id, "category": r.category})
		print(voice_arr)
		emit_signal("request_voices", voice_arr)
	else:
		emit_signal("request_error", response_code)

func text_to_speech(text:String, voice_id:String = "21m00Tcm4TlvDq8ikWAM"):
	#var headers = {"Authorization": "Bearer " + api_key}
#	http_request.cancel_request()
	print( http_request.get_http_client_status() )
	
	CURRENT_FUNC = FUNCTION.text_to_speech
	var headers = [
	"Content-Type: application/json",
	"xi-api-key:" + api_key,
	"Accept: audio/mpeg",
	]

	var data:Dictionary = {
		"text": text,
		"voice_settings": {
			"stability": 0,
			"similarity_boost": 0
		}
	}

	var url = "https://api.elevenlabs.io/v1/text-to-speech/"+ voice_id+"/stream"
	http_request.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(data) )
	print("[ElevenLabsAPI] Sent msg.")

signal request_success(data)
signal request_voices(data)
signal request_success_stream(data)
signal request_error(error_code)
