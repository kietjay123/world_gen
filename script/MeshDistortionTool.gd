@tool
class_name VisualTile extends Node3D

@export_tool_button("Create", "Callable") var Initialize = initializeEditor
@export_tool_button("Reset", "Callable") var Reset = reset
@export_tool_button("Update", "Callable") var update = updateMeshEditor
@export_tool_button("test", "Callable") var Test = test
@export_tool_button("test2", "Callable") var Test2 = test2
enum TYPE {WATER, LAND, MOUNTAIN, PATH}
@export var centroidNode : CentroidNodeCustom
@export var mesh : MeshInstance3D 
@export var landMeshNode : MeshInstance3D
@export var waterMeshNode : MeshInstance3D
@export var pathMeshNode : MeshInstance3D
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
@export var grassMaterial : Material = preload("res://shader/grassMat.tres")
@export var treeScatter : PackedScene = preload("res://scene/tree scatter.tscn")
@export var grassSpacing : float = 0.025
@export var grassLOD : Array[float] = [30, 100]
@export var treeDensity : float = 0.0234375


var defaultMesh : Array[MeshDataTool] = []
var mdt : MeshDataTool = MeshDataTool.new()
const MESH_OFFSET : Vector3 = Vector3(40, 40, 40)
const TILE_SIZE : Vector3 = Vector3(80, 80, 80)

func _ready() -> void:
	mesh = get_child(0) as MeshInstance3D
	for child in get_children() :
		if child.get_name().ends_with("-water") :
			waterMeshNode = child as MeshInstance3D
		elif child.get_name().ends_with("-land") :
			landMeshNode = child as MeshInstance3D
		elif child.get_name().ends_with("-path") :
			pathMeshNode = child as MeshInstance3D

func runInit(parRotation : int, vertices : Array, graphNode : CentroidNodeCustom, parMirror : bool) -> void :
	centroidNode = graphNode
	initializeConstructor(parRotation, vertices, parMirror)
	updateMeshContructor()
	applyRiver()
	if centroidNode.is_river() :
		applyRiverDir()

#region distorsion 
func test() -> void:
	boundArrayVector3 = [
		Vector3(-172.246,0,138.563),
		Vector3(-201.111,0,204.211),
		Vector3(-239.215,0,138.551),
		Vector3(-271.731,0,192.368),
		Vector3(-172.246,30,138.563),
		Vector3(-201.111,30,204.211),
		Vector3(-239.215,30,138.551),
		Vector3(-271.731,30,192.368),
	]
	updateMeshContructor()

func test2() -> void :
	var noise : FastNoiseLite = FastNoiseLite.new()
	noise.set_seed(randi())
	var noiseImg : Image = noise.get_image(1000, 1000)
	createGrass(noiseImg, 0.25)

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
	for child in get_children() :
		if child.get_name().ends_with("-water") :
			waterMeshNode = child as MeshInstance3D
		elif child.get_name().ends_with("-land") :
			landMeshNode = child as MeshInstance3D
		elif child.get_name().ends_with("-path") :
			pathMeshNode = child as MeshInstance3D
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
				v = (v.x * (1.0 - v.z) * (b - a) + (1.0 - v.x) * v.z * (c - a) + v.x * v.z * (d - a)) * TILE_SIZE.x - MESH_OFFSET + Vector3(offset.x, oldV.y + offset.y, offset.z)
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

			# Run through the vertices one last time to normalize their normals
			for i in range(mdt.get_vertex_count()):
				var v = mdt.get_vertex_normal(i).normalized()
				mdt.set_vertex_normal(i, v)
			
			# Update main mesh surface
			child.mesh.clear_surfaces()
			mdt.commit_to_surface(child.mesh)
			
			# Build a position-and-index-only surface array for the shadow mesh
			var shadow_mesh = child.mesh.get_shadow_mesh()
			if shadow_mesh:
				var shadow_arrays := []
				shadow_arrays.resize(Mesh.ARRAY_MAX)

				# Extract vertex positions
				var shadow_verts := PackedVector3Array()
				shadow_verts.resize(mdt.get_vertex_count())
				for i in mdt.get_vertex_count():
					shadow_verts[i] = mdt.get_vertex(i)

				# Extract face indices
				var shadow_indices := PackedInt32Array()
				var face_count := mdt.get_face_count()
				shadow_indices.resize(face_count * 3)
				var idx := 0
				for f in face_count:
					shadow_indices[idx] = mdt.get_face_vertex(f, 0)
					shadow_indices[idx + 1] = mdt.get_face_vertex(f, 1)
					shadow_indices[idx + 2] = mdt.get_face_vertex(f, 2)
					idx += 3

				shadow_arrays[Mesh.ARRAY_VERTEX] = shadow_verts
				shadow_arrays[Mesh.ARRAY_INDEX] = shadow_indices

				shadow_mesh.clear_surfaces()
				shadow_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, shadow_arrays)

