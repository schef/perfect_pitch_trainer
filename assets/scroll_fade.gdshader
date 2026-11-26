shader_type canvas_item;
render_mode unshaded;

uniform sampler2D background_texture : source_color, filter_linear;
uniform vec2 background_size;
uniform vec2 region_position;
uniform vec2 region_size;
uniform bool top_edge = true;
uniform float strength : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	// Match the full-screen TextureRect's KEEP_ASPECT_COVERED mapping.
	vec2 image_size = vec2(textureSize(background_texture, 0));
	float cover_scale = max(background_size.x / image_size.x, background_size.y / image_size.y);
	vec2 position = region_position + UV * region_size;
	vec2 background_uv = (position - background_size * 0.5) / (image_size * cover_scale) + 0.5;
	float edge = top_edge ? 1.0 - UV.y : UV.y;
	COLOR = vec4(texture(background_texture, background_uv).rgb, smoothstep(0.0, 1.0, edge) * strength);
}
