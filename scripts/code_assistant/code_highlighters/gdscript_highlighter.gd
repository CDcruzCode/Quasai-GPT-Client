extends Node

var text_input:CodeEdit
var code_theme:CodeHighlighter = CodeHighlighter.new()

func _ready():
	text_input = self.get_parent()
	print("GDscript highlighter loaded.")
	code_theme.number_color = Color("#a1fee0")
	code_theme.symbol_color = Color("#abc8ff")
	code_theme.function_color = Color("#57b2ff")
	code_theme.member_variable_color = Color("#cdced2")
	
	const statement_color:Color = Color("#ff7085")
	const statements:PackedStringArray = [
		"if",
		"elif",
		"else",
		"for",
		"in",
		"while",
		"match",
		"return",
		"func",
		"super",
		"break",
		"continue",
		"class",
		"class_name",
		"extends",
		"is",
		"in",
		"as",
		"self",
		"signal",
		"static",
		"const",
		"enum",
		"var",
		"breakpoint",
		"preload",
		"await",
		"yeild",
		"assert",
		"void",
		"PI",
		"TAU",
		"INF",
		"NAN",
		"not",
		"and",
		"or",
		"true",
		"false"
	]
	
	for s in statements:
		code_theme.add_keyword_color(s, statement_color)
	
	const base_class_color:Color = Color("#8effda")
	const base_classes:PackedStringArray = [
		"Color",
		"PackedByteArray",
		"PackedFloat32Array",
		"PackedColorArray",
		"PackedDataContainer",
		"PackedFloat64Array",
		"PackedInt32Array",
		"PackedInt64Array",
		"PackedScene",
		"PackedStringArray",
		"PackedVector2Array",
		"PackedVector3Array",
		"PacketPeerDTLS",
		"PacketPeer",
		"PackedDataContainer",
		"PackedDataContainerRef",
		"Time",
		"OS",
		"SceneMultiplayer",
		"SceneReplicationConfig",
		"SceneState",
		"SceneTree",
		"SceneTreeTimer",
		"JSON",
		"JSONRPC",
		"JNISingleton",
		"FileAccess",
		"DirAccess",
		"Vector2",
		"Vector2i",
		"Vector3",
		"Vector3i",
		"Vector4",
		"Vector4i"
	]
	for b in base_classes:
		code_theme.add_keyword_color(b, base_class_color)
	
	
	
	
	code_theme.add_color_region("#", "", Color("#CCCED380"), true)
	code_theme.add_color_region("\"", "\"", Color("#ffeca1"), false)
	code_theme.add_color_region("@", " ", Color("#ffb373"), true)
	
	code_theme.update_cache()
	text_input.syntax_highlighter = code_theme
