extends "res://resources/story/commands/StoryCommand.gd"
class_name MockDialogueEntry

const MockSignalSource := preload("res://tests/mocks/MockSignalSource.gd")

var identifier: String = ""
var returns_signal := false
var applied := false
var signal_emitted := false
var _signal_source = null  # Keep reference to prevent GC

func execute(_scene):
	applied = true
	if returns_signal:
		_signal_source = MockSignalSource.new()
		_signal_source.completed.connect(func(): signal_emitted = true)
		_signal_source.trigger()
		return _signal_source.completed
	return null
