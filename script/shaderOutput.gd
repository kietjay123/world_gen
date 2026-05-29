@tool
class_name ShaderOutput extends SubViewport

func addOutput(input : Sprite2D) -> void :
	input.centered = false
	add_child(input)
	input.owner = get_tree().edited_scene_root

func getOutput(spriteName : String) -> Image :
	var node : Sprite2D = get_node(spriteName)
	node.set_visible(true)
	for i in get_children() :
		if !( i == node ) :
			i.set_visible(false)
	var imageSize : Vector2i = Vector2i(node.get_texture().get_size())
	set_size(imageSize)
	var texture := get_texture()
	await RenderingServer.frame_post_draw
	var image : Image = texture.get_image()
	return image
