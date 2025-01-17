-- https://registry.khronos.org/OpenGL/extensions/KHR/KHR_debug.txt
-- https://williamaadams.wordpress.com/2012/04/16/headsup-opengl-extension-wrangling/
-- https://www.freelists.org/post/luajit/Proper-OpenGL-dynamic-library

-- https://moddb.fandom.com/wiki/SDL:Tutorial:OpenGL_Extensions_with_SDL
-- https://github.com/fogfx/love2d-pointbatch/blob/master/ufo/ffi/OpenGL.lua
-- https://github.com/rxi/json.lua/tree/dbf4b2dd2eb7c23be2773c89eb059dadd6436f94
-- https://github.com/rozenmad/Menori/tree/dev/menori/modules/core3d
-- https://github.com/excessive/iqm-exm/blob/master/iqm-ffi.lua
-- https://love2d.org/forums/viewtopic.php?t=92481
-- https://learnopengl.com/In-Practice/Debugging

-- http://luajit.org/ext_ffi_api.html#ffi_string
-- https://stackoverflow.com/questions/25597155/luajit-ffi-return-string-from-c-function-to-lua
-- https://www.khronos.org/registry/OpenGL/api/GL/glcorearb.h
-- https://luajit.org/ext_ffi_tutorial.html
-- https://github.com/excessive/love3d/

-- To find the function pointer/define of a extensions we can use GLAD
-- if the needed information isn't listed in OGL official headers
-- https://gen.glad.sh/
-- https://github.com/KhronosGroup/OpenGL-Registry/blob/main/xml/genheaders.py

-- OGL definitions:
-- https://registry.khronos.org/OpenGL/index_gl.php
-- https://registry.khronos.org/OpenGL/api/GL/glcorearb.h
-- https://registry.khronos.org/OpenGL/api/GL/glext.h

local FFI = require( 'ffi' )
local OPENGL = {}
local IsInit = false

local Int = FFI.new( "int[1]", false )
local UInt64_1 = FFI.new( "uint64_t[1]", false )
local UInt64_2 = FFI.new( "uint64_t[1]", false )

OPENGL.GL = {
	-- Depth test
	GL_DEPTH_CLAMP = 0x864F,

	-- Timers
	GL_TIMESTAMP = 0x8E28,
	GL_QUERY_RESULT = 0x8866,
	GL_QUERY_RESULT_AVAILABLE = 0x8867,

	-- Textures
	GL_MAX_ARRAY_TEXTURE_LAYERS = 0x88FF,

	-- Clip plane
	GL_CLIP_DISTANCE0 = 0x3000,
	GL_CLIP_DISTANCE1 = 0x3001,
	GL_CLIP_DISTANCE2 = 0x3002,
	GL_CLIP_DISTANCE3 = 0x3003,
	GL_CLIP_DISTANCE4 = 0x3004,
	GL_CLIP_DISTANCE5 = 0x3005,
	GL_CLIP_DISTANCE6 = 0x3006,
	GL_CLIP_DISTANCE7 = 0x3007,
	GL_MAX_CLIP_DISTANCES = 0x0D32,

	GL_DEPTH_BOUNDS_TEST_EXT = 0x8890,
	GL_DEPTH_BOUNDS_EXT = 0x8891,

	GL_MAX_COMPUTE_WORK_GROUP_INVOCATIONS = 0x90EB,
	GL_MAX_COMPUTE_WORK_GROUP_COUNT = 0x91BE,
	GL_MAX_COMPUTE_WORK_GROUP_SIZE = 0x91BF,

	GPU_MEMORY_INFO_DEDICATED_VIDMEM_NVX 			= 0x9047,
	GPU_MEMORY_INFO_TOTAL_AVAILABLE_MEMORY_NVX 		= 0x9048,
	GPU_MEMORY_INFO_CURRENT_AVAILABLE_VIDMEM_NVX 	= 0x9049,
	GPU_MEMORY_INFO_EVICTION_COUNT_NVX 				= 0x904A,
	GPU_MEMORY_INFO_EVICTED_MEMORY_NVX 				= 0x904B,

	GL_BUFFER 				= 0x82E0,
	GL_SHADER 				= 0x82E1,
	GL_PROGRAM 				= 0x82E2,
	GL_QUERY 				= 0x82E3,
	GL_PROGRAM_PIPELINE 	= 0x82E4,
	GL_SAMPLER 				= 0x82E6,
	-- GL_BUFFER,
	-- GL_SHADER,
	-- GL_PROGRAM,
	-- GL_VERTEX_ARRAY,
	-- GL_QUERY,
	-- GL_PROGRAM_PIPELINE,
	-- GL_TRANSFORM_FEEDBACK,
	-- GL_SAMPLER,
	-- GL_TEXTURE,
	-- GL_RENDERBUFFER,
	-- GL_FRAMEBUFFER

	TEXTURE_CUBE_MAP_SEAMLESS = 0x884F,
}
OPENGL.SDL = (FFI.os == "Windows" and FFI.load("SDL2") or FFI.C)

