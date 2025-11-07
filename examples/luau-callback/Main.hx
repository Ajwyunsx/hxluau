package;

import luau.Lua;
import luau.LuaL;
import luau.State;
import luau.Convert;
import luau.LuaCallback;

class Main {
    public static function main():Void {
        var L:State = LuaL.newstate();
        LuaL.openlibs(L);
        Lua.init_callbacks(L);

        // Register Haxe callbacks into Lua globals
        Lua_helper.add_callback(L, "sum", sum);
        Lua_helper.add_callback(L, "multi", multi);

        // Also demonstrate passing a Haxe function as an argument
        Lua_helper.add_callback(L, "haxeCb", sum);

        // Run script
        var code = sys.io.File.getContent("script.lua");
        var status = LuaL.dostring(L, code);
        if (status != Lua.OK) {
            var err:String = cast(Lua.tostring(L, -1), String);
            Lua.pop(L, 1);
            Sys.println('Luau error: ' + (err != null ? err : 'unknown'));
        }

        // --- Engine-style call(funcName, args) 示例 ---
        // 预检：查看全局函数类型
        Lua.getglobal(L, "call_with_callback");
        var gtype0 = Lua.type(L, -1);
        Sys.println('global call_with_callback type (before calls) = ' + gtype0);
        Lua.pop(L, 1);
        // 1) 将 Lua 全局函数 sum 封装为 LuaCallback 传入
        Lua.getglobal(L, "sum");
        // 正确将函数引用保存在注册表中：传入栈索引（-1 表示栈顶）
        var sumRef:Int = Lua.ref(L, -1);
        var sumCb = new LuaCallback(cpp.Pointer.fromRaw(L), sumRef);
        var r1 = Caller.luaCall(L, "call_with_callback", [sumCb, 11, 22]);
        Lua.getglobal(L, "call_with_callback");
        var gtype1 = Lua.type(L, -1);
        Sys.println('global call_with_callback type (after #1) = ' + gtype1);
        Lua.pop(L, 1);
        Sys.println('luaCall(call_with_callback, [LuaCallback,sum]): ' + r1);

        // 2) 直接传入 Haxe 函数（由 Convert.toLua 封装为 C 闭包）
        var r2 = Caller.luaCall(L, "call_with_callback", [sum, 33, 44]);
        Lua.getglobal(L, "call_with_callback");
        var gtype2 = Lua.type(L, -1);
        Sys.println('global call_with_callback type (after #2) = ' + gtype2);
        Lua.pop(L, 1);
        Sys.println('luaCall(call_with_callback, [Haxe sum]): ' + r2);

        // Inspect _G and its entry for call_with_callback
        Lua.getglobal(L, "_G");
        var gt = Lua.type(L, -1);
        Sys.println('_G type = ' + gt);
        Lua.getfield(L, -1, "call_with_callback");
        var entryType = Lua.type(L, -1);
        Sys.println('_G.call_with_callback type = ' + entryType);
        Lua.pop(L, 2);

        // Inspect global type for call_with_callback
        Lua.getglobal(L, "call_with_callback");
        var gtype = Lua.type(L, -1);
        Sys.println('global call_with_callback type (after calls) = ' + gtype);
        Lua.pop(L, 1);

        Lua.close(L);
        L = null;
    }

    // Simple callback: returns a + b
    static function sum(a:Dynamic, b:Dynamic):Dynamic {
        var x:Float = Std.isOfType(a, Float) || Std.isOfType(a, Int) ? a : Std.parseFloat(Std.string(a));
        var y:Float = Std.isOfType(b, Float) || Std.isOfType(b, Int) ? b : Std.parseFloat(Std.string(b));
        return x + y;
    }

    // Multi-return: returns {a, b, a+b}
    static function multi(a:Dynamic, b:Dynamic):Dynamic {
        var x:Float = Std.isOfType(a, Float) || Std.isOfType(a, Int) ? a : Std.parseFloat(Std.string(a));
        var y:Float = Std.isOfType(b, Float) || Std.isOfType(b, Int) ? b : Std.parseFloat(Std.string(b));
        return [x, y, x + y];
    }
}

// 仿照引擎 FunkinLua.call 的实现，用于示例
class Caller {
    public static function luaCall(L:State, func:String, args:Array<Dynamic>):Dynamic {
        Lua.getglobal(L, func);
        var type:Int = Lua.type(L, -1);
        if (!Lua.isfunction(L, -1)) {
            var tname = Lua.typename(L, type);
            if (type > Lua.LUA_TNIL) Sys.println('ERROR (' + func + '): attempt to call a ' + tname + ' value');
            Lua.pop(L, 1);
            return null;
        }
        var seq = 0;
        for (arg in args) {
            // Special-case function arguments to ensure Lua sees them as callable
            if (Std.isOfType(arg, LuaCallback)) {
                var cb:LuaCallback = cast arg;
                Lua.rawgeti(L, Lua.REGISTRYINDEX, cb.ref);
            } else if (Type.typeof(arg) == TFunction) {
                var fname = 'hxluau_argcb_' + (seq++);
                @:privateAccess Lua_helper.callbacks.set(fname, arg);
                Lua.pushstring(L, fname);
                Lua.pushcclosure(L, cpp.Callable.fromStaticFunction(@:privateAccess Lua_helper.callback_handler), fname, 1);
            } else {
                Convert.toLua(L, arg);
            }
        }
        // Debug: inspect argument types just before pcall
        if (args != null && args.length > 0) {
            for (i in 0...args.length) {
                var idx = -(args.length - i);
                var at = Lua.type(L, idx);
                Sys.println('arg[' + i + '] type = ' + at);
            }
        }
        var fidx = - (args.length + 1);
        var calleeType = Lua.type(L, fidx);
        Sys.println('callee type at ' + fidx + ' = ' + calleeType);
        Sys.stdout().flush();
        var status:Int = Lua.pcall(L, args.length, 1, 0);
        if (status != Lua.OK) {
            var err = cast(Lua.tostring(L, -1), String);
            Lua.pop(L, 1);
            Sys.println('ERROR (' + func + '): ' + (err != null ? err : 'unknown'));
            return null;
        }
        var result:Dynamic = cast Convert.fromLua(L, -1);
        Lua.pop(L, 1);
        return result;
    }
}