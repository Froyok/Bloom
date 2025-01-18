local GL = require( "lib.frogl" )

local SCENE = {}

SCENE.AnimateOnX = true
SCENE.AnimateOnY = true
SCENE.AnimateX = 0.0
SCENE.AnimateY = 0.0
SCENE.RectangleWidth = 16
SCENE.RectangleHeight = 16
SCENE.Color = { 1, 1, 1 }
SCENE.Intensity = 200.0

local ShaderEmissive = nil

function SCENE.Init()
	SCENE.Resize( 1280, 720 )

	ShaderEmissive = love.graphics.newShader(
		"shader/emissive.FRG.glsl",
		"shader/emissive.VTX.glsl",
		{
			debugname = "Shader.Emissive"
		}
	)
end

function SCENE.Update( DeltaTime )
	if SCENE.AnimateOnX then
		SCENE.AnimateX = SCENE.AnimateX + DeltaTime * 0.1
	else
		SCENE.AnimateX = 0.0
	end

	if SCENE.AnimateOnY then
		SCENE.AnimateY = SCENE.AnimateY + DeltaTime * 0.1
	else
		SCENE.AnimateY = 0.0
	end
end

function SCENE.Resize( NewWidth, NewHeight )
	SCENE.Texture = love.graphics.newCanvas(
		NewWidth, NewHeight,
		{
			type = "2d",
			format = "rgba16f",
			debugname = "Texture.Scene"
		}
	)
end

function SCENE.Draw()
	GL.PushEvent( "Scene" )

	love.graphics.setColor( 1, 1, 1, 1 )
	love.graphics.setMeshCullMode( "back" )
	love.graphics.setBlendMode( "none" )

	love.graphics.setCanvas( SCENE.Texture )
	love.graphics.clear( 0, 0, 0, 1 )
	love.graphics.setShader( ShaderEmissive )

	ShaderEmissive:send( "Color", SCENE.Color )
	ShaderEmissive:send( "Intensity", SCENE.Intensity )

	local Width, Height = SCENE.Texture:getDimensions()
	local OffsetX = 0.0
	local OffsetY = 0.0

	if SCENE.AnimateOnX then
		OffsetX = math.sin( SCENE.AnimateX * math.pi ) * 128
	end

	if SCENE.AnimateOnY then
		OffsetY = math.cos( SCENE.AnimateY * math.pi ) * 128
	end

	love.graphics.rectangle(
		"fill",
		(Width - SCENE.RectangleWidth) * 0.5 + OffsetX,
		(Height - SCENE.RectangleHeight) * 0.5 + OffsetY,
		SCENE.RectangleWidth,
		SCENE.RectangleHeight
	)

	-- Force love to send the draw command
	love.graphics.setCanvas()

	GL.PopEvent()

	return SCENE.Texture
end

return SCENE