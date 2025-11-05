package;

import hxluau.Lua;

import hxluau.LuaL;
import hxluau.Types;

class Main
{
	public static function main():Void
	{
		/* version info */
		Sys.println(Lua.VERSION);

		/* initialize Lua */
		var vm:cpp.RawPointer<Lua_State> = LuaL.newstate();

		/* load Lua base libraries */
		LuaL.openlibs(vm);

		/* run the script */
		LuaL.dostring(vm, sys.io.File.getContent("script.lua"));

		/* cleanup Lua */
		Lua.close(vm);
		vm = null;
	}
}