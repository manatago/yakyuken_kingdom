extends "res://resources/story/commands/StoryCommand.gd"
class_name StoryHideDialogueCommand

func execute(scene):
	return scene.hide_dialogue_command(self)
