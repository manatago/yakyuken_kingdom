shader_type canvas_item;

uniform vec4 key_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // Default to white
uniform float similarity : hint_range(0.0, 1.0) = 0.1;
uniform float smoothness : hint_range(0.0, 1.0) = 0.08;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	float diff = distance(color.rgb, key_color.rgb);
	float alpha = smoothstep(similarity, similarity + smoothness, diff);
	COLOR = vec4(color.rgb, color.a * alpha);
}