#not needed might return 
#func updateCheckSum() -> void :
	#borderChecsum = {
	#TYPE.WATER : [],
	#TYPE.LAND : []
	#}
	#for i in corners_indices.keys() :
		#var tempMesh : ArrayMesh
		#match i :
			#TYPE.WATER :
				#if !waterMeshNode :
					#continue
				#tempMesh = waterMeshNode.get_mesh()
			#TYPE.LAND :
				#if !landMeshNode :
					#continue
				#tempMesh = landMeshNode.get_mesh()
		#var verts : Array = []
		#var surface_arrays: Array = tempMesh.surface_get_arrays(0)
		#verts = surface_arrays[Mesh.ARRAY_VERTEX]
		#for j in corners_indices[i] :
			#if j.size() == 2 :
				#var firtVec : Vector3 = verts[j[0]]
				#var secVec : Vector3 = verts[j[1]]
				#var sum : Vector3 = firtVec + secVec
				#var final : Vector3i = Vector3i(sum)
				#borderChecsum[i].append(Vector2i(final.x, final.z))
#endregion distorsion 
#region river
func applyRiver() -> void :
	if !centroidNode.is_river() :
		return 
	else :
		for i in range(1, get_child_count(), 1) :
			if get_child(i).get_name().ends_with("-rivermesh") :
				get_child(i).get_mesh().surface_set_material(0, riverMaterial.duplicate())

func applyRiverDir() -> void :
	var temp : Array[MeshInstance3D] = []
	for i in range(1, get_child_count(), 1) :
		if get_child(i).get_name().ends_with("-rivermesh") :
			temp.append(get_child(i))
	var from : CentroidNodeCustom = centroidNode.get_river_from()
	var to : Array[CentroidNodeCustom] = centroidNode.get_river_to()
	if to.is_empty() :
		var dir3d := centroidNode.get_position() - from.get_position()
		var dir := Vector2(dir3d.x * -1, dir3d.z)
		temp[0].mesh.surface_get_material(0).set_shader_parameter("dir", dir)
	elif !from :
		var dir3d := to[0].get_position() - centroidNode.get_position()
		var dir := Vector2(dir3d.x * -1, dir3d.z)
		temp[0].mesh.surface_get_material(0).set_shader_parameter("dir", dir)
	elif to.size() == 1:
		var dirFrom : Vector3 = centroidNode.get_position() - from.get_position()
		var dirFrom2d := Vector2(dirFrom.x * -1, dirFrom.z)
		temp[0].mesh.surface_get_material(0).set_shader_parameter("dir", dirFrom2d)
		var dirTo := to[0].get_position() - centroidNode.get_position()
		var dirTo2d := Vector2(dirTo.x * -1, dirTo.z)
		if temp.size() == 2 :
			temp[1].mesh.surface_get_material(0).set_shader_parameter("dir", dirTo2d)
	else :
		var dirFrom : Vector3 = centroidNode.get_position() - from.get_position()
		var dirFrom2d := Vector2(dirFrom.x * -1, dirFrom.z)
		temp[0].mesh.surface_get_material(0).set_shader_parameter("dir", dirFrom2d)
		var dirTo1 : Vector3 = centroidNode.get_position() - to[0].get_position()
		var dirTo1d := Vector2(dirTo1.x * -1, dirTo1.z)
		var dirTo2 : Vector3 = centroidNode.get_position() - to[1].get_position()
		var dirTo2d := Vector2(dirTo2.x * -1, dirTo2.z)
		var damn := dirTo1d + dirTo2d
		temp[1].mesh.surface_get_material(0).set_shader_parameter("dir", -damn)
		temp[2].mesh.surface_get_material(0).set_shader_parameter("dir", -damn)
