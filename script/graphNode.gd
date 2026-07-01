class_name GraphNodeCustom extends Marker3D

@export var neighbour: Array[GraphNodeCustom] = [] :
	get = get_neighbour, set = set_neighbour

enum TYPE {WATER, LAND, MOUNTAIN}

var tileColor : Dictionary[TYPE, Color] = {
	TYPE.WATER : Color.from_rgba8(0,0,255),
	TYPE.LAND : Color.from_rgba8(0,255,0),
	TYPE.MOUNTAIN : Color.from_rgba8(108, 123, 109)
}
var tileTypeString : Dictionary[TYPE, String] = {
	TYPE.WATER : "W",
	TYPE.LAND : "L",
	TYPE.MOUNTAIN : "M"
}
@export var tileType : TYPE 

func _init(parName : String, parPosition : Vector3, parNeighbour : Array[GraphNodeCustom] = []) -> void:
	self.name = parName
	self.neighbour =  parNeighbour
	self.position =  parPosition

func _ready() -> void:
	set_gizmo_extents(5.0)


func get_neighbour() -> Array[GraphNodeCustom]:
	return neighbour

func set_neighbour(value) -> void:
	neighbour = value

func add_neighbour(value: GraphNodeCustom) -> void:
	neighbour.append(value)

func remove_neighbour(value: GraphNodeCustom) -> void:
	neighbour.erase(value)

func clear_neighbor() -> void :
	neighbour.clear()

func isNeighbor(node : GraphNodeCustom) -> bool :
	return true if neighbour.has(node) else false

func toString() -> String :
	return get_name()

func get_type() -> TYPE :
	return tileType

func get_type_string() -> String :
	return tileTypeString[get_type()]

func set_type(type : TYPE) -> void :
	tileType = type
	for i in get_children() :
		if i is Line3D :
			i.setColor(tileColor[get_type()])
