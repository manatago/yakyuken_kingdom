extends Node
class_name MockStoryScene

var play_line_calls: Array = []
var play_line_result = null

func play_line(entry):
	play_line_calls.append(entry)
	return play_line_result
