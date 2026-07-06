@tool
extends EditorScript

const BASE_ASSET_PATH = "res://assets/test/ver color.glb"
const OUTPUT_SCENE_PATH = "res://assets/test/ver color.tscn"

func _run() -> void:
	print(ResourceLoader.list_directory("res://assets/test/"))
	var base_scene: PackedScene = load(BASE_ASSET_PATH)
	if not base_scene:
		printerr("Failed to load base asset at: ", BASE_ASSET_PATH)
		return
		
	# 2. Instantiate the base scene to establish inheritance
	var base_instance: Node = base_scene.instantiate()
	
	# 3. Create a new empty PackedScene to house the inherited root
	var inherited_scene = PackedScene.new()
	
	# IMPORTANT: Mark the instance so Godot knows it is an inherited scene
	base_instance.scene_file_path = BASE_ASSET_PATH
	
	# 4. Pack the instance configuration into the new scene
	var pack_result = inherited_scene.pack(base_instance)
	if pack_result != OK:
		printerr("Failed to pack the inherited scene. Error code: ", pack_result)
		base_instance.queue_free()
		return
		
	# 5. Save the generated .tscn file to your project directory
	var save_result = ResourceSaver.save(inherited_scene, OUTPUT_SCENE_PATH)
	if save_result == OK:
		print("Successfully automated inherited scene creation at: ", OUTPUT_SCENE_PATH)
	else:
		printerr("Failed to save inherited scene. Error code: ", save_result)
		
	# Clean up memory
	base_instance.queue_free()
