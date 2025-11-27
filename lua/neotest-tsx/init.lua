---@diagnostic disable: undefined-field
local async = require("neotest.async")
local lib = require("neotest.lib")
local logger = require("neotest.logging")
local util = require("neotest-tsx.util")

---@class neotest.TsxOptions
---@field tsxCommand? string|fun(): string
---@field env? table<string, string>|fun(): table<string, string>
---@field cwd? string|fun(): string
---@field filter_dir? fun(name: string, relpath: string, root: string): boolean
---@field is_test_file? fun(file_path: string): boolean

---@class neotest.Adapter
local adapter = { name = "neotest-tsx" }

---@param packageJsonContent string
---@return boolean
local function hasTsxDependencyInJson(packageJsonContent)
  local parsedPackageJson = vim.json.decode(packageJsonContent)

  for _, dependencyType in ipairs({ "dependencies", "devDependencies" }) do
    if parsedPackageJson[dependencyType] then
      for key, _ in pairs(parsedPackageJson[dependencyType]) do
        if key == "tsx" then
          return true
        end
      end
    end
  end

  return false
end

---@param packageJsonContent string
---@return boolean
local function hasTsxTestScriptInJson(packageJsonContent)
  local parsedPackageJson = vim.json.decode(packageJsonContent)

  if parsedPackageJson.scripts then
    for scriptName, scriptCommand in pairs(parsedPackageJson.scripts) do
      if scriptCommand:find("tsx%s+--test") then
        return true
      end
    end
  end

  return false
end

---@return boolean
local function hasRootProjectTsxDependency()
  local rootPackageJson = vim.loop.cwd() .. "/package.json"

  local success, packageJsonContent = pcall(lib.files.read, rootPackageJson)
  if not success then
    print("cannot read package.json, got " .. rootPackageJson)
    return false
  end

  return hasTsxDependencyInJson(packageJsonContent)
end

---@return boolean
local function hasRootProjectTsxTestScript()
  local rootPackageJson = vim.loop.cwd() .. "/package.json"

  local success, packageJsonContent = pcall(lib.files.read, rootPackageJson)
  if not success then
    print("cannot read package.json, got " .. rootPackageJson)
    return false
  end

  return hasTsxTestScriptInJson(packageJsonContent)
end

---@param path string
---@return boolean
local function hasTsxTestSetup(path)
  local rootPath = lib.files.match_root_pattern("package.json")(path)

  if not rootPath then
    return false
  end

  local success, packageJsonContent = pcall(lib.files.read, rootPath .. "/package.json")
  if not success then
    print("cannot read package.json")
    return false
  end

  local gitRootPath = util.find_git_ancestor(path)
  local hasRootMonorepoTsxTestSetup = false

  -- only check the git root's package.json if it's different (e.g. in monorepos)
  if gitRootPath and rootPath ~= gitRootPath then
    local monorepoSuccess, monorepoRootPackageJsonContent =
      pcall(lib.files.read, gitRootPath .. "/package.json")
    if monorepoSuccess then
      hasRootMonorepoTsxTestSetup = hasTsxTestScriptInJson(monorepoRootPackageJsonContent)
    end
  end

  return hasTsxTestScriptInJson(packageJsonContent)
    or hasRootProjectTsxTestScript()
    or hasRootMonorepoTsxTestSetup
end

---@param file_path string
---@return boolean
local function usesNodeTest(file_path)
  local success, content = pcall(lib.files.read, file_path)
  if not success then
    return false
  end

  -- Check for node:test import
  return content:match("import.*node:test") or content:match("require%(['\"]node:test['\"]%)")
end

adapter.root = function(path)
  return lib.files.match_root_pattern("package.json")(path)
end

function adapter.filter_dir(name, _relpath, _root)
  return name ~= "node_modules"
end

---@param file_path? string
---@return boolean
function adapter.is_test_file(file_path)
  if file_path == nil then
    return false
  end
  local is_test_file = false

  if string.match(file_path, "__tests__") then
    is_test_file = true
  end

  for _, x in ipairs({ "e2e", "spec", "test" }) do
    for _, ext in ipairs({ "js", "jsx", "coffee", "ts", "tsx" }) do
      if string.match(file_path, "%." .. x .. "%." .. ext .. "$") then
        is_test_file = true
        goto matched_pattern
      end
    end
  end
  ::matched_pattern::
  return is_test_file and hasTsxTestSetup(file_path)
end

