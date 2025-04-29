'''
License: 
Licenses of Others' Code: None

In writing this code, the following was used as a reference without copying:
	https://docs.godotengine.org/en/stable/tutorials/networking/http_request_class.html
'''

extends HTTPRequest

# instance variables
var status_indicators: Control
var request_disabled := false

func _ready() -> void:
	SignalBus.disable_existing_requests.connect(_disable_request)
	
func push_goal_automaton(goal_automaton: Dictionary, ip: String):
	SignalBus.disable_existing_requests.emit(self)
	var headers = ["Content-Type: application/json"]
	self.request_completed.connect(_cb_request_completed)
	print("Requesting " + "http://" + ip + ":5000/goal_automaton")
	self.request("http://" + ip + ":5000/goal_automaton",
						 headers,
						 HTTPClient.METHOD_POST,
						 JSON.stringify(goal_automaton))
	#self.request("https://backend-615592958900.us-east4.run.app/goal_automaton",
						 #headers,
						 #HTTPClient.METHOD_POST,
						 #JSON.stringify(goal_automaton))
	#status_indicators.get_node("wait_icon").visible = true
	#status_indicators.get_node("Exceptions").visible = false

func _cb_request_completed(_result, _response_code, _headers, body) -> void:
	if not request_disabled:
		var json = JSON.parse_string(body.get_string_from_utf8())
		status_indicators.get_node("wait_icon").visible = false
		status_indicators.get_node("Exceptions").visible = true
		SignalBus.set_plan.emit(json)
	get_parent().remove_child(self)
	queue_free()
	
func set_status_indicators(node: Control):
	status_indicators = node

func _disable_request(other_request: Node) -> void:
	'''
	Disable this request if another request was made.
	'''
	if self != other_request:
		request_disabled = true
