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

		/* register our function */
		Lua.pushcfunction(vm, cpp.Function.fromStaticFunction(print), "print");
		Lua.setglobal(vm, "print");

		/* run the script */
		LuaL.dofile(vm, "script.lua");

		/* cleanup Lua */
		Lua.close(vm);
		vm = null;
	}

	private static function print(l:cpp.RawPointer<Lua_State>):Int
	{
		final n:Int = Lua.gettop(l);

		/* loop through each argument */
		for (i in 0...n)
			Sys.println(cast(Lua.tostring(l, i + 1), String));

		Lua.pop(l, n); /* clear the stack */

		return 0;
	}
}
