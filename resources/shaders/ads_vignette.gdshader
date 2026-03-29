shader_type canvas_item;

uniform vec2 center_px = vec2(640.0, 360.0);
uniform float radius_px = 30.0;
uniform float darkness = 0.75;
uniform float softness_px = 4.0;

void fragment() {
	vec2 screen_size = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 frag_px = SCREEN_UV * screen_size;
	float dist = distance(frag_px, center_px);
	float mask = smoothstep(radius_px - softness_px, radius_px + softness_px, dist);
	COLOR = vec4(0.0, 0.0, 0.0, darkness * mask);
}
