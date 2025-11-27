extends Area3D

@export var viewport: SubViewport
@export var mesh_instance: MeshInstance3D

func _input_event(camera, event, position, normal, shape_idx):
	if not viewport:
		return

	if event is InputEventMouse:
		var mouse_event = event.duplicate()

		# Calculate local position on the quad
		# Assuming the mesh is a QuadMesh centered at (0,0) with size (mesh_size.x, mesh_size.y)
		var mesh_size = mesh_instance.mesh.size

		# Transform global intersection point to local space of the mesh
		var local_pos = mesh_instance.to_local(position)

		# Map local position (-size/2 to size/2) to UV coordinates (0 to 1)
		# Note: In Godot, QuadMesh UVs usually start top-left (0,0) to bottom-right (1,1)
		# Local Y is up, so we need to flip Y for UV
		var uv_x = (local_pos.x / mesh_size.x) + 0.5
		var uv_y = 0.5 - (local_pos.y / mesh_size.y)

		# Map UV to viewport coordinates
		mouse_event.position = Vector2(uv_x * viewport.size.x, uv_y * viewport.size.y)
		mouse_event.global_position = mouse_event.position

		viewport.push_input(mouse_event)
