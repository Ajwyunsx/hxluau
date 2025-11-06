package luau;

#if !cpp
#error 'Luau supports only C++ target platforms.'
#end
import hxluau.Types;

typedef State = cpp.RawPointer<hxluau.Lua_State>;
typedef StatePointer = cpp.RawPointer<hxluau.Lua_State>;
