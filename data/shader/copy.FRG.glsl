#pragma language glsl4

varying vec4 VarScreenPosition;
varying vec2 VarVertexCoord;

uniform sampler2D TextureBuffer;
uniform bool FlipU;
uniform bool FlipV;

#define MIPOFFSET -10

out vec4 FragColor;
void pixelmain()
{
	vec2 UV = VarVertexCoord.xy;

	if( FlipU )
	{
		UV.x = 1.0 - UV.x;
	}

	if( FlipV )
	{
		UV.y = 1.0 - UV.y;
	}

	vec4 Color = Texel( TextureBuffer, UV, MIPOFFSET ).rgba;
	FragColor = Color;
}