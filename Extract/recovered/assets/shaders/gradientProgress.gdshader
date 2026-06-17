shader_type canvas_item;

// For static gradient
uniform vec4 color_left : source_color = vec4(0.6, 0.1, 0.1, 1.0);
uniform vec4 color_right : source_color = vec4(0.9, 0.2, 0.2, 1.0);

// For value-based tint
uniform float brightness_boost = 1.2;

void fragment() {
    // Horizontal gradient
    vec4 gradient = mix(color_left, color_right, UV.x);

    // Add some shine in the middle
    float shine = smoothstep(0.3, 0.5, UV.x) * smoothstep(0.7, 0.5, UV.x);
    gradient.rgb += vec3(shine * 0.3);

    // Darken top and bottom edges for depth
    float edge_shadow = smoothstep(0.0, 0.1, UV.y) * smoothstep(1.0, 0.9, UV.y);
    gradient.rgb *= edge_shadow * 0.2 + 0.8;

    COLOR = gradient;
}