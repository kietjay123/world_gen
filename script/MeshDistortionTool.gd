@tool
extends Node3D

@export_tool_button("Create", "Callable") var Initialize = initializeEditor
@export_tool_button("Reset", "Callable") var Reset = reset
@export_tool_button("Update", "Callable") var update = updateMeshEditor
@export_tool_button("test", "Callable") var Test = test
@export_tool_button("test2", "Callable") var Test2 = test2

@export var centroidNode : CentroidNodeCustom
@export var mesh : MeshInstance3D 
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
@export var riverMaterial : Material = preload("res://shader/riverMat.tres")
var defaultMesh : Array[MeshDataTool] = []
var mdt : MeshDataTool = MeshDataTool.new()

const MESH_OFFSET : Vector3 = Vector3(40, 40, 40)
const TILE_SIZE : Vector3 = Vector3(80, 80, 80)

func _ready() -> void:
	mesh = get_child(0) as MeshInstance3D

func runInit(parRotation : int, vertices : Array, graphNode : CentroidNodeCustom, parMirror : bool) -> void :
	centroidNode = graphNode
	initializeConstructor(parRotation, vertices, parMirror)
	updateMeshContructor()
	applyRiver()
	if centroidNode.is_river() :
		applyRiverDir()

#region distorsion 
func test() -> void:
	initializeEditor()
	boundArray[0].position = Vector3(-37.519, 0, -64.959)
	boundArray[1].position = Vector3(-52.254, 0, -39.668)
	boundArray[2].position = Vector3(-52.293, 0, -90.4)
	boundArray[3].position = Vector3(-74.608, 0, -66.307)
	updateMeshEditor()

func test2() -> void :
	for i in range(1, get_child_count(), 1) :
		if get_child(i) is MeshInstance3D :
			get_child(i).get_mesh().surface_set_material(0, riverMaterial)
	for i in 4 :
		boundArray[i].position = boundArrayVector3[i]
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
		var meshSize : Vector3 = mesh.get_aabb().size
		var newMarker : Marker3D = Marker3D.new()
		
		add_child(newMarker)
		newMarker.owner = get_tree().edited_scene_root
		match i :
			0 :
				newMarker.position = Vector3(-40, -40, -40) + mesh.position
				newMarker.set_name("b1")
			1 :
				newMarker.position = Vector3(40, -40, -40) + mesh.position
				newMarker.set_name("b2")
			2 :
				newMarker.position = Vector3(-40, -40, 40) + mesh.position
				newMarker.set_name("b3")
			3 :
				newMarker.position = Vector3(40, -40, 40) + mesh.position
				newMarker.set_name("b4")
			4 :
				newMarker.position = Vector3(-40, -40 + meshSize.y, -40) + mesh.position
				newMarker.set_name("t1")
			5 :
				newMarker.position = Vector3(40, -40 + meshSize.y, -40) + mesh.position
				newMarker.set_name("t2")
			6 :
				newMarker.position = Vector3(-40, -40 + meshSize.y, 40) + mesh.position
				newMarker.set_name("t3")
			7 :
				newMarker.position = Vector3(40, -40 + meshSize.y, 40) + mesh.position
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
	for i in get_children() :
		if i is MeshInstance3D :
			var temp : MeshDataTool = MeshDataTool.new()
			temp.create_from_surface(i.mesh, 0)
			defaultMesh.append(temp)

