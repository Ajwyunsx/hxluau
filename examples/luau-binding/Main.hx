package;

import luau.Lua;
import luau.LuaL;
import luau.State;

class Main {
    public static function main() {
        Sys.println("Luau Example - Reading script file");
        
        // 创建一个新的 Luau 状态
        var L:State = LuaL.newstate();
        
        // 打开所有标准库
        LuaL.openlibs(L);
        
        // 初始化回调函数，确保 print 函数被正确注册
        Lua.init_callbacks(L);
        
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