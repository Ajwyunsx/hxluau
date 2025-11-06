#ifndef HXLUAU_LUA_IMPL_H
#define HXLUAU_LUA_IMPL_H

#include "lua.h"

#ifdef __cplusplus
extern "C" {
#endif

// Wrapper for luaL_loadstring functionality using Luau
int hxluau_LuaL_loadstring_wrapper(lua_State* L, const char* s);

// Wrapper for luaL_loadfile functionality using Luau
int hxluau_LuaL_loadfile_wrapper(lua_State* L, const char* filename);

// Wrapper for luaL_dostring functionality
int hxluau_LuaL_dostring_wrapper(lua_State* L, const char* str);

#ifdef __cplusplus
}
#endif

#endif // HXLUAU_LUA_IMPL_H