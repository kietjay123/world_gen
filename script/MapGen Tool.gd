@tool
extends Node

@export_tool_button("Create", "Callable") var create = createMap

@export var gridSize : int = 5 : 
	set(value):
		gridSize = value

@export_range(-1, 1) var seaLevel := -0.027 : 
	set(value):
		seaLevel = value

@export_range(-1, 1) var landLevel : float = 0.492 : 
	set(value):
		landLevel = value

@export var samplingMultiplier : float = 1.5

@export_enum("Default") var heightMapMethod: String = "Default"

@export var noise : FastNoiseLite

@export var userSeed : String = "test" :
	get: 
		return userSeed
	set(value):
		userSeed = value
		noise.seed = value.hash()

@export var ShapeGradient : GradientTexture2D

var heightMap : Image 
var computeShader : ComputeHelper
var noiseTexture : ImageUniform
var gradTexture : ImageUniform
var heightMapTexture : SharedImageUniform
var gradientMapTexture : SharedImageUniform
var levelsUniform : StorageBufferUniform

@export var graph := preload("res://scene/graph_creator.scn")
@export var shaderOutputSubviewport := preload("res://scene/shader_output.tscn")

var shaderOutput : ShaderOutput

#region height map creation

# nyquist-shannon sampling theorem
func calGradientSize() -> int :
	var result : int = 0
	result = ceil(2 * ( 2 * (gridSize * 2) + 1 ) * samplingMultiplier) 
	return result 

func setupGradient() -> void :
	var size = calGradientSize()
	ShapeGradient.set_width(size)
	ShapeGradient.set_height(size)
	var to = (Vector2(0.5, 0).rotated(deg_to_rad(30)) + ShapeGradient.get_fill_from()) * (2/sqrt(5))
	ShapeGradient.set_fill_to(to)

func createMaps():
	setupGradient()
	var result : Image = useShaderMap()
	heightMap = result
	var heightMapNode : Sprite2D = Sprite2D.new()
	heightMapNode.set_name("heightMap")
	heightMapNode.texture = ImageTexture.create_from_image(heightMap)
	shaderOutput.addOutput(heightMapNode)
	
	var gradientMap : Image = useShaderGradientMap()
	var gradientMapNode : Sprite2D = Sprite2D.new()
	gradientMapNode.set_name("gradientMap")
	var gradientMat : Material = load("res://shader/gradientMat.tres")
	gradientMapNode.set_material(gradientMat)
	gradientMapNode.texture = ImageTexture.create_from_image(gradientMap)
	shaderOutput.addOutput(gradientMapNode)
	

func useShaderMap() -> Image :
	computeShader = ComputeHelper.create("res://shader/addingHeightMap.glsl")
	var noiseImg : Image = noise.get_image(ShapeGradient.get_width() , ShapeGradient.get_height())
	noiseImg.convert(Image.FORMAT_RGBA8)
	var graImg := ShapeGradient.get_image()
	noiseTexture = ImageUniform.create(noiseImg)
	gradTexture = ImageUniform.create(graImg)
	heightMapTexture = SharedImageUniform.create(noiseTexture)
	levelsUniform = StorageBufferUniform.create(PackedFloat32Array([seaLevel, landLevel]).to_byte_array())
	computeShader.add_uniform_array([gradTexture, noiseTexture, heightMapTexture, levelsUniform])
	var w = int(ceil(ShapeGradient.get_width() / 8.0))
	var h = int(ceil(ShapeGradient.get_height() / 8.0))
	computeShader.run(Vector3i(w, h, 1))
	ComputeHelper.sync()
	return heightMapTexture.get_image()

func useShaderGradientMap() -> Image :
	computeShader = ComputeHelper.create("res://shader/gradientHeightMap.glsl")
	var noiseImg : Image = noise.get_image(ShapeGradient.get_width() , ShapeGradient.get_height())
	noiseImg.convert(Image.FORMAT_RGBA8)
	var graImg := ShapeGradient.get_image()
	noiseTexture = ImageUniform.create(noiseImg)
	gradTexture = ImageUniform.create(graImg)
	gradientMapTexture = SharedImageUniform.create(noiseTexture)
	computeShader.add_uniform_array([gradTexture, noiseTexture, gradientMapTexture])
	var w = int(ceil(ShapeGradient.get_width() / 8.0))
	var h = int(ceil(ShapeGradient.get_height() / 8.0))
	computeShader.run(Vector3i(w, h, 1))
	ComputeHelper.sync()
	return gradientMapTexture.get_image()

#endregion

func samplingMesh(graphNode : Hex) -> void :
	var halfGridSize : float = gridSize * graphNode.gridSpacing
	for i in graphNode.mainGrid :
		var pos : Vector3 = i.get_position()
		var sampleX : int = clampi(roundi(remap(pos.x, -halfGridSize, halfGridSize, 0, heightMap.get_width())), 0, heightMap.get_width() - 1)
		var sampleY : int = clampi(roundi(remap(pos.z, -halfGridSize, halfGridSize, 0, heightMap.get_height())), 0, heightMap.get_height() -1)
		var samplerResult : Color = heightMap.get_pixel(sampleX, sampleY)
		if samplerResult.is_equal_approx(Color(0, 1, 0, 1)) :
			i.set_type(GraphNodeCustom.TYPE.LAND)
		elif samplerResult.is_equal_approx(Color(0, 0, 1, 1)) :
			i.set_type(GraphNodeCustom.TYPE.WATER)
		elif samplerResult.is_equal_approx(Color.from_rgba8(108, 123, 109, 255)) :
			i.set_type(GraphNodeCustom.TYPE.MOUNTAIN)
		else :
			push_warning("what" + str(samplerResult))

func createMap() -> void :
	for i in get_children() :
		if i is Camera3D :
			continue
		remove_child(i)
	
	shaderOutput = shaderOutputSubviewport.instantiate()
	add_child(shaderOutput)
	shaderOutput.owner = get_tree().edited_scene_root
	
	createMaps()
	
	var graphNode : Hex = graph.instantiate()
	add_child(graphNode)
	graphNode.owner = get_tree().edited_scene_root
	graphNode.create(gridSize, userSeed)
	samplingMesh(graphNode)
	
	graphNode.renderMesh()
	
	var test := await shaderOutput.getOutput("gradientMap")
	print(test.get_pixel(6, 0))
