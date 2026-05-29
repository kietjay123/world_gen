@tool
class_name Hex extends Node3D

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

var mainGrid : Array[GraphNodeCustom] = []

var previousLayer : Array[GraphNodeCustom] = []

var triangles : Array[Array] = []

var squares : Array[Array] = []

var afterSplitSquares : Array[Array] = []

var offsetGrid : Array[GraphNodeCustom] = []

var outermostLayer : Array[GraphNodeCustom] = []

var insideGrid : Array[CentroidNodeCustom] = [] 

var meshes : Array[Node3D] = []

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
	insideGrid.append_array(insideNodes)

func renderGrid() -> void :
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
	#for i in outermostLayer :
		#print(i)
	#print("triangles: " + str(triangles.size()))
	#for i in triangles :
		#print(i)
	#print("squares: " + str(squares.size()))
	#for i in squares :
		#print(i)
	#print("after split square: " + str(afterSplitSquares.size()))
	#for i in afterSplitSquares :
		#print(i)
	if addNodeToTree :
		var insideGridNode : Node3D = Node3D.new()
		insideGridNode.set_name("insideGrid")
		add_child(insideGridNode)
		insideGridNode.owner = get_tree().edited_scene_root
		var outsideGridNode : Node3D = Node3D.new()
		outsideGridNode.set_name("outsideGrid")
		add_child(outsideGridNode)
		outsideGridNode.owner = get_tree().edited_scene_root
		
		for i in mainGrid :
			var outsideGrid : Node3D = get_node("outsideGrid")
			outsideGrid.add_child(i)
			i.owner = get_tree().edited_scene_root
			for j in i.neighbour :
				var neighbourLine : Line3D = Line3D.new(Vector3.ZERO, Vector3.ZERO.lerp(j.position - i.position, 0.5), Color.WHITE)
				i.add_child(neighbourLine)
				neighbourLine.owner = get_tree().edited_scene_root
		
		for i in insideGrid :
			var insideGridThing : Node3D = get_node("insideGrid")
			insideGridThing.add_child(i)
			i.owner = get_tree().edited_scene_root
			for j in i.neighbour :
				var neighbourLine : Line3D = Line3D.new(Vector3.ZERO, Vector3.ZERO.lerp(j.position - i.position, 0.5), Color.WHITE)
				i.add_child(neighbourLine)
				neighbourLine.owner = get_tree().edited_scene_root

#region Utilities
#GRAPH UTILITY
func addNodeNeighbour(nodeOne : GraphNodeCustom, nodeTwo : GraphNodeCustom) -> void:
	nodeOne.add_neighbour(nodeTwo)
	nodeTwo.add_neighbour(nodeOne)

func removeNodeNeighbour(nodeOne : GraphNodeCustom, nodeTwo : GraphNodeCustom) -> void:
	nodeOne.remove_neighbour(nodeTwo)
	nodeTwo.remove_neighbour(nodeOne)

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

#MESH UTILITY
func baseThreeToBaseTen(arg : String) -> int :
	var result : int  = 0
	var power : int = 0
	for i in range(arg.length() - 1, -1, -1) :
		result += arg[i].to_int() * (3 ** power)
		power += 1
	return result 
#endregion

func create(parGridSize: int = gridSize, parSeed: String = userSeed) -> void:
	gridSize = parGridSize
	if parSeed.is_empty() :
		var randSeed :  String = str(randi_range(0, 9999999))
		userSeed = randSeed
	else :
		userSeed = parSeed
	renderGrid()

var reverseTypeLookUp : Dictionary[String, String] =  {"W" : "0", "L" : "1", "M" : "2"}
func loadMesh( centroid : CentroidNodeCustom ) -> Node3D :
	var tileType : String = ""
	for i in centroid.get_verticies().size()  :
		tileType += centroid.get_verticies()[i].get_type_string()
	
	var tileTypeBaseThree : String = ""
	for ii in tileType :
		tileTypeBaseThree += reverseTypeLookUp[ii]
	var tileTypeBaseTen : int = baseThreeToBaseTen(tileTypeBaseThree)
	
	# does not apply multi tile 
	var randMesh : int = randi() % tileData.meshNameLookUp[tileData.lookUptable[tileTypeBaseTen]["type"]]["names"].size()
	var meshPath : String = tileData.scenePath + tileData.meshNameLookUp[tileData.lookUptable[tileTypeBaseTen]["type"]]["names"][randMesh] + ".tscn"
	var mesh : Node3D = load(meshPath).instantiate()
	var meshRotation : int = tileData.lookUptable[tileTypeBaseTen]["rotation"]
	mesh.initializeConstructor(meshRotation, centroid.get_verticies().map(func pos(marker): return marker.position))
	mesh.updateMeshContructor()
	return mesh 

func renderMesh() -> void :
	meshes.clear()
	if find_child("meshes") :
		queue_free()
	var meshesNode : Node3D = Node3D.new()
	meshesNode.set_name("meshes")
	add_child(meshesNode)
	meshesNode.owner = get_tree().edited_scene_root
	for i in insideGrid.size() :
		#if insideGrid[i].name == " -1_0 0 ~ -2_0 0 -1_0 0 -0_5 -1 ~ -1_0 0 -1_25 -0_5" :
			var newMesh : Node3D = loadMesh(insideGrid[i])
			meshes.append(newMesh)
			meshesNode.add_child(newMesh)
			newMesh.owner = get_tree().edited_scene_root
