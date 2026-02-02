#!/usr/bin/env lua

--[[
===========================================
🔍 Roblox Dependency Analyzer
===========================================
Analyzes require() dependencies in Roblox/Rojo projects
Detects circular dependencies
Handles .client.lua and .server.lua files
===========================================
]]

local function findLuaFiles(dir)
    local files = {}
    local handle = io.popen("find " .. dir .. " -type f \\( -name '*.lua' -o -name '*.luau' \\) 2>/dev/null")

    if not handle then
        return files
    end

    for file in handle:lines() do
        table.insert(files, file)
    end

    handle:close()
    return files
end

local function extractRequires(filePath)
    local requires = {}
    local file = io.open(filePath, "r")

    if not file then
        return requires
    end

    for line in file:lines() do
        -- Match various require patterns:
        -- require(script.Parent.ModuleName)
        -- require(ReplicatedStorage.Shared.Modules.ModuleName)
        -- local X = require(...)

        -- Pattern 1: require(path.to.Module)
        for match in line:gmatch("require%s*%(%s*([%w%.]+)%s*%)") do
            table.insert(requires, match)
        end

        -- Pattern 2: require("path/to/module")
        for match in line:gmatch('require%s*%(%s*["\']([^"\']+)["\']%s*%)') do
            table.insert(requires, match)
        end
    end

    file:close()
    return requires
end

local function getModuleName(filePath)
    -- Extract module name from file path
    -- src/shared/Modules/MoneyService/init.lua -> MoneyService
    local name = filePath:match("([^/]+)/init%.lua[u]?$")
    if name then
        return name
    end

    -- Handle non-init files
    name = filePath:match("([^/]+)%.lua[u]?$")
    if name then
        -- Remove .client or .server suffix
        name = name:gsub("%.client$", "")
        name = name:gsub("%.server$", "")
        return name
    end

    return filePath
end

