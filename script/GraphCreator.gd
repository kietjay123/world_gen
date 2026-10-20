@tool
class_name Hex extends Node3D
#region variable
var randy :=  RandomNumberGenerator.new()
@export_tool_button("Create", "Callable") var Create = renderGrid
@export var gridSize : int = 2
@export var gridSpacing : float = 50
@export var userSeed : String = "test" : 
	get: 
		return userSeed
	set(value):
		userSeed = value
		randy.set_seed(hash(value))
@export var relaxIteration : int = 50
@export var relaxForceScale : float = 0.1
@export var useRelax : bool = true
@export var addNodeToTree : bool = false
@export_enum("Boids") var relaxMethod: String = "Boids"
@export var tileData : TileDataRes 
@export var ocean : PackedScene
@export var riverLengthThreshold : int = 5
@export var forestThreshold : float = 0.5
var mainGrid : Array[GraphNodeCustom] = []
var previousLayer : Array[GraphNodeCustom] = []
var triangles : Array[Array] = []
var squares : Array[Array] = []
var afterSplitSquares : Array[Array] = []
var offsetGrid : Array[GraphNodeCustom] = []
var outermostLayer : Array[GraphNodeCustom] = []
var insideGrid : Array[CentroidNodeCustom] = [] 
var meshes : Array[VisualTile] = []
var riverNodes : Array[CentroidNodeCustom] = []
#endregion
#region Inital Hex Grid
func createGrid() -> void :
	var startingPoint = GraphNodeCustom.new("0_0 0", Vector3.ZERO, [])
	previousLayer.append(startingPoint)
	mainGrid.append(startingPoint)
	for i in gridSize :
		var newNodeArr: Array[GraphNodeCustom] = []
		var sizeVec = Vector3(1, 0, 0) * (i + 1) * gridSpacing
		var dirArr : Array[float] = [0, PI / 3, 2 * PI / 3, PI, 4 * PI / 3 , 5 * PI / 3]
		for j in dirArr.size() :
			var newPos : Vector3 = sizeVec.rotated(Vector3.UP, dirArr[j])
			var newNode := GraphNodeCustom.new(hexGridNameGen(i, newNodeArr.size()), newPos, [])
			newNodeArr.append(newNode)
			var infrontPos : Vector3 = sizeVec.rotated(Vector3.UP, dirArr[(j + 1) % dirArr.size()])
			#get intermediate node between the big node
			var temp: Array[GraphNodeCustom] = []
			for k in i :
				var intermediaryPos : Vector3 = newPos.lerp(infrontPos, (k + 1) * (1.0 / (i + 1))) 
				var intermediaryNode := GraphNodeCustom.new(hexGridNameGen(i, newNodeArr.size() + temp.size()), intermediaryPos, [])
				temp.append(intermediaryNode)
			newNodeArr.append_array(temp)
		if gridSize - i == 1 :
			outermostLayer.append_array(newNodeArr)
		#finding neighbour and create polygons
		for ii in newNodeArr.size() :
			addNodeNeighbour(newNodeArr[ii] ,newNodeArr[ii - 1])
			var neighbor : Array[GraphNodeCustom] = [newNodeArr[ii - 1]]
			for jj in previousLayer : 
				if (newNodeArr[ii].position - jj.position).length_squared() <= (gridSpacing ** 2 + 0.5):
					addNodeNeighbour(newNodeArr[ii] ,jj)
					neighbor.append(jj)
			if neighbor.size() == 2 :
				triangles.append([newNodeArr[ii], neighbor[0], neighbor[1]])
			else :
				var midNeigborIdx : int = 1 if neighbor[1].get_neighbour().has(neighbor[0]) else -1
				triangles.append([newNodeArr[ii], neighbor[midNeigborIdx], neighbor[0]])
				triangles.append([newNodeArr[ii], neighbor[midNeigborIdx], neighbor[-midNeigborIdx]])
		mainGrid.append_array(newNodeArr)
		previousLayer = newNodeArr

#BUG currently delete different node depending on the size
func removeGridLinkRand(node : GraphNodeCustom) -> void :
	var removeableNode : Array[GraphNodeCustom]  = findDeletableLink(node)
	if removeableNode.size() :
		var deletingnode : GraphNodeCustom = removeableNode[randy.randi_range(0, removeableNode.size() - 1)]
		var neighbors : Array[GraphNodeCustom] = []
		#create square remove triangle
		for i in node.get_neighbour() :
			if deletingnode.get_neighbour().has(i) :
				neighbors.append(i)
		var deletingTriangles : Array[int] = findGeometryWithVertices(triangles, [node, deletingnode])
		if deletingTriangles.size() != 2 :
			push_error("DAFUK")
		else :
			for i in deletingTriangles :
				triangles[i] = []
			triangles = triangles.filter(func isEmpty(triangle : Array) : return !triangle.is_empty())
		squares.append([node, neighbors[0], deletingnode, neighbors[-1]])
		removeNodeNeighbour(node, deletingnode)

