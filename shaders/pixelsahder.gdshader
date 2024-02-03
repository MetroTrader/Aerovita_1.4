shader_type spatial;

void vertex() {
	// Called for every vertex the material is visible on.
}
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear;

// resolution must be divisible by pixel_size
const int pixel_size = 1;





void fragment() {
	// a variant of nearest neighbour fragment shader
	float x = float(int(FRAGCOORD.x) % pixel_size);
	float y = float(int(FRAGCOORD.y) % pixel_size);

	x = FRAGCOORD.x + floor(float(pixel_size) / 2.0) - x;
	y = FRAGCOORD.y + floor(float(pixel_size) / 2.0) - y;
	
	ALBEDO = texture(SCREEN_TEXTURE, vec2(x, y) / VIEWPORT_SIZE).xyz;