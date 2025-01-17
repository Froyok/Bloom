local FFI = require( "ffi" )
local STRICT = require( "lib.luastrict.strict" )

local function InitPackage()
	local TempPath = love.filesystem.getSource() .. "/../bin/lib/"
	TempPath = love.filesystem.canonicalizeRealPath( TempPath )

	if FFI.os == "Windows" then
		local ConvertedPath = ""
		local Character = false

		for i=1, #TempPath do
			Character = string.sub( TempPath, i, i )
			if Character == "\\" then Character = "/" end
			ConvertedPath = ConvertedPath .. Character
		end

		TempPath = ConvertedPath .. "/"
	end

	local PackageSecondPath = {
		["Windows"] = string.format( "./?.dll;%swin64/?.dll", TempPath ),
		["Linux"]	= string.format( "./?.so;%s/linux/?.so", TempPath )
	}

	-- By default package.cpath on Linux looks like this:
	-- ./?.so;/usr/local/lib/lua/5.1/?.so;/usr/lib/lua/5.1/?.so;/usr/local/lib/lua/5.1/loadall.so
	package.cpath = PackageSecondPath[FFI.os]
end

InitPackage()
local IMGUI = require( "lib.cimgui" )
local GL = require( "lib.frogl" )
local SCENE = require( "scene" )
local BLOOM = require( "bloom" )
local COMMON = require( "common" )
local UI = require( "ui" )

function love.load( Args )
	IMGUI.love.Init()
	GL.Init()
	SCENE.Init()
	BLOOM.Init()
	COMMON.Init()
	UI.Init()
end

function love.update( DeltaTime )
	SCENE.Update( DeltaTime )
	IMGUI.love.Update( DeltaTime )
	IMGUI.NewFrame()
	UI.Update( DeltaTime )
end

function love.resize( NewWidth, NewHeight )
	SCENE.Resize( NewWidth, NewHeight )
	BLOOM.Resize( NewWidth, NewHeight )
end

function love.draw()
	local SceneTexture = SCENE.Draw()
	local ResultTexture = BLOOM.Draw( SceneTexture )

	-- To screen
	GL.PushEvent( "To screen" )
	COMMON.CopyTexture( ResultTexture, nil )
	GL.PopEvent()

	-- Imgui drawing
	GL.PushEvent( "Imgui" )
	love.graphics.setCanvas()
	love.graphics.setShader()
	love.graphics.setBlendMode( "alpha", "alphamultiply" )
	love.graphics.setMeshCullMode( "none" )
	IMGUI.Render()
	IMGUI.love.RenderDrawLists()
	GL.PopEvent()
end

----------------------------------------
function love.quit()
	IMGUI.love.Shutdown()
end