func findDeletableLink(node : GraphNodeCustom) -> Array[GraphNodeCustom] :
	#find all neighbour that can be remove by check if taget is deletable if 2 node have 2 other node reachable by both
	var removeableNode : Array[GraphNodeCustom]  = [] 
	for j in node.get_neighbour():
		var counter := 0
		for k in j.get_neighbour():
			if counter < 2 && node.get_neighbour().has(k):
				counter += 1
			if counter >= 2 :
				removeableNode.append(j)
	return removeableNode

func findRemainingDeletableLinks() -> Array[Array] :
	var result : Array[Array] = []
	for i in get_children():
		if i is GraphNodeCustom :
			for j in findDeletableLink(i) :
				result.append([i, j])
	return result

func createFinalHexCell() -> void :
	#change to increase rounds of random deletion
	for i in 10:
		for j in mainGrid:
			if randy.randi_range(0, 1):
				removeGridLinkRand(j)
	var deleteOrder : Array[Array] = []
	var temp := findRemainingDeletableLinks().duplicate()
	var tempSize := temp.size()
	for i in tempSize :
		var index = randy.randi_range(0, temp.size())
		deleteOrder.append(temp[index])
		temp.remove_at(index) 
	for i in deleteOrder :
		if findRemainingDeletableLinks().has(i):
			removeNodeNeighbour(i[0], i[1])

#endregion
#region Splitting Hex Grid
func splitTriangle(index : int) -> void :
	var startingPoints : Array = triangles[index]
	var midNameX : float
	var midNameY : float
	var xNamePool : Array[float] = []
	var yNamePool : Array[float] = []
	for i in startingPoints :
		var nameArr : Array = Array(i.get_name().split(" "))
		xNamePool.append(nameArr[0].replace("_", ".").to_float())
		yNamePool.append(nameArr[1].to_float())
	xNamePool.sort()
	yNamePool.sort()
	midNameX = xNamePool[1]
	midNameY = (yNamePool[0] + yNamePool[2]) / 2
	var midName = str(midNameX) + " " + str(midNameY)
	var midPos = startingPoints[0].position.lerp(startingPoints[1].position.lerp(startingPoints[2].position, 0.5), 2.0/3.0)
	var mid : GraphNodeCustom = GraphNodeCustom.new(midName, midPos)
	
	var midPoints : Array[GraphNodeCustom] = []
	for i in startingPoints.size() :
		var thisPoint : GraphNodeCustom = startingPoints[i]
		var nextPoint : GraphNodeCustom = startingPoints[(i + 1) % startingPoints.size()]
		# if the 2 point already have a mid point
		if !thisPoint.isNeighbor(nextPoint) :
			for j in thisPoint.get_neighbour():
				if j.isNeighbor(nextPoint) :
					midPoints.append(j)
					break
		else :
			var tempName : String = thisPoint.get_name() + " ~ " +  nextPoint.get_name()
			var temp : GraphNodeCustom = GraphNodeCustom.new(tempName, thisPoint.position.lerp(nextPoint.position, 0.5))
			removeNodeNeighbour(thisPoint, nextPoint)
			addNodeNeighbour(thisPoint, temp)
			addNodeNeighbour(nextPoint, temp)
			midPoints.append(temp)
			#append outer most layer node
			var thisPointIdx = outermostLayer.find(thisPoint)
			var nextPointIdx = outermostLayer.find(nextPoint)
			if thisPointIdx != -1 && nextPointIdx != -1 :
				if thisPointIdx + 1 == nextPointIdx :
					outermostLayer.insert(nextPointIdx, temp)
				elif nextPointIdx + 1 == thisPointIdx :
					outermostLayer.insert(thisPointIdx, temp)
				else :
					outermostLayer.append(temp)
	
	# modify geometry array
	triangles.remove_at(index)
	for i in midPoints.size() :
		var thisPoint : GraphNodeCustom = midPoints[i]
		var nextPoint : GraphNodeCustom = midPoints[(i + 1) % midPoints.size()]
		for j in thisPoint.get_neighbour():
			for k in nextPoint.get_neighbour():
				if j == k :
					var forthVertex : GraphNodeCustom = j
					var vertices : Array[GraphNodeCustom] = [mid, thisPoint, nextPoint, forthVertex]
					var centroid : Vector3 = vertices.reduce(func(accum, SP): return accum + SP.position, Vector3.ZERO) / vertices.size() 
					var angleArr : Array = vertices.map(func(a): return Vector3(-1,0,0).signed_angle_to((a.position - centroid), Vector3(0,1,0)))
					angleArr = angleArr.map(func(a): return (2 * PI) + a if a < 0 else a)
					var sorted := angleArr.duplicate()
					sorted.sort_custom(func sortDecending(a, b) : return a > b)
					var final : Array[GraphNodeCustom] = []
					for l in sorted :
						final.append(vertices[angleArr.find(l)])
					afterSplitSquares.append(final)
	
	for i in midPoints :
		addNodeNeighbour(mid, i)
	mainGrid.append_array(midPoints)
	mainGrid.append(mid)

