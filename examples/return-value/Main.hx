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
		var scriptContent:String = sys.io.File.getContent("script.lua");
		var result = LuaL.dostring(vm, scriptContent);
		
		// Check the result if needed
		if (result != 0) {
			Sys.println("Error running script: " + result);
		}

		final stack:Int = Lua.gettop(vm);

		trace('stack: $stack');

		final num:Int = Lua.tointeger(vm, 1);

		trace('num: $num');

		/* cleanup Lua */
		Lua.close(vm);
		vm = null;
	}
}