#endregion
#BUG can not use this trick outside the editor / will crash project when save if use queue free
func removeMesh() -> void :
	var undo_redo := EditorInterface.get_editor_undo_redo()
	undo_redo.create_action("Delete node")
	for child in get_children() :
		if child.get_name().ends_with("-water") :
			undo_redo.add_do_method(self, "remove_child", child)
			undo_redo.add_undo_reference(child)
			undo_redo.add_undo_method(self, "add_child", child)
			undo_redo.commit_action()
		elif child.get_name().ends_with("-land") :
			undo_redo.add_do_method(self, "remove_child", child)
			undo_redo.add_undo_reference(child)
			undo_redo.add_undo_method(self, "add_child", child)
			undo_redo.commit_action()
		elif child.get_name().ends_with("-path") :
			undo_redo.add_do_method(self, "remove_child", child)
			undo_redo.add_undo_reference(child)
			undo_redo.add_undo_method(self, "add_child", child)
			undo_redo.commit_action()
		#elif child.get_name().ends_with("Collider") :
			#undo_redo.add_do_method(self, "remove_child", child)
			#undo_redo.add_undo_reference(child)
			#undo_redo.add_undo_method(self, "add_child", child)
			#undo_redo.commit_action()


func createGrass(noise : Image, threshold : float) -> void :
	#WARNING turn this on if not testing
	#if !centroidNode.get_terrain_code_string().contains("L") :
		#return 
	for child in get_children():
		if child.get_name().ends_with("-land") :
			var ogMesh : ArrayMesh = child.get_mesh()
			var forestMesh : ArrayMesh = createForestMesh(ogMesh, noise, threshold)
			if !forestMesh :
				return
			#LODTool(forestMesh)
			#var meshNode : MeshInstance3D = MeshInstance3D.new()
			#meshNode.set_mesh(forestMesh)
			#meshNode.set_name("forestMesh") 
			#add_child(meshNode)
			#meshNode.owner = get_tree().edited_scene_root
			
			var forestShape : ConcavePolygonShape3D = createForestColliderShape(forestMesh)
			var colliderNode : StaticBody3D = StaticBody3D.new()
			colliderNode.set_name("forestCollider") 
			add_child(colliderNode)
			colliderNode.owner = get_tree().edited_scene_root
			
			var shapeNode : CollisionShape3D = CollisionShape3D.new()
			shapeNode.set_shape(forestShape)
			shapeNode.set_name("forestShape") 
			colliderNode.add_child(shapeNode)
			shapeNode.owner = get_tree().edited_scene_root
			colliderNode.set_position(colliderNode.get_position() + Vector3(0, 39.9, 0))
			
			var lowResGrass : ArrayMesh = createLowRezGrassMesh(forestMesh)
			var surfaceVert : PackedVector3Array = []
			var templateMesh : Array = lowResGrass.surface_get_arrays(0)
			for i in templateMesh[Mesh.ARRAY_VERTEX].size() :
				var vert : Vector3 = templateMesh[Mesh.ARRAY_VERTEX][i] + Vector3(0, 40.05, 0)
				surfaceVert.append(vert)
				vert += Vector3(0, grassSpacing, 0)
			templateMesh[Mesh.ARRAY_VERTEX] = surfaceVert
			
			var grassNode : Node3D = Node3D.new()
			grassNode.set_name("Grass") 
			add_child(grassNode)
			grassNode.owner = get_tree().edited_scene_root
			
			for i in 8 :
				var grassLayerMesh : ArrayMesh = ArrayMesh.new()
				grassLayerMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, templateMesh)
				var mat : Material = grassMaterial.duplicate()
				mat.set_shader_parameter("currentLayer", i)
				
				var grassLayer : MeshInstance3D = MeshInstance3D.new()
				grassLayer.set_mesh(grassLayerMesh)
				grassLayer.set_position(grassLayer.get_position() + Vector3(0, i * grassSpacing, 0))
				grassLayer.set_cast_shadows_setting(GeometryInstance3D.ShadowCastingSetting.SHADOW_CASTING_SETTING_OFF)
				grassLayer.set_name("grassLayer" + str(i)) 
				grassNode.add_child(grassLayer)
				grassLayer.owner = get_tree().edited_scene_root
				
				if i % 2 == 1 :
					mat.set_shader_parameter("visibleRange", grassLOD[0])
					grassLayer.set_visibility_range_end(grassLOD[0])
				elif i != 0:
					mat.set_shader_parameter("visibleRange", grassLOD[1])
					grassLayer.set_visibility_range_end(grassLOD[1])
				grassLayerMesh.surface_set_material(0, mat)
			print(name)
			createTree()