func splitAllTriangles() -> void :
	for i in triangles.size():
		if !triangles.is_empty() :
			splitTriangle(0)

func splitSquare(index : int) -> void :
	var startingPoints : Array = squares[index]
	var midNameX : float
	var midNameY : float
	var xNamePool : Array[float] = []
	var yNamePool : Array[float] = []
	for i in startingPoints :
		var nameArr : Array = Array(i.get_name().split(" "))
		xNamePool.append(nameArr[0].replace("_", ".").to_float())
		yNamePool.append(nameArr[1].to_float())
	midNameX = xNamePool.reduce(func(accum, number): return accum + number) / xNamePool.size()
	midNameY = yNamePool.reduce(func(accum, number): return accum + number) / yNamePool.size()
	var midName : String = str(midNameX) + " " + str(midNameY)
	var midPos : Vector3 = startingPoints.reduce(func(accum, SP): return accum + SP.position, Vector3.ZERO) / startingPoints.size() 
	var mid : GraphNodeCustom = GraphNodeCustom.new(midName, midPos)
	
	var midPoints : Array[GraphNodeCustom] = []
	var tooAddToMainArr : Array[GraphNodeCustom] = []
	for i in startingPoints.size() :
		var thisPoint : GraphNodeCustom = startingPoints[i]
		var nextPoint : GraphNodeCustom = startingPoints[(i + 1) % startingPoints.size()]
		# if the 2 point already have a mid point
		if !thisPoint.isNeighbor(nextPoint) :
			for j in thisPoint.get_neighbour():
				if j.isNeighbor(nextPoint) :
					midPoints.append(j)
					break
		else :
			var tempName : String = thisPoint.get_name() + " ~ " +  nextPoint.get_name()
			var temp : GraphNodeCustom = GraphNodeCustom.new(tempName, thisPoint.position.lerp(nextPoint.position, 0.5))
			removeNodeNeighbour(thisPoint, nextPoint)
			addNodeNeighbour(thisPoint, temp)
			addNodeNeighbour(nextPoint, temp)
			midPoints.append(temp)
			tooAddToMainArr.append(temp)
			#append outer most layer node
			var thisPointIdx = outermostLayer.find(thisPoint)
			var nextPointIdx = outermostLayer.find(nextPoint)
			if thisPointIdx != -1 && nextPointIdx != -1 :
				if thisPointIdx + 1 == nextPointIdx :
					outermostLayer.insert(nextPointIdx, temp)
				elif nextPointIdx + 1 == thisPointIdx :
					outermostLayer.insert(thisPointIdx, temp)
				else :
					outermostLayer.append(temp)
	
	#modify geometry arr
	squares.remove_at(index)
	for i in startingPoints :
		for j in midPoints :
			for k in midPoints :
				if j == k :
					break
				elif j.isNeighbor(i) && k.isNeighbor(i) :
					var vertices : Array[GraphNodeCustom] = [mid, j, i, k]
					var centroid : Vector3 = vertices.reduce(func(accum, SP): return accum + SP.position, Vector3.ZERO) / vertices.size() 
					var angleArr : Array = vertices.map(func(a): return Vector3(-1,0,0).signed_angle_to((a.position - centroid), Vector3(0,1,0)))
					angleArr = angleArr.map(func(a): return (2 * PI) + a if a < 0 else a)
					var sorted := angleArr.duplicate()
					sorted.sort_custom(func sortDecending(a, b) : return a > b)
					var final : Array[GraphNodeCustom] = []
					for l in sorted :
						final.append(vertices[angleArr.find(l)])
					afterSplitSquares.append(final)
	
	for i in midPoints :
		addNodeNeighbour(mid, i)
	mainGrid.append_array(tooAddToMainArr)
	mainGrid.append(mid)

func splitAllSquares() -> void :
	for i in squares.size() :
		if !squares.is_empty() :
			splitSquare(0)

#endregion
#region relax forces 
func runRelaxForceBoids() -> void :
	var forces: Array[Vector3] = []
	forces.resize(mainGrid.size())
	forces.fill(Vector3.ZERO)
	for i in range(relaxIteration):
		for j in mainGrid.size() :
			if !outermostLayer.has(mainGrid[j]):
				var proximityNodes : Array[GraphNodeCustom] = []
				if !proximityNodes.has(mainGrid[j]) :
					proximityNodes.append(mainGrid[j]) 
				for k in mainGrid[j].get_neighbour() :
					if !proximityNodes.has(k) :
						proximityNodes.append(k) 
				for kk in proximityNodes :
					var ratio : float = clampf((kk.position - mainGrid[j].position).length() / gridSpacing, 0.0, 1.0)
					forces[j] -= (kk.position - mainGrid[j].position) * -ratio
		
		# Apply force to vertices
		for jj in range(forces.size()):
			mainGrid[jj].position += forces[jj] * relaxForceScale
		
		# Reset for next iteration
		if i != relaxIteration - 1:
			for jj in range(forces.size()):
				forces[jj] = Vector3.ZERO

