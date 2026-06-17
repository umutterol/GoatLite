shader_type canvas_item;

uniform float glow_strength : hint_range(0.0, 3.0) = 1.0;
uniform vec4 glow_color : source_color = vec4(1.0, 0.843, 0.0, 1.0); // Golden
uniform float glow_size : hint_range(0.0, 20.0) = 10.0;

void fragment() {
    vec4 original = texture(TEXTURE, UV);

    // Create glow by sampling around the texture
    vec2 ps = TEXTURE_PIXEL_SIZE;
    float glow = 0.0;

    for(float x = -glow_size; x <= glow_size; x++) {
        for(float y = -glow_size; y <= glow_size; y++) {
            vec2 offset = vec2(x, y) * ps;
            float dist = length(offset) / (glow_size * ps.x);
            if(dist <= 1.0) {
                float weight = 1.0 - dist;
                glow += texture(TEXTURE, UV + offset).a * weight;
            }
        }
    }

    glow = min(glow * glow_strength, 1.0);

    // Mix glow with original
    vec4 glow_col = glow_color * glow;
    COLOR = mix(glow_col, original, original.a);
    COLOR.a = max(original.a, glow * glow_color.a);
}