func createForestMesh(ogMesh : ArrayMesh, noiseImg : Image, threshold : float) -> ArrayMesh :
	var forestMeshArr : Array = ogMesh.surface_get_arrays(0)
	var packedVert : PackedVector3Array = PackedVector3Array(forestMeshArr[Mesh.ARRAY_VERTEX]).duplicate()
	var packedNormal : PackedVector3Array = PackedVector3Array(forestMeshArr[Mesh.ARRAY_NORMAL])
	var packedColor : PackedColorArray = PackedColorArray(forestMeshArr[Mesh.ARRAY_COLOR])
	var packedIndices : PackedInt32Array = PackedInt32Array(forestMeshArr[Mesh.ARRAY_INDEX])
	var outputArr : PackedInt32Array = PackedInt32Array([])
	outputArr.resize(packedIndices.size())
	outputArr.fill(0)
	var computeShader = ComputeHelper.create("res://shader/cullSurface.glsl")
	
	var noiseUniform = ImageUniform.create(noiseImg)
	var thresholdAndOffset = StorageBufferUniform.create(PackedFloat32Array([threshold, noiseImg.get_width() / 2.0]).to_byte_array())
	var indicesUniform = StorageBufferUniform.create(packedIndices.to_byte_array())
	var vertUniform = StorageBufferUniform.create(packedVert.to_byte_array())
	var output = StorageBufferUniform.create(outputArr.to_byte_array())
	computeShader.add_uniform_array([noiseUniform, thresholdAndOffset, indicesUniform, vertUniform, output])
	var total_faces: int = int(ceil(packedIndices.size() / 3.0))
	var workgroups_x: int = int(ceil(total_faces / 8.0))
	computeShader.run(Vector3i(workgroups_x, 1, 1))
	ComputeHelper.sync()
	
	var updatedOutput = output.get_data().to_int32_array()
	var newIndices : PackedInt32Array = packedIndices.duplicate()
	for i in range(updatedOutput.size() - 1, -1, -1) :
		if updatedOutput[i] == 1 :
			newIndices.remove_at(i)
	if newIndices.size() == 0 :
		return null
	var surface_array = []
	var AABBposition : Vector2 = Vector2(ogMesh.get_aabb().position.x, ogMesh.get_aabb().position.z)
	var packedUV : PackedVector2Array = PackedVector2Array([])
	#BUG do this in the compute shader 
	for i in packedVert :
		var uvX : float = (i.x - AABBposition.x) / 80
		var uvY : float = (i.z - AABBposition.y) / 80
		packedUV.append(Vector2(uvX, uvY))
	
	surface_array.resize(Mesh.ARRAY_MAX)
	surface_array[Mesh.ARRAY_VERTEX] = packedVert
	surface_array[Mesh.ARRAY_NORMAL] = packedNormal
	surface_array[Mesh.ARRAY_COLOR] = packedColor
	surface_array[Mesh.ARRAY_INDEX] = newIndices
	surface_array[Mesh.ARRAY_TEX_UV] = packedUV
	
	var tempMesh : ArrayMesh = ArrayMesh.new()
	tempMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	return tempMesh

func createForestColliderShape(ogMesh : Mesh) -> ConcavePolygonShape3D :
	var tempShape : ConcavePolygonShape3D = ogMesh.create_trimesh_shape() 
	tempShape.set_backface_collision_enabled(true)
	return tempShape

func createLowRezGrassMesh(ogMesh : ArrayMesh) -> ArrayMesh :
	var importer_mesh = ImporterMesh.new()
	importer_mesh.add_surface(Mesh.PRIMITIVE_TRIANGLES, ogMesh.surface_get_arrays(0))
	var normal_merge_angle = 25.0
	importer_mesh.generate_lods(normal_merge_angle, normal_merge_angle, [])
	var finalMesh : ArrayMesh = ArrayMesh.new()
	var testMeshArr : Array = importer_mesh.get_mesh().surface_get_arrays(0)
	var lodIdx : PackedInt32Array = []
	if importer_mesh.get_surface_lod_count(0) >= 2:
		lodIdx  = importer_mesh.get_surface_lod_indices(0, importer_mesh.get_surface_lod_count(0) - 2)
	else :
		lodIdx = testMeshArr[Mesh.ARRAY_INDEX]
	testMeshArr[Mesh.ARRAY_INDEX] =  lodIdx
	finalMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, testMeshArr)
	return finalMesh

