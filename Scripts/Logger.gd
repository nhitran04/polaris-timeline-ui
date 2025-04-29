extends Node

var frontend_log: String

func _ready() -> void:
	frontend_log = ""
	SignalBus.dump_frontend_log.connect(_dump_frontend_log)

func log_event(subject: String, data: Dictionary) -> void:
	# TODO: this is messy code
	if "log_to_backend" in Options.opts and Options.opts.log_to_backend:
		SignalBus.log_to_backend.emit(
			Time.get_ticks_msec(),
			subject,
			data
		)
	if "log_to_frontend" in Options.opts and Options.opts.log_to_frontend:
		var time: String = str(Time.get_ticks_msec())
		var s: String = time + " - " + subject + ": " + str(data) + "\n"
		#print(s)
		frontend_log += s
		
func _dump_frontend_log() -> void:
	SignalBus.send_to_parent_html_frame.emit("log", frontend_log)
