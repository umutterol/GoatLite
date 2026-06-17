shader_type canvas_item;

uniform float pixel_size : hint_range(1.0, 16.0) = 4.0;
uniform float color_steps : hint_range(2.0, 32.0) = 8.0;

void fragment() {
    // Snap UVs to a coarser grid → nearest-neighbor downsample look
    vec2 size = vec2(textureSize(TEXTURE, 0));
    vec2 snapped_uv = floor(UV * size / pixel_size) * pixel_size / size;
    
    vec4 color = texture(TEXTURE, snapped_uv);
    
    // Quantize each channel to a fixed number of steps → limited palette feel
    color.rgb = floor(color.rgb * color_steps) / color_steps;
    
    COLOR = color;
}