extends "res://resources/story/commands/StoryCommand.gd"
class_name MockDialogueEntry

const MockSignalSource := preload("res://tests/mocks/MockSignalSource.gd")

var identifier: String = ""
var returns_signal := false
var applied := false
var signal_emitted := false

func execute(_scene):
	applied = true
	if returns_signal:
		var source := MockSignalSource.new()
		source.completed.connect(func(): signal_emitted = true)
		source.trigger()
		return source.completed
	return null
