package llua;

#if !cpp
#error 'LuaJIT supports only C++ target platforms.'
#end
import hxluajit.Types;

typedef State = cpp.RawPointer<hxluajit.Lua_State>;
typedef StatePointer = cpp.RawPointer<hxluajit.Lua_State>;
