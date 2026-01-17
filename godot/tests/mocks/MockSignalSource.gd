extends RefCounted
class_name MockSignalSource

signal completed

func trigger() -> void:
	call_deferred("emit_signal", "completed")