func runRelaxForce(index : String) -> void:
	if index == "Boids" :
		runRelaxForceBoids()

#endregion

func createInsideGrid() -> void:
	var insideNodes : Array[CentroidNodeCustom] = []
	insideNodes.resize(afterSplitSquares.size())
	var remainingConnection : Array[int] = []
	remainingConnection.resize(afterSplitSquares.size())
	remainingConnection.fill(4)
	var activeSquare : Array[Array] = []
	for i in afterSplitSquares.size() :
		var centroid : Vector3 = afterSplitSquares[i].reduce(func sum(accum: Vector3, vector: GraphNodeCustom): return accum + vector.position, Vector3.ZERO) / 4
		var newNodename : String = afterSplitSquares[i].reduce((func concat(accum: String, string: GraphNodeCustom): return accum + " " + string.name), "")
		var newNode : CentroidNodeCustom = CentroidNodeCustom.new(newNodename, centroid, [], afterSplitSquares[i])
		for j in 4 :
			var firstVertex : GraphNodeCustom = afterSplitSquares[i][j]
			var secondVertex : GraphNodeCustom = afterSplitSquares[i][(j + 1) % 4]
			var matches : Array[int] = findGeometryWithVertices(activeSquare, [firstVertex, secondVertex])
			for k in matches :
				var matchIdx : int = afterSplitSquares.find(activeSquare[k])
				var squareInsideNode : CentroidNodeCustom = insideNodes[matchIdx]
				addNodeNeighbour(newNode, squareInsideNode)
				
				remainingConnection[matchIdx] -= 1
				if remainingConnection[matchIdx] == 0 :
					activeSquare.remove_at(k)
		activeSquare.append(afterSplitSquares[i])
		insideNodes[i] = newNode
	for ii in insideNodes :
		var neighbourVer : Array[Array] = []
		var sortedNeighbor : Array[CentroidNodeCustom] = [null, null, null, null]
		for jj in ii.get_neighbour() :
			neighbourVer.append(jj.get_verticies())
		for jjj in 4 :
			var firstVertex : GraphNodeCustom = ii.get_verticies()[jjj]
			var secondVertex : GraphNodeCustom =ii.get_verticies()[(jjj + 1) % 4]

			var matches : Array[int] = findGeometryWithVertices(neighbourVer, [firstVertex, secondVertex])
			if matches.size() != 0 :
				sortedNeighbor[jjj] = ii.get_neighbour()[matches[0]]
		ii.clear_neighbor()
		for jjjj in sortedNeighbor :
			ii.add_neighbour(jjjj)
	insideGrid.append_array(insideNodes)

func initGrid() -> void :
	randy.set_seed(hash(userSeed))
	mainGrid.clear()
	insideGrid.clear()
	previousLayer.clear()
	triangles.clear()
	squares.clear()
	afterSplitSquares.clear()
	outermostLayer.clear()
	for i in get_children() :
		remove_child(i)
		i.queue_free()
	createGrid()
	createFinalHexCell()
	splitAllTriangles()
	splitAllSquares()
	if useRelax :
		runRelaxForce(relaxMethod)
	createInsideGrid()

func renderGrid() -> void :
	for i in get_children() :
		if i.get_name() == "insideGrid" || i.get_name() == "outsideGrid" :
			remove_child(i)
			i.queue_free()
	var insideGridNode : Node3D = Node3D.new()
	insideGridNode.set_name("insideGrid")
	add_child(insideGridNode)
	insideGridNode.owner = get_tree().edited_scene_root
	var outsideGridNode : Node3D = Node3D.new()
	outsideGridNode.set_name("outsideGrid")
	add_child(outsideGridNode)
	outsideGridNode.owner = get_tree().edited_scene_root
	var outsideGrid : Node3D = get_node("outsideGrid")
	var insideGridThing : Node3D = get_node("insideGrid")
	for i in mainGrid :
		outsideGrid.add_child(i)
		i.owner = get_tree().edited_scene_root
		i.createNeighborLine()
	
	for i in insideGrid :
		insideGridThing.add_child(i)
		i.owner = get_tree().edited_scene_root
		i.createNeighborLine()

#region Utilities
#GRAPH UTILITY
func addNodeNeighbour(nodeOne : GraphNodeCustom, nodeTwo : GraphNodeCustom) -> void:
	nodeOne.add_neighbour(nodeTwo)
	nodeTwo.add_neighbour(nodeOne)

