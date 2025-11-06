print("Hello from Luau!")

-- 基本运算
local x = 10
local y = 20
print("10 + 20 =", x + y)

-- 表操作
local colors = {"red", "green", "blue"}
print("Colors:")
for i, color in ipairs(colors) do
    print("  " .. color)
end

-- 局部函数
function test()
    print("Inside function")
end
test()