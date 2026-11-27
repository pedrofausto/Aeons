shader_type canvas_item;

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform float base_alpha : hint_range(0.0, 1.0) = 0.08;
uniform float flash_alpha : hint_range(0.0, 1.0) = 0.90;
uniform vec4 rim_color : source_color = vec4(0.76, 0.88, 1.0, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float luma = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	vec2 centered = UV - vec2(0.5, 0.48);
	float radial = clamp(1.0 - smoothstep(0.32, 0.78, length(centered * vec2(1.0, 1.12))), 0.0, 1.0);
	float detail = smoothstep(0.03, 0.65, luma);
	vec3 shadow_col = tex.rgb * vec3(0.28, 0.34, 0.50);
	vec3 lit_col = mix(tex.rgb, rim_color.rgb, 0.20 + detail * 0.22);
	vec3 col = mix(shadow_col, lit_col, flash_amount);
	float alpha = tex.a * radial * mix(base_alpha, flash_alpha, flash_amount) * (0.35 + 0.65 * detail);
	COLOR = vec4(col, alpha);
}
