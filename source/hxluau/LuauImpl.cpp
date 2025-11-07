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

// Wrapper for luaL_dofile functionality
int hxluau_LuaL_dofile_wrapper(lua_State* L, const char* filename) {
    int loadResult = hxluau_LuaL_loadfile_wrapper(L, filename);
    if (loadResult == 0) {
        return lua_pcall(L, 0, LUA_MULTRET, 0);
    }
    return loadResult;
}

// Custom print implementation that mirrors Lua's base print behavior
static int hxluau_print(lua_State* L) {
    int n = lua_gettop(L);  /* number of arguments */
    for (int i = 1; i <= n; i++) {
        const char* s = lua_tolstring(L, i, NULL);
        if (!s) {
            // Convert non-strings to string
            luaL_tolstring(L, i, NULL);
            s = lua_tolstring(L, -1, NULL);
            // remove temporary string
            lua_remove(L, -2);
        }
        fputs(s ? s : "nil", stdout);
        if (i < n) fputc('\t', stdout);
    }
    fputc('\n', stdout);
    return 0;
}

// Register the custom print into the global 'print'
void hxluau_register_print(lua_State* L) {
    lua_pushcfunction(L, hxluau_print, "print");
    lua_setglobal(L, "print");
}

}

// Provide graceful stubs for Luau native codegen APIs when the linked Luau library
// doesn't export them. This avoids unresolved externals at link time and lets
// higher-level code feature-detect support. Use C++ symbols to match Haxe/C++ calls.
int luau_codegen_supported(void) {
    return 0; // codegen not available by default in this distribution
}

void luau_codegen_create(lua_State* L) {
    // no-op stub
    (void)L;
}

void luau_codegen_compile(lua_State* L, int idx) {
    // no-op stub
    (void)L;
    (void)idx;
}
