package;

import luau.Lua;
import luau.LuaL;
import luau.State;
import hxluau.LuaOpen;
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
            if (Lua.isnumber(L, i + 1) == 0)
                LuaL.error(L, "Incorrect argument to 'myAdd'");
            sum += Lua.tonumber(L, i + 1);
        }
        
        Lua.pop(L, n); // 清除堆栈
        Lua.pushnumber(L, sum); // 推入结果
        return 1; // 返回结果数量
    }
    
    static function myGreetFunction(L:cpp.RawPointer<hxluau.Lua_State>):Int {
        if (Lua.gettop(L) < 1) {
            LuaL.error(L, "Not enough arguments to 'myGreet'");
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
        
        // 示例 1: 基本操作
        Sys.println("\n--- Example 1: Basic Operations ---");
        var script1 = '
            local result = 5 + 3
            print("5 + 3 =", result)
            
            local mul_result = 4 * 6
            print("4 * 6 =", mul_result)
        ';
        
        var result = LuaL.dostring(L, script1);
        if (result != 0) {
            Sys.println("Error running script: " + result);
        }
        
        // 示例 2: 注册一个 C++ 函数并从 Luau 调用
        Sys.println("\n--- Example 2: Registering C++ Functions ---");
        
        // 手动注册函数到 Luau - 使用 pushcfunction 并提供 debugname 参数
        Lua.pushcfunction(L, cpp.Callable.fromStaticFunction(myAddFunction), "myAdd");
        Lua.setglobal(L, "myAdd");
        
        Lua.pushcfunction(L, cpp.Callable.fromStaticFunction(myGreetFunction), "myGreet");
        Lua.setglobal(L, "myGreet");
        
        var script2 = '
            local sum = myAdd(10, 20, 30, 40, 50)
            print("myAdd(10, 20, 30, 40, 50) =", sum)
            
            local greeting = myGreet("Luau User")
            print(greeting)
        ';
        
        result = LuaL.dostring(L, script2);
        if (result != 0) {
            Sys.println("Error running script: " + result);
        }
        
        // 示例 3: 与 Luau 状态交互 - 从 C++ 读取 Luau 变量
        Sys.println("\n--- Example 3: Interacting with Luau State from Haxe ---");
        var script3 = '
            -- 在 Luau 中定义一个变量
            myVariable = 42
            
            -- 在 Luau 中定义一个函数
            function multiply(x, y)
                return x * y
            end
            
            -- 创建一个表
            myTable = {
                x = 100,
                y = 200,
                name = "test_table"
            }
            
            print("Luau variables and function created")
        ';
        
        result = LuaL.dostring(L, script3);
        if (result != 0) {
            Sys.println("Error running script: " + result);
        }
        
        // 从 C++ 获取 Luau 变量
        Lua.getglobal(L, "myVariable");
        if (Lua.type(L, -1) == Lua.TNUMBER) {
            var value = Lua.tonumber(L, -1);
            Sys.println("Retrieved myVariable from Luau: " + value);
        }
        Lua.pop(L, 1); // 从堆栈中移除值
        
        // 调用 Luau 函数从 C++
        Lua.getglobal(L, "multiply");
        Lua.pushnumber(L, 7);
        Lua.pushnumber(L, 8);
        if (Lua.pcall(L, 2, 1, 0) == Lua.OK) {
            if (Lua.type(L, -1) == Lua.TNUMBER) {
                var result = Lua.tonumber(L, -1);
                Sys.println("Called multiply(7, 8) from C++: " + result);
            }
        } else {
            var error = Lua.tostring(L, -1);
            Sys.println("Error calling function: " + error);
        }
        Lua.pop(L, 1); // 从堆栈中移除结果
        
        // 示例 4: 使用表
        Sys.println("\n--- Example 4: Working with Tables ---");
        var script4 = '
            local fruits = {"apple", "banana", "orange"}
            
            print("Fruits:")
            for i, fruit in ipairs(fruits) do
                print("  " .. i .. ": " .. fruit)
            end
            
            local person = {
                name = "Alice",
                age = 30,
                city = "New York"
            }
            
            print("\nPerson info:")
            print("  Name:", person.name)
            print("  Age:", person.age)
            print("  City:", person.city)
        ';
        
        result = LuaL.dostring(L, script4);
        if (result != 0) {
            Sys.println("Error running script: " + result);
        }
        
        // 清理
        Lua.close(L);
        
        Sys.println("\nLuau binding example completed successfully!");
    }
}