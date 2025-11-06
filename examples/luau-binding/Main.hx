package;

import luau.Lua;
import luau.LuaL;
import luau.State;
import hxluau.Types;
import cpp.Callable;

/**
 * 示例：使用 source/luau 目录中的 Luau 绑定
 * 这个示例展示了如何使用 hxluau 库来访问 Luau 功能
 */
class Main {
    // 定义 Haxe 函数，将被注册到 Luau
    static function myAddFunction(L:cpp.RawPointer<hxluau.Lua_State>):Int {
        var sum:Float = 0.0;
        final n:Int = Lua.gettop(L);
        
        // 计算所有参数的和
        for (i in 0...n) {
            if (!Lua.isnumber(L, i + 1)) {
                Lua.pushstring(L, "Incorrect argument to 'myAdd'");
                Lua.error(L);
                return 0;
            }
            sum += Lua.tonumber(L, i + 1);
        }
        
        Lua.pushnumber(L, sum); // 推入结果
        return 1; // 返回结果数量
    }
    
    static function myGreetFunction(L:cpp.RawPointer<hxluau.Lua_State>):Int {
        if (Lua.gettop(L) < 1) {
            Lua.pushstring(L, "Not enough arguments to 'myGreet'");
            Lua.error(L);
            return 0;
        }
        
        var name = LuaL.checkstring(L, 1);
        var greeting = "Hello, " + name + "!";
        Lua.pushstring(L, greeting);
        return 1;
    }
    
    public static function main() {
        Sys.println("Luau Binding Example - Using hxluau bindings from source/luau");
        
        // 创建一个新的 Luau 状态
        var L:State = LuaL.newstate();
        
        // 打开所有标准库
        LuaL.openlibs(L);
        
        // 初始化回调函数，确保 print 函数被正确注册
        Lua.init_callbacks(L);
        
        // 注册 Haxe 函数到 Luau
        Lua.register(L, "myAdd", cpp.Callable.fromStaticFunction(myAddFunction));
        Lua.register(L, "myGreet", cpp.Callable.fromStaticFunction(myGreetFunction));
        
        // 读取并运行脚本文件
        Sys.println("\n--- Running Luau script from file ---");
        var scriptContent:String = sys.io.File.getContent("script.lua");
        var result = LuaL.dostring(L, scriptContent);
        
        if (result != 0) {
            Sys.println("Error running script: " + result);
        }
        
        // 清理
        Lua.close(L);
        
        Sys.println("\nLuau binding example completed successfully!");
    }
}