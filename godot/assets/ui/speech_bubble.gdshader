shader_type canvas_item;

uniform float radius : hint_range(0.0, 0.5) = 0.12;
uniform float border : hint_range(0.0, 0.05) = 0.012;
uniform float shadow_soft : hint_range(0.0, 0.1) = 0.04;
uniform float tail_width : hint_range(0.0, 0.3) = 0.1;
uniform float tail_height : hint_range(0.0, 0.5) = 0.22;
uniform vec2 tail_pos = vec2(0.5, 0.78);
uniform vec4 bg_color_top : source_color = vec4(1.0, 1.0, 1.0, 0.96);
uniform vec4 bg_color_bottom : source_color = vec4(0.93, 0.92, 0.96, 0.96);
uniform vec4 border_color : source_color = vec4(0.45, 0.38, 0.55, 0.6);
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.18);

float sdf_rounded_rect(vec2 p, vec2 half_size, float r) {
	vec2 d = abs(p) - half_size + vec2(r);
	return length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0) - r;
}

float sdf_tail(vec2 uv, vec2 tip, float w, float body_bottom) {
	vec2 a = vec2(tip.x - w, body_bottom);
	vec2 b = vec2(tip.x + w, body_bottom);
	vec2 c = tip;
	vec2 v0 = c - a; vec2 v1 = b - a; vec2 v2 = uv - a;
	float d00 = dot(v0, v0); float d01 = dot(v0, v1); float d02 = dot(v0, v2);
	float d11 = dot(v1, v1); float d12 = dot(v1, v2);
	float inv = 1.0 / (d00 * d11 - d01 * d01);
	float u = (d11 * d02 - d01 * d12) * inv;
	float v = (d00 * d12 - d01 * d02) * inv;
	if (u >= 0.0 && v >= 0.0 && (u + v) <= 1.0) return -0.001;
	float dist = 1e6;
	vec2 e1 = c - a; vec2 p1 = uv - a;
	float t1 = clamp(dot(p1, e1) / dot(e1, e1), 0.0, 1.0);
	dist = min(dist, length(p1 - e1 * t1));
	vec2 e2 = c - b; vec2 p2 = uv - b;
	float t2 = clamp(dot(p2, e2) / dot(e2, e2), 0.0, 1.0);
	dist = min(dist, length(p2 - e2 * t2));
	return dist;
}

void fragment() {
	vec2 uv = UV;
	float body_h = 1.0 - tail_height;
	vec2 body_center = vec2(0.5, body_h * 0.5);
	vec2 body_half = vec2(0.5, body_h * 0.5);

	float d_body = sdf_rounded_rect(uv - body_center, body_half, radius);

	vec2 tip = vec2(tail_pos.x, tail_pos.y + tail_height * 0.3);
	float d_tail = sdf_tail(uv, tip, tail_width, body_h);

	float d = min(d_body, d_tail);

	float shadow_d = min(
		sdf_rounded_rect(uv - body_center + vec2(0.008, 0.015), body_half, radius),
		sdf_tail(uv + vec2(0.008, 0.015), tip, tail_width, body_h)
	);
	float shadow = smoothstep(0.0, shadow_soft, -shadow_d) * shadow_color.a;

	float fill = smoothstep(0.002, -0.002, d);
	vec4 bg = mix(bg_color_bottom, bg_color_top, smoothstep(body_h, 0.0, uv.y));

	float border_ring = smoothstep(border + 0.003, border, abs(d));
	border_ring *= step(d, 0.003);

	vec4 col = vec4(0.0);
	col = mix(col, shadow_color, shadow * (1.0 - fill));
	col = mix(col, bg, fill);
	col = mix(col, border_color, border_ring * border_color.a);

	COLOR = col;
}