#buggy as hell but does reduce vert count
func createLowRezGrassMesh2(ogMesh : ArrayMesh) -> ArrayMesh :
	var importer_mesh = ImporterMesh.new()
	importer_mesh.add_surface(Mesh.PRIMITIVE_TRIANGLES, ogMesh.surface_get_arrays(0))
	var normal_merge_angle = 25.0
	importer_mesh.generate_lods(normal_merge_angle, normal_merge_angle, [])
	print("damn")
	var finalMesh : ArrayMesh = ArrayMesh.new()
	var testMeshArr : Array = importer_mesh.get_mesh().surface_get_arrays(0)
	var packedVert : PackedVector3Array  = testMeshArr[Mesh.ARRAY_VERTEX]
	var packedColor : PackedColorArray = testMeshArr[Mesh.ARRAY_COLOR]
	var lodIdx : PackedInt32Array = []
	if importer_mesh.get_surface_lod_count(0) != 0:
		lodIdx  = importer_mesh.get_surface_lod_indices(0, importer_mesh.get_surface_lod_count(0) - 1)
	else :
		lodIdx = testMeshArr[Mesh.ARRAY_INDEX]
	testMeshArr[Mesh.ARRAY_INDEX] =  lodIdx
	finalMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, testMeshArr)
	
	var uniqueBorderIdxDict : Dictionary[int, bool] = {}
	for i in lodIdx :
		if packedColor[i] == Color.RED :
			uniqueBorderIdxDict[i] = true
	var uniqueBorderIdx : Array = uniqueBorderIdxDict.keys()
	var midPoint : Vector3 = Vector3.ZERO
	for i in uniqueBorderIdx :
		midPoint += packedVert[i]
	midPoint /= uniqueBorderIdx.size()
	var angleArr : Array[float] = []
	var angleDict : Dictionary[float, int] = {}
	for i in uniqueBorderIdx :
		var angle : float = Vector3.FORWARD.signed_angle_to(packedVert[i] - midPoint, Vector3.UP) 
		if angleDict.has(angle) :
			push_warning(str(angle) + " key already existed") 
		else :
			angleArr.append(angle)
		angleDict[angle] = i
	angleArr.sort()
	var sortedIdx : Array[int] = []
	for i in angleArr :
		sortedIdx.append(angleDict[i])
	var tempMDT : MeshDataTool = MeshDataTool.new()
	tempMDT.create_from_surface(finalMesh, 0)
	var twoSurfaceBorderVert : Array[int] = []
	for i in sortedIdx :
		if tempMDT.get_vertex_faces(i).size() == 2 :
			#print(tempMDT.get_vertex_faces(i))
			twoSurfaceBorderVert.append(i)
	
	var faceVerticesIdx := func (faceIdx: int) -> Array[int]:
		return [lodIdx[faceIdx * 3], lodIdx[(faceIdx * 3) + 1], lodIdx[(faceIdx * 3) + 2]]
	
	var mergedFaces : Array[int] = []
	var mergedFacesVerts : Array[int] = []
	var currentMerge : Array[int] = []
	var currentMergeVerts : Array[int] = []
	var toFindIdx : int = 2
	var corners : Array[int] = []
	
	for i in twoSurfaceBorderVert.size() - 1 :
		var currentFaces : PackedInt32Array = tempMDT.get_vertex_faces(twoSurfaceBorderVert[i])
		if currentMerge.is_empty() :
			for j in tempMDT.get_vertex_faces(twoSurfaceBorderVert[i + 1]).size() :
				var findIdx : int = currentFaces.find(tempMDT.get_vertex_faces(twoSurfaceBorderVert[i + 1])[j])
				#if the next vert share the same face
				if findIdx != -1 :
					currentMerge.assign(currentFaces) 
					toFindIdx = j - 1
					#prints("toFindIdx", toFindIdx)
					#prints("current merge new", currentMerge)
					#find the outside mesh
					var faceVertA : Array[int]  = faceVerticesIdx.call(currentFaces[findIdx - 1]) # the outside mesh
					var faceVertB : Array[int]  = faceVerticesIdx.call(currentFaces[findIdx])
					#prints("faceVertA", faceVertA)
					#prints("faceVertB", faceVertB)
					for k in faceVertA :
						var vertFindIdx : int = faceVertB.find(k)
						if vertFindIdx == -1 :
							currentMergeVerts.append(k)
						else :
							corners.append(k)
		else :
			#prints("to find", currentFaces[toFindIdx])
			var findIdx : int = tempMDT.get_vertex_faces(twoSurfaceBorderVert[i + 1]).find(currentFaces[toFindIdx])
			currentMerge.append(currentFaces[toFindIdx]) 
			#prints("current merge con", currentMerge)
			#if the next vert share the same face
			if findIdx != -1 :
				toFindIdx = findIdx - 1
			#when the merging ends 
			else :
				#prints("currentMerge", currentMerge)
				
				#find the outside mesh
				var faceVertA : Array[int]  = faceVerticesIdx.call(currentFaces[toFindIdx]) # the outside mesh
				var faceVertB : Array[int]  = faceVerticesIdx.call(currentFaces[toFindIdx - 1])
				for k in faceVertA :
					var vertFindIdx : int = faceVertB.find(k)
					if vertFindIdx == -1 :
						currentMergeVerts.append(k)
					else :
						if corners.find(k) != -1 :
							currentMergeVerts.insert(0, k)
						
				if currentMergeVerts.size() != 3 :
					prints("not3", currentMergeVerts)
				else :
					mergedFaces.append_array(currentMerge)
					
					var n : Vector3 = packedVert[currentMergeVerts[0]] - packedVert[currentMergeVerts[1]].cross(packedVert[currentMergeVerts[0]] - packedVert[currentMergeVerts[2]]).normalized()
					if n.y < -0.5 :
						#print("flip")
						var temp : int = currentMergeVerts[2]
						currentMergeVerts[2] = currentMergeVerts[1]
						currentMergeVerts[1] = temp
					mergedFacesVerts.append_array(currentMergeVerts)
				currentMerge.clear()
				currentMergeVerts.clear()
				corners.clear()
				#print("cut")
	mergedFaces.sort()
	#print("result")
	#print(mergedFaces)
	#print("")
	#print(mergedFacesVerts)
	#print(mergedFacesVerts.size() / 3.0)
	var oldIdx : PackedInt32Array = testMeshArr[Mesh.ARRAY_INDEX].duplicate()
	for i in range(mergedFaces.size() - 1, -1, -1) :
		var idx : int = mergedFaces[i] * 3 
		for j in 3 :
			oldIdx.remove_at(idx)
	oldIdx.append_array(mergedFacesVerts)
	testMeshArr[Mesh.ARRAY_INDEX] = oldIdx
	var finalFinalMesh : ArrayMesh  = ArrayMesh.new()
	finalFinalMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, testMeshArr)
	#var meshNode : MeshInstance3D = MeshInstance3D.new()
	#meshNode.set_mesh(finalFinalMesh)
	#meshNode.set_name("big test") 
	#add_child(meshNode)
	#meshNode.owner = get_tree().edited_scene_root
	return finalFinalMesh

