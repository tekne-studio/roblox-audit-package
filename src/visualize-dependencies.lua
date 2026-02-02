#!/usr/bin/env lua

--[[
===========================================
🎨 Dependency Visualizer - Tekne Style
===========================================
Generates beautiful SVG dependency graphs
Uses Graphviz with high-tech neon aesthetic
===========================================
]]

-- ============================================
-- TEKNE STYLE CONFIGURATION
-- Easy to copy/paste to other projects
-- ============================================

local TEKNE_STYLE = {
    -- Graph layout
    layout = {
        direction = "LR",           -- Left to right
        splines = "ortho",          -- Orthogonal (straight) edges
        nodeSep = 0.8,              -- Horizontal spacing between nodes
        rankSep = 1.2,              -- Vertical spacing between ranks
        pad = 0.5,                  -- Margin around the graph (inches)
    },

    -- Dark mode colors
    colors = {
        background = "#0A0A0A",     -- Deep black

        -- Neon category colors (for borders/strokes)
        framework = "#00D9FF",      -- Cyan
        service = "#00FF88",        -- Green
        controller = "#FF8800",     -- Orange
        bootstrap = "#CC00FF",      -- Purple
        utility = "#888888",        -- Grey
        orphan = "#FF0055",         -- Pink (for unconnected modules)
    },

    -- Typography
    fonts = {
        main = "JetBrains Mono, monospace",
        -- Note: Graphviz/DOT doesn't support font weights directly
        -- Titles use same font but slightly larger size for emphasis
    },

    -- Node styling
    nodes = {
        fillColor = "#1A1A1A33",    -- 80% transparent dark
        textColor = "#E0E0E0",      -- Light grey
        borderWidth = 2.5,
        fontSize = 11,
        padding = {
            horizontal = 0.35,      -- inches
            vertical = 0.25,        -- inches
        },
    },

    -- Edge styling
    edges = {
        color = "#606060",          -- Medium-dark grey (more visible)
        labelColor = "#B0B0B0",     -- Light grey (better contrast with edges)
        width = 1.8,                -- Slightly thicker for visibility
        fontSize = 8,
    },

    -- Cluster (group) styling
    clusters = {
        borderWidth = 2.5,
        fontSize = 14,
        textColor = "#E0E0E0",
        background = "#00000000",   -- Fully transparent
        margin = 32,                -- Padding around cluster content (points)
        labelSpacing = "\\n",       -- Add newline after label for visual spacing
    },
}

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
    local name = filePath:match("([^/]+)/init%.lua[u]?$")
    if name then
        return name
    end

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

    for _, filePath in ipairs(files) do
        local moduleName = getModuleName(filePath)
        local requires = extractRequires(filePath)

        graph[moduleName] = {
            file = filePath,
            requires = {},
            requirePaths = {}  -- Store original require paths for edge labels
        }

        -- Extract module names and store original paths
        for _, req in ipairs(requires) do
            local depName = req:match("([^%.]+)$") or req
            table.insert(graph[moduleName].requires, depName)
            graph[moduleName].requirePaths[depName] = req
        end
    end

    return graph
end

local function getModuleCategory(moduleName, filePath)
    -- Categorize modules for better visualization
    if moduleName:match("Service$") then
        return "service"
    elseif moduleName:match("Controller$") then
        return "controller"
    elseif filePath:match("/Framework/") then
        return "framework"
    elseif moduleName == "init" or filePath:match("init%.server") or filePath:match("init%.client") then
        return "bootstrap"
    else
        return "utility"
    end
end

