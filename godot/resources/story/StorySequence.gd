extends Resource
class_name StorySequence

const StoryBackgroundCommand := preload("res://resources/story/commands/StoryBackgroundCommand.gd")

var id: String = ""
var entries: Array[StoryCommand] = []
var _skipping := false

func play(scene):
	for entry in entries:
		if entry == null:
			continue
		if _skipping and entry is StoryBackgroundCommand:
			_skipping = false
		var result = entry.execute(scene)
		if result is Signal:
			if _skipping:
				scene._trigger_skip_advance()
			else:
				await result

func skip_to_next_background():
	_skipping = true
