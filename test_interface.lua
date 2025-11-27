#!/usr/bin/env lua

-- Test neotest adapter interface compliance
-- Checks if the adapter follows the expected structure

print("Testing neotest-tsx adapter interface compliance")
print("================================================")

-- Read the adapter file
local f = io.open("lua/neotest-tsx/init.lua", "r")
if not f then
    print("❌ Cannot read adapter file")
    return
end

local content = f:read("*all")
f:close()

-- Check for required adapter interface elements
local interface_checks = {
    { name = "name field", pattern = "name%s*=%s*['\"]([^'\"]*)['\"]" },
    { name = "root function", pattern = "adapter%.root%s*=" },
    { name = "filter_dir function", pattern = "adapter%.filter_dir%s*=" },
    { name = "is_test_file function", pattern = "adapter%.is_test_file%s*=" },
    { name = "discover_positions function", pattern = "function adapter%.discover_positions" },
    { name = "build_spec function", pattern = "function adapter%.build_spec" },
    { name = "results function", pattern = "function adapter%.results" },
    { name = "setmetatable call", pattern = "setmetatable%s*%(adapter" },
    { name = "return adapter", pattern = "return adapter" }
}

print("\nChecking adapter interface compliance:")
for _, check in ipairs(interface_checks) do
    local found = content:find(check.pattern) ~= nil
    local status = found and "✓" or "✗"
    print(string.format("   - %s: %s", check.name, status))
end

-- Check for neotest-tsx specific elements
local tsx_checks = {
    { name = "tsx command detection", pattern = "getTsxCommand" },
    { name = "tsx test setup check", pattern = "hasTsxTestSetup" },
    { name = "tsx test script check", pattern = "hasTsxTestScriptInJson" },
    { name = "treesitter query", pattern = "call_expression" },
}

print("\nChecking tsx-specific features:")
for _, check in ipairs(tsx_checks) do
    local found = content:find(check.pattern) ~= nil
    local status = found and "✓" or "✗"
    print(string.format("   - %s: %s", check.name, status))
end

-- Extract adapter name if found
local name_match = content:match("name%s*=%s*['\"]([^'\"]*)['\"]")
if name_match then
    print(string.format("\nAdapter name: %s", name_match))
else
    print("\nAdapter name: NOT FOUND")
end

print("\n===============================================")
print("Interface compliance test completed!")