local FFI = require( "ffi" )
local IMGUI = require( "lib.cimgui" )
local BLOOM = require( "bloom" )
local SCENE = require( "scene" )

local UI = {}

local Float = FFI.new( "float[1]", false )
local Bool = FFI.new( "bool[1]", false )
local Vec2 = IMGUI.ImVec2_Float( 0.0, 0.0 )

function UI.Init()
	UI.IO = IMGUI.GetIO()
	UI.IO.IniFilename = nil
end

local function Spacer()
	Vec2.x = 0.0
	Vec2.y = 4.0

	IMGUI.Dummy( Vec2 )
end

function UI.Update( Deltatime )
	IMGUI.Begin( "Settings", nil, nil )
	IMGUI.PushItemWidth( -1 )

	IMGUI.Text( "Scene" )

	IMGUI.Indent( 16 )

	IMGUI.Text( "Color (RGB)" )
	Float[0] = SCENE.Color[1]
	if IMGUI.DragFloat( "##ColorR", Float, 0.01, 0.0, 1.0 ) then
		SCENE.Color[1] = Float[0]
	end
	Float[0] = SCENE.Color[2]
	if IMGUI.DragFloat( "##ColorG", Float, 0.01, 0.0, 1.0 ) then
		SCENE.Color[2] = Float[0]
	end
	Float[0] = SCENE.Color[3]
	if IMGUI.DragFloat( "##ColorB", Float, 0.01, 0.0, 1.0 ) then
		SCENE.Color[3] = Float[0]
	end

	Spacer()
	IMGUI.Text( "Color intensity" )
	Float[0] = SCENE.Intensity
	if IMGUI.DragFloat( "##ColorIntensity", Float, 0.1, 0.0, 1000.0 ) then
		SCENE.Intensity = Float[0]
	end

	Spacer()
	IMGUI.Text( "Width" )
	Float[0] = SCENE.RectangleWidth
	if IMGUI.DragFloat( "##Width", Float, 1.0, 0.0, 1000.0 ) then
		SCENE.RectangleWidth = Float[0]
	end

	Spacer()
	IMGUI.Text( "Height" )
	Float[0] = SCENE.RectangleHeight
	if IMGUI.DragFloat( "##Height", Float, 1.0, 0.0, 1000.0 ) then
		SCENE.RectangleHeight = Float[0]
	end

	Spacer()
	Bool[0] = SCENE.AnimateOnX
	IMGUI.Checkbox( "Animate on X", Bool )
	SCENE.AnimateOnX = Bool[0]

	Spacer()
	Bool[0] = SCENE.AnimateOnY
	IMGUI.Checkbox( "Animate on Y", Bool )
	SCENE.AnimateOnY = Bool[0]


	IMGUI.Unindent( 16 )

	IMGUI.Separator()

	IMGUI.Text( "Bloom" )

	IMGUI.Indent( 16 )
	IMGUI.Text( "Internal blend (lerp during upsample)" )
	Float[0] = BLOOM.InternalBlend
	if IMGUI.SliderFloat( "##InternalBlend", Float, 0.5, 1.0 ) then
		BLOOM.InternalBlend = Float[0]
	end

	Spacer()
	IMGUI.Text( "Intensity (lerp scene + bloom)" )
	Float[0] = BLOOM.Intensity
	if IMGUI.SliderFloat( "##Intensity", Float, 0.0, 1.0 ) then
		BLOOM.Intensity = Float[0]
	end

	Spacer()
	Bool[0] = BLOOM.UseAntiFlicker
	IMGUI.Checkbox( "Use anti-flicker (borked)", Bool )
	BLOOM.UseAntiFlicker = Bool[0]

	IMGUI.Unindent( 16 )

	IMGUI.PopItemWidth()
	IMGUI.End()
end

function love.mousemoved( x, y )
	IMGUI.love.MouseMoved( x, y )
end

function love.mousepressed( x, y, Button )
	IMGUI.love.MousePressed( Button )
end

function love.mousereleased( x, y, Button )
	IMGUI.love.MouseReleased( Button )
end

function love.wheelmoved( x, y )
	IMGUI.love.WheelMoved( x, y )
end

function love.keypressed( Key, ScanCode )
	IMGUI.love.KeyPressed( Key )
end

function love.keyreleased( Key, ScanCode )
	IMGUI.love.KeyReleased( Key )
end

function love.textinput( Text )
	IMGUI.love.TextInput( Text )
end

return UI