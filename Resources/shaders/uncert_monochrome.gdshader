shader_type spatial;

uniform sampler2D sampler;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	// pretend that the world position (0, 0, 0) has been activated
	vec3 pixel_world_pos = (INV_VIEW_MATRIX  * vec4(VERTEX, 1.0)).xyz;
	//ALBEDO = vec3(1.0/UV[0], 1.0/UV[1], 1.0/(UV[0] * UV[1]));
	// ALPHA = 0.2;
	vec4 input_color = texture(sampler, UV);

	// set level to the input texture
	float level = input_color.a;

	vec4 output_color;

	// blue
	if (level < 0.25) {
		output_color = vec4(0, 0, level*4.0, 1.0);
	}
	// purple
	else if (level < 0.50) {
		output_color = vec4((level-0.25)*2.0, 0.0, 1.0, 1.0);
	}
	// yellow
	else if (level < 0.75) { // from 0.5, 0.0, 1.0
		output_color = vec4(0.5 + (level - 0.5) * 2.0, (level - 0.5) * 4.0, 1.0 - (level - 0.5) * 4.0, 1.0);
	}
	// white
	else if (level <= 1.0) {
		output_color = vec4(1.0, 1.0, (level - 0.75) * 4.0, 1.0);
	}
	ALBEDO = vec3(output_color[0], output_color[1], output_color[2]);

	/*
	if (level == 0.0){
		ALBEDO = vec3(0, 0, 0);
	}
	else if (level < 0.25) {
		ALBEDO = vec3(level*1.33, 0, 0);
	}
	else if (level < 0.75) {
		ALBEDO = vec3(level*1.33, 0, 0); //0.5-(level*1.33/0.5));
	}
	else {
		ALBEDO = vec3(1.0, (level - 0.75)*2.0, (level - 0.75)*2.0);
	}
	*/

	ALPHA = 0.8 + (level*0.2);
	/*
	if (level < 0.5) {
		output_color = vec4(level*2.0, 0, 0, 1.0);
	}
	else {
		output_color = vec4(1.0, (level-0.5)*2.0, (level-0.5)*2.0, 1.0);
	}
	*/
	//ALBEDO = vec3(output_color[0], output_color[1], output_color[2]);
	//DEPTH = level;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
