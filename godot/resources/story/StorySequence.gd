extends Resource
class_name StorySequence

var id: String = ""
var entries: Array[StoryCommand] = []

func play(scene):
	for entry in entries:
		if entry == null:
			continue
		var result = entry.execute(scene)
		if result is Signal:
			await result
