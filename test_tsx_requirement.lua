#!/usr/bin/env lua

-- Test tsx --test requirement
print("Testing tsx --test requirement")
print("==============================")

-- Test the hasTsxTestScriptInJson function (simple string check)
local function hasTsxTestScriptInJson(packageJsonContent)
  return packageJsonContent:find("tsx%s+--test") ~= nil
end

-- Test with our package.json (should pass)
local f1 = io.open("package.json", "r")
if f1 then
    local content1 = f1:read("*all")
    f1:close()
    local hasTsxTest1 = hasTsxTestScriptInJson(content1)
    print(string.format("✓ Our package.json has 'tsx --test': %s", hasTsxTest1 and "PASS" or "FAIL"))
else
    print("✗ Cannot read package.json")
end

-- Test with the no-tsx package.json (should fail)
local f2 = io.open("test_package_no_tsx.json", "r")
if f2 then
    local content2 = f2:read("*all")
    f2:close()
    local hasTsxTest2 = hasTsxTestScriptInJson(content2)
    print(string.format("✓ Test package.json without 'tsx --test': %s", not hasTsxTest2 and "PASS" or "FAIL"))
else
    print("✗ Cannot read test_package_no_tsx.json")
end

print("\n==============================")
print("Tsx --test requirement test completed!")