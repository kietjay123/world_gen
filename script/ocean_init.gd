@tool
extends Node3D

@export var mesh : MeshInstance3D 
@export var stencil : MeshInstance3D 

func start(x : int, y : int) -> void :
	mesh.mesh.set_size(Vector2(x, y))
	mesh.mesh.set_subdivide_depth(y/4.0)
	mesh.mesh.set_subdivide_width(x/4.0)
	@warning_ignore("integer_division")
	stencil.set_scale(Vector3(x/2, x/2, x/2))
