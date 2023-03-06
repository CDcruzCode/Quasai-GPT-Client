extends PanelContainer

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()
		return
