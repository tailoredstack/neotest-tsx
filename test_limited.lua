#!/usr/bin/env lua

-- Test script for neotest-tsx adapter
-- Tests basic functionality that doesn't require full Neovim runtime

print("Testing neotest-tsx adapter (limited)")
print("=====================================")

-- Set up package path
package.path = package.path .. ";lua/?.lua;lua/?/init.lua"

-- Test 1: Check if files exist
print("\n1. Checking file structure:")
local files = {
    "lua/neotest-tsx/init.lua",
    "lua/neotest-tsx/util.lua",
    "README.md",
    "package.json",
    "tests/basic.test.ts"
}

for _, file in ipairs(files) do
    local exists = io.open(file, "r") ~= nil
    print(string.format("   - %s: %s", file, exists and "✓ EXISTS" or "✗ MISSING"))
end

-- Test 2: File readability check
print("\n2. File readability check:")
local lua_files = {
    "lua/neotest-tsx/init.lua",
    "lua/neotest-tsx/util.lua"
}

for _, file in ipairs(lua_files) do
    local f = io.open(file, "r")
    if f then
        local content = f:read("*all")
        f:close()
        local lines = 0
        for _ in content:gmatch("\n") do lines = lines + 1 end
        print(string.format("   - %s: ✓ READABLE (%d lines)", file, lines + 1))
    else
        print(string.format("   - %s: ✗ CANNOT READ", file))
    end
end

-- Test 3: Check TypeScript test files
print("\n3. TypeScript test file validation:")
local ts_files = {
    "tests/basic.test.ts",
    "tests/advanced.test.ts",
    "tests/example.spec.ts",
    "tests/failing.test.ts"
}

for _, file in ipairs(ts_files) do
    local f = io.open(file, "r")
    if f then
        local content = f:read("*all")
        f:close()

        -- Check for node:test imports
        local has_node_test = content:find("node:test") ~= nil
        -- Check for test patterns
        local has_describe = content:find("describe") ~= nil
        local has_it = content:find("it%(") ~= nil or content:find("test%(") ~= nil

        local valid = has_node_test and (has_describe or has_it)
        print(string.format("   - %s: %s", file, valid and "✓ VALID TEST FILE" or "⚠ MAYBE INVALID"))
    else
        print(string.format("   - %s: ✗ CANNOT READ", file))
    end
end

-- Test 4: Check package.json
print("\n4. Package.json validation:")
local f = io.open("package.json", "r")
if f then
    local content = f:read("*all")
    f:close()

    local has_tsx = content:find('"tsx"') ~= nil
    local has_test_script = content:find('"test"') ~= nil
    local has_tsx_test = content:find("tsx%s+--test") ~= nil
    local is_module = content:find('"type": "module"') ~= nil

    print(string.format("   - Has tsx dependency: %s", has_tsx and "✓" or "✗"))
    print(string.format("   - Has test script: %s", has_test_script and "✓" or "✗"))
    print(string.format("   - Has 'tsx --test' script: %s", has_tsx_test and "✓" or "✗"))
    print(string.format("   - Is ES module: %s", is_module and "✓" or "✗"))
else
    print("   - package.json: ✗ CANNOT READ")
end

print("\n================================")
print("Limited test completed!")
print("For full functionality testing, use Neovim with test_adapter.vim")