local GL = require( "lib.frogl" )

local COMMON = {}

local ShaderCopy = nil

function COMMON.Init()
	ShaderCopy = love.graphics.newShader(
		"shader/copy.FRG.glsl",
		"shader/copy.VTX.glsl",
		{
			debugname="Shader.CopyTexture"
		}
	)
end

function COMMON.DrawFullscreenTriangle()
	love.graphics.drawFromShader( "triangles", 3, 1 )
end

function COMMON.CopyTexture( Source, Target, FlipU, FlipV )
	GL.PushEvent( "Copy texture" )

	ShaderCopy:send( "FlipU", (FlipU or false) )
	ShaderCopy:send( "FlipV", (FlipV or false) )
	ShaderCopy:send( "TextureBuffer", Source )

	love.graphics.setBlendMode( "none" )
	love.graphics.setShader( ShaderCopy )
	love.graphics.setCanvas( Target )

	COMMON.DrawFullscreenTriangle()

	GL.PopEvent()
end

return COMMON