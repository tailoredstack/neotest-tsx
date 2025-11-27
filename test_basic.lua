#!/usr/bin/env lua

-- Basic Lua test for neotest-tsx adapter structure
-- Tests parts that don't require Neovim runtime

print("Basic Lua test for neotest-tsx adapter")
print("=====================================")

-- Test loading the adapter (will fail due to missing dependencies, but we can catch that)
local ok, adapter = pcall(require, "neotest-tsx")
if not ok then
    print("Expected failure loading adapter without Neovim:", string.match(adapter, "^[^\n]+"))
else
    print("Unexpectedly loaded adapter - this shouldn't happen in plain Lua")
end

-- Test loading util module
local ok_util, util = pcall(require, "neotest-tsx.util")
if not ok_util then
    print("Expected failure loading util without Neovim:", string.match(util, "^[^\n]+"))
else
    print("✓ Util module loaded successfully")
    print("  - path utilities available:", type(util.path) == "table" and "✓" or "✗")
    print("  - root_pattern function:", type(util.root_pattern) == "function" and "✓" or "✗")
    print("  - find_git_ancestor function:", type(util.find_git_ancestor) == "function" and "✓" or "✗")
end

print("\nBasic structure test completed!")
print("For full testing, run test_adapter.vim in Neovim")