shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;

uniform float progress      : hint_range(0.0, 1.0) = 1.0;
uniform vec4  couleur_plein : source_color = vec4(1.0, 0.65, 0.1, 1.0);
uniform vec4  couleur_vide  : source_color = vec4(0.55, 0.55, 0.55, 0.18);
uniform float epaisseur     : hint_range(0.01, 0.4) = 0.06;

void fragment() {
	vec2  uv        = UV;
	float e         = epaisseur;
	bool  is_border = uv.x < e || uv.x > (1.0 - e)
	               || uv.y < e || uv.y > (1.0 - e);

	if (is_border) {
		// Décompte horaire depuis haut-gauche
		float border_t;
		if (uv.y > (1.0 - e))       border_t = uv.x * 0.25;
		else if (uv.x > (1.0 - e))  border_t = 0.25 + (1.0 - uv.y) * 0.25;
		else if (uv.y < e)           border_t = 0.5  + (1.0 - uv.x) * 0.25;
		else                         border_t = 0.75 + uv.y * 0.25;

		// Transition douce sur ±1.5% autour du front
		float blend = smoothstep(progress - 0.015, progress + 0.015, border_t);
		vec4  c     = mix(couleur_plein, couleur_vide, blend);
		ALBEDO = c.rgb;
		ALPHA  = c.a;
	} else {
		ALBEDO = vec3(0.0);
		ALPHA  = 0.0;
	}
}
