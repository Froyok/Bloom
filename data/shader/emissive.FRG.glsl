uniform vec3 Color;
uniform float Intensity;

float SRGB_to_LinearSRGB( float x )
{
	return x <= 0.04045 ?
		x * 0.0773993808 : // 1.0/12.92
		pow( (x + 0.055) / 1.055, 2.4 );
}

vec3 SRGB_to_LinearSRGB( vec3 color )
{
	return vec3(
		SRGB_to_LinearSRGB( color.r ),
		SRGB_to_LinearSRGB( color.g ),
		SRGB_to_LinearSRGB( color.b )
	);
}

float LinearSRGB_to_SRGB( float x )
{
	return x <= 0.0031308 ?
		12.92 * x :
		1.055 * pow(x, 0.41666) - 0.055;
}

vec3 LinearSRGB_to_SRGB( vec3 color )
{
	return vec3(
		LinearSRGB_to_SRGB( color.r ),
		LinearSRGB_to_SRGB( color.g ),
		LinearSRGB_to_SRGB( color.b )
	);
}

vec4 effect(
	vec4 color,
	Image tex,
	vec2 texture_coords,
	vec2 screen_coords
)
{
	return vec4( SRGB_to_LinearSRGB(Color) * Intensity, 1.0 );
}