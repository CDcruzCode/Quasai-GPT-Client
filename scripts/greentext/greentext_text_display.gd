extends TextEdit

var code_theme:CodeHighlighter = CodeHighlighter.new()

func _ready():
	code_theme.number_color = Color("#843e40")
	code_theme.symbol_color = Color("#843e40")
	code_theme.function_color = Color("#843e40")
	code_theme.member_variable_color = Color("#843e40")
	code_theme.add_color_region(">", "", Color("#68A035"), true)
	self.set("theme_override_colors/font_color", Color("#843e40"))
	
	self.syntax_highlighter = code_theme
