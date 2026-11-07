@tool
extends Node3D

@export_tool_button("Create", "Callable") var Create = test
@export var stencil : MeshInstance3D 
@export var size : int  
@export var tile : ArrayMesh
var ring : int  

func test() -> void :
	start(1000, 1000)

@warning_ignore("unused_parameter")
func start(x : int, y : int) -> void :
	stencil.set_scale(Vector3(x/2.0, x/2.0, x/2.0))
	var borderSize : int = ceili(x/float(size))
	ring = ceili(borderSize/2.0)
	renderGrid()


func renderGrid() -> void :
	var parent : Node3D = get_node("tiles")
	for i in parent.get_children() :
		i.queue_free()
	var dir : Array[Vector3] = [
		Vector3(1,0,0),
		Vector3(0,0,1),
		Vector3(-1,0,0),
		Vector3(0,0,-1),
	]
	var startDir : Array[Vector3] = [
		Vector3(-sqrt(2)/2,0,-sqrt(2)/2),
		Vector3(sqrt(2)/2,0,-sqrt(2)/2),
		Vector3(sqrt(2)/2,0,sqrt(2)/2),
		Vector3(-sqrt(2)/2,0,sqrt(2)/2),
	]
	for i in ring :
		var length : float = ((size * i) * sqrt(2)) + ((size * sqrt(2))/2)
		for j in 4 :
			var startPos : Vector3 = startDir[j] * length
			for k in ((i + 1) * 2) - 1 :
				var meshNode : MeshInstance3D = MeshInstance3D.new()
				parent.add_child(meshNode)
				meshNode.owner = get_tree().edited_scene_root
				
				meshNode.set_position(startPos + (dir[j] * size * k))
				meshNode.set_mesh(tile)
				meshNode.set_lod_bias(0.001)
				
