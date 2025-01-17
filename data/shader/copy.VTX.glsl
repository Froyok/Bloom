#pragma language glsl4

varying vec4 VarScreenPosition;
varying vec2 VarVertexCoord;

void vertexmain()
{
	VarVertexCoord = vec2(
		(love_VertexID << 1) & 2,
		love_VertexID & 2
	);

	VarScreenPosition = vec4(
		VarVertexCoord.xy * vec2(2.0, -2.0) + vec2(-1.0, 1.0),
		0,
		1
	);

	// OpenGL Flip
	// VarVertexCoord.y = 1.0 - VarVertexCoord.y;

	gl_Position = VarScreenPosition;
}