func removeNodeNeighbour(nodeOne : GraphNodeCustom, nodeTwo : GraphNodeCustom) -> void:
	nodeOne.remove_neighbour(nodeTwo)
	nodeTwo.remove_neighbour(nodeOne)

func clearNodeNeighbor(node : GraphNodeCustom) -> void :
	for i in node.get_neighbour() :
		removeNodeNeighbour(node, i)

#highly coupled to createGrid
#can rewrite to caculate using grid spacing and node position
func hexGridNameGen(layer: int, index: int) -> String:
	layer += 1
	var result := ""
	var bigEgde : int = int(float(index) / layer) 
	var egdeIdx : int = index - bigEgde * layer 
	var x : float
	var y : int 
	match bigEgde :
		0 :
			x = float(layer) - (0.5 * egdeIdx)
			y = egdeIdx
		5 :
			x = float(layer) / 2 + (0.5 * egdeIdx)
			y = -layer + egdeIdx
		2 :
			x = -float(layer) / 2 - (0.5 * egdeIdx)
			y = layer - egdeIdx
		3 :
			x = -float(layer) + (0.5 * egdeIdx)
			y = -egdeIdx
		1 :
			x = float(layer) / 2 - egdeIdx
			y = layer
		4 :
			x = -float(layer) / 2 + egdeIdx
			y = -layer
		_:
			push_error("hexGridNameGen >6 ERROR: " + str(bigEgde) + " " + str(index) + " " + str(layer))
	result = str(x) + " " + str(y)
	return result

#GEOMETRY UTILITY
func findGeometryWithVertices(geometries: Array[Array], vertices: Array[GraphNodeCustom]) -> Array[int]:
	var pool : Array[int] = [] 
	pool.resize(geometries.size())
	for i in pool.size() :
		pool[i] = i
	for i in vertices :
		var temp : Array[int] = []
		for j in pool.size() :
			if !geometries[pool[j]].has(i) :
				temp.append(j)
		for jj in temp :
			pool[jj] = -1
		pool = pool.filter(func isNotNeg(number): return number != -1)
	#if pool.size() != 2 :
		#print("vertices" + str(vertices))
		#print("geometries")
		#for i in geometries :
			#print(i)
		#
	#print("pool" + str(pool))
	return pool
#endregion
#region init stuff
func create(parGridSize: int = gridSize, parSeed: String = userSeed) -> void:
	gridSize = parGridSize
	if parSeed.is_empty() :
		var randSeed :  String = str(randi_range(0, 9999999))
		userSeed = randSeed
	else :
		userSeed = parSeed
	initGrid()


func loadMesh( centroid : CentroidNodeCustom) -> Node3D :
	var tileTypeBaseTen : int = centroid.getCentroidCode()
	
	#BUG is not deterministic
	var randMesh : int = randi() % tileData.meshNameLookUp[tileData.lookUptable[tileTypeBaseTen]["type"]]["names"].size()
	var meshPath : String = tileData.scenePath + tileData.meshNameLookUp[tileData.lookUptable[tileTypeBaseTen]["type"]]["names"][randMesh] + ".scn"
	var mesh : Node3D = load(meshPath).instantiate()
	var meshRotation : int = tileData.lookUptable[tileTypeBaseTen]["rotation"]
	var meshMirror : int = tileData.lookUptable[tileTypeBaseTen]["mirror"]
	mesh.runInit(meshRotation, centroid.get_verticies().map(func pos(marker): return marker.position), centroid, meshMirror)
	return mesh 

func renderMesh() -> void :
	meshes.clear()
	if find_child("meshes") :
		queue_free()
	var meshesNode : Node3D = Node3D.new()
	meshesNode.set_name("meshes")
	add_child(meshesNode)
	meshesNode.owner = get_tree().edited_scene_root
	
	var noise : FastNoiseLite = FastNoiseLite.new()
	noise.set_seed(randy.randi())
	var noiseImg : Image = noise.get_image(int(gridSize * gridSpacing * 2), int(gridSize * gridSpacing * 2))
	
	for i in insideGrid.size() :
		if insideGrid[i].getCentroidCode() != 0 :
			var newMesh : VisualTile = loadMesh(insideGrid[i])
			meshes.append(newMesh)
			meshesNode.add_child(newMesh)
			newMesh.owner = get_tree().edited_scene_root
			newMesh.createGrass(noiseImg, forestThreshold)
	createOcean()
	stichingMesh()
	for i in meshes :
		i.removeMesh()
	
	createForestMesh(noiseImg)

func setInsideGridType() -> void :
	for i in insideGrid :
		i.set_centroid_tile_type()

func createOcean() -> void :
	var oceanNode : Node3D = ocean.instantiate()
	oceanNode.start(gridSize * gridSpacing * 2, gridSize * gridSpacing * 2)
	add_child(oceanNode)
	oceanNode.owner = get_tree().edited_scene_root
