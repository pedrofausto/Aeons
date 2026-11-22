// Dissolução/desfoque sutil para encontros efêmeros (estilo "ephemeral_metaphysical").
// Compatível com gl_compatibility (OpenGL 3.3 / WebGL 2.0): lê a tela via hint_screen_texture.
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;   // 0 = presente, 1 = desfeito
uniform float blur_lod : hint_range(0.0, 4.0) = 1.5;
uniform float pixel_size : hint_range(1.0, 16.0) = 4.0; // grão da dissolução em pixels lógicos
uniform vec4 void_color : source_color = vec4(0.02, 0.02, 0.05, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 cell = floor(FRAGCOORD.xy / pixel_size);
	float noise = hash(cell);
	vec3 scene = textureLod(screen_texture, SCREEN_UV, blur_lod * dissolve).rgb;
	float gray = dot(scene, vec3(0.299, 0.587, 0.114));
	vec3 faded = mix(scene, vec3(gray), dissolve * 0.8);
	float gone = step(noise, dissolve);
	COLOR = vec4(mix(faded, void_color.rgb, gone), 1.0);
}
