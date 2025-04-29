extends SetPlan

func _on_top_plus_button_pressed():	
	_on_add_helper(checkpt, self.get_index(), top_plus_button)
	_on_add_helper(top_plus_button, self.get_index() - 1, top_plus_button)
	
	var vbox = VBoxContainer.new()
	get_parent().add_child(vbox)
	get_parent().move_child(vbox, self.get_index() - 1)