#endregion
#region river stuff
func getPotValidRiverNode() -> Dictionary:
	const VALID_CODES : Array[int] = [76, 52, 44, 68]
	const VALID_END_CODES : Array[int] = [36, 12, 4, 28]
	const VALID_START_CODES : Array[int] = [80, 40]
	var allResult : Array[CentroidNodeCustom] = []
	var startResult : Array[CentroidNodeCustom] = []
	var endResult : Array[CentroidNodeCustom] = []
	for node in insideGrid:
		var code = node.getCentroidCode()
		if VALID_CODES.has(code):
			allResult.append(node)
		elif VALID_START_CODES.has(code) :
			startResult.append(node)
		elif VALID_END_CODES.has(code) :
			endResult.append(node)
	var final := {
		"start" : startResult,
		"valid" : allResult,
		"end" : endResult,
	}
	return final

const VALID_RIVER_NODE : Array = [[40, 76, 52, 44, 68], [80]]
const VALID_RIVER_END_CODE : Array[int] = [36, 12, 4, 28]
const TRANSITION_NODE : Array[int] = [76, 52, 44, 68]

func createRiverDrain(gradientField : Image, start : CentroidNodeCustom = null, length = 10) -> void :
	var validNode : Dictionary = getPotValidRiverNode()
	if !start :
		start = validNode["end"][randy.randi_range(0, validNode["end"].size()) -1]
	var level : int = 0
	var past : Array[CentroidNodeCustom] = [start]
	var from : CentroidNodeCustom = start
	var to : CentroidNodeCustom 
	for i in length :
		if from.get_river_from() :
			break
		elif TRANSITION_NODE.has(from.get_terrain_code()) :
			#prints(from, "trigger")
			var lastNodeIdx : int = from.get_neighbour().find(from.get_river_to()[-1])
			var nextNodeIdx = lastNodeIdx - 2
			if VALID_RIVER_NODE[level + 1].has(from.get_neighbour()[nextNodeIdx].getCentroidCode()) :
				to = from.get_neighbour()[nextNodeIdx]
				level += 1
			else :
				#prints(from.get_neighbour()[nextNodeIdx], "cut")
				break
		else :
			var neighborScore : Array[float] = []
			var neighbors : Array[GraphNodeCustom] = from.get_neighbour()
			var fromDir : Vector2 = getGradientDir(from, gradientField)
			if fromDir.length() < 0.01:
				break 
			for j in neighbors :
				var temp2d := Vector2((j.get_position() - from.get_position()).x, (j.get_position() - from.get_position()).z)
				var score : float = fromDir.normalized().dot(temp2d.normalized())
				neighborScore.append(score)
			var bestScore : float = -INF
			for jj in neighborScore.size() :
				if !VALID_RIVER_NODE[level].has(neighbors[jj].get_terrain_code()) || !validNextRiverNode(from, neighbors[jj]) || past.has(neighbors[jj]) :
					continue
				if neighbors[jj].is_river() :
					#print("detected")
					if neighbors[jj].get_river_to().size() == 1  && neighbors[jj].get_river_from() :
						#print("merge")
						bestScore = 0
						to = neighbors[jj]
						break
					else :
						continue
				if neighborScore[jj] > bestScore :
					bestScore = neighborScore[jj]
					to = neighbors[jj]
			if bestScore == -INF :
				to = null
		if !to :
			break
		from.set_river_from(to)
		to.add_river_to(from)
		past.append(from)
		from = to

func validNextRiverNode(from : CentroidNodeCustom, to : CentroidNodeCustom) -> bool :
	var toIdx = from.get_neighbour().find(to)
	var nextNodeVer1 : int = toIdx
	var nextNodeVer2 : int = (toIdx + 1) % 4 
	return from.get_verticies()[nextNodeVer1].get_type() == from.get_verticies()[nextNodeVer2].get_type()

func getGradientDir(node : CentroidNodeCustom, gradientField : Image) -> Vector2 :
	var halfGridSize : float = gridSize * gridSpacing
	var pos : Vector3 = node.get_position()
	var sampleX : int = clampi(roundi(remap(pos.x, -halfGridSize, halfGridSize, 0, gradientField.get_width())), 0, gradientField.get_width() - 1)
	var sampleY : int = clampi(roundi(remap(pos.z, -halfGridSize, halfGridSize, 0, gradientField.get_height())), 0, gradientField.get_height() -1)
	var samplerResult : Color = gradientField.get_pixel(sampleX, sampleY)
	var dirX : float = samplerResult.r * 2.0 - 1.0
	var dirY : float = samplerResult.g * 2.0 - 1.0
	return Vector2(dirX, dirY) 

func getAllRiverNode() -> void :
	for i in insideGrid :
		if i.is_river() :
			riverNodes.append(i)

