@tool
extends Node3D

@export_tool_button("Create", "Callable") var Initialize = initializeEditor
@export_tool_button("Reset", "Callable") var Reset = reset
@export_tool_button("Update", "Callable") var update = updateMeshEditor
@export_tool_button("test", "Callable") var Test = test
@export var bilinear : bool = true
@export var mesh : MeshInstance3D = get_child(0) 
@export var boundArray : Array[Marker3D] = []
@export var boundArrayVector3 : Array[Vector3] = []
@export var markerPostion : Dictionary[String, Vector3] = {
	"b1" : Vector3.ZERO,
	"b2" : Vector3.ZERO,
	"b3" : Vector3.ZERO,
	"b4" : Vector3.ZERO,
	"t1" : Vector3.ZERO,
	"t2" : Vector3.ZERO,
	"t3" : Vector3.ZERO,
	"t4" : Vector3.ZERO,
}
@export var defaultBoundArray : Array = []
var defaultMesh : MeshDataTool = MeshDataTool.new()
var mdt : MeshDataTool = MeshDataTool.new()

const MESH_OFFSET : Vector3 = Vector3(40, 40, 40)
const TILE_SIZE : Vector3 = Vector3(80, 80, 80)

func test() -> void:
	boundArray[0].position = Vector3(1000, 1, 1000)
	boundArray[1].position = Vector3(1080, 1, 1000)
	boundArray[2].position = Vector3(1000, 1, 1080)
	boundArray[3].position = Vector3(1080, 1, 1080)
	updateMeshEditor()

func initializeEditor() -> void :
	for i in get_children() :
		if i.is_class("MeshInstance3D") :
			continue
		else :
			remove_child(i)
	boundArray.clear()
	defaultBoundArray.clear()
	mesh.mesh = mesh.mesh.duplicate()
	for i in 8 :
		var meshStart : Vector3 = mesh.get_aabb().position
		var meshSize : Vector3 = mesh.get_aabb().size
		var newMarker : Marker3D = Marker3D.new()
		
		add_child(newMarker)
		newMarker.owner = get_tree().edited_scene_root
		match i :
			0 :
				newMarker.position = meshStart + mesh.position
				newMarker.set_name("b1")
			1 :
				newMarker.position = Vector3(meshStart.x + meshSize.x, meshStart.y, meshStart.z) + mesh.position
				newMarker.set_name("b2")
			2 :
				newMarker.position = Vector3(meshStart.x, meshStart.y, meshStart.z + meshSize.z) + mesh.position
				newMarker.set_name("b3")
			3 :
				newMarker.position = Vector3(meshStart.x + meshSize.x, meshStart.y, meshStart.z + meshSize.z) + mesh.position
				newMarker.set_name("b4")
			4 :
				newMarker.position = meshStart + mesh.position + Vector3(0, meshSize.y, 0)
				newMarker.set_name("t1")
			5 :
				newMarker.position = Vector3(meshStart.x + meshSize.x, meshStart.y + meshSize.y, meshStart.z) + mesh.position
				newMarker.set_name("t2")
			6 :
				newMarker.position = Vector3(meshStart.x, meshStart.y + meshSize.y, meshStart.z + meshSize.z) + mesh.position
				newMarker.set_name("t3")
			7 :
				newMarker.position = Vector3(meshStart.x + meshSize.x, meshStart.y + meshSize.y, meshStart.z + meshSize.z) + mesh.position
				newMarker.set_name("t4")
		newMarker.set_gizmo_extents(3.0)
		boundArray.append(newMarker)
	defaultBoundArray = boundArray.map(func pos(marker : Marker3D): return marker.position)
	var transformedPos : Array = boundArray.map(func pos(marker): return marker.position)
	for j in transformedPos.size() :
		transformedPos[j] = calNewPositionScale(transformedPos[j])
	markerPostion["b1"] = transformedPos[0]
	markerPostion["b2"] = transformedPos[1]
	markerPostion["b3"] = transformedPos[2]
	markerPostion["b4"] = transformedPos[3]
	markerPostion["t1"] = transformedPos[4]
	markerPostion["t2"] = transformedPos[5]
	markerPostion["t3"] = transformedPos[6]
	markerPostion["t4"] = transformedPos[7]
	defaultMesh.create_from_surface(mesh.mesh, 0)

