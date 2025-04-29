extends Node

var parent

# Called when the node enters the scene tree for the first time.
func _ready():
	parent = JavaScriptBridge.get_interface("parent")
	SignalBus.send_to_parent_html_frame.connect(_send_data)

'''
autoproceed - automatically move to the next page in the study
allowproceed - allow participant to move to the next page themselves
log - contains the participant log
results - contains participant results
itemOrder - contains the order of objects that participants experienced
resultsPixelValues - contains raw participant results in terms of pixel values
'''
func _send_data(category: String, data: String) -> void:
	match OS.get_name():
		"Web":
			parent.postMessage(category + ": " + data, '*')
		_:
			pass#print(category + ": " + data)
