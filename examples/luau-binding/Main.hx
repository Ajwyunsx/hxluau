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
        var a = LuaL.checknumber(L, 1);
        var b = LuaL.checknumber(L, 2);
        var result = a + b;
        Lua.pushnumber(L, result);
        return 1; // 返回值的数量
    }
    
    static function myGreetFunction(L:cpp.RawPointer<hxluau.Lua_State>):Int {
        var name = LuaL.checkstring(L, 1);
        var greeting = "Hello, " + name + "!";
        Lua.pushstring(L, greeting);
        return 1;
    }
    
    public static function main() {
        trace("Luau Binding Example - Using hxluau bindings from source/luau");
        
        // 创建一个新的 Luau 状态
        var L:State = LuaL.newstate();
        
        // 打开所有标准库
        LuaL.openlibs(L);
        
        // 示例 1: 基本操作
        trace("\n--- Example 1: Basic Operations ---");
        var script1 = '
            local result = 5 + 3
            print("5 + 3 =", result)
            
            local mul_result = 4 * 6
            print("4 * 6 =", mul_result)
        ';
        
        if (LuaL.loadstring(L, script1) == Lua.OK) {
            if (Lua.pcall(L, 0, 0, 0) != Lua.OK) {
                var error = Lua.tostring(L, -1);
                trace("Error: " + error);
            }
        } else {
            var error = Lua.tostring(L, -1);
            trace("Load Error: " + error);
        }
        
        // 示例 2: 注册一个 C++ 函数并从 Luau 调用
        trace("\n--- Example 2: Registering C++ Functions ---");
        
        // 注册函数到 Luau
        Lua.register(L, "myAdd", cpp.Callable.fromStaticFunction(myAddFunction));
        Lua.register(L, "myGreet", cpp.Callable.fromStaticFunction(myGreetFunction));
        
        var script2 = '
            local sum = myAdd(10, 20)
            print("myAdd(10, 20) =", sum)
            
            local greeting = myGreet("Luau User")
            print(greeting)
        ';
        
        if (LuaL.loadstring(L, script2) == Lua.OK) {
            if (Lua.pcall(L, 0, 0, 0) != Lua.OK) {
                var error = Lua.tostring(L, -1);
                trace("Error: " + error);
            }
        } else {
            var error = Lua.tostring(L, -1);
            trace("Load Error: " + error);
        }
        
        // 示例 3: 与 Luau 状态交互 - 从 C++ 读取 Luau 变量
        trace("\n--- Example 3: Interacting with Luau State from Haxe ---");
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
        ';
        
        if (LuaL.loadstring(L, script3) == Lua.OK) {
            if (Lua.pcall(L, 0, 0, 0) != Lua.OK) {
                var error = Lua.tostring(L, -1);
                trace("Error: " + error);
            }
        } else {
            var error = Lua.tostring(L, -1);
            trace("Load Error: " + error);
        }
        
        // 从 C++ 获取 Luau 变量
        Lua.getglobal(L, "myVariable");
        if (Lua.type(L, -1) == Lua.TNUMBER) {
            var value = Lua.tonumber(L, -1);
            trace("Retrieved myVariable from Luau: " + value);
        }
        Lua.pop(L, 1); // 从堆栈中移除值
        
        // 调用 Luau 函数从 C++
        Lua.getglobal(L, "multiply");
        Lua.pushnumber(L, 7);
        Lua.pushnumber(L, 8);
        if (Lua.pcall(L, 2, 1, 0) == Lua.OK) {
            if (Lua.type(L, -1) == Lua.TNUMBER) {
                var result = Lua.tonumber(L, -1);
                trace("Called multiply(7, 8) from C++: " + result);
            }
        } else {
            var error = Lua.tostring(L, -1);
            trace("Error calling function: " + error);
        }
        Lua.pop(L, 1); // 从堆栈中移除结果
        
        // 示例 4: 使用表
        trace("\n--- Example 4: Working with Tables ---");
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
        
        if (LuaL.loadstring(L, script4) == Lua.OK) {
            if (Lua.pcall(L, 0, 0, 0) != Lua.OK) {
                var error = Lua.tostring(L, -1);
                trace("Error: " + error);
            }
        } else {
            var error = Lua.tostring(L, -1);
            trace("Load Error: " + error);
        }
        
        // 清理
        Lua.close(L);
        
        trace("\nLuau binding example completed successfully!");
    }
}