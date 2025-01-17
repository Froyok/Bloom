#pragma language glsl4

varying vec4 VarScreenPosition;
varying vec2 VarVertexCoord;

uniform sampler2D SceneBuffer;
uniform sampler2D BloomBuffer;
uniform float Intensity;

uniform sampler3D TonemapLUT3;

vec3 Tonemap_Tony( vec3 ColorInput )
{
	// Apply a non-linear transform that the LUT is encoded with.
	vec3 encoded = ColorInput / (ColorInput + 1.0);
	encoded = clamp( encoded, 0.0, 1.0 );

	// Align the encoded range to texel centers.
	const float LUT_DIMS = 48.0;
	vec3 uv = encoded * ((LUT_DIMS - 1.0) / LUT_DIMS) + 0.5 / LUT_DIMS;

	// Note: for OpenGL, do `uv.y = 1.0 - uv.y`
	uv.y = 1.0 - uv.y;

	vec3 OutColor = texture( TonemapLUT3, uv ).rgb;

	return OutColor;
}

float RandomHash12( vec2 p )
{
	vec3 p3  = fract( vec3(p.xyx) * 0.1031 );
	p3 += dot( p3, p3.yzx + 33.33 );
	return fract( (p3.x + p3.y) * p3.z );
}

out vec4 FragColor;
void pixelmain()
{
	vec2 UV = VarVertexCoord.xy;

	vec3 Scene = Texel( SceneBuffer, UV, -999 ).rgb;
	vec3 Bloom = Texel( BloomBuffer, UV, -999 ).rgb;

	// Composite bloom (using mix to stay energy preserving)
	vec3 OutColor = mix( Scene, Bloom, Intensity );

	// Tonemap
	OutColor = Tonemap_Tony( OutColor );

	// Dithering to avoid 8bit banding
	float Grain = RandomHash12( UV * 7065.048 );
	const float GrainQuantization = 1.0 / 256.0;

	float GrainAdd = (Grain * GrainQuantization) + (-0.5 * GrainQuantization);
	OutColor += GrainAdd;

	FragColor = vec4( OutColor, 1.0 );
}