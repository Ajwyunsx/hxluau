package luau;

#if !cpp
#error 'Luau supports only C++ target platforms.'
#end
import hxluau.Types;

@:buildXml('<include name="${haxelib:hxluau}/project/Build.xml" />')
@:include('lua.h')
@:include('lualib.h')
@:include('luacode.h')
@:unreflective
extern class Lua {
	public static inline var LUA_MULTRET:Int = (-1);
	public static inline var LUA_REGISTRYINDEX:Int = (-10000);
	public static inline var LUA_ENVIRONINDEX:Int = (-10001);
	public static inline var LUA_GLOBALSINDEX:Int = (-10002);
	public static inline var LUA_OK:Int = 0;
	public static inline var LUA_YIELD:Int = 1;
	public static inline var LUA_ERRRUN:Int = 2;
	public static inline var LUA_ERRSYNTAX:Int = 3;
	public static inline var LUA_ERRMEM:Int = 4;
	public static inline var LUA_ERRERR:Int = 5;
	public static inline var LUA_TNONE:Int = (-1);
	public static inline var LUA_TNIL:Int = 0;
	public static inline var LUA_TBOOLEAN:Int = 1;
	public static inline var LUA_TLIGHTUSERDATA:Int = 2;
	public static inline var LUA_TNUMBER:Int = 3;
	public static inline var LUA_TSTRING:Int = 4;
	public static inline var LUA_TTABLE:Int = 5;
	public static inline var LUA_TFUNCTION:Int = 6;
	public static inline var LUA_TUSERDATA:Int = 7;
	public static inline var LUA_TTHREAD:Int = 8;
	public static inline var LUA_MINSTACK:Int = 20;

	// Luau-style constant aliases for compatibility
	public static inline var MULTRET:Int = LUA_MULTRET;
	public static inline var REGISTRYINDEX:Int = LUA_REGISTRYINDEX;
	public static inline var ENVIRONINDEX:Int = LUA_ENVIRONINDEX;
	public static inline var GLOBALSINDEX:Int = LUA_GLOBALSINDEX;
	public static inline var OK:Int = LUA_OK;
	public static inline var YIELD:Int = LUA_YIELD;
	public static inline var ERRRUN:Int = LUA_ERRRUN;
	public static inline var ERRSYNTAX:Int = LUA_ERRSYNTAX;
	public static inline var ERRMEM:Int = LUA_ERRMEM;
	public static inline var ERRERR:Int = LUA_ERRERR;
	public static inline var TNONE:Int = LUA_TNONE;
	public static inline var TNIL:Int = LUA_TNIL;
	public static inline var TBOOLEAN:Int = LUA_TBOOLEAN;
	public static inline var TLIGHTUSERDATA:Int = LUA_TLIGHTUSERDATA;
	public static inline var TNUMBER:Int = LUA_TNUMBER;
	public static inline var TSTRING:Int = LUA_TSTRING;
	public static inline var TTABLE:Int = LUA_TTABLE;
	public static inline var TFUNCTION:Int = LUA_TFUNCTION;
	public static inline var TUSERDATA:Int = LUA_TUSERDATA;
	public static inline var TTHREAD:Int = LUA_TTHREAD;
        @:functionCode('return ::String("Luau")')
    public static inline function versionJIT():String return "";
        @:functionCode('return ::String("Luau")')
        public static inline function version():String return "";

	@:native('lua_pushnil')
	static function pushnil(L:cpp.RawPointer<Lua_State>):Void;

	@:native('lua_pushnumber')
	static function pushnumber(L:cpp.RawPointer<Lua_State>, n:Lua_Number):Void;

	@:native('lua_pushinteger')
	static function pushinteger(L:cpp.RawPointer<Lua_State>, n:Lua_Integer):Void;

	@:native('lua_pushlstring')
	static function pushlstring(L:cpp.RawPointer<Lua_State>, s:cpp.ConstCharStar, len:cpp.SizeT):Void;

	@:native('lua_pushstring')
	static function pushstring(L:cpp.RawPointer<Lua_State>, s:cpp.ConstCharStar):Void;

	@:native('lua_pushvfstring')
	static function pushvfstring(L:cpp.RawPointer<Lua_State>, s:cpp.ConstCharStar, argp:cpp.VarList):Void;

	@:native('lua_pushfstring')
	static function pushfstring(L:cpp.RawPointer<Lua_State>, fmt:cpp.ConstCharStar, args:cpp.Rest<cpp.VarArg>):cpp.ConstCharStar;

	@:native('lua_pushcclosure')
	static function pushcclosure(L:cpp.RawPointer<Lua_State>, fn:Lua_CFunction, debugname:cpp.ConstCharStar, n:Int):Void;

	@:native('lua_pushcfunction')
	static function pushcfunction(L:cpp.RawPointer<Lua_State>, fn:Lua_CFunction, debugname:cpp.ConstCharStar):Void;

	@:noCompletion
	@:native('lua_pushboolean')
	static function _pushboolean(l:State, b:Int):Void;

	static inline function pushboolean(l:State, b:Bool):Void {
		_pushboolean(l, b == true ? 1 : 0);
	}

	@:native('lua_pushlightuserdata')
	static function pushlightuserdata(L:cpp.RawPointer<Lua_State>, p:cpp.RawPointer<cpp.Void>):Void;

	@:native('lua_pushthread')
	static function pushthread(L:cpp.RawPointer<Lua_State>):Int;

	@:native('lua_pop')
	static function pop(L:cpp.RawPointer<Lua_State>, n:Int):Void;

	@:native('lua_type')
	static function type(L:cpp.RawPointer<Lua_State>, idx:Int):Int;

	@:native('lua_typename')
	static function typename(L:cpp.RawPointer<Lua_State>, tp:Int):cpp.ConstCharStar;

    @:native('lua_setglobal')
    static function setglobal(L:cpp.RawPointer<Lua_State>, s:cpp.ConstCharStar):Void;

	@:native('lua_getglobal')
	static function getglobal(L:cpp.RawPointer<Lua_State>, s:cpp.ConstCharStar):Int;

	@:native('lua_tostring')
	static function tostring(L:cpp.RawPointer<Lua_State>, i:Int):cpp.ConstCharStar;

	@:native('lua_close')
	static function close(L:cpp.RawPointer<Lua_State>):Void;

	@:native('lua_gettop')
	static function gettop(L:cpp.RawPointer<Lua_State>):Int;

	@:native('lua_upvalueindex')
	static function upvalueindex(i:Int):Int;

	@:noCompletion
	@:native('lua_isboolean')
	static function _isboolean(L:cpp.RawPointer<Lua_State>, idx:Int):Int;

	static inline function isboolean(L:cpp.RawPointer<Lua_State>, idx:Int):Bool {
		return _isboolean(L, idx) != 0;
	}

	@:noCompletion
	@:native('lua_isstring')
	static function _isstring(L:cpp.RawPointer<Lua_State>, idx:Int):Int;

	static inline function isstring(L:cpp.RawPointer<Lua_State>, idx:Int):Bool {
		return _isstring(L, idx) != 0;
	}

	@:noCompletion
	@:native('lua_toboolean')
	static function _toboolean(l:State, idx:Int) : Int;

	static inline function toboolean(l:State, idx:Int) : Bool {
		return _toboolean(l, idx) != 0;
	}

	@:noCompletion
	@:native('lua_isnumber')
	static function _isnumber(L:cpp.RawPointer<Lua_State>, idx:Int):Int;

	static inline function isnumber(L:cpp.RawPointer<Lua_State>, idx:Int):Bool {
		return _isnumber(L, idx) != 0;
	}

	@:native('lua_tonumber')
	static function tonumber(L:cpp.RawPointer<Lua_State>, idx:Int):Lua_Number;

	@:noCompletion
	@:native('lua_isfunction')
	static function _isfunction(L:cpp.RawPointer<Lua_State>, idx:Int):Int;

	static inline function isfunction(L:cpp.RawPointer<Lua_State>, idx:Int):Bool {
		return _isfunction(L, idx) != 0;
	}

	@:native('lua_pcall')
	static function pcall(L:cpp.RawPointer<Lua_State>, nargs:Int, nresults:Int, errfunc:Int):Int;

	@:native('lua_tointeger')
	static function tointeger(L:cpp.RawPointer<Lua_State>, idx:Int):Lua_Integer;

	@:native('lua_next')
	static function next(L:cpp.RawPointer<Lua_State>, idx:Int):Int;

	@:native('lua_createtable')
	static function createtable(L:cpp.RawPointer<Lua_State>, narr:Int, nrec:Int):Void;

	@:native('lua_settable')
	static function settable(L:cpp.RawPointer<Lua_State>, idx:Int):Int;

	@:native('lua_newtable')
	static function newtable(L:cpp.RawPointer<Lua_State>):Void;

	@:native('lua_getmetatable')
	static function getmetatable(L:cpp.RawPointer<Lua_State>, objindex:Int):Int;

	@:native('lua_setmetatable')
	static function setmetatable(L:cpp.RawPointer<Lua_State>, objindex:Int):Int;

	@:native('lua_rawgeti')
	static function rawgeti(L:cpp.RawPointer<Lua_State>, idx:Int, n:Int):Int;

	@:native('lua_rawget')
	static function rawget(L:cpp.RawPointer<Lua_State>, idx:Int):Int;

	@:native('lua_rawset')
	static function rawset(L:cpp.RawPointer<Lua_State>, idx:Int):Int;

	@:native('lua_rawseti')
	static function rawseti(L:cpp.RawPointer<Lua_State>, idx:Int, n:Int):Int;

    static inline function register(L:cpp.RawPointer<Lua_State>, name:cpp.ConstCharStar, f:Lua_CFunction):Void {
        Lua.pushcfunction(L, f, name);
        Lua.setglobal(L, name);
    }

    static inline function init_callbacks(L:cpp.RawPointer<Lua_State>):Void {
        Lua.pushcfunction(L, cpp.Callable.fromStaticFunction(print), "print");
        Lua.setglobal(L, "print");
    }

	@:native('lua_pushvalue')
	static function pushvalue(L:cpp.RawPointer<Lua_State>, idx:Int):Void;

	@:native('lua_getfield')
	static function getfield(l:State, idx:Int, k:String):Void;

	@:native('lua_setfield')
	static function setfield(l:State, idx:Int, k:String):Void;

    static inline function print(L:cpp.RawPointer<Lua_State>):Int {
        final nargs:Int = Lua.gettop(L);

        for (i in 0...nargs)
            Sys.println(cast(Lua.tostring(L, i + 1), String));

        Lua.pop(L, nargs);
        return 0;
    }

	static inline function set_callbacks_function(f:cpp.Callable<State->String->Int>):Void {
		@:privateAccess
		Lua_helper.callbacks_function = f;
	}
}