func initializeConstructor(parRotation : int, vertices : Array) -> void :
	for i in get_children() :
		if i.is_class("MeshInstance3D") :
			continue
		else :
			remove_child(i)
	boundArrayVector3.clear()
	defaultBoundArray.clear()
	#make mesh local
	mesh.mesh = mesh.mesh.duplicate()
	for i in 8 :
		var meshStart : Vector3 = mesh.get_aabb().position
		var meshSize : Vector3 = mesh.get_aabb().size
		var pos : Vector3 
		match i :
			0 :
				pos = meshStart + mesh.position
			1 :
				pos = Vector3(meshStart.x + meshSize.x, meshStart.y, meshStart.z) + mesh.position
			2 :
				pos = Vector3(meshStart.x, meshStart.y, meshStart.z + meshSize.z) + mesh.position
			3 :
				pos = Vector3(meshStart.x + meshSize.x, meshStart.y, meshStart.z + meshSize.z) + mesh.position
			4 :
				pos = meshStart + mesh.position + Vector3(0, meshSize.y, 0)
			5 :
				pos = Vector3(meshStart.x + meshSize.x, meshStart.y + meshSize.y, meshStart.z) + mesh.position
			6 :
				pos = Vector3(meshStart.x, meshStart.y + meshSize.y, meshStart.z + meshSize.z) + mesh.position
			7 :
				pos = Vector3(meshStart.x + meshSize.x, meshStart.y + meshSize.y, meshStart.z + meshSize.z) + mesh.position
		boundArrayVector3.append(pos)
	defaultBoundArray = boundArrayVector3.duplicate()
	defaultMesh.create_from_surface(mesh.mesh, 0)
	for ii in 4 :
		boundArrayVector3[ii].x = vertices[(ii + parRotation) % 4].x
		boundArrayVector3[ii].z = vertices[(ii + parRotation) % 4].z
	var temp := boundArrayVector3[2]
	boundArrayVector3[2] = boundArrayVector3[3]
	boundArrayVector3[3] = temp

func reset() -> void :
	mesh.mesh.clear_surfaces()
	defaultMesh.commit_to_surface(mesh.mesh)
	initializeEditor()

func calNewPositionScale(newPos : Vector3) -> Vector3 :
	var temp : Vector3 = newPos - defaultBoundArray[0]
	var meshSize : Vector3 = mesh.get_aabb().size
	var result : Vector3 = Vector3(temp.x / meshSize.x, temp.y / meshSize.y if !is_zero_approx(meshSize.y) else 0.0 , temp.z / meshSize.z)
	return result

func updateMeshEditor() -> void :
	if defaultBoundArray.is_empty() :
		initializeEditor()
	mdt.create_from_surface(mesh.mesh, 0)
	if bilinear :
		for i in 4 :
			boundArray[i + 4].position.x = boundArray[i].position.x
			boundArray[i + 4].position.z = boundArray[i].position.z
		var transformedPos : Array = boundArray.map(func pos(marker): return marker.position)
		for j in transformedPos.size() :
			transformedPos[j] = calNewPositionScale(transformedPos[j])
		markerPostion["b1"] = transformedPos[0]
		markerPostion["b2"] = transformedPos[1]
		markerPostion["b3"] = transformedPos[2]
		markerPostion["b4"] = transformedPos[3]
		markerPostion["t1"] = transformedPos[4]
		markerPostion["t2"] = transformedPos[5]
		markerPostion["t3"] = transformedPos[6]
		markerPostion["t4"] = transformedPos[7]
		var a : Vector3 = transformedPos[0]
		var b : Vector3 = transformedPos[1]
		var c : Vector3 = transformedPos[2]
		var d : Vector3 = transformedPos[3]
		var offset : Vector3 = boundArray[0].position - defaultBoundArray[0]
		for ii in mdt.get_vertex_count() :
			var v : Vector3 = mdt.get_vertex(ii)
			v = mesh.position + v
			var oldV = v
			v = calNewPositionScale(v)
			v = ((v.x * (1.0 - v.z) * (b - a) + (1.0 - v.x) * v.z * (c - a) + v.x * v.z * (d - a)) * (TILE_SIZE.x)) - MESH_OFFSET  + Vector3(offset.x, oldV.y + offset.y, offset.z)
			mdt.set_vertex(ii, v)
		mesh.mesh.clear_surfaces()
		mdt.commit_to_surface(mesh.mesh)

func updateMeshContructor() -> void :
	mdt.create_from_surface(mesh.mesh, 0)
	if bilinear :
		for i in 4 :
			boundArrayVector3[i + 4].x = boundArrayVector3[i].x
			boundArrayVector3[i + 4].z = boundArrayVector3[i].z
		var transformedPos : Array = boundArrayVector3.duplicate()
		for j in transformedPos.size() :
			transformedPos[j] = calNewPositionScale(transformedPos[j])
		markerPostion["b1"] = transformedPos[0]
		markerPostion["b2"] = transformedPos[1]
		markerPostion["b3"] = transformedPos[2]
		markerPostion["b4"] = transformedPos[3]
		markerPostion["t1"] = transformedPos[4]
		markerPostion["t2"] = transformedPos[5]
		markerPostion["t3"] = transformedPos[6]
		markerPostion["t4"] = transformedPos[7]
		var a : Vector3 = transformedPos[0]
		var b : Vector3 = transformedPos[1]
		var c : Vector3 = transformedPos[2]
		var d : Vector3 = transformedPos[3]
		var offset : Vector3 = boundArrayVector3[0] - defaultBoundArray[0]
		for ii in mdt.get_vertex_count() :
			var v : Vector3 = mdt.get_vertex(ii)
			v = mesh.position + v
			var oldV = v
			v = calNewPositionScale(v)
			v = (v.x * (1.0 - v.z) * (b - a) + (1.0 - v.x) * v.z * (c - a) + v.x * v.z * (d - a)) * TILE_SIZE.x - MESH_OFFSET  + Vector3(offset.x, oldV.y + offset.y, offset.z)
			mdt.set_vertex(ii, v)
		mesh.mesh.clear_surfaces()
		mdt.commit_to_surface(mesh.mesh)
