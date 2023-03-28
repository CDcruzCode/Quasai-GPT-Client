# @author: Devis Lucato. @license: CC0.

extends Node

var BPE_CACHE: Dictionary = {}
var BYTES_TO_UNICODE_CACHE: Dictionary = {}

func _ready():
	pass

func encode(text: String) -> Array:
	if text.is_empty():
		return []
	
	var byte_encoder: Dictionary = bytes_to_unicode()
	var pat: String = "'s|'t|'re|'ve|'m|'ll|'d| ?\\p{L}+| ?\\p{N}+| ?[^\\s\\p{L}\\p{N}]+|\\s+(?!\\S)|\\s+"
	var matches = RegEx.new().compile(pat).search_all(text)

	var bpe_tokens: Array = []
	for match in matches.get_strings():
		var token: String = String.new(UTF8.to_utf8(match)).utf8_to_charlist().map(func(x): byte_encoder[x]).join("")
		var new_tokens: Array = byte_pair_encoding(token).split(" ").map(func(x): GPT3Settings.ENCODER[x])
		bpe_tokens += new_tokens

	return bpe_tokens

func ord(x: String) -> int:
	return x.unicode_escape()[1]

func bytes_to_unicode() -> Dictionary:
	if BYTES_TO_UNICODE_CACHE != null:
		return BYTES_TO_UNICODE_CACHE

	var bytes: Array = range(ord("!"), ord("~") + 1).concat(range(ord("¡"), ord("¬") + 1)).concat(range(ord("®"), ord("ÿ") + 1))
	var chars: Array = bytes.map(func(x): chr(x))

	var n = 0
	for b in range(0, 256):
		if bytes.has(b):
			continue
		bytes.append(b)
		chars.append(chr(256 + n))
		n += 1

	BYTES_TO_UNICODE_CACHE = bytes.zip(chars).to_dict()
	return BYTES_TO_UNICODE_CACHE

func byte_pair_encoding(token: String) -> String:
	if BPE_CACHE.has(token):
		return BPE_CACHE[token]

	var word: Array = token.chars()
	var pairs: Array = get_pairs(word)
	if pairs.empty():
		BPE_CACHE[token] = token
		return token

	while true:
		var min_pairs: Dictionary = {}
		for pair in pairs:
			if GPT3Settings.BPE_RANKS.has(pair):
				var rank: int = GPT3Settings.BPE_RANKS[pair]
				min_pairs[rank] = pair
			else:
				min_pairs[100000000000] = pair

		var bi_gram = min_pairs[min(min_pairs.keys())]
		if not GPT3Settings.BPE_RANKS.has(bi_gram):
			break

		var first = bi_gram[0]
		var second = bi_gram[1]

		var new_word: Array = []
		var i = 0

		while i < word.size():
			var j = word.find(first, i)

			if j == -1:
				var slice = word.slice(i, word.size() - 1)
				new_word += slice
				break
	
			var slice2 = word.slice(i, j - 1)
			new_word += slice2
			i = j
	
			if word[i] == first and i < (word.size() - 1) and word[i + 1] == second:
				new_word.append("%s%s" % [first, second])
				i += 2
			else:
				new_word.append(word[i])
				i += 1
			
			word = new_word
			if word.size() == 1:
				break
			pairs = get_pairs(word)
			
			var result: String = word.join(" ")
			BPE_CACHE[token] = result
			return result



func get_pairs(word: Array) -> Array:
	var result: Array = []
	var prev_char: String = word[0]
	for i in range(1, word.size()):
		var current_char: String = word[i]
		result.append([prev_char, current_char])
		prev_char = current_char

	return result
