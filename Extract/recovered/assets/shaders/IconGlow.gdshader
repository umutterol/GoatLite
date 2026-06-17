shader_type canvas_item;

uniform float glow_strength : hint_range(0.0, 3.0) = 1.0;
uniform vec4 glow_color : source_color = vec4(1.0, 0.843, 0.0, 1.0);
uniform float glow_width : hint_range(1.0, 10.0) = 3.0;

void fragment() {
    vec4 original = texture(TEXTURE, UV);

    // Only process if we're outside the original texture
    if (original.a < 0.01) {
        float glow = 0.0;

        // Sample in a circle around the current pixel
        for(float angle = 0.0; angle < 6.28; angle += 0.628) {
            vec2 offset = vec2(cos(angle), sin(angle)) * glow_width * TEXTURE_PIXEL_SIZE;
            glow = max(glow, texture(TEXTURE, UV + offset).a);
        }

        // Apply glow
        COLOR = glow_color;
        COLOR.a = glow * glow_strength * glow_color.a;
    } else {
        // Keep original pixels
        COLOR = original;
    }
}