extends RefCounted
class_name StoryChapterBase

const StoryDsl := preload("res://resources/story/dsl/StoryDsl.gd")

func register_sequences(target_script, cast) -> void:
	if target_script == null or cast == null:
		push_warning("StoryChapterBase.register_sequences called without script or cast")
		return

	for definition in get_sequence_builders():
		var sequence_id: String = definition.get("id", "")
		var builder_name: String = definition.get("builder", "")
		if sequence_id.is_empty() or builder_name.is_empty():
			continue
		if not has_method(builder_name):
			push_warning("Missing builder method %s for chapter %s" % [builder_name, get_class()])
			continue

		var dsl := StoryDsl.new(cast)
		var sequence := dsl.build(sequence_id, Callable(self, builder_name))
		if sequence:
			target_script.register_sequence(sequence)

func get_sequence_builders() -> Array:
	return []

func sequence_builder(sequence_id: String, method_name: String) -> Dictionary:
	return {
		"id": sequence_id,
		"builder": method_name,
	}