local function generateDOT(graph, options)
    options = options or {}
    local showOrphans = options.showOrphans ~= false
    local groupByType = options.groupByType ~= false
    local detailedMode = options.detailedMode or false
    local showEdgeLabels = options.showEdgeLabels or false
    local darkMode = options.darkMode ~= false  -- Default to dark mode

    local output = {}
    table.insert(output, "digraph Dependencies {")
    table.insert(output, string.format("    rankdir=%s;", TEKNE_STYLE.layout.direction))
    table.insert(output, string.format("    splines=%s;", TEKNE_STYLE.layout.splines))
    table.insert(output, string.format("    nodesep=%s;", TEKNE_STYLE.layout.nodeSep))
    table.insert(output, string.format("    ranksep=%s;", TEKNE_STYLE.layout.rankSep))
    table.insert(output, string.format("    pad=%s;", TEKNE_STYLE.layout.pad))

    -- Apply Tekne styling
    if darkMode then
        local margin = string.format("%s,%s", TEKNE_STYLE.nodes.padding.horizontal, TEKNE_STYLE.nodes.padding.vertical)

        table.insert(output, string.format("    bgcolor=\"%s\";", TEKNE_STYLE.colors.background))
        table.insert(output, string.format("    node [shape=box, style=\"rounded,filled\", fontname=\"%s\", fontcolor=\"%s\", fillcolor=\"%s\", penwidth=%s, margin=\"%s\"];",
            TEKNE_STYLE.fonts.main, TEKNE_STYLE.nodes.textColor, TEKNE_STYLE.nodes.fillColor, TEKNE_STYLE.nodes.borderWidth, margin))
        table.insert(output, string.format("    edge [color=\"%s\", fontcolor=\"%s\", fontname=\"%s\", penwidth=%s];",
            TEKNE_STYLE.edges.color, TEKNE_STYLE.edges.labelColor, TEKNE_STYLE.fonts.main, TEKNE_STYLE.edges.width))

        if detailedMode then
            table.insert(output, string.format("    graph [fontsize=%s, fontcolor=\"%s\", fontname=\"%s\"];",
                TEKNE_STYLE.clusters.fontSize, TEKNE_STYLE.edges.labelColor, TEKNE_STYLE.fonts.main))
            table.insert(output, "    node [fontsize=9];")
            table.insert(output, "    edge [fontsize=7];")
        else
            table.insert(output, string.format("    graph [fontsize=%s, fontcolor=\"%s\", fontname=\"%s\"];",
                TEKNE_STYLE.clusters.fontSize, TEKNE_STYLE.edges.labelColor, TEKNE_STYLE.fonts.main))
            table.insert(output, string.format("    node [fontsize=%s];", TEKNE_STYLE.nodes.fontSize))
            table.insert(output, string.format("    edge [fontsize=%s];", TEKNE_STYLE.edges.fontSize))
        end
    else
        local margin = string.format("%s,%s", TEKNE_STYLE.nodes.padding.horizontal, TEKNE_STYLE.nodes.padding.vertical)

        table.insert(output, string.format("    node [shape=box, style=rounded, fontname=\"%s\", margin=\"%s\"];",
            TEKNE_STYLE.fonts.main, margin))
        table.insert(output, string.format("    edge [color=\"#666666\", fontname=\"%s\"];", TEKNE_STYLE.fonts.main))

        if detailedMode then
            table.insert(output, string.format("    graph [fontsize=10, fontname=\"%s\"];", TEKNE_STYLE.fonts.main))
            table.insert(output, "    node [fontsize=10];")
            table.insert(output, string.format("    edge [fontsize=%s];", TEKNE_STYLE.edges.fontSize))
        else
            table.insert(output, string.format("    graph [fontsize=%s, fontname=\"%s\"];",
                TEKNE_STYLE.clusters.fontSize, TEKNE_STYLE.fonts.main))
        end
    end

    table.insert(output, "")

    -- Use Tekne colors
    local colors = TEKNE_STYLE.colors

    -- Create nodes with appropriate detail level
    if groupByType and not detailedMode then
        local categories = {}

        -- Organize modules by category
        for moduleName, node in pairs(graph) do
            local category = getModuleCategory(moduleName, node.file)
            if not categories[category] then
                categories[category] = {}
            end
            table.insert(categories[category], moduleName)
        end

        -- Create subgraphs for each category
        local categoryOrder = {"framework", "bootstrap", "service", "controller", "utility"}
        for _, category in ipairs(categoryOrder) do
            if categories[category] then
                table.insert(output, string.format("    subgraph cluster_%s {", category))
                table.insert(output, string.format("        label=\"%s\";", category:upper()))

                if darkMode then
                    table.insert(output, "        style=\"rounded\";")
                    table.insert(output, string.format("        bgcolor=\"%s\";", TEKNE_STYLE.clusters.background))
                    table.insert(output, string.format("        color=\"%s\";", colors[category]))
                    table.insert(output, string.format("        penwidth=%s;", TEKNE_STYLE.clusters.borderWidth))
                    table.insert(output, string.format("        fontcolor=\"%s\";", TEKNE_STYLE.clusters.textColor))
                    table.insert(output, string.format("        fontname=\"%s\";", TEKNE_STYLE.fonts.main))
                    table.insert(output, string.format("        fontsize=%s;", TEKNE_STYLE.clusters.fontSize))
                    table.insert(output, string.format("        margin=%s;", TEKNE_STYLE.clusters.margin))
                else
                    table.insert(output, "        style=filled;")
                    table.insert(output, string.format("        color=\"%s\";", colors[category]))
                    table.insert(output, string.format("        fontname=\"%s\";", TEKNE_STYLE.fonts.main))
                    table.insert(output, string.format("        fontsize=%s;", TEKNE_STYLE.clusters.fontSize))
                    table.insert(output, string.format("        margin=%s;", TEKNE_STYLE.clusters.margin))
                end

                table.insert(output, "")

                for _, moduleName in ipairs(categories[category]) do
                    -- In grouped view, just show module name (category is already in cluster label)
                    table.insert(output, string.format('        "%s";', moduleName))
                end

                table.insert(output, "    }")
                table.insert(output, "")
            end
        end
    else
        -- Flat view with detailed labels
        for moduleName, node in pairs(graph) do
            local category = getModuleCategory(moduleName, node.file)
            local color = colors[category]

            if detailedMode then
                -- Show more details: module name + category (no file path)
                local label = string.format("%s\\n[%s]", moduleName, category)
                if darkMode then
                    table.insert(output, string.format('    "%s" [label="%s", fillcolor="%s", color="%s", style="rounded,filled"];',
                        moduleName, label, TEKNE_STYLE.nodes.fillColor, color))
                else
                    table.insert(output, string.format('    "%s" [label="%s", fillcolor="%s", style="rounded,filled"];',
                        moduleName, label, color))
                end
            else
                if darkMode then
                    table.insert(output, string.format('    "%s" [fillcolor="%s", color="%s", style="rounded,filled"];',
                        moduleName, TEKNE_STYLE.nodes.fillColor, color))
                else
                    table.insert(output, string.format('    "%s" [fillcolor="%s", style="rounded,filled"];',
                        moduleName, color))
                end
            end
        end
        table.insert(output, "")
    end

    -- Add edges
    local hasEdges = {}
    for moduleName, node in pairs(graph) do
        for _, dep in ipairs(node.requires) do
            if graph[dep] then  -- Only show edges to known modules
                if showEdgeLabels and node.requirePaths[dep] then
                    -- Show the require path as edge label
                    local requirePath = node.requirePaths[dep]
                    -- Shorten common paths
                    requirePath = requirePath:gsub("ReplicatedStorage%.Shared%.Modules%.", "")
                    requirePath = requirePath:gsub("script%.Parent%.", "")
                    table.insert(output, string.format('    "%s" -> "%s" [label="%s"];',
                        moduleName, dep, requirePath))
                else
                    table.insert(output, string.format('    "%s" -> "%s";', moduleName, dep))
                end
                hasEdges[moduleName] = true
                hasEdges[dep] = true
            end
        end
    end

    -- Optionally highlight orphan nodes (no connections)
    if showOrphans then
        for moduleName in pairs(graph) do
            if not hasEdges[moduleName] then
                if darkMode then
                    table.insert(output, string.format('    "%s" [style="rounded,filled,dashed", fillcolor="%s", color="%s", penwidth=%s];',
                        moduleName, TEKNE_STYLE.nodes.fillColor, TEKNE_STYLE.colors.orphan, TEKNE_STYLE.nodes.borderWidth))
                else
                    table.insert(output, string.format('    "%s" [style="rounded,filled,dashed", fillcolor="#FFE8E8"];', moduleName))
                end
            end
        end
    end

    table.insert(output, "}")
    return table.concat(output, "\n")
