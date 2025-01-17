#pragma language glsl4

varying vec4 VarScreenPosition;
varying vec2 VarVertexCoord;

uniform sampler2D TextureBuffer;
uniform vec2 PixelSize;

uniform bool UseAntiFlicker;
uniform sampler2D PreviousBuffer;
uniform mat4 PreviousViewProjectionMatrix;
uniform float TemporalBlend;

vec3 MaxVec3( vec3 A, vec3 B )
{
	return vec3(
		max( A.r, B.r ),
		max( A.g, B.g ),
		max( A.b, B.b )
	);
}

vec3 MinVec3( vec3 A, vec3 B )
{
	return vec3(
		min( A.r, B.r ),
		min( A.g, B.g ),
		min( A.b, B.b )
	);
}

// Works for both rgba16f (+65504) and rg11b10f (+65024)
vec3 SafeHDR( vec3 Color )
{
	return vec3(
		min( Color.r, 65000 ),
		min( Color.g, 65000 ),
		min( Color.b, 65000 )
	);
}

//---------------------------------------
// Bloom coords and weights
//---------------------------------------
const vec2 BloomCoords[13] = vec2[13](
	vec2( -1.0,  1.0 ), vec2( 1.0,  1.0 ),
	vec2( -1.0, -1.0 ), vec2( 1.0, -1.0 ),

	vec2( -2.0, 2.0 ), vec2( 0.0, 2.0 ), vec2( 2.0, 2.0 ),
	vec2( -2.0, 0.0 ), vec2( 0.0, 0.0 ), vec2( 2.0, 0.0 ),
	vec2( -2.0,-2.0 ), vec2( 0.0,-2.0 ), vec2( 2.0,-2.0 )
);

const float OneOverFour = (1.0 / 4.0) * 0.5;
const float OneOverNine = (1.0 / 9.0) * 0.5;

const float BloomWeights[13] = float[13](
	// 4 samples
	// (1 / 4) * 0.5f = 0.125f
	OneOverFour, OneOverFour,
	OneOverFour, OneOverFour,

	// 9 samples
	// (1 / 9) * 0.5f
	OneOverNine, OneOverNine, OneOverNine,
	OneOverNine, OneOverNine, OneOverNine,
	OneOverNine, OneOverNine, OneOverNine
);

const vec2 AverageDirections[4] = vec2[4](
	vec2( -1.0,  1.0 ),
	vec2(  1.0,  1.0 ),
	vec2( -1.0, -1.0 ),
	vec2(  1.0, -1.0 )
);

float MaxBrightness( vec3 Color )
{
	return max( max( Color.r, Color.g ), Color.b );
}


//----------------------------------------
// Partial Karis average
// (Weight pixels per block of 2x2)
//----------------------------------------
// Karis's luma weighted average (using brightness instead of luma)
// Goal is to eliminate fireflies during mip0 to mp1 downsample
// Use average on 13 taps, not just 4, COD use partial average
// and not full average of all the 13 taps at once.
//----------------------------------------
vec3 AverageBlock( vec2 InUV, vec2 InPixelSize, sampler2D InTexture )
{
	float WeightSum = 0.0;
	vec3 FinalColor = vec3(0.0);

	for( int i = 0; i < 4; i++ )
	{
		vec2 CurrentUV = InUV + (AverageDirections[i] * InPixelSize);

		vec3 Color = Texel( InTexture, CurrentUV ).rgb;
		float AverageWeight = 1.0 / ( MaxBrightness(Color) + 1.0 );

		WeightSum += AverageWeight;
		FinalColor += Color * AverageWeight;
	}

	return FinalColor * (1.0 / WeightSum);
}

