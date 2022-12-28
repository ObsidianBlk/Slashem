shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0);
uniform float smoothness : hint_range(0.0, 1.0);
uniform sampler2D mask;

void fragment() {
	vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV);
	float value = texture(mask, UV).r * (1.0 - smoothness);
	float weight = smoothstep(progress, progress + smoothness, value + smoothness);
	COLOR = mix(COLOR, screen_color, weight);
}