func initializeConstructor(parRotation : int, vertices : Array, parMirror : bool) -> void :
	mesh = get_child(0) as MeshInstance3D
	for i in get_children() :
		if i.is_class("MeshInstance3D") :
			continue
		else :
			remove_child(i)
	boundArrayVector3.clear()
	defaultBoundArray.clear()
	#make mesh local
	for i in get_children() :
		i.mesh = i.mesh.duplicate()
	for i in 8 :
		var meshSize : Vector3 = mesh.get_aabb().size
		var pos : Vector3 
		match i :
			0 :
				pos = Vector3(-40, -40, -40) + mesh.position
			1 :
				pos = Vector3(40, -40, -40) + mesh.position
			2 :
				pos = Vector3(-40, -40, 40) + mesh.position
			3 :
				pos = Vector3(40, -40, 40) + mesh.position
			4 :
				pos = Vector3(-40, -40 + meshSize.y, -40) + mesh.position
			5 :
				pos = Vector3(40, -40 + meshSize.y, -40) + mesh.position
			6 :
				pos = Vector3(-40, -40 + meshSize.y, 40) + mesh.position
			7 :
				pos = Vector3(40, -40 + meshSize.y, 40) + mesh.position
		boundArrayVector3.append(pos)
	defaultBoundArray = boundArrayVector3.duplicate()
	
	#WORK BUT IS BUGGED rotate assume [0,1,2,3] mirror assume [0,1,3,2] mirror behave diffently inconsistance
	var getIdx : Array = [0,1,2,3]
	
	for i in parRotation :
		var first : int  = getIdx.pop_at(0)
		getIdx.append(first)
	
	if parMirror :
		var temp0 : int = getIdx[0]
		var temp2 : int = getIdx[2]
		getIdx[0] = getIdx[1]
		getIdx[2] = getIdx[3]
		getIdx[1] = temp0
		getIdx[3] = temp2
	
	getIdx.append(getIdx.pop_at(2))
	
	for ii in 4 :
		boundArrayVector3[ii].x = vertices[getIdx[ii]].x
		boundArrayVector3[ii].z = vertices[getIdx[ii]].z
	
	##rotaion
	#for ii in 4 :
		#boundArrayVector3[ii].x = vertices[(ii + parRotation) % 4].x
		#boundArrayVector3[ii].z = vertices[(ii + parRotation) % 4].z
	#
	##mirror 
	#if parMirror :
		#var temp0 : Vector3 = boundArrayVector3[0]
		#var temp1 : Vector3 = boundArrayVector3[2]
		#boundArrayVector3[0] = boundArrayVector3[1]
		#boundArrayVector3[2] = boundArrayVector3[3]
		#boundArrayVector3[1] = temp0
		#boundArrayVector3[3] = temp1
	
	#var temp := boundArrayVector3[2]
	#boundArrayVector3[2] = boundArrayVector3[3]
	#boundArrayVector3[3] = temp
	

func reset() -> void :
	var counter := 0
	for i in get_children() :
		if i is MeshInstance3D :
			i.mesh.clear_surfaces()
			defaultMesh[counter].commit_to_surface(i.mesh)
			counter += 1
	initializeEditor()

func calNewPositionScale(newPos : Vector3) -> Vector3 :
	var temp : Vector3 = newPos - defaultBoundArray[0]
	var meshSize : Vector3 = Vector3(80, mesh.get_aabb().size.y, 80)
	var result : Vector3 = Vector3(temp.x / meshSize.x, temp.y / meshSize.y if !is_zero_approx(meshSize.y) else 0.0 , temp.z / meshSize.z)
	return result

func updateMeshEditor() -> void :
	for child in get_children() :
		if child is MeshInstance3D :
			if defaultBoundArray.is_empty() :
				initializeEditor()
			mdt.clear()
			mdt.create_from_surface(child.mesh, 0)
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
				mdt.set_vertex_normal(ii,Vector3.ZERO)
			# Calculate the vertex normals, face-by-face.
			for i in range(mdt.get_face_count()):
				# Get the index in the vertex array.
				var va := mdt.get_face_vertex(i, 0)
				var vb := mdt.get_face_vertex(i, 1)
				var vc := mdt.get_face_vertex(i, 2)
				# Get the vertex position using the vertex index.
				var ap := mdt.get_vertex(va)
				var bp := mdt.get_vertex(vb)
				var cp := mdt.get_vertex(vc)
				# Calculate the normal of the face.
				var n = (bp - cp).cross(ap - bp).normalized()
				# Add this face normal to the current vertex normals.
				# This will not result in perfect normals, but it will be close.
				mdt.set_vertex_normal(va, n + mdt.get_vertex_normal(va))
				mdt.set_vertex_normal(vb, n + mdt.get_vertex_normal(vb))
				mdt.set_vertex_normal(vc, n + mdt.get_vertex_normal(vc))

			# Run through the vertices one last time to normalize their normals and
			# set the vertex colors to these new normals.
			for i in range(mdt.get_vertex_count()):
				var v = mdt.get_vertex_normal(i).normalized()
				mdt.set_vertex_normal(i, v)
				#mdt.set_vertex_color(i, Color(v.x, v.y, v.z))
			
			child.mesh.clear_surfaces()
			mdt.commit_to_surface(child.mesh)