class Lua_helper {
	public static var sendErrorsToLua:Bool = true;
	public static var callbacks:Map<String, Dynamic> = new Map();

	@:noCompletion
	private static var callbacks_function:cpp.Callable<State->String->Int> = null;

	public static function add_callback(L:cpp.RawPointer<Lua_State>, fname:String, f:Dynamic):Bool {
		callbacks.set(fname, f);
        Lua.pushstring(L, fname);
        Lua.pushcclosure(L, cpp.Callable.fromStaticFunction(callback_handler), fname, 1);
        Lua.setglobal(L, fname);
		return true;
	}

	public function remove_callback(L:cpp.RawPointer<Lua_State>, key:String) {
		if (L == null)
			return;

		callbacks.remove(key);

        Lua.pushnil(L);
        Lua.setglobal(L, key);
	}

	private static function callback_handler(L:cpp.RawPointer<Lua_State>):Int {
		if (callbacks_function != null)
			return callbacks_function(L, cast(Lua.tostring(L, Lua.upvalueindex(1)), String));

		try {
            final nargs:Int = Lua.gettop(L);

			var args:Array<Dynamic> = [];
			for (i in 0...nargs)
				args[i] = Convert.fromLua(L, i + 1);

            Lua.pop(L, nargs);

            final name:String = cast(Lua.tostring(L, Lua.upvalueindex(1)), String);

			if (callbacks.exists(name)) {
				var ret:Dynamic = Reflect.callMethod(null, callbacks.get(name), args);

				if (ret != null) {
					Convert.toLua(L, ret);
					return 1;
				}
			}
		} catch (e:Dynamic) {
			if (sendErrorsToLua) {
				LuaL.error(L, 'CALLBACK ERROR! ${e.message != null ? e.message : e}');
				return 0;
			}
			trace(e);
			throw(e);
		}

		return 0;
	}
}
