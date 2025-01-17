local function SetupEnvironment()
	local FFI = require("ffi")
	FFI.cdef[[
		int setenv(const char*, const char*, int); // Linux
		int _putenv( const char* envstring ); // Windows
	]]

	if FFI.os == "Linux" then
		FFI.C.setenv( "SDL_VIDEO_X11_NET_WM_BYPASS_COMPOSITOR", "0", 1 )
		FFI.C.setenv( "SDL_MOUSE_FOCUS_CLICKTHROUGH", "1", 1 )
	elseif FFI.os == "Windows" then
		FFI.C._putenv( "SDL_MOUSE_FOCUS_CLICKTHROUGH=1" )
	end
end

function love.conf( Settings )
	SetupEnvironment()

	Settings.window.displayindex = 1
	-- Settings.window.display = 3
	Settings.highdpi = true
	Settings.window.usedpiscale  = false

	Settings.console = true
	Settings.gammacorrect = true

	Settings.window.title = "Froyok's Bloom"

	Settings.window.width = 1280
	Settings.window.height = 720
	Settings.window.minwidth = 256
	Settings.window.minheight = 256
	Settings.window.resizable = true

	Settings.window.borderless = false
	Settings.window.fullscreen = false
	Settings.window.fullscreentype = "desktop"

	Settings.window.vsync = 1
	Settings.window.msaa = 0
	Settings.window.depth = false
	Settings.window.stencil = nil

	Settings.modules.touch = false
	Settings.modules.video = false
	Settings.modules.physics = false
end