func updateMeshContructor() -> void :
	for child in get_children() :
		if child is MeshInstance3D :
			mdt.clear()
			mdt.create_from_surface(child.mesh, 0)
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
				mdt.set_vertex_normal(ii,Vector3.ZERO)
			# Calculate the vertex normals, face-by-face.
			for i in range(mdt.get_face_count()):
				# Get the index in the vertex array.
				var va := mdt.get_face_vertex(i, 0)
				var vb := mdt.get_face_vertex(i, 1)
				var vc := mdt.get_face_vertex(i, 2)
				# Get the vertex position using the vertex index.
				var ap := mdt.get_vertex(va)
				var bp := mdt.get_vertex(vb)
				var cp := mdt.get_vertex(vc)
				# Calculate the normal of the face.
				var n = (bp - cp).cross(ap - bp).normalized()
				# Add this face normal to the current vertex normals.
				# This will not result in perfect normals, but it will be close.
				mdt.set_vertex_normal(va, n + mdt.get_vertex_normal(va))
				mdt.set_vertex_normal(vb, n + mdt.get_vertex_normal(vb))
				mdt.set_vertex_normal(vc, n + mdt.get_vertex_normal(vc))

			# Run through the vertices one last time to normalize their normals and
			# set the vertex colors to these new normals.
			for i in range(mdt.get_vertex_count()):
				var v = mdt.get_vertex_normal(i).normalized()
				mdt.set_vertex_normal(i, v)
			
			child.mesh.clear_surfaces()
			mdt.commit_to_surface(child.mesh)
#endregion distorsion 

func applyRiver() -> void :
	if !centroidNode.is_river() :
		return 
	else :
		for i in range(1, get_child_count(), 1) :
			get_child(i).get_mesh().surface_set_material(0, riverMaterial.duplicate())

#BUG REWORK THIS IF REDO THE RIVER MODEL TO HAVE CONSISTANCE ORDER
func applyRiverDir() -> void :
	var neighbor : Array[GraphNodeCustom] = centroidNode.get_neighbour()
	var from : CentroidNodeCustom = centroidNode.get_river_from()
	var to : Array[CentroidNodeCustom] = centroidNode.get_river_to()
	if to.is_empty() :
		var dir3d := centroidNode.get_position() - from.get_position()
		var dir := Vector2(dir3d.x * -1, dir3d.z)
		get_child(1).mesh.surface_get_material(0).set_shader_parameter("dir", dir)
	elif !from :
		var dir3d := to[0].get_position() - centroidNode.get_position()
		var dir := Vector2(dir3d.x * -1, dir3d.z)
		get_child(1).mesh.surface_get_material(0).set_shader_parameter("dir", dir)
	elif to.size() == 1:
		var dirFrom : Vector3 = centroidNode.get_position() - from.get_position()
		var dirFrom2d := Vector2(dirFrom.x * -1, dirFrom.z)
		get_child(1).mesh.surface_get_material(0).set_shader_parameter("dir", dirFrom2d)
		if get_child_count() == 3 :
			var dirTo := to[0].get_position() - centroidNode.get_position()
			var dirTo2d := Vector2(dirTo.x * -1, dirTo.z)
			get_child(2).mesh.surface_get_material(0).set_shader_parameter("dir", dirTo2d)
	else :
		var dirFrom : Vector3 = centroidNode.get_position() - from.get_position()
		var dirFrom2d := Vector2(dirFrom.x * -1, dirFrom.z)
		get_child(1).mesh.surface_get_material(0).set_shader_parameter("dir", dirFrom2d)
		var fromIdx : int = neighbor.find(from)
		var fromOppositeIdx : int = (fromIdx + 2) % neighbor.size()
		var notRiverIdx : int 
		for i in neighbor.size() :
			if neighbor[i].is_river() == false :
				notRiverIdx = i
		var idx : Array[int] = [0,1,2,3]
		idx.remove_at(idx.find(fromIdx))
		idx.remove_at(idx.find(notRiverIdx))
		if fromOppositeIdx != notRiverIdx :
			var dirTo1 := neighbor[fromOppositeIdx].get_position() - centroidNode.get_position()
			var dirTo1_2d := Vector2(dirTo1.x * -1, dirTo1.z)
			get_child(3).mesh.surface_get_material(0).set_shader_parameter("dir", dirTo1_2d)
			idx.remove_at(idx.find(fromOppositeIdx))
			for i in idx :
				var dirTo2 := neighbor[i].get_position() - centroidNode.get_position()
				var dirTo2_2d := Vector2(dirTo2.x * -1, dirTo2.z)
				get_child(2).mesh.surface_get_material(0).set_shader_parameter("dir", dirTo2_2d)
		#may be redo this
		else :
			var dirTo2 := neighbor[0].get_position() - centroidNode.get_position()
			var dirTo2_2d := Vector2(dirTo2.x * -1, dirTo2.z)
			get_child(3).mesh.surface_get_material(0).set_shader_parameter("dir", dirTo2_2d)
			
			var dirTo3 := neighbor[1].get_position() - centroidNode.get_position()
			var dirTo3_2d := Vector2(dirTo3.x * -1, dirTo3.z)
			get_child(2).mesh.surface_get_material(0).set_shader_parameter("dir", dirTo3_2d)
