print("calling sum(10, 20)")
local s = sum(10, 20)
print("sum:", s)

print("calling multi(3, 5)")
local a, b, c = multi(3, 5)
print("multi:", a, b, c)

-- Define a Lua-side function that accepts a callback and arguments,
-- then invokes the callback and returns its result
function call_with_callback(cb, x, y)
    print("cb type:", type(cb))
    local r = cb(x, y)
    print("call_with_callback:", r)
    return r
end

print("calling call_with_callback(sum, 7, 8)")
local r = call_with_callback(sum, 7, 8)
print("result:", r)