func cullShortRiver() -> void :
	getAllRiverNode()
	var roots : Array[CentroidNodeCustom]
	for i in riverNodes :
		if !i.riverFrom :
			roots.append(i)
	for ii in roots :
		var list : Array[CentroidNodeCustom]
		preOrder(ii, list)
		if list.size() < riverLengthThreshold :
			for i in list :
				i.clearRiver()
	

func preOrder(node : CentroidNodeCustom, list : Array[CentroidNodeCustom]) -> void :
	if !node :
		return 
	list.append(node)
	for i in node.get_river_to() :
		preOrder(i, list)
#endregion
#region road stuff
func createNav() -> void :
	var temp : Array[CentroidNodeCustom] = insideGrid.duplicate()
	temp.filter(pathable)
	for i in temp :
		var edges : Array[int] = [0,1,2,3]
		if i.is_river() :
			if i.riverFrom :
				edges[i.neighbour.find(i.riverFrom)] = -1
			for k in i.riverTo :
				edges[(i.neighbour.find(k))] = -1
		for j in edges :
			if j == -1 :
				continue
			if i.vertices[j].tileType == 1 || (i.vertices[j].tileType == 2 && i.vertices[j].modable):
				if i.vertices[(j + 1) % 4].tileType == 1 || (i.vertices[(j + 1) % 4].tileType == 2 && i.vertices[(j + 1) % 4].modable) :
					i.set_pathable_single(j, true)
	
#FIX add water tile
const PATH_TILE : Array = [
	40,										#LLLL
	80,										#MMMM
	37,39,13,31,							#LLWL
	42,14,58,46,38,66,22,34,				#LLMW
	36,12,4,28,								#LLWW
	51,17,59,73,65,75,25,35,				#LMMW
	67,49,43,41,							#MLLL
	70,50,									#MLML
	76,52,44,68,							#MMLL
	77,79,53,71,							#MMLM
	74,78,26,62,							#MMWM
	526,202,4414,1498,						#LLLL/0020
	2713,931,4657,1579,						#LLLL/1020
	3685,1255,445,4495,2389,5143,1741,607	#LLLL/1200
	]

func pathable(node : CentroidNodeCustom) -> bool :
	if PATH_TILE.has(node.getCentroidCode()) :
		return true 
	else :
		return false

func find_path_dijkstra(from_node: CentroidNodeCustom, to_node: CentroidNodeCustom) -> Array[CentroidNodeCustom]:
	
	if not from_node or not to_node:
		return []
		
	if from_node == to_node:
		return [from_node]

	var distances: Dictionary = { from_node: 0.0 } # GraphNodeCustom -> float
	var came_from: Dictionary = {}               # GraphNodeCustom -> GraphNodeCustom
	var visited: Dictionary = {}                 # Set of visited nodes
	var unvisited: Array[CentroidNodeCustom] = [from_node]

	while unvisited.size() > 0:
		# 1. Get unvisited node with smallest distance
		var current: CentroidNodeCustom = unvisited[0]
		var current_dist: float = distances[current]
		
		for node in unvisited:
			if distances[node] < current_dist:
				current = node
				current_dist = distances[node]

		# 2. Early exit on reaching target
		if current == to_node:
			return reconstruct_path(came_from, to_node)

		unvisited.erase(current)
		visited[current] = true

		# 3. Explore adjacent neighbors
		for i in current.get_pathable().size():
			if current.get_pathable()[i] == false or visited.has(current.get_neighbour()[i]):
				continue
			var neighbour = current.get_neighbour()[i]
			var step_cost: float = calculate_weight(current, neighbour)
			var new_dist: float = distances[current] + step_cost

			if not distances.has(neighbour) or new_dist < distances[neighbour]:
				distances[neighbour] = new_dist
				came_from[neighbour] = current
				
				if not unvisited.has(neighbour):
					unvisited.append(neighbour)

	return []

func calculate_weight(from_n: CentroidNodeCustom, to_n: CentroidNodeCustom) -> float:
	if from_n.neighbourIsPathed(to_n) :
		return 1
	if to_n.is_river() :
		return 3
	return 2

func reconstruct_path(came_from: Dictionary, current: CentroidNodeCustom) -> Array[CentroidNodeCustom]:
	var path: Array[CentroidNodeCustom] = [current]
	while came_from.has(current):
		current = came_from[current]
		path.append(current)
	path.reverse()
	return path

