// hxcpp precompiled header must be included first
#include "hxcpp.h"

#include "lua.h"
#include "lualib.h"
#include "luacode.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

// Luau does not define LUA_ERRFILE; provide a fallback to match PUC-Lua
#ifndef LUA_ERRFILE
#define LUA_ERRFILE 7
#endif

extern "C" {

// Wrapper for luaL_loadstring functionality using Luau
int hxluau_LuaL_loadstring_wrapper(lua_State* L, const char* s) {
    size_t s_len = strlen(s);
    size_t bytecodeSize;
    char* bytecode = luau_compile(s, s_len, NULL, &bytecodeSize);
    
    if (!bytecode) {
        lua_pushfstring(L, "cannot compile string");
        return LUA_ERRSYNTAX;
    }
    
    // Load the bytecode
    int loadResult = luau_load(L, "string", bytecode, bytecodeSize, 0);
    free(bytecode);
    return loadResult;
}

// Wrapper for luaL_loadfile functionality using Luau
int hxluau_LuaL_loadfile_wrapper(lua_State* L, const char* filename) {
    FILE* file = fopen(filename, "rb");
    if (!file) {
        lua_pushfstring(L, "cannot open %s", filename);
        return LUA_ERRFILE;
    }
    
    fseek(file, 0, SEEK_END);
    size_t size = ftell(file);
    fseek(file, 0, SEEK_SET);
    
    char* buffer = (char*)malloc(size);
    if (!buffer) {
        fclose(file);
        lua_pushfstring(L, "cannot allocate %d bytes for file %s", (int)size, filename);
        return LUA_ERRMEM;
    }
    
    size_t read = fread(buffer, 1, size, file);
    fclose(file);
    
    if (read != size) {
        free(buffer);
        lua_pushfstring(L, "cannot read %s", filename);
        return LUA_ERRFILE;
    }
    
    // Compile using Luau
    size_t bytecodeSize;
    char* bytecode = luau_compile(buffer, size, NULL, &bytecodeSize);
    free(buffer);
    
    if (!bytecode) {
        lua_pushfstring(L, "cannot compile %s", filename);
        return LUA_ERRSYNTAX;
    }
    
    // Load the bytecode
    int loadResult = luau_load(L, filename, bytecode, bytecodeSize, 0);
    free(bytecode);
    return loadResult;
}

// Wrapper for luaL_dostring functionality
int hxluau_LuaL_dostring_wrapper(lua_State* L, const char* str) {
    int loadResult = hxluau_LuaL_loadstring_wrapper(L, str);
    if (loadResult == 0) {
        return lua_pcall(L, 0, LUA_MULTRET, 0);
    }
    return loadResult;
}

}
