shader_type canvas_item;

uniform vec4 shadow_color : source_color = vec4(0.20, 0.18, 0.12, 0.28);
uniform float opacity : hint_range(0.0, 1.0) = 0.35;
uniform float edge_softness : hint_range(0.0, 1.0) = 0.45;
uniform float noise_strength : hint_range(0.0, 1.0) = 0.12;
uniform float wind_strength : hint_range(0.0, 10.0) = 1.0;
uniform float wind_speed : hint_range(0.0, 5.0) = 0.35;
uniform float wind_phase = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);

	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	vec2 u = f * f * (3.0 - 2.0 * f);

	return mix(a, b, u.x) +
		(c - a) * u.y * (1.0 - u.x) +
		(d - b) * u.x * u.y;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	// 텍스처 알파를 기본 그림자 마스크로 사용
	float mask = tex.a;

	// 가장자리 부드럽게
	mask = smoothstep(edge_softness, 1.0, mask);

	// 아주 약한 바람 흔들림 느낌
	float t = TIME * wind_speed + wind_phase;
	vec2 wind_uv = UV;
	wind_uv.x += sin(UV.y * 8.0 + t) * 0.015 * wind_strength;

	float n = noise(wind_uv * 8.0 + vec2(t * 0.15, 0.0));
	float variation = mix(1.0 - noise_strength, 1.0, n);

	COLOR = shadow_color;
	COLOR.a = mask * opacity * variation;
}