func createRoad() -> void :
	for i in insideGrid.size() :
		if insideGrid[i].name == " -4_25 -0_5 -4_0 0 ~ -3_5 -1 -3_5 -1 -3_5 -1 ~ -4_5 -1" || insideGrid[i].name == " 3_5 -1 ~ 3_0 0 3_5 -1 3_0 -2 ~ 3_5 -1 3_0 -1_0" :
			prints(i, insideGrid[i])
	var from : CentroidNodeCustom = insideGrid[317]
	var to : CentroidNodeCustom = insideGrid[906]
	var path : Array[CentroidNodeCustom] = find_path_dijkstra(from, to)
	for i in path.size() - 1 :
		path[i].pathed[path[i].get_neighbour().find(path[i + 1])] = true
	for i in range(1, path.size()) :
		path[i].pathed[path[i].get_neighbour().find(path[i - 1])] = true
	for i in path :
		for j in i.pathed.size() :
			if i.pathed[j] == true :
				if i.vertices[j].tileType != 1 :
					i.vertices[j].set_type(GraphNodeCustom.TYPE.LAND)
				if i.vertices[(j + 1) % 4].tileType != 1 :
					i.vertices[(j + 1) % 4].set_type(GraphNodeCustom.TYPE.LAND)

#endregion 

func stichingMesh() -> void :
	var toCheck : Array[String] = ["land", "water", "path"]
	for type in toCheck :
		var surface_array = []
		surface_array.resize(Mesh.ARRAY_MAX)
		var verts = PackedVector3Array()
		var indices = PackedInt32Array()
		for i in meshes :
			var mesh : ArrayMesh
			for j in i.get_children() :
				if j.get_name().ends_with("-" + type) :#######
					mesh = j.get_mesh()
			if !mesh :
				continue
			var arr : Array = mesh.surface_get_arrays(0)
			var packedVert : PackedVector3Array = PackedVector3Array(arr[Mesh.ARRAY_VERTEX]).duplicate()
			var packedIndices : PackedInt32Array = PackedInt32Array(arr[Mesh.ARRAY_INDEX]).duplicate()
			for j in packedIndices.size() :
				packedIndices[j] = packedIndices[j] + verts.size()
			verts.append_array(packedVert)
			indices.append_array(packedIndices)
		
		surface_array[Mesh.ARRAY_VERTEX] = verts
		surface_array[Mesh.ARRAY_INDEX] = indices
	
		var meshNode : MeshInstance3D = MeshInstance3D.new()
		var tempMesh : ArrayMesh = ArrayMesh.new()
		tempMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
		meshNode.set_mesh(tempMesh)
		meshNode.set_name(type + "Mesh") 
		add_child(meshNode)
		meshNode.owner = get_tree().edited_scene_root

func createForestMesh(noiseImg : Image) -> void :
	var forestMesh : MeshInstance3D = get_node("landMesh")
	var forestMeshArr : Array = forestMesh.get_mesh().surface_get_arrays(0)
	var packedVert : PackedVector3Array = PackedVector3Array(forestMeshArr[Mesh.ARRAY_VERTEX]).duplicate()
	var packedIndices : PackedInt32Array = PackedInt32Array(forestMeshArr[Mesh.ARRAY_INDEX])
	var outputArr : PackedInt32Array = PackedInt32Array([])
	outputArr.resize(packedIndices.size())
	outputArr.fill(0)
	var computeShader = ComputeHelper.create("res://shader/cullSurface.glsl")
	
	var noiseUniform = ImageUniform.create(noiseImg)
	var thresholdAndOffset = StorageBufferUniform.create(PackedFloat32Array([forestThreshold, gridSize * gridSpacing]).to_byte_array())
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
	var surface_array = []
	var tempOffset : float = gridSize * gridSpacing
	var mapWidth : float = tempOffset * 2
	var packedUV : PackedVector2Array = PackedVector2Array([])
	
	for i in packedVert :
		var uvX : float = (i.x + tempOffset) / mapWidth
		var uvY : float = (i.z + tempOffset) / mapWidth
		packedUV.append(Vector2(uvX, uvY))
	
	surface_array.resize(Mesh.ARRAY_MAX)
	surface_array[Mesh.ARRAY_VERTEX] = packedVert
	surface_array[Mesh.ARRAY_INDEX] = newIndices
	surface_array[Mesh.ARRAY_TEX_UV] = packedUV
	
	var tempMesh : ArrayMesh = ArrayMesh.new()
	tempMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	var tempShape : ConcavePolygonShape3D = tempMesh.create_trimesh_shape() 
	tempShape.set_backface_collision_enabled(true)
	var meshNode : MeshInstance3D = MeshInstance3D.new()
	meshNode.set_mesh(tempMesh)
	meshNode.set_name("forestMesh") 
	add_child(meshNode)
	meshNode.owner = get_tree().edited_scene_root
	
	var colliderNode : StaticBody3D = StaticBody3D.new()
	colliderNode.set_name("forestCollider") 
	add_child(colliderNode)
	colliderNode.owner = get_tree().edited_scene_root
	
	var shapeNode : CollisionShape3D = CollisionShape3D.new()
	shapeNode.set_shape(tempShape)
	shapeNode.set_name("forestShape") 
	colliderNode.add_child(shapeNode)
	shapeNode.owner = get_tree().edited_scene_root
