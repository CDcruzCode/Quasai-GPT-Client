extends OptionButton

func init_theme_options():
	self.item_selected.connect(theme_selected)
	
	
	var themes_list:PackedStringArray = globals.list_folders_in_directory("user://themes/")
	print(themes_list)
	for t in themes_list:
		if(t.get_extension() == "tres"):
			var theme_name:String = t.trim_suffix(".tres")
			self.add_item(theme_name)
	
	globals.set_button_by_text(self, globals.THEME)
	globals.set_new_theme()


func theme_selected(index:int):
	var selected_theme:String = self.get_item_text(index)
	if(selected_theme == globals.THEME):
		return
	
	if(globals.load_file_as_string("user://themes/"+selected_theme+".tres") == "error"):
		globals.set_button_by_text(self, "Default")
		globals.THEME = "Default"
	else:
		globals.THEME = selected_theme
	
	globals.set_new_theme()
