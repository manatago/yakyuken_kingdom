extends Node3D
class_name ParallaxBackground3D

@export var camera_path: NodePath
@export var background_texture: Texture2D
@export var mesh_size: Vector3 = Vector3(40, 20, 0)
@export var distance: float = 20.0

@onready var mesh_instance: MeshInstance3D = MeshInstance3D.new()

func _ready():
    add_child(mesh_instance)
    mesh_instance.mesh = QuadMesh.new()
    mesh_instance.mesh.size = Vector2(mesh_size.x, mesh_size.y)
    mesh_instance.position = Vector3(0, camera_position_y(), -distance)
    _update_texture()

func set_texture(texture: Texture2D):
    background_texture = texture
    _update_texture()

func _update_texture():
    if background_texture == null:
        mesh_instance.visible = false
        return
    mesh_instance.visible = true
    var material := StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.albedo_texture = background_texture
    material.albedo_color = Color(1, 1, 1)
    mesh_instance.material_override = material

func camera_position_y() -> float:
    if has_node(camera_path):
        var cam := get_node(camera_path)
        if cam:
            return cam.global_position.y
    return 0.0
