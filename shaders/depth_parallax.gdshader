shader_type canvas_item;

// Depth map baked by tools/depth_gen. Red channel = depth. Near = bright.
// filter_linear for smooth sampling; repeat_disable to avoid wrap on edge taps.
uniform sampler2D depth_tex : hint_default_white, filter_linear, repeat_disable;

// Normalized offset driven by touch drag + idle sway. x,y ~ [-1, 1] after
// clamping in the script.
uniform vec2 parallax_offset = vec2(0.0, 0.0);

// Max displacement in UV units. 0.04 = up to 4% of image width. Keep <= 0.05
// to hide the silhouette-stretching artifact inherent to backward-warp parallax.
uniform float displacement_strength : hint_range(0.0, 0.15) = 0.04;

// Parallax factor for far (dark) pixels relative to near (bright). 0.15 means
// far pixels move at 15% of near-pixel speed.
uniform float far_ratio : hint_range(0.0, 1.0) = 0.15;

void fragment() {
    // Two-pass sampling: first estimate depth at the original UV, compute a
    // candidate displaced UV, then re-sample depth AT the candidate position
    // and recompute. This reduces the smearing artifact around foreground
    // silhouettes.

    float depth_0 = texture(depth_tex, UV).r;
    float factor_0 = mix(far_ratio, 1.0, depth_0);
    vec2 disp_0 = -parallax_offset * displacement_strength * factor_0;

    vec2 uv_1 = clamp(UV + disp_0, vec2(0.0), vec2(1.0));
    float depth_1 = texture(depth_tex, uv_1).r;
    float factor_1 = mix(far_ratio, 1.0, depth_1);
    vec2 disp_1 = -parallax_offset * displacement_strength * factor_1;

    vec2 uv_final = clamp(UV + disp_1, vec2(0.0), vec2(1.0));
    COLOR = texture(TEXTURE, uv_final);
}