end

local function visualize(srcDir, outputFile, format, detailedMode)
    format = format or "svg"
    outputFile = outputFile or ("dependency-graph." .. format)
    detailedMode = detailedMode or false

    local modeLabel = detailedMode and " (detailed)" or ""
    print("🎨 Visualizing dependencies in: " .. srcDir .. modeLabel)
    print("")

    local graph = buildDependencyGraph(srcDir)

    -- Count modules
    local moduleCount = 0
    for _ in pairs(graph) do
        moduleCount = moduleCount + 1
    end

    print("📦 Found " .. moduleCount .. " modules")

    -- Generate DOT with appropriate options
    local dotContent = generateDOT(graph, {
        showOrphans = true,
        groupByType = not detailedMode,  -- Disable grouping in detailed mode
        detailedMode = detailedMode,
        showEdgeLabels = detailedMode,   -- Show edge labels in detailed mode
        darkMode = true                  -- Always use dark mode
    })

    -- Write DOT file (keep it in same directory as output)
    local dotFile = outputFile:gsub("%." .. format .. "$", ".dot")

    -- Ensure parent directory exists
    local parentDir = dotFile:match("(.*/)")
    if parentDir then
        os.execute("mkdir -p " .. parentDir)
    end

    local file = io.open(dotFile, "w")
    if not file then
        print("❌ Failed to write DOT file: " .. dotFile)
        return false
    end
    file:write(dotContent)
    file:close()

    print("✓ Generated: " .. dotFile)

    -- Convert to desired format using graphviz
    if format ~= "dot" then
        local cmd = string.format("dot -T%s %s -o %s 2>&1", format, dotFile, outputFile)
        local handle = io.popen(cmd)

        if not handle then
            print("❌ Failed to run graphviz (is 'dot' installed?)")
            print("   → brew install graphviz")
            return false
        end

        local result = handle:read("*a")
        local success = handle:close()

        if success then
            print("✓ Generated: " .. outputFile)
            print("")
            print("🎉 Done! Open the file to view:")
            print("   → open " .. outputFile)
            return true
        else
            print("❌ Graphviz error:")
            print(result)
            return false
        end
    end

    return true
