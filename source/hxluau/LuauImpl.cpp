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
#include <list>
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
    struct Entry
    {
        std::string bytecode;
        uint64_t hash;
    };

    typedef std::list<std::string> OrderList;

    static std::unordered_map<std::string, Entry>& data()
    {
        static std::unordered_map<std::string, Entry> inst;
        return inst;
    }

    static OrderList& order()
    {
        static OrderList inst;
        return inst;
    }

    static std::unordered_map<std::string, OrderList::iterator>& orderPos()
    {
        static std::unordered_map<std::string, OrderList::iterator> inst;
        return inst;
    }

    static size_t& capacity()
    {
        static size_t cap = 128; // increased default cache size for better hit rates
        return cap;
    }

    static void setCapacity(size_t cap)
    {
        capacity() = cap > 0 ? cap : 1;
        // Trim if necessary
        while (order().size() > capacity())
        {
            const std::string& victim = order().front();
            data().erase(victim);
            orderPos().erase(victim);
            order().pop_front();
        }
    }

    static void clear()
    {
        data().clear();
        orderPos().clear();
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

    // Returns a pointer to the cached bytecode, or NULL on miss. O(1) hit path:
    // single map lookup, no bytecode copy, no linear LRU scan.
    static const std::string* get(const std::string& key, uint64_t h)
    {
        auto di = data().find(key);
        if (di == data().end() || di->second.hash != h)
            return NULL;

        // Refresh LRU position in O(1) via a stored list iterator
        auto pi = orderPos().find(key);
        if (pi != orderPos().end())
        {
            OrderList& ord = order();
            ord.splice(ord.end(), ord, pi->second);
            pi->second = --ord.end();
        }
        return &di->second.bytecode;
    }

    static void put(const std::string& key, uint64_t h, const char* bytecode, size_t size)
    {
        Entry& e = data()[key];
        e.hash = h;
        e.bytecode.assign(bytecode, size);

        // Refresh/insert LRU position in O(1)
        OrderList& ord = order();
        auto pi = orderPos().find(key);
        if (pi != orderPos().end())
            ord.splice(ord.end(), ord, pi->second);
        else
            orderPos()[key] = ord.insert(ord.end(), key);

        // evict if needed
        while (ord.size() > capacity())
        {
            const std::string& victim = ord.front();
            data().erase(victim);
            orderPos().erase(victim);
            ord.pop_front();
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
    /*optimizationLevel*/ 2, // prefer higher optimization by default
    /*debugLevel*/ 0,        // reduce debug info for faster code
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

// Pause GC only for large compiles; small scripts skip the 2-3 gc calls entirely.
static inline int gcPauseForLoad(lua_State* L, size_t sourceSize)
{
    if (sourceSize < 16384)
        return 0;
    int gcWasRunning = lua_gc(L, LUA_GCISRUNNING, 0);
    if (gcWasRunning)
        lua_gc(L, LUA_GCSTOP, 0);
    return gcWasRunning;
}

static inline void gcResumeAfterLoad(lua_State* L, int gcWasRunning)
{
    if (gcWasRunning)
        lua_gc(L, LUA_GCRESTART, 0);
}

// Wrapper for luaL_loadstring functionality using Luau
int hxluau_LuaL_loadstring_wrapper(lua_State* L, const char* s) {
    size_t s_len = strlen(s);

    int gcWasRunning = gcPauseForLoad(L, s_len);

    // Cache repeated loads of small sources (hot-reload loops) keyed by source text
    const bool cacheable = (s_len > 0 && s_len <= 16384);
    uint64_t h = 0;
    const std::string* cached = NULL;
    if (cacheable)
    {
        h = BytecodeCache::fnv1a64(s, s_len);
        cached = BytecodeCache::get(s, h);
        if (cached)
        {
            gcResumeAfterLoad(L, gcWasRunning);
            return luau_load(L, "string", cached->data(), cached->size(), 0);
        }
    }

    size_t bytecodeSize;
    char* bytecode = luau_compile(s, s_len, &g_compile_opts, &bytecodeSize);
    
    if (!bytecode) {
        gcResumeAfterLoad(L, gcWasRunning);
        lua_pushfstring(L, "cannot compile string");
        return LUA_ERRSYNTAX;
    }
    
    // Load the bytecode
    int loadResult = luau_load(L, "string", bytecode, bytecodeSize, 0);

    if (loadResult == 0 && cacheable)
        BytecodeCache::put(s, h, bytecode, bytecodeSize);
    
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
    gcResumeAfterLoad(L, gcWasRunning);
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

    int gcWasRunning = gcPauseForLoad(L, size);
    
    // Compute content hash for cache lookup
    uint64_t h = BytecodeCache::fnv1a64(buffer, size);

    // Try cache first (single map lookup, no bytecode copy on hit)
    const std::string* cached = BytecodeCache::get(filename, h);
    int loadResult;
    if (cached)
    {
        free(buffer);
        loadResult = luau_load(L, filename, cached->data(), cached->size(), 0);
    }
    else
    {
        // Compile using Luau
        size_t bytecodeSize;
        char* bytecode = luau_compile(buffer, size, &g_compile_opts, &bytecodeSize);
        free(buffer);

        if (!bytecode) {
            gcResumeAfterLoad(L, gcWasRunning);
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
    gcResumeAfterLoad(L, gcWasRunning);
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
    if (n <= 0)
    {
        fputc('\n', stdout);
        return 0;
    }
    // Build the whole line in one buffer, then emit it with a single write.
    // Avoids per-character fputc calls on log-heavy scripts.
    std::string line;
    line.reserve(256);
    for (int i = 1; i <= n; i++) {
        const char* s = lua_tolstring(L, i, NULL);
        if (!s) {
            // Convert non-strings to string
            luaL_tolstring(L, i, NULL);
            s = lua_tolstring(L, -1, NULL);
            // remove temporary string
            lua_remove(L, -2);
        }
        if (s)
            line.append(s);
        else
            line.append("nil");
        if (i < n) line.push_back('\t');
    }
    line.push_back('\n');
    fwrite(line.data(), 1, line.size(), stdout);
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
// Enable codegen by default to improve runtime speed on supported platforms (LuaJIT-like behavior)
bool g_codegen_enabled = true;
std::unordered_map<lua_State*, bool> g_codegen_created;

// -----------------------------
// Autocompile (hot-counter) support
// -----------------------------
static std::unordered_map<const void*, int> g_hot_counters;
static int g_autocompile_threshold = 1000; // default threshold
static bool g_autocompile_enabled = false;

// Hook called on function calls; will push the function on the stack via lua_getinfo("f")
static void hxluau_call_hook(lua_State* L, lua_Debug* ar)
{
    if (!g_autocompile_enabled)
        return;

    // Only attempt to autocompile if codegen is supported
#ifdef HXLUAU_WITH_CODEGEN
    if (!luau_codegen_supported())
        return;

    // Push the current function onto the stack
    // Luau's lua_getinfo signature is (L, level, what, ar)
    if (lua_getinfo(L, 0, "f", ar))
    {
        const void* funcptr = lua_topointer(L, -1);
        if (funcptr)
        {
            int& cnt = g_hot_counters[funcptr];
            ++cnt;
            if (cnt >= g_autocompile_threshold)
            {
                // Ensure codegen is created for main thread
                lua_State* mainL = lua_mainthread(L);
                auto it = g_codegen_created.find(mainL);
                if (it == g_codegen_created.end() || !it->second)
                {
                    luau_codegen_create(mainL);
                    g_codegen_created[mainL] = true;
                }

                // Compile the function at top of stack
                luau_codegen_compile(L, -1);

                // Mark compiled (prevent repeated compiles)
                cnt = INT_MIN / 2;
            }
        }

        // remove pushed function
        lua_pop(L, 1);
    }
#endif
}

// Lower-overhead interrupt hook: called at VM safepoints (loop back edges, call/ret, gc)
static void hxluau_interrupt_hook(lua_State* L, int gc)
{
    if (!g_autocompile_enabled)
        return;

#ifdef HXLUAU_WITH_CODEGEN
    if (!luau_codegen_supported())
        return;

    // lua_getinfo + map ops are far too costly to run at every safepoint.
    // Sample sparsely: only every 256th safepoint runs the expensive path.
    static int tick = 0;
    if ((++tick & 0xFF) != 0)
        return;

    // Bound the hot-counter map so long-running apps don't grow it without limit
    if (g_hot_counters.size() > 4096)
        g_hot_counters.clear();

    lua_Debug ar;
    // Use level 0 to get current function on top of the stack
    if (lua_getinfo(L, 0, "f", &ar))
    {
        const void* funcptr = lua_topointer(L, -1);
        if (funcptr)
        {
            int& cnt = g_hot_counters[funcptr];
            // Count in sampling-sized increments to keep the threshold meaningful
            cnt += 256;
            if (cnt >= g_autocompile_threshold)
            {
                lua_State* mainL = lua_mainthread(L);
                auto it = g_codegen_created.find(mainL);
                if (it == g_codegen_created.end() || !it->second)
                {
                    luau_codegen_create(mainL);
                    g_codegen_created[mainL] = true;
                }
                luau_codegen_compile(L, -1);
                cnt = INT_MIN / 2;
            }
        }

        // remove pushed function
        lua_pop(L, 1);
    }
#endif
}

// Enable or disable the autocompile hook for a given state
void hxluau_enable_autocompile(lua_State* L, int enable)
{
    g_autocompile_enabled = (enable != 0);
    if (g_autocompile_enabled)
    {
        // Install lower-overhead hook via Luau's interrupt callback (safepoints)
        lua_Callbacks* cbs = lua_callbacks(L);
        if (cbs)
            cbs->interrupt = hxluau_interrupt_hook;
    }
    else
    {
        lua_Callbacks* cbs = lua_callbacks(L);
        if (cbs)
            cbs->interrupt = NULL;
    }
}

// Set the hot-call threshold
void hxluau_set_autocompile_threshold(int threshold)
{
    if (threshold <= 0)
        threshold = 1;
    g_autocompile_threshold = threshold;
}
