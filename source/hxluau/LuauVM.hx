package hxluau;

#if !cpp
#error 'Luau supports only C++ target platforms.'
#end
import hxluau.Types;

/**
 * Provides access to various properties and functionalities of Luau.
 * This class contains Luau-specific extensions that are not part of the standard Lua API.
 */
@:buildXml('<include name="${haxelib:hxluau}/project/Build.xml" />')
@:include('lua.h')
@:include('luacode.h')
@:include('luacodegen.h')
@:unreflective
extern class LuauVM
{
	/**
	 * Compile a string of Lua source code into bytecode for execution by Luau VM.
	 *
	 * @param source The Lua source code to compile.
	 * @param size The size of the source code string.
	 * @param options Compilation options (can be null).
	 * @param bytecodeSize Pointer to store the size of the resulting bytecode.
	 * @return A pointer to the compiled bytecode, or null on error.
	 */
	@:native('luau_compile')
	static function compile(source:cpp.ConstCharStar, size:cpp.SizeT, options:cpp.RawPointer<cpp.Void>, bytecodeSize:cpp.Star<cpp.SizeT>):cpp.RawPointer<cpp.Char>;

	/**
	 * Load a precompiled Luau chunk into the Lua state.
	 *
	 * @param L The Lua state.
	 * @param chunkname The name of the chunk.
	 * @param bytecode The compiled bytecode.
	 * @param bytecodeSize The size of the bytecode.
	 * @param env The environment index (0 for default).
	 * @return 0 on success, or an error code on failure.
	 */
	@:native('luau_load')
	static function load(L:cpp.RawPointer<Lua_State>, chunkname:cpp.ConstCharStar, bytecode:cpp.ConstCharStar, bytecodeSize:cpp.SizeT, env:Int):Int;

	/**
	 * Sets the maximum bytecode count for loop unrolling.
	 *
	 * @param limit The new limit.
	 */
	@:native('luau_setloopunrolllimit')
	static function setloopunrolllimit(limit:Int):Void;

	/**
	 * Sets the maximum include depth for bytecode.
	 *
	 * @param limit The new limit.
	 */
	@:native('luau_setstepmul')
	static function setstepmul(limit:Int):Void;

	/**
	 * Sets the garbage collector step multiplier.
	 *
	 * @param limit The new limit.
	 */
	@:native('luau_setgcthreshold')
	static function setgcthreshold(limit:Int):Void;

	/**
	 * Returns 1 if Luau native code generator is supported on this platform, 0 otherwise.
	 */
	@:native('luau_codegen_supported')
	static function codegen_supported():Int;

	/**
	 * Creates a code generator instance bound to the given state. Must check support first.
	 */
	@:native('luau_codegen_create')
	static function codegen_create(L:cpp.RawPointer<Lua_State>):Void;

	/**
	 * Builds native code for target function (and inner functions) at stack index `idx`.
	 */
	@:native('luau_codegen_compile')
	static function codegen_compile(L:cpp.RawPointer<Lua_State>, idx:Int):Void;
}