shader_type canvas_item;

uniform float wind_strength : hint_range(0.0, 4.0, 0.05) = 0.8;
uniform float wind_speed : hint_range(0.0, 5.0, 0.05) = 0.9;
uniform float wind_frequency : hint_range(0.0, 20.0, 0.1) = 4.5;
uniform float base_lock : hint_range(0.0, 1.0, 0.01) = 0.35;
uniform bool pixel_step = true;

instance uniform float wind_phase = 0.0;
instance uniform float wind_scale = 1.0;

void vertex() {
	float top_weight = 1.0 - UV.y;
	top_weight = smoothstep(base_lock, 1.0, top_weight);

	float wave = sin(TIME * wind_speed + wind_phase + UV.y * wind_frequency);
	float offset = wave * wind_strength * wind_scale * top_weight;

	if (pixel_step) {
		offset = round(offset);
	}

	VERTEX.x += offset;
}