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
		Lua.pushcfunction(vm, cpp.Function.fromStaticFunction(average), "average");
		Lua.setglobal(vm, "average");

		/* run the script */
		LuaL.dostring(vm, sys.io.File.getContent("script.lua"));

		/* cleanup Lua */
		Lua.close(vm);
		vm = null;
	}

	private static function average(l:cpp.RawPointer<Lua_State>):Int
	{
		var sum:Float = 0.0;

		final n:Int = Lua.gettop(l);

		/* loop through each argument */
		for (i in 0...n)
		{
			if (Lua.isnumber(l, i + 1) != 1)
				LuaL.error(l, "Incorrect argument to 'average'");

			/* total the arguments */
			sum += Lua.tonumber(l, i + 1);
		}

		Lua.pop(l, n); /* clear the stack */

		Lua.pushnumber(l, sum / n); /* push the average */
		Lua.pushnumber(l, sum); /* push the sum */

		return 2; /* return the number of results */
	}
}
