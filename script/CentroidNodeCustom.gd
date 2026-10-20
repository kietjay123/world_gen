class_name CentroidNodeCustom extends "res://script/graphNode.gd"

@export var centroidTileType : String = ""

@export var vertices : Array[GraphNodeCustom] = [] 

@export var riverFrom : CentroidNodeCustom :
	set = set_river_from

@export var riverTo : Array[CentroidNodeCustom] = []  

@export var pathable : Array[bool] = [false, false, false, false]
@export var pathed : Array[bool] = [false, false, false, false]

func _init(parName : String, parPosition : Vector3, parNeighbour : Array[GraphNodeCustom] = [], parVertices : Array[GraphNodeCustom] = []) -> void:
	super(parName, parPosition, parNeighbour)
	self.vertices = parVertices

func _ready() -> void:
	set_gizmo_extents(2.0)

func get_verticies() -> Array[GraphNodeCustom] :
	return vertices

func set_vertices(parVertices : Array[GraphNodeCustom]) -> void :
	vertices = parVertices

func get_centroid_tile_type() -> String:
	set_centroid_tile_type()
	return centroidTileType

func set_centroid_tile_type() -> void:
	centroidTileType = ""
	var terrainString  := ""
	for i in get_verticies().size() :
		terrainString += get_verticies()[i].get_type_string()
	var riverString : String = "0000"
	var pathString : String = "0000"
	if is_river() :
		if !riverFrom:
			riverString[neighbour.find(riverTo[0])] = "2"
		elif riverTo.is_empty() :
			riverString[neighbour.find(riverFrom)] = "1"
		else :
			riverString[neighbour.find(riverFrom)] = "1"
			for i in riverTo.size() :
				riverString[neighbour.find(riverTo[i])] = "2"
	for i in pathed.size() :
		if pathed[i] == true :
			pathString[i] = "1"
	centroidTileType = pathString + riverString + terrainString

var reverseTypeLookUp : Dictionary[String, String] =  {"W" : "0", "L" : "1", "M" : "2"}

func baseThreeToBaseTen(arg : String) -> int :
	var result : int  = 0
	var power : int = 0
	for i in range(arg.length() - 1, -1, -1) :
		result += arg[i].to_int() * (3 ** power)
		power += 1
	return result 

func getCentroidCode() -> int :
	var localTileType : String = get_centroid_tile_type()
	var terrainCode : String = localTileType.right(4)
	var tileTypeBaseThree : String = ""
	for ii in terrainCode :
		tileTypeBaseThree += reverseTypeLookUp[ii]
	localTileType  = localTileType.left(-4) + tileTypeBaseThree
	var tileTypeBaseTen : int = baseThreeToBaseTen(localTileType)
	return tileTypeBaseTen

func get_river_from() -> CentroidNodeCustom :
	return riverFrom

func set_river_from(value : CentroidNodeCustom) -> void :
	if modable == true :
		for i in vertices :
			i.modable = false
	modable = false
	riverFrom = value
	var fromIdx := neighbour.find(riverFrom)
	if get_child_count() == 0 :
		return 
	
	if fromIdx != -1 :
		get_child(fromIdx).setColor(Color.CYAN)

func set_river_to(value : Array[CentroidNodeCustom]) -> void :
	riverTo = value 

func add_river_to(value : CentroidNodeCustom) -> void :
	if modable == true :
		for i in vertices :
			i.modable = false
	modable = false
	riverTo.append(value)
	var toIdx := neighbour.find(riverTo[-1])
	if get_child_count() == 0 :
		return 
	
	if toIdx != -1 :
		get_child(toIdx).setColor(Color.BLACK)

func get_river_to() -> Array[CentroidNodeCustom] :
	return riverTo

func is_river() -> bool :
	return true if riverFrom || !riverTo.is_empty() else false

func get_terrain_code() -> int :
	var localTileType : String = get_centroid_tile_type()
	var terrainCode : String = localTileType.right(4)
	var tileTypeBaseThree : String = ""
	for ii in terrainCode :
		tileTypeBaseThree += reverseTypeLookUp[ii]
	var tileTypeBaseTen : int = baseThreeToBaseTen(tileTypeBaseThree)
	return tileTypeBaseTen

func get_terrain_code_string() -> String :
	var localTileType : String = get_centroid_tile_type()
	var terrainCode : String = localTileType.right(4)
	return terrainCode

func clearRiver() -> void :
	riverFrom = null
	riverTo = []

func getLineColor(_neighbor : CentroidNodeCustom) -> Color :
	if pathable[neighbour.find(_neighbor)] == true :
		if pathed[neighbour.find(_neighbor)] == true :
			return Color.BLUE_VIOLET
		return Color.CORAL
	if is_river() :
		if _neighbor == riverFrom :
			return Color.CYAN
		elif riverTo.has(_neighbor) :
			return Color.BLACK
	return Color.WHITE

func createNeighborLine() -> void:
	for j in neighbour :
			if j :
				var neighbourLine : Line3D = Line3D.new(Vector3.ZERO, Vector3.ZERO.lerp(j.position - position, 0.5), getLineColor(j))
				add_child(neighbourLine)
				neighbourLine.owner = get_tree().edited_scene_root

func get_pathable() -> Array[bool] :
	return pathable
func set_pathable(_pathable : Array[bool]) -> void :
	_pathable = pathable
func set_pathable_single(idx : int , value : bool) -> void :
	pathable[idx] = value

func get_pathed() -> Array[bool] :
	return pathed
func set_pathed(_path : Array[bool]) :
	pathed = _path 

func neighbourIsPathed(_neighbour : CentroidNodeCustom) -> bool :
	var idx : int = neighbour.find(_neighbour)
	if idx == -1 :
		return false
	elif pathed[idx] == false :
		return false
	else :
		return true