local function buildDependencyGraph(srcDir)
    local files = findLuaFiles(srcDir)
    local graph = {}
    local moduleToFile = {}

    print("📦 Found " .. #files .. " Lua files")
    print("")

    -- Build graph
    for _, filePath in ipairs(files) do
        local moduleName = getModuleName(filePath)
        local requires = extractRequires(filePath)

        graph[moduleName] = {
            file = filePath,
            requires = {}
        }

        moduleToFile[moduleName] = filePath

        -- Extract just the module names from requires
        for _, req in ipairs(requires) do
            -- Get last component of require path
            local depName = req:match("([^%.]+)$") or req
            table.insert(graph[moduleName].requires, depName)
        end
    end

    return graph, moduleToFile
end

local function findCycles(graph, start, visited, recStack, path, cycles)
    visited = visited or {}
    recStack = recStack or {}
    path = path or {}
    cycles = cycles or {}

    visited[start] = true
    recStack[start] = true
    table.insert(path, start)

    local node = graph[start]
    if node then
        for _, dep in ipairs(node.requires) do
            if not visited[dep] then
                findCycles(graph, dep, visited, recStack, path, cycles)
            elseif recStack[dep] then
                -- Found a cycle!
                local cycleStart = nil
                for i, module in ipairs(path) do
                    if module == dep then
                        cycleStart = i
                        break
                    end
                end

                if cycleStart then
                    local cycle = {}
                    for i = cycleStart, #path do
                        table.insert(cycle, path[i])
                    end
                    table.insert(cycle, dep) -- Close the cycle
                    table.insert(cycles, cycle)
                end
            end
        end
    end

    table.remove(path)
    recStack[start] = false

    return cycles
end

local function analyzeDependencies(srcDir)
    print("🔍 Analyzing dependencies in: " .. srcDir)
    print("")

    local graph, moduleToFile = buildDependencyGraph(srcDir)

    -- Find all cycles
    local allCycles = {}
    local visited = {}

    for module in pairs(graph) do
        if not visited[module] then
            local cycles = findCycles(graph, module, visited, {}, {}, {})
            for _, cycle in ipairs(cycles) do
                -- Check if we already have this cycle (in reverse)
                local isDuplicate = false
                for _, existingCycle in ipairs(allCycles) do
                    if #existingCycle == #cycle then
                        local matches = true
                        for i = 1, #cycle do
                            if cycle[i] ~= existingCycle[i] then
                                matches = false
                                break
                            end
                        end
                        if matches then
                            isDuplicate = true
                            break
                        end
                    end
                end

                if not isDuplicate then
                    table.insert(allCycles, cycle)
                end
            end
        end
    end

    -- Filter out self-references and trivial cycles FIRST
    local realCycles = {}
    local filteredCycles = {}

    for _, cycle in ipairs(allCycles) do
        -- Track what we filter out
        if #cycle == 2 and cycle[1] == cycle[2] then
            -- Self-reference (A → A)
            table.insert(filteredCycles, {type = "self", cycle = cycle})
        elseif #cycle > 2 then
            -- Real cycle (A → B → C → A)
            table.insert(realCycles, cycle)
        else
            -- Edge case: 2-node cycle that's not self-reference
            table.insert(filteredCycles, {type = "trivial", cycle = cycle})
        end
    end

    -- Report results
    print("📊 Analysis Results")
    print("==================")
    print("")

    local moduleCount = 0
    for _ in pairs(graph) do
        moduleCount = moduleCount + 1
    end

    print("Modules analyzed: " .. moduleCount)

    if #allCycles > 0 then
        print("Raw cycles detected: " .. #allCycles)
        if #filteredCycles > 0 then
            print("Filtered (self-references): " .. #filteredCycles)
            for _, filtered in ipairs(filteredCycles) do
                print("  - " .. table.concat(filtered.cycle, " → ") .. " (self-reference)")
            end
        end
        print("Real circular dependencies: " .. #realCycles)
    else
        print("Circular dependencies: 0")
    end
    print("")

    if #realCycles > 0 then
        print("⚠️  Circular Dependencies Detected:")
        print("")
        for i, cycle in ipairs(realCycles) do
            print("Cycle #" .. i .. ":")
            print("  " .. table.concat(cycle, " → "))
            print("")

            -- Show file paths
            print("  Files involved:")
            for j, module in ipairs(cycle) do
                if j < #cycle then -- Don't repeat the last one (same as first)
                    local node = graph[module]
                    if node then
                        print("    " .. node.file)
                    end
                end
            end
            print("")
        end
        return false, realCycles
    else
        print("✅ No circular dependencies found!")
        return true, {}
    end
end

local function printModuleTree(graph, module, indent, visited)
    indent = indent or 0
    visited = visited or {}

    if visited[module] then
        print(string.rep("  ", indent) .. "├─ " .. module .. " (already visited)")
        return
    end

    visited[module] = true
    print(string.rep("  ", indent) .. "├─ " .. module)

    local node = graph[module]
    if node and #node.requires > 0 then
        for _, dep in ipairs(node.requires) do
            printModuleTree(graph, dep, indent + 1, visited)
        end
    end
end

-- Export module functions
local M = {
    analyzeDependencies = analyzeDependencies,
    buildDependencyGraph = buildDependencyGraph,
    findCycles = findCycles,
}

-- Main execution (only if run as script, not when required)
if not pcall(debug.getlocal, 4, 1) then
    local srcDir = arg[1] or "src"

    if arg[1] == "--help" or arg[1] == "-h" then
        print([[
Usage: ./analyze-dependencies [directory]

Analyzes require() dependencies in Roblox/Rojo Luau projects.
Detects circular dependencies.
Handles .client.lua and .server.lua files.

Examples:
  ./analyze-dependencies src
  ./analyze-dependencies src/shared/Modules

Options:
  -h, --help    Show this help message
]])
        os.exit(0)
    end

    -- Run analysis
    local success, cycles = analyzeDependencies(srcDir)

    -- Exit with appropriate code
    if success then
        os.exit(0)
    else
        os.exit(1)
    end
end

return M
