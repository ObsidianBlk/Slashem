shader_type canvas_item;

uniform vec4 color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 original = texture(TEXTURE, UV);
	if (original.r >= 0.97 && original.g >= 0.97 && original.b >= 0.97){
		COLOR = vec4(color.rgb, original.a);
	} else {
		COLOR = original;
	}
}
