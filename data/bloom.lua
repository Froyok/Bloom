local GL = require( "lib.frogl" )
local COMMON = require( "common" )

local BLOOM = {}

BLOOM.InternalBlend = 0.7
BLOOM.Intensity = 0.1
BLOOM.UseAntiFlicker = true

local Textures = {}
local ShaderDownsample = nil
local ShaderUpsample = nil
local ShaderTonemap = nil

local string_view_name = "Texture.%s"
local string_view_mipname = "Texture.%s.MipmapView-"
local string_downsample = "Downsample_%i_%ix%i"
local string_upsample = "Upsample_%i_%ix%i"
local CanvasSettings = {
	type 		= "2d",
	format 		= "",
	readable 	= true,
	msaa 		= 0,
	mipmaps 	= "",
	mipmapcount = 0,
	debugname 	= "untitled_view_canvas"
}

function BLOOM.Init()
	BLOOM.Resize( 1280, 720 )

	Textures.TonyLUT = love.graphics.newVolumeImage(
		"texture/tonemap_tony.exr",
		{ linear = true }
	)
	Textures.TonyLUT:setWrap( "clamp", "clamp", "clamp" )
	Textures.TonyLUT:setFilter( "linear", "linear", 1 )

	ShaderDownsample = love.graphics.newShader(
		"shader/downsample.FRG.glsl",
		"shader/copy.VTX.glsl",
		{
			debugname = "Shader.BloomDownsample"
		}
	)
	ShaderUpsample = love.graphics.newShader(
		"shader/upsample.FRG.glsl",
		"shader/copy.VTX.glsl",
		{
			debugname = "Shader.BloomUpsample"
		}
	)
	ShaderTonemap = love.graphics.newShader(
		"shader/tonemap.FRG.glsl",
		"shader/copy.VTX.glsl",
		{
			debugname = "Shader.TonemapComposite"
		}
	)
end

local function NewCanvasWithMipmaps( Width, Height, Format, Name, MipCount )
	CanvasSettings.format 		= Format
	CanvasSettings.debugname 	= string.format( string_view_name, Name )
	CanvasSettings.mipmaps 		= "manual"
	CanvasSettings.mipmapcount 	= MipCount -- Include the base level

	return love.graphics.newCanvas(
		Width,
		Height,
		CanvasSettings
	)
end

local function CreateMipmapViews( Texture, Name )
	local TextureViews = {}
	local DebugName = string.format( string_view_mipname, Name )

	for i=1, Texture:getMipmapCount() do
		local NewView = love.graphics.newTextureView(
			Texture,
			{
				mipmapstart = i,
				mipmapcount = 1,
				debugname = DebugName .. tostring(i)
			}
		)
		table.insert( TextureViews, NewView )
	end

	return TextureViews
end

function BLOOM.Resize( NewWidth, NewHeight )
	--------------------------------
	-- Compute mip levels for bloom, blur, fog, etc.
	--------------------------------
	--[[
		1: 1920x1080
		2: 960x540
		3: 480x270
		4: 240x135
		5: 120x67
		6: 60x33
		7: 30x16
		8: 15x8
		9: 7x4
		10: 3x2
		11: 1x1

		math.floor(math.log(math.max(w, h), 2)) + 1
	]]--

	-- Compute number of mips needed
	-- Examples:
	-- 720 = 6 levels
	-- 1080 = 7 levels
	local Max = math.min( NewWidth, NewHeight )
	local Log = math.log( Max ) / math.log( 2 )

	-- Use -3 to get 7 levels at 720p
	local Levels = math.floor( Log ) - 3
	Levels = math.max( 1, Levels )

	--------------------------------
	-- Generate textures
	--------------------------------
	local HalfWidth = math.floor( NewWidth * 0.5 )
	local HalfHeight = math.floor( NewHeight * 0.5 )

	Textures.Downsamples = NewCanvasWithMipmaps(
		HalfWidth, HalfHeight, "rgba16f", "Texture.BloomDownsamples", Levels
	)
	Textures.Upsamples = NewCanvasWithMipmaps(
		HalfWidth, HalfHeight, "rgba16f", "Texture.BloomUpsamples", Levels
	)

	Textures.Downsamples:setWrap( "clampzero", "clampzero" )
	Textures.Upsamples:setWrap( "clamp", "clamp" )

	Textures.ViewDownsamples = {}
	Textures.ViewUpsamples = {}

	Textures.ViewDownsamples = CreateMipmapViews(
		Textures.Downsamples,
		"BloomViewDownsamples"
	)
	Textures.ViewUpsamples = CreateMipmapViews(
		Textures.Upsamples,
		"BloomViewUpsamples"
	)

	Textures.Composite = love.graphics.newCanvas(
		NewWidth, NewHeight,
		{
			type = "2d",
			format = "srgba8",
			debugname = "Texture.BloomComposite"
		}
	)