-- Love
-- https://github.com/love2d/love/blob/main/src/modules/graphics/wrap_GraphicsShader.lua
OPENGL.ExtensionGL = {
	"GL_KHR_debug",					-- For debug group in RenderDoc
	"GL_ARB_framebuffer_object",	-- For MRT rendering
	"GL_EXT_depth_bounds_test", 	-- For shadow volume (https://registry.khronos.org/OpenGL/extensions/EXT/EXT_depth_bounds_test.txt)
	"GL_NVX_gpu_memory_info", 		-- GPU memory info (should work on Intel/AMD/Nvidia)
	"GL_ARB_seamless_cube_map"		-- Seamless cubemap sampling
}
OPENGL.ExtensionGLSL = {
	"GL_ARB_arrays_of_arrays",		-- For multi-dimensional arrays in shaders
}

-- https://registry.khronos.org/OpenGL/api/GLSC/1.0/gl.h
-- https://registry.khronos.org/OpenGL/api/GL/glext.h
-- https://registry.khronos.org/OpenGL/api/GL/glcorearb.h
function OPENGL.Init()
	local RendererName = love.graphics.getRendererInfo()

	if RendererName == "Vulkan" then
		return
	end

	local Names = {
		{ "glEnable", "PFNGLENABLE" },
		{ "glDisable", "PFNGLDISABLE" },
		{ "glIsEnabled", "PFNGLISENABLED" },
		{ "glPushDebugGroup", "PFNGLPUSHDEBUGGROUPPROC" },
		{ "glPopDebugGroup", "PFNGLPOPDEBUGGROUPPROC" },
		{ "glGenQueries", "PFNGLGENQUERIESPROC" },
		{ "glQueryCounter", "PFNGLQUERYCOUNTERPROC" },
		{ "glGetQueryObjectiv", "PFNGLGETQUERYOBJECTIVPROC" },
		{ "glGetQueryObjectui64v", "PFNGLGETQUERYOBJECTUI64VPROC" },
		{ "glGetIntegerv", "PFNGLGETINTEGERVPROC" },
		{ "glDepthBoundsEXT", "PFNGLDEPTHBOUNDSEXTPROC" },
		{ "glObjectLabel", "PFNGLOBJECTLABELPROC" },
		{ "glDepthRange", "PFNGLDEPTHRANGEPROC" }
	}
	local Definitions = [[
		//---------------------
		// OpenGL
		// https://www.khronos.org/opengl/wiki/OpenGL_Type
		//---------------------
		typedef char GLchar;
		typedef int GLsizei;
		typedef unsigned int GLuint;
		typedef uint64_t GLuint64;
		typedef unsigned int GLenum;
		typedef unsigned char GLboolean;
		typedef unsigned int GLbitfield;
		typedef signed char GLbyte;
		typedef int GLint;
		typedef unsigned char GLubyte;
		typedef unsigned short GLushort;
		typedef float GLfloat;
		typedef float GLclampf;
		typedef double GLclampd;
		typedef double GLdouble;
		typedef void GLvoid;

		// void glEnable( GLenum cap );
		typedef void (APIENTRYP PFNGLENABLE) (GLint capability);

		// void glDisable( GLenum cap );
		typedef void (APIENTRYP PFNGLDISABLE) (GLint capability);

		// GLboolean glIsEnabled( GLenum cap );
		typedef GLboolean (APIENTRYP PFNGLISENABLED) (GLint capability);

		// void glPushDebugGroup( GLenum source, GLuint id, GLsizei length, const GLchar *message );
		typedef void (APIENTRYP PFNGLPUSHDEBUGGROUPPROC) (GLenum source, GLuint id, GLsizei length, const GLchar *message);

		// void glPopDebugGroup( void );
		typedef void (APIENTRYP PFNGLPOPDEBUGGROUPPROC) (void);

		// void glGenQueries(GLsizei n, GLuint * ids);
		typedef void (APIENTRYP PFNGLGENQUERIESPROC) (GLsizei n, GLuint *ids);

		// void glQueryCounter(	GLuint id, GLenum target );
		typedef void (APIENTRYP PFNGLQUERYCOUNTERPROC) (GLuint id, GLenum target);

		// void glGetQueryObjectiv( GLuint id, GLenum pname, GLint * params );
		typedef void (APIENTRYP PFNGLGETQUERYOBJECTIVPROC) (GLuint id, GLenum pname, GLint *params);

		// void glGetQueryObjectui64v(	GLuint id, GLenum pname, GLuint64 * params );
		typedef void (APIENTRYP PFNGLGETQUERYOBJECTUI64VPROC) (GLuint id, GLenum pname, GLuint64 *params);

		// void glGetIntegerv( GLenum pname, GLint *data );
		typedef void (APIENTRYP PFNGLGETINTEGERVPROC) (GLenum pname, GLint *data);

		// void glDepthBoundsEXT( GLclampd zmin, GLclampd zmax );
		typedef void (APIENTRYP PFNGLDEPTHBOUNDSEXTPROC) (GLclampd zmin, GLclampd zmax);


		// void glObjectLabel( GLenum identifier, GLuint name, GLsizei length, const char * label);
		typedef void (APIENTRYP PFNGLOBJECTLABELPROC) (GLenum identifier, GLuint name, GLsizei length, const GLchar *label);

		// void APIENTRY glDepthRange( GLdouble n, GLdouble f );
		typedef void (APIENTRYP PFNGLDEPTHRANGEPROC) (GLdouble n, GLdouble f);

		//---------------------
		// SDL
		//---------------------
		typedef bool SDL_bool;
		SDL_bool SDL_GL_ExtensionSupported( const char *extension );
		void* SDL_GL_GetProcAddress( const char *proc );
	]]

	if FFI.os == "Windows" then
		Definitions = Definitions:gsub( "APIENTRYP", "__stdcall *" )
	else
		Definitions = Definitions:gsub( "APIENTRYP", "*" )
	end

	FFI.cdef( Definitions )

	local ProcName = ""
	local GLName = ""
	local Function = false

	for i=1, #Names do
		GLName = Names[i][1]
		ProcName = Names[i][2]
		Function = FFI.cast(
			ProcName,
			OPENGL.SDL.SDL_GL_GetProcAddress(GLName)
		)

		if Function ~= FFI.NULL then
			rawset( OPENGL.GL, GLName, Function )
		end
	end

	IsInit = true
end

function OPENGL.IsExtensionSupported( Name )
	if not IsInit then return end
	return OPENGL.SDL.SDL_GL_ExtensionSupported( Name )
end

function OPENGL.CheckHardwareSupport( LOG )
	if not IsInit then return end
	LOG.Print( "Checking OpenGL extensions support:" )

	for i=1, #OPENGL.ExtensionGL do
		local IsSupported = OPENGL.IsExtensionSupported( OPENGL.ExtensionGL[i] )
		LOG.Print( string.format( "%s: %s", OPENGL.ExtensionGL[i], tostring(IsSupported) ) )
	end
	for i=1, #OPENGL.ExtensionGLSL do
		local IsSupported = OPENGL.IsExtensionSupported( OPENGL.ExtensionGLSL[i] )
		LOG.Print( string.format( "%s: %s", OPENGL.ExtensionGLSL[i], tostring(IsSupported) ) )
	end

	LOG.Print( "---" )
	LOG.Print( "Checking OpenGL extensions values:" )

	local Queries = {
		"GL_MAX_CLIP_DISTANCES",
		"GL_MAX_ARRAY_TEXTURE_LAYERS",
		"GL_MAX_COMPUTE_WORK_GROUP_INVOCATIONS",
		"GL_MAX_COMPUTE_WORK_GROUP_COUNT",
		"GL_MAX_COMPUTE_WORK_GROUP_SIZE"
	}

	for i=1, #Queries do
		LOG.Print(
			string.format(
				"%s: %i",
				Queries[i],
				OPENGL.GetInteger( OPENGL.GL[ Queries[i] ] )
			)
		)
	end

	LOG.Print(
		string.format(
			"%s: %s",
			"TEXTURE_CUBE_MAP_SEAMLESS",
			tostring( OPENGL.IsEnabled( OPENGL.GL.TEXTURE_CUBE_MAP_SEAMLESS ) )
		)
	)
end

function OPENGL.GetInteger( Name )
	if not IsInit then return end
	if OPENGL.GL.glGetIntegerv then
		OPENGL.GL.glGetIntegerv( Name, Int )
		return Int[0]
	end
end

function OPENGL.Enable( Cap )
	if not IsInit then return end
	if OPENGL.GL.glEnable then
		OPENGL.GL.glEnable( Cap )
	end
end

function OPENGL.Disable( Cap )
	if not IsInit then return end
	if OPENGL.GL.glDisable then
		OPENGL.GL.glDisable( Cap )
	end
end

function OPENGL.IsEnabled( Cap )
	if not IsInit then return end
	if OPENGL.GL.glIsEnabled then
		return OPENGL.GL.glIsEnabled( Cap )
	else
		return false
	end
end

function OPENGL.PushEvent( Message )
	if not IsInit then return end
	if OPENGL.GL.glPushDebugGroup then
		OPENGL.GL.glPushDebugGroup(
			0,
			0,
			string.len( Message ),
			Message
		)
	end
end

function OPENGL.PopEvent()
	if not IsInit then return end
	if OPENGL.GL.glPopDebugGroup then
		OPENGL.GL.glPopDebugGroup()
	end
end

function OPENGL.SetDepthBounds( Min, Max )
	if not IsInit then return end
	if OPENGL.GL.glDepthBoundsEXT then
		-- Min must be equal or lower than max, otherwise will return an error
		local MinFloat = FFI.new( "double[1]", false )
		MinFloat[0] = math.min( Min, Max )

		local MaxFloat = FFI.new( "double[1]", false )
		MaxFloat[0] = Max

		OPENGL.GL.glDepthBoundsEXT( MinFloat[0], MaxFloat[0] )
	end
end

function OPENGL.TimerGenerateNew( Name )
	if not IsInit then return end
	if OPENGL.GL.glGenQueries then
		local NewTimer = FFI.new( "int[2]", false )
		OPENGL.GL.glGenQueries( 2, NewTimer )

		local NameStart = "TimerQuery:" .. Name .. "_start"
		local NameStop = "TimerQuery:" .. Name .. "_stop"

		local NameStartC = FFI.new("char[?]", #NameStart + 1)
		local NameStopC = FFI.new("char[?]", #NameStop + 1)
		FFI.copy( NameStartC, NameStart )
		FFI.copy( NameStopC, NameStop )

		OPENGL.GL.glObjectLabel( OPENGL.GL.GL_QUERY, NewTimer[0], -1, NameStartC );
		OPENGL.GL.glObjectLabel( OPENGL.GL.GL_QUERY, NewTimer[1], -1, NameStopC );

		return {
			Time = 0.0,
			IsInvalid = true,
			Ids = NewTimer
		}
	end
end

function OPENGL.TimerStart( Timer )
	if not IsInit then return end
	if OPENGL.GL.glQueryCounter then
		Timer.IsInvalid = false
		OPENGL.GL.glQueryCounter( Timer.Ids[0], OPENGL.GL.GL_TIMESTAMP )
	end
end

function OPENGL.TimerStop( Timer )
	if not IsInit then return end
	if OPENGL.GL.glQueryCounter then
		OPENGL.GL.glQueryCounter( Timer.Ids[1], OPENGL.GL.GL_TIMESTAMP )
	end
end

function OPENGL.TimerGetResult( Timer )
	if not IsInit then return end
	if OPENGL.GL.glGetQueryObjectui64v then
		OPENGL.GL.glGetQueryObjectui64v(
			Timer.Ids[0],
			OPENGL.GL.GL_QUERY_RESULT,
			UInt64_1
		)
		OPENGL.GL.glGetQueryObjectui64v(
			Timer.Ids[1],
			OPENGL.GL.GL_QUERY_RESULT,
			UInt64_2
		)

		-- ToNumber() convert cdata int64 into a double
		-- See: Extended library function on https://luajit.org/ext_ffi_api.html
		local Difference = tonumber(UInt64_2[0]) - tonumber(UInt64_1[0])

		-- Result is in nanoseconds, return in ms
		Timer.Time = Difference * 0.000001
	else
		return 0
	end
end

function OPENGL.SetDepthRange( Start, Stop )
	if not IsInit then return end
	if OPENGL.GL.glDepthRange then
		local MinFloat = FFI.new( "double[1]", false )
		MinFloat[0] = Start

		local MaxFloat = FFI.new( "double[1]", false )
		MaxFloat[0] = Stop

		OPENGL.GL.glDepthRange( MinFloat[0], MaxFloat[0] )
	end
end

return OPENGL