func LODTool(ogMesh : ArrayMesh) -> void :
	var importer_mesh = ImporterMesh.new()
	importer_mesh.add_surface(Mesh.PRIMITIVE_TRIANGLES, ogMesh.surface_get_arrays(0))
	var normal_merge_angle = 90
	importer_mesh.generate_lods(normal_merge_angle, normal_merge_angle, [])
	var testNode : MeshInstance3D = MeshInstance3D.new()
	testNode.set_mesh(importer_mesh.get_mesh())
	testNode.set_name("test") 
	testNode.set_lod_bias(0.001)
	add_child(testNode)
	testNode.owner = get_tree().edited_scene_root

func createTree() -> void :
	var scatterNode : ProtonScatter = treeScatter.instantiate()
	add_child(scatterNode)
	scatterNode.owner = get_tree().edited_scene_root
	var shapeNode : ProtonScatterShape = scatterNode.get_node("ScatterShape")
	var shape : ProtonScatterBoxShape = ProtonScatterBoxShape.new()
	var aabb : AABB = get_child(0).get_mesh().get_aabb()
	prints(shape, aabb)
	shapeNode.set_position(Vector3(aabb.get_center().x, 0, aabb.get_center().z))
	shape.size = aabb.size
	shapeNode.shape = shape
	scatterNode.modifier_stack.stack[0].amount = treeDensity * aabb.size.x * aabb.size.z
	await scatterNode.build_completed
	var outputNode : Marker3D = get_node("ProtonScatter/ScatterOutput")
	outputNode.reparent(self)
	scatterNode.queue_free()
	var collider : StaticBody3D = get_node("./forestCollider")
	collider.queue_free()