end

function BLOOM.Draw( InputTexture )
	BLOOM.BlurDownsample(
		InputTexture,
		Textures.ViewDownsamples,
		ShaderDownsample
	)

	BLOOM.BlurUpsample(
		Textures.ViewDownsamples,
		Textures.ViewUpsamples,
		ShaderUpsample,
		BLOOM.InternalBlend
	)

	BLOOM.Composite( InputTexture )

	-- Return composited image (scene + bloom)
	return Textures.Composite
end

function BLOOM.BlurDownsample( InputTexture, Buffers, Shader )
	GL.PushEvent( "Bloom downsample" )

	local Width, Height = 0
	local PrevWidth, PrevHeight = 0
	local CurrentCanvas = nil

	love.graphics.setShader( Shader )
	love.graphics.setBlendMode( "none" )

	for i=1, #Buffers do
		CurrentCanvas = Buffers[i]
		Width, Height = CurrentCanvas:getDimensions()
		PrevWidth, PrevHeight = InputTexture:getDimensions()

		GL.PushEvent( string.format( string_downsample, i, Width, Height ) )

		love.graphics.setCanvas( CurrentCanvas )

		-- Need to use the previous buffer size for the pixel size
		-- otherwise with sample too far creating a square pattern bug
		-- see: https://mastodon.gamedev.place/@froyok/110381289593520237
		Shader:send(
			"PixelSize",
			{
				1.0 / PrevWidth,
				1.0 / PrevHeight
			}
		)

		if i == 1 and BLOOM.UseAntiFlicker then
			Shader:send( "UseAntiFlicker", true )
		else
			Shader:send( "UseAntiFlicker", false )
		end

		Shader:send( "TextureBuffer", InputTexture )

		COMMON.DrawFullscreenTriangle()

		InputTexture = CurrentCanvas

		GL.PopEvent()
	end

	-- end downsample
	GL.PopEvent()
end


function BLOOM.BlurUpsample( DownsampleBuffers, UpsampleBuffers, Shader, Radius )
	GL.PushEvent( "Bloom upsample" )

	local Width, Height = 0
	local CurrentCanvas = nil
	local Levels = #UpsampleBuffers
	local PreviousTexture = DownsampleBuffers[#DownsampleBuffers]

	love.graphics.setShader( Shader )
	love.graphics.setBlendMode( "none" )

	for i = Levels - 1, 1, -1 do
		CurrentCanvas = UpsampleBuffers[i]
		Width, Height = CurrentCanvas:getDimensions()

		GL.PushEvent( string.format( string_upsample, i, Width, Height ) )

		love.graphics.setCanvas( CurrentCanvas )

		Shader:send(
			"PixelSize",
			{
				1.0 / Width,
				1.0 / Height
			}
		)
		Shader:send( "Blend", Radius )

		-- The previously blended result, which will get
		-- upsampled by the tent filter
		Shader:send( "PreviousTexture", PreviousTexture )

		-- The downsample that is at the same resolution as
		-- the current canvas (so same upsample level)
		Shader:send( "TextureBuffer", DownsampleBuffers[i] )

		COMMON.DrawFullscreenTriangle()

		PreviousTexture = CurrentCanvas

		GL.PopEvent()
	end

	-- end upsample
	GL.PopEvent()
end

function BLOOM.Composite( InputTexture )
	GL.PushEvent( "Bloom compositing" )

	love.graphics.setShader( ShaderTonemap )
	love.graphics.setCanvas( Textures.Composite )

	ShaderTonemap:send( "TonemapLUT3", Textures.TonyLUT )
	ShaderTonemap:send( "SceneBuffer", InputTexture )
	ShaderTonemap:send( "BloomBuffer", Textures.Upsamples )
	ShaderTonemap:send( "Intensity", BLOOM.Intensity )

	COMMON.DrawFullscreenTriangle()

	GL.PopEvent()
end

return BLOOM