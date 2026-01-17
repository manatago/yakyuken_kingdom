extends Resource
class_name StoryScript

const StoryCast := preload("res://resources/story/StoryCast.gd")

var _cast: StoryCast = StoryCast.new()
var _sequences: Dictionary = {}

func set_cast(cast: StoryCast) -> void:
	_cast = cast if cast else StoryCast.new()

func get_cast() -> StoryCast:
	return _cast

func register_sequence(sequence: StorySequence) -> void:
	if sequence == null:
		return
	if sequence.id.is_empty():
		push_warning("StorySequence missing id; skipping registration")
		return
	_sequences[sequence.id] = sequence

func register_sequences(sequences: Array[StorySequence]) -> void:
	for sequence in sequences:
		register_sequence(sequence)

func get_sequence(sequence_id: String) -> StorySequence:
	return _sequences.get(sequence_id, null)

func get_sequence_ids() -> Array[String]:
	return _sequences.keys()

func clear_sequences() -> void:
	_sequences.clear()
