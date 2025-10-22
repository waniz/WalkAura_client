shader_type canvas_item;

uniform vec2 rect_size = vec2(128.0, 128.0);
uniform vec4 border_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // ring color
uniform float border_px = 6.0;    // ring thickness in pixels (inner ring)
uniform float feather_px = 2.0;   // anti-alias softness at the outer edge

void fragment() {
    // Normalize rect so the circle stays round even if the control isn't perfectly square.
    float min_dim = min(rect_size.x, rect_size.y);

    // UV is 0..1 across the control. Make it aspect-correct around the center.
    vec2 p = (UV - vec2(0.5)) * (rect_size / min_dim);  // center at 0, aspect-corrected
    float d = length(p);                               // distance from center, 0 at center

    // Circle radius is 0.5 in this normalized space.
    float R  = 0.5;
    float t  = border_px  / min_dim;   // border thickness in normalized units
    float f  = feather_px / min_dim;   // feather in normalized units

    // Sample portrait
    vec4 tex = texture(TEXTURE, UV);

    // Masks (smooth for clean edges):
    // outside mask: 1 at/after edge, 0 inside
    float outside = smoothstep(R - f, R, d);

    // ring (border) mask: 1 in the ring band [R - t, R], 0 elsewhere
    float ring_outer = smoothstep(R - f, R, d);
    float ring_inner = smoothstep(R - t - f, R - t, d);
    float ring = clamp(ring_outer - ring_inner, 0.0, 1.0);

    // Compose: inside circle = portrait; border ring overlays; outside = transparent
    vec4 col = mix(tex, border_color, ring);

    // Clip outside with feather
    col.a *= (1.0 - outside);

    COLOR = col;
}