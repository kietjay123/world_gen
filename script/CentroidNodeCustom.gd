class_name CentroidNodeCustom extends "res://script/graphNode.gd"

@export var vertices : Array[GraphNodeCustom] = [] 

func _init(parName : String, parPosition : Vector3, parNeighbour : Array[GraphNodeCustom] = [], parVertices : Array[GraphNodeCustom] = []) -> void:
	super(parName, parPosition, parNeighbour)
	self.vertices = parVertices

func _ready() -> void:
	set_gizmo_extents(2.0)

func get_verticies() -> Array[GraphNodeCustom] :
	return vertices

func set_vertices(parVertices : Array[GraphNodeCustom]) -> void :
	vertices = parVertices
