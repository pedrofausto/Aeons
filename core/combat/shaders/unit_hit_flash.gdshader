shader_type canvas_item;

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 0.96, 0.85, 1.0);
uniform float morale_dim : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 col = mix(tex.rgb, flash_color.rgb, flash_amount);
	col = mix(col, vec3(dot(col, vec3(0.299, 0.587, 0.114))) * 0.65, morale_dim);
	COLOR = vec4(col, tex.a);
}
