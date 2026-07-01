shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 result = COLOR;
	float rateX = dFdxFine(result.x);
	float rateY = dFdyFine(result.x);
	vec2 test =  (vec2(rateX, rateY));
	COLOR = vec4(test * 0.5 + 0.5, 0.0, 1.0);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
