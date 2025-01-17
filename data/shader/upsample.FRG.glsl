#pragma language glsl4

varying vec4 VarScreenPosition;
varying vec2 VarVertexCoord;

uniform vec2 PixelSize;
uniform sampler2D TextureBuffer;
uniform sampler2D PreviousTexture;
uniform float Blend;

const vec2 Coords[9] = vec2[9](
	vec2( -1.0,  1.0 ), vec2(  0.0,  1.0 ), vec2(  1.0,  1.0 ),
	vec2( -1.0,  0.0 ), vec2(  0.0,  0.0 ), vec2(  1.0,  0.0 ),
	vec2( -1.0, -1.0 ), vec2(  0.0, -1.0 ), vec2(  1.0, -1.0 )
);

const float Weights[9] = float[9](
	0.0625, 0.125, 0.0625,
	0.125,  0.25,  0.125,
	0.0625, 0.125, 0.0625
);

// Works for both rgba16f (+65504) and rg11b10f (+65024)
vec3 SafeHDR( vec3 Color )
{
	return vec3(
		min( Color.r, 65000 ),
		min( Color.g, 65000 ),
		min( Color.b, 65000 )
	);
}

out vec4 FragColor;
void pixelmain()
{
	vec2 UV = VarVertexCoord.xy;
	vec3 CurrentColor = Texel( TextureBuffer, UV ).rgb;
	vec3 PreviousColor = vec3( 0.0 );

	for( int i = 0; i < 9; i++ )
	{
		vec2 CurrentUV = UV + Coords[i] * PixelSize;
		PreviousColor += Weights[i] * Texel( PreviousTexture, CurrentUV ).rgb;
	}

	vec3 OutColor = mix( CurrentColor, PreviousColor, Blend );

	OutColor = SafeHDR( OutColor );

	FragColor = vec4( OutColor, 1.0 );
}