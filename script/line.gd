class_name Line3D extends MeshInstance3D

@export var m_pntStart : Vector3 = Vector3.ZERO : get=getStart,set=setStart

@export var m_pntEnd : Vector3 = Vector3.ZERO : get=getEnd,set=setEnd

var m_color : Color = Color.WHITE

@export var m_material : ORMMaterial3D = ORMMaterial3D.new()

func _init(start: Vector3, end: Vector3, color: Color = Color.WHITE) -> void:
	setStart(start)
	setEnd(end)
	setColor(color)

func _ready():
	mesh = ImmediateMesh.new()
	m_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m_material.albedo_color = m_color

func _process(_delta):
	draw()

func getStart():
	return m_pntStart

func getEnd():
	return m_pntEnd
	
func setStart(a : Vector3):
	m_pntStart = a
	
func setEnd(a : Vector3):
	m_pntEnd = a

func setColor(a : Color):
	m_color = a
	m_material.albedo_color = m_color

func draw():
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, m_material)
	mesh.surface_add_vertex(m_pntStart)
	mesh.surface_add_vertex(m_pntEnd)
	mesh.surface_end()