end

-- Export module functions
local M = {
    visualize = visualize,
}

-- Main execution (only if run as script, not when required)
if not pcall(debug.getlocal, 4, 1) then
    local srcDir = arg[1] or "src"
    local outputFile = arg[2]
    local format = arg[3] or "svg"
    local detailedMode = arg[4] == "detailed" or arg[4] == "--detailed"

    if arg[1] == "--help" or arg[1] == "-h" then
        print([[
Usage: ./visualize-dependencies [directory] [output] [format] [mode]

Generates dependency graph visualizations for Roblox/Rojo projects.

Arguments:
  directory  Source directory to analyze (default: src)
  output     Output file name (default: dependency-graph.<format>)
  format     Output format: svg, png, pdf, dot (default: svg)
  mode       "detailed" for detailed mode with full paths and edge labels

Examples:
  ./visualize-dependencies src
  ./visualize-dependencies src graph.svg
  ./visualize-dependencies src graph.png png
  ./visualize-dependencies src graph-full.svg svg detailed

Modes:
  Normal (default):
    - Grouped by module type (Services, Controllers, etc.)
    - Simple module names
    - Clean, high-level overview

  Detailed:
    - Flat layout (no grouping)
    - Full file paths shown
    - Edge labels showing require() paths
    - Module category annotations

Theme:
  - High-tech neon aesthetic with deep black background
  - JetBrains Mono font throughout (with monospace fallback)
  - 80% transparent node backgrounds
  - Vibrant neon-colored strokes/borders (2.5px thick)
  - Subtle grey edges for connections

Requires:
  - Graphviz (brew install graphviz)

Color coding (neon strokes):
  - Cyan (#00D9FF): Framework modules
  - Purple (#CC00FF): Bootstrap (init files)
  - Green (#00FF88): Services
  - Orange (#FF8800): Controllers
  - Grey (#888888): Utilities
  - Pink dashed (#FF0055): Orphan modules (no connections)
]])
        os.exit(0)
    end

    -- Run visualization
    local success = visualize(srcDir, outputFile, format, detailedMode)

    if success then
        os.exit(0)
    else
        os.exit(1)
    end
end

return M
