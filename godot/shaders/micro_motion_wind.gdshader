shader_type canvas_item;

uniform float amplitude : hint_range(0.0, 32.0, 0.1) = 8.0;
uniform float frequency : hint_range(0.0, 10.0, 0.1) = 2.5;
uniform float speed_multiplier : hint_range(0.0, 6.0, 0.1) = 1.0;
uniform float vertical_scale : hint_range(0.0, 8.0, 0.1) = 3.0;

void vertex() {
    float wave = sin(TIME * speed_multiplier + UV.y * vertical_scale * TAU);
    VERTEX.x += wave * amplitude;
}
