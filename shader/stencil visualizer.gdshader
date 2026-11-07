shader_type spatial;
render_mode unshaded, depth_test_disabled, cull_disabled;

// Set your desired visualization color in the Inspector
uniform vec4 stencil_visible_color : source_color = vec4(0.0, 1.0, 0.0, 0.5);

void vertex() {
	// Transforming vertex positions to fill the screen perfectly regardless of FOV
	POSITION = vec4(VERTEX.xy, 0.0, 1.0);
}

void fragment() {
	//The actual stencil filtering is handled by the material configuration below.
	//When the stencil test passes, this color will overlay onto the screen.
	ALBEDO = stencil_visible_color.rgb;
	ALPHA = stencil_visible_color.a;
}