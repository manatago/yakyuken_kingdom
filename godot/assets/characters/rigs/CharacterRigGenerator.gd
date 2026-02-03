extends SceneTree

## Character Rig Generator
## Generates Skeleton2D + Polygon2D rig from a sprite sheet with separated parts.
## Run: godot --headless --script res://assets/characters/rigs/CharacterRigGenerator.gd

const TEXTURE_PATH := "res://assets/characters/samples/char01-skeleton-transparent.png"
const OUTPUT_PATH := "res://assets/characters/rigs/char01_rig.tscn"

# Image dimensions
const IMAGE_WIDTH := 1408
const IMAGE_HEIGHT := 3040

# Part bounding boxes (detected from image)
var parts := {
	"head": {
		"bounds": Rect2(322, 5, 756, 970),
		"pivot": Vector2(700, 500),
	},
	"body": {
		"bounds": Rect2(311, 1405, 808, 1635),
		"pivot": Vector2(715, 1500),
	},
	"right_arm": {
		"bounds": Rect2(7, 893, 311, 1453),
		"pivot": Vector2(250, 950),
	},
	"left_arm": {
		"bounds": Rect2(1047, 870, 361, 1516),
		"pivot": Vector2(1100, 930),
	},
}

# Bone structure definition
var bone_structure := {
	"root": {
		"position": Vector2(700, 2200),
		"children": {
			"spine": {
				"position": Vector2(0, -300),
				"children": {
					"chest": {
						"position": Vector2(0, -250),
						"children": {
							"neck": {
								"position": Vector2(0, -150),
								"children": {
									"head": {
										"position": Vector2(0, -350),
										"children": {}
									}
								}
							},
							"left_shoulder": {
								"position": Vector2(-250, -50),
								"children": {
									"left_upper_arm": {
										"position": Vector2(-50, 200),
										"children": {
											"left_lower_arm": {
												"position": Vector2(0, 300),
												"children": {}
											}
										}
									}
								}
							},
							"right_shoulder": {
								"position": Vector2(250, -50),
								"children": {
									"right_upper_arm": {
										"position": Vector2(50, 200),
										"children": {
											"right_lower_arm": {
												"position": Vector2(0, 300),
												"children": {}
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
}

func _init() -> void:
	print("=== Character Rig Generator ===")

	# Create root node
	var rig_root := Node2D.new()
	rig_root.name = "Char01Rig"

	# Load texture
	var texture := load(TEXTURE_PATH) as Texture2D
	if not texture:
		push_error("Failed to load texture: " + TEXTURE_PATH)
		quit(1)
		return
	print("Loaded texture: ", TEXTURE_PATH)

	# Create Skeleton2D
	var skeleton := Skeleton2D.new()
	skeleton.name = "Skeleton2D"
	rig_root.add_child(skeleton)
	skeleton.owner = rig_root

	# Create bones recursively
	_create_bones(skeleton, bone_structure, rig_root)

	# Create Polygon2D for each part
	for part_name in parts:
		var polygon := _create_polygon_for_part(part_name, parts[part_name], texture)
		polygon.skeleton = polygon.get_path_to(skeleton)
		rig_root.add_child(polygon)
		polygon.owner = rig_root

	# Create AnimationPlayer
	var anim_player := AnimationPlayer.new()
	anim_player.name = "AnimationPlayer"
	rig_root.add_child(anim_player)
	anim_player.owner = rig_root

	# Create a simple idle animation
	_create_idle_animation(anim_player, skeleton)

	# Save scene
	var packed_scene := PackedScene.new()
	var result := packed_scene.pack(rig_root)
	if result == OK:
		var save_result := ResourceSaver.save(packed_scene, OUTPUT_PATH)
		if save_result == OK:
			print("Scene saved to: ", OUTPUT_PATH)
		else:
			push_error("Failed to save scene: " + str(save_result))
			quit(1)
			return
	else:
		push_error("Failed to pack scene: " + str(result))
		quit(1)
		return

	print("=== Generation Complete ===")
	quit(0)


func _create_bones(parent: Node, structure: Dictionary, scene_root: Node) -> void:
	for bone_name in structure:
		var bone_data: Dictionary = structure[bone_name]
		var bone := Bone2D.new()
		bone.name = bone_name
		bone.position = bone_data["position"]

		parent.add_child(bone)
		bone.owner = scene_root

		if bone_data.has("children") and bone_data["children"].size() > 0:
			_create_bones(bone, bone_data["children"], scene_root)


func _create_polygon_for_part(part_name: String, part_data: Dictionary, texture: Texture2D) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.name = part_name + "_mesh"
	polygon.texture = texture

	var bounds: Rect2 = part_data["bounds"]
	var pivot: Vector2 = part_data["pivot"]

	var subdivisions := 3

	var vertices := PackedVector2Array()
	var uvs := PackedVector2Array()

	# Create grid of vertices
	for y in range(subdivisions + 1):
		for x in range(subdivisions + 1):
			var t_x := float(x) / float(subdivisions)
			var t_y := float(y) / float(subdivisions)

			# Vertex position (relative to pivot)
			var vx := bounds.position.x + bounds.size.x * t_x - pivot.x
			var vy := bounds.position.y + bounds.size.y * t_y - pivot.y
			vertices.append(Vector2(vx, vy))

			# UV coordinates (normalized to texture size)
			var uv_x := (bounds.position.x + bounds.size.x * t_x) / IMAGE_WIDTH
			var uv_y := (bounds.position.y + bounds.size.y * t_y) / IMAGE_HEIGHT
			uvs.append(Vector2(uv_x, uv_y))

	polygon.polygon = vertices
	polygon.uv = uvs
	polygon.position = pivot

	return polygon


func _create_idle_animation(anim_player: AnimationPlayer, skeleton: Skeleton2D) -> void:
	var anim := Animation.new()
	anim.length = 2.0
	anim.loop_mode = Animation.LOOP_LINEAR

	# Subtle breathing animation to spine
	var track_idx := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_idx, "Skeleton2D/root/spine:rotation")
	anim.track_insert_key(track_idx, 0.0, 0.0)
	anim.track_insert_key(track_idx, 1.0, deg_to_rad(1.5))
	anim.track_insert_key(track_idx, 2.0, 0.0)

	# Subtle head movement
	var head_track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(head_track, "Skeleton2D/root/spine/chest/neck/head:rotation")
	anim.track_insert_key(head_track, 0.0, 0.0)
	anim.track_insert_key(head_track, 1.0, deg_to_rad(-1.0))
	anim.track_insert_key(head_track, 2.0, 0.0)

	var lib := AnimationLibrary.new()
	lib.add_animation("idle", anim)
	anim_player.add_animation_library("", lib)
