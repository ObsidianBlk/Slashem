shader_type canvas_item;

uniform vec4 region = vec4(1.0);
uniform vec4 color : source_color = vec4(1.0);

vec2 remap_uv(vec2 uv, vec2 scale){
	float dx = region.x * scale.x;
	float dy = region.y * scale.y;
	float dw = region.z * scale.x;
	float dh = region.w * scale.y;
	return vec2(dx + (dw * uv.x), dy + (dh * uv.y));
}

void fragment() {
	vec2 uv = remap_uv(UV, TEXTURE_PIXEL_SIZE);
	vec4 original = texture(TEXTURE, uv);
	if (original.r >= 0.97 && original.g >= 0.97 && original.b >= 0.97)
		original = vec4(color.rgb, original.a);
	COLOR = original;
}
