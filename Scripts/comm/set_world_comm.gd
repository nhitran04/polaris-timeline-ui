'''
License: 
Licenses of Others' Code: None

In writing this code, the following was used as a reference without copying:
	https://docs.godotengine.org/en/stable/tutorials/networking/http_request_class.html
'''

extends HTTPRequest
	
func broadcast_world(world: Dictionary, ip: String):
	var headers = ["Content-Type: application/json"]
	self.request_completed.connect(_cb_request_completed)
	print("Requesting " + "http://" + ip + ":5000/set_world")
	print(world)
	self.request("http://" + ip + ":5000/set_world",
						 headers,
						 HTTPClient.METHOD_POST,
						 JSON.stringify(world))
	#self.request("https://backend-615592958900.us-east4.run.app/set_world",
						 #headers,
						 #HTTPClient.METHOD_POST,
						 #JSON.stringify(world))
						
func _cb_request_completed(_result, _response_code, _headers, _body) -> void:
	get_parent().remove_child(self)
	queue_free()
