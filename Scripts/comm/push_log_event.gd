'''
License: 
Licenses of Others' Code: None

In writing this code, the following was used as a reference without copying:
	https://docs.godotengine.org/en/stable/tutorials/networking/http_request_class.html
'''

extends HTTPRequest

var ip: String
						
func push_log_item(log_item: Dictionary, ip: String):
	var headers = ["Content-Type: application/json"]
	self.request_completed.connect(_cb_request_completed)
	print("Requesting " + "http://" + ip + ":5000/log")
	self.request("http://" + ip + ":5000/log",
						 headers,
						 HTTPClient.METHOD_POST,
						 JSON.stringify(log_item))
	#self.request("https://backend-615592958900.us-east4.run.app/log",
						 #headers,
						 #HTTPClient.METHOD_POST,
						 #JSON.stringify(log_item))

func _cb_request_completed(result, _response_code, _headers, body) -> void:
	pass
