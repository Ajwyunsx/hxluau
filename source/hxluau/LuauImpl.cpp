// hxcpp precompiled header must be included first
#include "hxcpp.h"

#include "lua.h"
#include "lualib.h"
#include "luacode.h"
#include "luacodegen.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unordered_map>
#include <string>
#include <deque>
#include <stdint.h>

// Luau does not define LUA_ERRFILE; provide a fallback to match PUC-Lua
#ifndef LUA_ERRFILE
#define LUA_ERRFILE 7
#endif

// Forward declarations for codegen control state used below
extern bool g_codegen_enabled;
extern std::unordered_map<lua_State*, bool> g_codegen_created;

extern "C" {

// ------------------------------------
// Simple bytecode cache for files (LRU)
// ------------------------------------
struct BytecodeCache
{
    static std::unordered_map<std::string, std::string>& data()
    {
        static std::unordered_map<std::string, std::string> inst;
        return inst;
    }

    static std::unordered_map<std::string, uint64_t>& hashes()
    {
        static std::unordered_map<std::string, uint64_t> inst;
        return inst;
    }

    static std::deque<std::string>& order()
    {
        static std::deque<std::string> inst;
        return inst;
    }

    static size_t& capacity()
    {
        static size_t cap = 32; // default cache size
        return cap;
    }

    static void setCapacity(size_t cap)
    {
        capacity() = cap > 0 ? cap : 1;
        // Trim if necessary
        while (order().size() > capacity())
        {
            const std::string& victim = order().front();
            order().pop_front();
            data().erase(victim);
            hashes().erase(victim);
        }
    }

    static void clear()
    {
        data().clear();
        hashes().clear();
        order().clear();
    }

    static uint64_t fnv1a64(const char* buf, size_t size)
    {
        const uint64_t FNV_OFFSET = 1469598103934665603ull;
        const uint64_t FNV_PRIME = 1099511628211ull;
        uint64_t h = FNV_OFFSET;
        for (size_t i = 0; i < size; ++i)
        {
            h ^= (uint8_t)buf[i];
            h *= FNV_PRIME;
        }
        return h;
    }

    static bool get(const std::string& key, uint64_t h, std::string& out)
    {
        auto hi = hashes().find(key);
        if (hi == hashes().end() || hi->second != h)
            return false;

        auto di = data().find(key);
        if (di == data().end())
            return false;

        out = di->second;

        // refresh LRU
        for (auto it = order().begin(); it != order().end(); ++it)
        {
            if (*it == key)
            {
                order().erase(it);
                break;
            }
        }
        order().push_back(key);
        return true;
    }

    static void put(const std::string& key, uint64_t h, const char* bytecode, size_t size)
    {
        std::string bc(bytecode, bytecode + size);
        data()[key] = std::move(bc);
        hashes()[key] = h;

        // refresh LRU
        for (auto it = order().begin(); it != order().end(); ++it)
        {
            if (*it == key)
            {
                order().erase(it);
                break;
            }
        }
        order().push_back(key);

        // evict if needed
        while (order().size() > capacity())
        {
            const std::string& victim = order().front();
            order().pop_front();
            data().erase(victim);
            hashes().erase(victim);
        }
    }
};

// Cache control APIs
void hxluau_bytecode_cache_clear()
{
    BytecodeCache::clear();
}

void hxluau_bytecode_cache_set_capacity(int cap)
{
    BytecodeCache::setCapacity((size_t)cap);
}

// ------------------------------------
// Global compile options for luau_compile
// ------------------------------------
static lua_CompileOptions g_compile_opts = {
    /*optimizationLevel*/ 1,
    /*debugLevel*/ 1,
    /*typeInfoLevel*/ 0,
    /*coverageLevel*/ 0,
    /*vectorLib*/ nullptr,
    /*vectorCtor*/ nullptr,
    /*vectorType*/ nullptr,
    /*mutableGlobals*/ nullptr,
    /*userdataTypes*/ nullptr,
    /*librariesWithKnownMembers*/ nullptr,
    /*libraryMemberTypeCb*/ nullptr,
    /*libraryMemberConstantCb*/ nullptr,
    /*disabledBuiltins*/ nullptr,
};

void hxluau_set_compile_options(int optimizationLevel, int debugLevel, int typeInfoLevel)
{
    if (optimizationLevel >= 0 && optimizationLevel <= 2)
        g_compile_opts.optimizationLevel = optimizationLevel;
    if (debugLevel >= 0 && debugLevel <= 2)
        g_compile_opts.debugLevel = debugLevel;
    if (typeInfoLevel >= 0 && typeInfoLevel <= 1)
        g_compile_opts.typeInfoLevel = typeInfoLevel;
}

void hxluau_enable_codegen(int enable)
{
    g_codegen_enabled = (enable != 0);
}

// Wrapper for luaL_loadstring functionality using Luau
int hxluau_LuaL_loadstring_wrapper(lua_State* L, const char* s) {
    // Pause GC during compilation/load to avoid excessive collector work under bulk loads
    int gcWasRunning = lua_gc(L, LUA_GCISRUNNING, 0);
    if (gcWasRunning)
        lua_gc(L, LUA_GCSTOP, 0);

    size_t s_len = strlen(s);
    size_t bytecodeSize;
    char* bytecode = luau_compile(s, s_len, &g_compile_opts, &bytecodeSize);
    
    if (!bytecode) {
        if (gcWasRunning)
            lua_gc(L, LUA_GCRESTART, 0);
        lua_pushfstring(L, "cannot compile string");
        return LUA_ERRSYNTAX;
    }
    
    // Load the bytecode
    int loadResult = luau_load(L, "string", bytecode, bytecodeSize, 0);
    
    // If load succeeded, optionally compile to native code (LuaJIT-like speed-ups)
    if (loadResult == 0 && g_codegen_enabled)
    {
#ifdef HXLUAU_WITH_CODEGEN
        if (luau_codegen_supported())
        {
            lua_State* mainL = lua_mainthread(L);
            auto it = g_codegen_created.find(mainL);
            if (it == g_codegen_created.end() || !it->second)
            {
                luau_codegen_create(mainL);
                g_codegen_created[mainL] = true;
            }
            // Compile function at top of the stack
            luau_codegen_compile(L, -1);
        }
#endif
    }
    free(bytecode);
    if (gcWasRunning)
        lua_gc(L, LUA_GCRESTART, 0);
    return loadResult;
}

// Wrapper for luaL_loadfile functionality using Luau
int hxluau_LuaL_loadfile_wrapper(lua_State* L, const char* filename) {
    // Pause GC during file read/compile/load to reduce overhead spikes
    int gcWasRunning = lua_gc(L, LUA_GCISRUNNING, 0);
    if (gcWasRunning)
        lua_gc(L, LUA_GCSTOP, 0);

    FILE* file = fopen(filename, "rb");
    if (!file) {
        if (gcWasRunning)
            lua_gc(L, LUA_GCRESTART, 0);
        lua_pushfstring(L, "cannot open %s", filename);
        return LUA_ERRFILE;
    }
    
    fseek(file, 0, SEEK_END);
    size_t size = ftell(file);
    fseek(file, 0, SEEK_SET);
    
    char* buffer = (char*)malloc(size);
    if (!buffer) {
        fclose(file);
        if (gcWasRunning)
            lua_gc(L, LUA_GCRESTART, 0);
        lua_pushfstring(L, "cannot allocate %d bytes for file %s", (int)size, filename);
        return LUA_ERRMEM;
    }
    
    size_t read = fread(buffer, 1, size, file);
    fclose(file);
    
    if (read != size) {
        free(buffer);
        if (gcWasRunning)
            lua_gc(L, LUA_GCRESTART, 0);
        lua_pushfstring(L, "cannot read %s", filename);
        return LUA_ERRFILE;
    }
    
    // Compute content hash for cache lookup
    uint64_t h = BytecodeCache::fnv1a64(buffer, size);

    // Try cache first
    std::string cached;
    bool haveCached = BytecodeCache::get(filename, h, cached);
    int loadResult;
    if (haveCached)
    {
        free(buffer);
        loadResult = luau_load(L, filename, cached.data(), cached.size(), 0);
    }
    else
    {
        // Compile using Luau
        size_t bytecodeSize;
        char* bytecode = luau_compile(buffer, size, &g_compile_opts, &bytecodeSize);
        free(buffer);

        if (!bytecode) {
            if (gcWasRunning)
                lua_gc(L, LUA_GCRESTART, 0);
            lua_pushfstring(L, "cannot compile %s", filename);
            return LUA_ERRSYNTAX;
        }

        // Load the bytecode
        loadResult = luau_load(L, filename, bytecode, bytecodeSize, 0);

        // Store in cache
        BytecodeCache::put(filename, h, bytecode, bytecodeSize);
        free(bytecode);
    }
    
    // If load succeeded, optionally compile to native code (LuaJIT-like speed-ups)
    if (loadResult == 0 && g_codegen_enabled)
    {
#ifdef HXLUAU_WITH_CODEGEN
        if (luau_codegen_supported())
        {
            lua_State* mainL = lua_mainthread(L);
            auto it = g_codegen_created.find(mainL);
            if (it == g_codegen_created.end() || !it->second)
            {
                luau_codegen_create(mainL);
                g_codegen_created[mainL] = true;
            }
            // Compile function at top of the stack
            luau_codegen_compile(L, -1);
        }
#endif
    }
    if (gcWasRunning)
        lua_gc(L, LUA_GCRESTART, 0);
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

// VM soft reset: collect & reset main thread without destroying VM
void hxluau_vm_soft_reset(lua_State* L)
{
    int running = lua_gc(L, LUA_GCISRUNNING, 0);
    if (running)
        lua_gc(L, LUA_GCSTOP, 0);
    // Full collect to reduce footprint between reloads
    lua_gc(L, LUA_GCCOLLECT, 0);
    if (running)
        lua_gc(L, LUA_GCRESTART, 0);

    // Reset main thread state
    lua_resetthread(lua_mainthread(L));
}
// -----------------------------
// Optional native codegen (AOT)
// -----------------------------
bool g_codegen_enabled = false;
std::unordered_map<lua_State*, bool> g_codegen_created;
