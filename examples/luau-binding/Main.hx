package;

import luau.Lua;
import luau.LuaL;
import luau.State;
import hxluau.Types;
import cpp.Callable;

class Main {
    static function customPrint(L:cpp.RawPointer<hxluau.Lua_State>):Int {
        final nargs:Int = Lua.gettop(L);
        
        for (i in 0...nargs) {
            final str = Lua.tostring(L, i + 1);
            if (str != null) {
                final msg:String = str;
                Sys.println(msg);
                Sys.stdout().flush();
            }
        }
        
        return 0;
    }
    public static function main() {
        Sys.println("Luau Example - Reading script file");
        
        // 创建一个新的 Luau 状态
        var L:State = LuaL.newstate();
        
        // 打开所有标准库
        LuaL.openlibs(L);
        
        // 注册自定义print函数，确保输出可见
        Lua.register(L, "print", cpp.Callable.fromStaticFunction(customPrint));
        
        // 读取并运行脚本文件
        Sys.println("\n--- Running script.lua ---");
        var scriptContent:String = sys.io.File.getContent("script.lua");
        var result = LuaL.dostring(L, scriptContent);
        
        if (result != 0) {
            Sys.println("Error running script: " + result);
        }
        
        // 清理
        Lua.close(L);
        
        Sys.println("\nExample completed!");
    }
}