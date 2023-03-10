class_name GPTTokenizer extends Node

var encoder_json:String = globals.load_file_as_string("res://scripts/tokenizer/encoder.json")
var encoder_dict:Dictionary
func _init():
	encoder_dict = JSON.parse_string(encoder_json)

func parse(input:String):
	var input_arr:Array = input.split("")
	var parsed_arr = input_arr.map(char_to_token)
	print(input_arr)
	print(parsed_arr)

func char_to_token(char:String):
	return encoder_dict.get(char)




func range(x: int, y: int):
	var res = []
	for i in range(x,y):
		res.append(i)
	return res

func ord(x: String):
	return x.unicode_at(0)

func chr(x: int):
	return String(chr(x))

func dictZip(x: Array, y: Array):
	var result = {}
	for i in range(x.size()):
		result[x[i]] = y[i]
	return result


func bytes_to_unicode():
	var bs = range(ord("!"), ord("~") + 1) + range(ord("¡"), ord("¬") + 1) + range(ord("®"), ord("ÿ") + 1)
	var cs = bs.duplicate()
	var n = 0
	for b in range(2 ** 8):
		if !bs.has(b):
			bs.append(b)
			cs.append(2 ** 8 + n)
			n += 1
		else:
			cs.remove(bs.find(b))
	cs = cs.map(func(x): return chr(x))
	var result = {}
	for i in range(bs.size()):
		result[bs[i]] = cs[i]
	return result


func get_pairs(word: String):
	var pairs = []
	var prev_char = word[0]
	for i in range(1, word.length()):
		var char = word[i]
		pairs.append([prev_char, char])
		prev_char = char
	return pairs