vec3 AveragePixelsPartial( vec2 InUV, vec2 InPixelSize, sampler2D InTexture )
{
	vec3 Center = AverageBlock(
		InUV,
		InPixelSize,
		InTexture
	);

	vec3 TopLeft = AverageBlock(
		InUV + vec2( -InPixelSize.x, InPixelSize.y ),
		InPixelSize,
		InTexture
	);

	vec3 TopRight = AverageBlock(
		InUV + InPixelSize,
		InPixelSize,
		InTexture
	);

	vec3 BottomLeft = AverageBlock(
		InUV - InPixelSize,
		InPixelSize,
		InTexture
	);

	vec3 BottomRight = AverageBlock(
		InUV + vec2( InPixelSize.x, -InPixelSize.y ),
		InPixelSize,
		InTexture
	);

	vec3 Color = Center * 0.25
		+ TopLeft * 0.1875
		+ TopRight * 0.1875
		+ BottomLeft * 0.1875
		+ BottomRight * 0.1875;

	return Color;
}

//----------------------------------------
// Neighbor color clamping
//----------------------------------------
const vec2 NeighborCoords[9] = vec2[9](
	vec2( -1.0,  1.0 ), vec2( 0.0,  1.0 ), vec2(  1.0, -1.0 ),
	vec2( -1.0,  0.0 ), vec2( 0.0,  0.0 ), vec2(  1.0,  0.0 ),
	vec2( -1.0, -1.0 ), vec2( 0.0, -1.0 ), vec2(  1.0, -1.0 )
);

vec3 ClampColorToNeighbor(
	vec3 InPreviousColor,
	vec2 InUV,
	vec2 InPixelSize,
	sampler2D InCurrentTextureBuffer,
	float Mask
)
{
	vec2 Scale = InPixelSize;
	vec3 MinColor = vec3(  9999.0 );
	vec3 MaxColor = vec3( -9999.0 );

	for( int i = 0; i < 9; i++ )
	{
		vec2 NextUV = InUV + (NeighborCoords[i] * Scale);
		vec3 Color = Texel( InCurrentTextureBuffer, NextUV ).rgb * Mask;
		MinColor = MinVec3( MinColor, Color );
		MaxColor = MaxVec3( MaxColor, Color );
	}

	vec3 NewPreviousColor = clamp( InPreviousColor, MinColor, MaxColor );

	return NewPreviousColor;
}

float ClampGrayscaleToNeighbor(
	float InPreviousGrayscale,
	vec2 InUV,
	vec2 InPixelSize,
	sampler2D InCurrentTextureBuffer
)
{
	vec2 Scale = InPixelSize;
	float MinColor =  9999.0;
	float MaxColor = -9999.0;

	for( int i = 0; i < 9; i++ )
	{
		vec2 NextUV = InUV + (NeighborCoords[i] * Scale);
		float Grayscale = Texel( InCurrentTextureBuffer, NextUV ).r;
		MinColor = min( MinColor, Grayscale );
		MaxColor = max( MaxColor, Grayscale );
	}

	float New = clamp( InPreviousGrayscale, MinColor, MaxColor );

	return New;
}

out vec4 FragColor;
void pixelmain()
{
	vec2 UV = VarVertexCoord.xy;
	vec3 OutColor = vec3( 0.0 );

	// Karis's luma weighted average (using brightness instead of luma)
	// Goal is to eliminate fireflies during mip0 to mp1 downsample
	//--------------
	// Use average on 13 taps, not just 4, COD use partial average
	// and not full average of all the 13 taps together however.
	if( UseAntiFlicker )
	{
		//--------------------------------
		// Average by luminance to compensate fireflies
		//--------------------------------
		OutColor = AveragePixelsPartial( UV, PixelSize, TextureBuffer );
	}
	else
	{
		for( int i = 0; i < 13; i++ )
		{
			vec2 CurrentUV = UV + BloomCoords[i] * PixelSize;
			OutColor += BloomWeights[i] * Texel( TextureBuffer, CurrentUV ).rgb;
		}
	}

	OutColor = SafeHDR( OutColor );

	FragColor = vec4( OutColor, 1.0 );
}