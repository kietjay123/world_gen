@tool
extends Node

## The folder where you want to save the individual scenes (must end with a slash /).
@export var output_folder: String = "res://assets/tiles/scenes/"

@export var script_to_attach : Script  = load("res://script/MeshDistortionTool.gd")
@export var material_to_set : Material = load("res://shader/universeTileMat.tres")

## Click this checkbox in the Inspector to run the export process.
@export var trigger_export: bool = false:
	set(value):
		if value and Engine.is_editor_hint():
			run_export()
		trigger_export = false # Immediately resets the checkbox

func run_export() -> void:
	if not DirAccess.dir_exists_absolute(output_folder):
		DirAccess.make_dir_absolute(output_folder)
		print("Created output directory: ", output_folder)

	print("Starting scene export...")
	var export_count: int = 0

	for child in get_children():
		child.set_position(Vector3(0, 0, 0))
		child.set_script(script_to_attach)
		for childChilren in child.get_children() :
			childChilren.set_position(Vector3(0, 40, 0))
			childChilren.get_mesh().surface_set_material(0, material_to_set)
		
		# Create a clean, sanitized file name from the node name
		# Sanitizing replaces characters like '(' and ')' with underscores to keep file paths safe
		var sanitized_name: String = child.name.validate_node_name().to_lower()
		var file_path: String = output_folder + sanitized_name + ".scn"
		
		# PackedScene requires the root of the packed scene to have an empty owner.
		# However, it needs its own children (like model_0) to keep their original owner relationships.
		# We temporarily detach the child's owner, pack it, and restore it.
		var original_owner = child.owner
		child.owner = null
		
		# Set owners of the grandchildren (the actual meshes) to the new sub-root
		_set_owner_recursive(child, child)

		# Pack the node into a scene file
		var packed_scene: PackedScene = PackedScene.new()
		var result: Error = packed_scene.pack(child)
		
		if result == OK:
			var save_result: Error = ResourceSaver.save(packed_scene, file_path)
			if save_result == OK:
				print("Successfully saved: ", file_path)
				export_count += 1
			else:
				printerr("Failed to save file to disk: ", file_path, " Error code: ", save_result)
		else:
			printerr("Failed to pack node: ", child.name, " Error code: ", result)
			
		# Restore original owner so your open scene doesn't break/corrupt
		child.owner = original_owner
		_set_owner_recursive(child, original_owner)

	print("Export complete! Total scenes generated: ", export_count)


# not needed might return 
func extract_border_vertex_indices(mesh: ArrayMesh) -> Array[Array]:
	var indices: Array[Array] = [[],[]]
	if not mesh or mesh.get_surface_count() == 0:
		return indices
	var verts : Array = []
	var surface_arrays: Array = mesh.surface_get_arrays(0)
	verts = surface_arrays[Mesh.ARRAY_VERTEX]

	if verts == null or verts.is_empty():
		printerr("Warning: Mesh has no vertex color data.")
		return indices
	
	var customSort = func(a: int, b: int) -> bool :
		var vecA : Vector3 = verts[a]
		var vecB: Vector3 = verts[b]
		return vecA > vecB
	
	var up : Array[int] = []
	var right : Array[int] = []
	var down : Array[int] = []
	var left : Array[int] = []
	for i in range(verts.size()):
		var pos: Vector3 = verts[i]
		if is_equal_approx(pos.z, -40) :
			up.append(i)
		elif is_equal_approx(pos.z, 40) :
			down.append(i)
		if is_equal_approx(pos.x, 40) :
			right.append(i)
		elif is_equal_approx(pos.x, -40) :
			left.append(i)
	up.sort_custom(customSort)
	right.sort_custom(customSort)
	down.sort_custom(customSort)
	left.sort_custom(customSort)
	indices[0] = [up, right, down, left]
	
	var corners : Array[Array] = []
	for i in 4 :
		var side: Array = indices[0][i]
		if not side.is_empty():
			var a: int = side[0]
			var b: int = side[-1]
			corners.append([a, b])
		else:
			corners.append([])
	indices[1] = corners
	return indices


# Helper function to ensure mesh sub-children are saved inside the packed scene
func _set_owner_recursive(node: Node, new_owner: Node) -> void:
	for child in node.get_children():
		child.owner = new_owner
		_set_owner_recursive(child, new_owner)
