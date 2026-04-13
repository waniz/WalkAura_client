shader_type canvas_item;

// Traveling highlight dot along a line. Applied to a ColorRect that overlays
// the synergy arc area. The dot position is driven by TIME.

uniform float speed : hint_range(0.1, 2.0) = 0.25;
uniform float dot_size : hint_range(0.01, 0.15) = 0.05;
uniform float glow_intensity : hint_range(0.5, 3.0) = 1.5;
uniform vec4 line_color : source_color = vec4(1.0, 0.784, 0.259, 1.0);

void fragment() {
    // UV.x = 0..1 along the arc, UV.y = perpendicular distance from center
    float t = fract(TIME * speed);

    // Distance from the traveling dot center
    float dist_along = abs(UV.x - t);
    // Wrap distance for seamless loop
    dist_along = min(dist_along, 1.0 - dist_along);

    float dist_perp = abs(UV.y - 0.5) * 2.0;

    // Combined radial distance from dot
    float d = length(vec2(dist_along, dist_perp * 0.3));

    // Soft glow falloff
    float glow = exp(-d * d / (dot_size * dot_size)) * glow_intensity;

    COLOR = vec4(line_color.rgb, glow * line_color.a);
}
