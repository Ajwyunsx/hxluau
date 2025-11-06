print("=== Luau Binding Example ===")

-- 基本运算
local a = 10
local b = 20
local sum = a + b
print("Sum of " .. a .. " and " .. b .. " is " .. sum)

-- 表操作
local fruits = {"apple", "banana", "orange"}
print("Fruits:")
for i, fruit in ipairs(fruits) do
    print("  " .. i .. ". " .. fruit)
end

-- 函数调用测试
function greet(name)
    return "Hello, " .. name .. "!"
end

local message = greet("Luau User")
print(message)

-- 测试 Haxe 函数调用
local addResult = myAdd(5, 3)
print("myAdd(5, 3) = " .. addResult)

local greetResult = myGreet("World")
print("myGreet('World') = " .. greetResult)

print("=== Example completed ===")