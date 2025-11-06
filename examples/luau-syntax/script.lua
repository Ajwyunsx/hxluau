-- Luau 类型注解示例
local function greet(name: string, age: number): string
	return "Hello, " .. name .. "! You are " .. age .. " years old."
end

print(greet("Alice", 30))

-- Luau 类型推断
local numbers: {number} = {1, 2, 3, 4, 5}
local total = 0
for _, num in ipairs(numbers) do
	total += num  -- Luau 支持复合赋值运算符
end
print("Total: " .. total)

-- Luau 字典类型
local person: {name: string, age: number} = {
	name = "Bob",
	age = 25
}
print("Person: " .. person.name .. ", age: " .. person.age)

-- Luau 联合类型 (模拟)
local function processValue(value: any)
	if type(value) == "string" then
		print("Got string: " .. value)
	elseif type(value) == "number" then
		print("Got number: " .. value)
	else
		print("Got other type: " .. type(value))
	end
end

processValue("Hello")
processValue(42)
processValue({x = 1, y = 2})

local a = 1
a += 20
print(a)

-- Luau 索引器类型 (模拟)
local config: {[string]: any} = {
	theme = "dark",
	version = "1.0",
	active = true
}

for key, value in pairs(config) do
	print(key .. " = " .. tostring(value))
end

-- Luau 的 table 库增强功能
local fruits = {"apple", "banana", "cherry"}
table.insert(fruits, "date")
print("Fruits: " .. table.concat(fruits, ", "))

-- Luau 支持的 for 循环
for i = 1, 3 do
	print("for loop: " .. i)
end

-- 使用 method 调用语法 (Luau 兼容)
local obj = {x = 10, y = 20}
function obj:move(dx, dy)
	self.x += dx
	self.y += dy
end

obj:move(5, -5)
print("Object position: (" .. obj.x .. ", " .. obj.y .. ")")

-- Luau 的位运算 (如果可用)
if bit32 then
	local a = 12
	local b = 10
	print("Bitwise AND: " .. bit32.band(a, b))
	print("Bitwise OR: " .. bit32.bor(a, b))
	print("Bitwise XOR: " .. bit32.bxor(a, b))
end