---@async
---@return neotest.Tree | nil
function adapter.discover_positions(path)
  local query = [[
    ; -- Namespaces --
    ; Matches: `describe('context')`
    ((call_expression
      function: (identifier) @func_name (#eq? @func_name "describe")
      arguments: (arguments (string (string_fragment) @namespace.name) (arrow_function))
    )) @namespace.definition
    ; Matches: `describe.only('context')`
    ((call_expression
      function: (member_expression
        object: (identifier) @func_name (#any-of? @func_name "describe")
      )
      arguments: (arguments (string (string_fragment) @namespace.name) (arrow_function))
    )) @namespace.definition
    ; Matches: `describe.each(['data'])('context')`
    ((call_expression
      function: (call_expression
        function: (member_expression
          object: (identifier) @func_name (#any-of? @func_name "describe")
        )
      )
      arguments: (arguments (string (string_fragment) @namespace.name) (arrow_function))
    )) @namespace.definition

    ; -- Tests --
    ; Matches: `test('test') / it('test')`
    ((call_expression
      function: (identifier) @func_name (#any-of? @func_name "it" "test")
      arguments: (arguments (string (string_fragment) @test.name) (arrow_function))
    )) @test.definition
    ; Matches: `test.only('test') / it.only('test')`
    ((call_expression
      function: (member_expression
        object: (identifier) @func_name (#any-of? @func_name "test" "it")
      )
      arguments: (arguments (string (string_fragment) @test.name) (arrow_function))
    )) @test.definition
    ; Matches: `test.each(['data'])('test') / it.each(['data'])('test')`
    ((call_expression
      function: (call_expression
        function: (member_expression
          object: (identifier) @func_name (#any-of? @func_name "it" "test")
        )
      )
      arguments: (arguments (string (string_fragment) @test.name) (arrow_function))
    )) @test.definition
  ]]
  query = query .. string.gsub(query, "arrow_function", "function_expression")
  return lib.treesitter.parse_positions(path, query, { nested_tests = true })
end

---@param path string
---@return string
local function getTsxCommand(path)
  local rootPath = util.find_node_modules_ancestor(path)
  local tsxBinary = util.path.join(rootPath, "node_modules", ".bin", "tsx")

  if util.path.exists(tsxBinary) then
    return tsxBinary
  end

  local gitRootPath = util.find_git_ancestor(path)
  if gitRootPath then
    tsxBinary = util.path.join(gitRootPath, "node_modules", ".bin", "tsx")
    if util.path.exists(tsxBinary) then
      return tsxBinary
    end
  end

  return "tsx"
end

local function escapeTestPattern(s)
  return (
    s:gsub("%(", "\\(")
      :gsub("%)", "\\)")
      :gsub("%]", "\\]")
      :gsub("%[", "\\[")
      :gsub("%.", "\\.")
      :gsub("%*", "\\*")
      :gsub("%+", "\\+")
      :gsub("%-", "\\-")
      :gsub("%?", "\\?")
      :gsub(" ", "\\s")
      :gsub("%$", "\\$")
      :gsub("%^", "\\^")
      :gsub("%/", "\\/")
  )
end

local function get_strategy_config(strategy, command, cwd)
  local config = {
    dap = function()
      return {
        name = "Debug Tsx Tests",
        type = "pwa-node",
        request = "launch",
        args = { unpack(command, 2) },
        runtimeExecutable = command[1],
        console = "integratedTerminal",
        internalConsoleOptions = "neverOpen",
        cwd = cwd or "${workspaceFolder}",
      }
    end,
  }
  if config[strategy] then
    return config[strategy]()
  end
end

local function getEnv(specEnv)
  return specEnv
end

---@param path string
---@return string|nil
local function getCwd(path)
  return util.find_node_modules_ancestor(path)
end

---@param args neotest.RunArgs
---@return neotest.RunSpec | nil
function adapter.build_spec(args)
  local tree = args.tree

  if not tree then
    return
  end

  local pos = args.tree:data()
  local binary = args.tsxCommand or getTsxCommand(pos.path)
  local command = vim.split(binary, "%s+")

  -- For tsx, we run the test file directly
  -- Node:test will handle test discovery and running
  vim.list_extend(command, {
    vim.fs.normalize(pos.path),
  })

  vim.list_extend(command, args.extra_args or {})

  local cwd = getCwd(pos.path)

  return {
    command = command,
    cwd = cwd,
    context = {
      file = pos.path,
    },
    strategy = get_strategy_config(args.strategy, command, cwd),
    env = getEnv(args[2] and args[2].env or {}),
  }
end

---@async
---@param spec neotest.RunSpec
---@return neotest.Result[]
function adapter.results(spec, b, tree)
  -- For now, return empty results
  -- TODO: Parse TAP output from node:test
  return {}
end

local is_callable = function(obj)
  return type(obj) == "function" or (type(obj) == "table" and obj.__call)
end

setmetatable(adapter, {
  ---@param opts neotest.TsxOptions
  __call = function(_, opts)
    if is_callable(opts.tsxCommand) then
      getTsxCommand = opts.tsxCommand
    elseif opts.tsxCommand then
      getTsxCommand = function()
        return opts.tsxCommand
      end
    end

    if is_callable(opts.env) then
      getEnv = opts.env
    elseif opts.env then
      getEnv = function(specEnv)
        return vim.tbl_extend("force", opts.env, specEnv)
      end
    end

    if is_callable(opts.cwd) then
      getCwd = opts.cwd
    elseif opts.cwd then
      getCwd = function()
        return opts.cwd
      end
    end

    if is_callable(opts.filter_dir) then
      adapter.filter_dir = opts.filter_dir
    end

    if is_callable(opts.is_test_file) then
      adapter.is_test_file = function(file_path)
        return (hasTsxDependency(file_path) or usesNodeTest(file_path)) and opts.is_test_file(file_path)
      end
    end

    return adapter
  end,
})

return adapter