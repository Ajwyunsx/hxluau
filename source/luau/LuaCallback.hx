package luau;

#if !cpp
#error 'Luau supports only C++ target platforms.'
#end
import hxluau.Types;

class LuaCallback {
	private final L:cpp.RawPointer<Lua_State>;

	public var ref(default, null):Int;

	public function new(lua:cpp.Pointer<Lua_State>, ref:Int) {
		this.L = lua.raw;
		this.ref = ref;
	}

	public function call(args:Array<Dynamic> = null) {
		Lua.rawgeti(L, Lua.REGISTRYINDEX, this.ref);
		if (Lua.isfunction(L, -1)) {
			if (args == null)
				args = [];
			for (arg in args)
				Convert.toLua(L, arg);
			var status:Int = Lua.pcall(L, args.length, 0, 0);
            if (status != Lua.OK) {
                var err:String = cast(Lua.tostring(L, -1), String);
                Lua.pop(L, 1);
                if (err == null || err == "") {
                    if (status == Lua.ERRRUN)
                        err = "Runtime Error";
                    else if (status == Lua.ERRMEM)
                        err = "Memory Allocation Error";
                    else if (status == Lua.ERRERR)
                        err = "Critical Error";
                    else
                        err = "Unknown Error";
                }
                Sys.println("Error on callback: " + err);
            }
		}
	}

	public function dispose()
		Lua.unref(L, ref);
}
