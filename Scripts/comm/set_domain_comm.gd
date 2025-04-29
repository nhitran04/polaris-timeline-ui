'''
License: 
Licenses of Others' Code: None

In writing this code, the following was used as a reference without copying:
	https://docs.godotengine.org/en/stable/tutorials/networking/http_request_class.html
'''

extends HTTPRequest

var ip: String
						
func request_domain(ipaddr: String):
	self.ip = ipaddr
	var headers = ["Content-Type: application/json"]
	var domain_name = {"domain": Options.opts.domain}
	self.request_completed.connect(_cb_request_completed)
	print("Requesting " + "http://" + ip + ":5000/set_domain")
	self.request("http://" + ip + ":5000/set_domain",
						 headers,
						 HTTPClient.METHOD_POST,
						 JSON.stringify(domain_name))
	#self.request("https://backend-615592958900.us-east4.run.app/set_domain",
						 #headers,
						 #HTTPClient.METHOD_POST,
						 #JSON.stringify(domain_name))

func _cb_request_completed(result, _response_code, _headers, body) -> void:
	if result == 0:
		var json = JSON.parse_string(body.get_string_from_utf8())
		Domain.add_domain(json)
		SignalBus.reset_predicates.emit()
		SignalBus.domain_received.emit()
		get_parent().remove_child(self)
		queue_free()
	else:
		print("Could not contact domain. Retrying...")
		request_domain(self.ip)
