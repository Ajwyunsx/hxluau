package hxluau;

#if !cpp
#error 'Luau supports only C++ target platforms.'
#end
import hxluau.Types;

/**
 * Provides static methods to open various standard Lua libraries and extensions.
 */
@:buildXml('<include name="${haxelib:hxluau}/project/Build.xml" />')
@:include('lua.h')
@:include('lualib.h')
@:unreflective
extern class LuaOpen
{
	/**
	 * Opens the basic library (`base`) into the given Lua state.
	 *
	 * @param L The Lua state.
	 * @return The number of results pushed onto the Lua stack.
	 */
	@:native('luaopen_base')
	static function base(L:cpp.RawPointer<Lua_State>):Int;

	/**
	 * Opens the mathematical library (`math`) into the given Lua state.
	 *
	 * @param L The Lua state.
	 * @return The number of results pushed onto the Lua stack.
	 */
	@:native('luaopen_math')
	static function math(L:cpp.RawPointer<Lua_State>):Int;

	/**
	 * Opens the string manipulation library (`string`) into the given Lua state.
	 *
	 * @param L The Lua state.
	 * @return The number of results pushed onto the Lua stack.
	 */
	@:native('luaopen_string')
	static function string(L:cpp.RawPointer<Lua_State>):Int;

	/**
	 * Opens the table manipulation library (`table`) into the given Lua state.
	 *
	 * @param L The Lua state.
	 * @return The number of results pushed onto the Lua stack.
	 */
	@:native('luaopen_table')
	static function table(L:cpp.RawPointer<Lua_State>):Int;

	/**
	 * Opens the coroutine library (`coroutine`) into the given Lua state.
	 *
	 * @param L The Lua state.
	 * @return The number of results pushed onto the Lua stack.
	 */
	@:native('luaopen_coroutine')
	static function coroutine(L:cpp.RawPointer<Lua_State>):Int;

	/**
	 * Opens the bit manipulation library (`bit32`) into the given Lua state.
	 *
	 * @param L The Lua state.
	 * @return The number of results pushed onto the Lua stack.
	 */
	@:native('luaopen_bit32')
	static function bit32(L:cpp.RawPointer<Lua_State>):Int;

	/**
	 * Opens the UTF-8 library (`utf8`) into the given Lua state.
	 *
	 * @param L The Lua state.
	 * @return The number of results pushed onto the Lua stack.
	 */
	@:native('luaopen_utf8')
	static function utf8(L:cpp.RawPointer<Lua_State>):Int;

	/**
	 * Opens the buffer library (`buffer`) into the given Lua state.
	 *
	 * @param L The Lua state.
	 * @return The number of results pushed onto the Lua stack.
	 */
	@:native('luaopen_buffer')
	static function buffer(L:cpp.RawPointer<Lua_State>):Int;
}