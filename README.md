# 🔍 Roblox Audit Tools

A collection of Lua-based audit and dependency analysis tools for Roblox/Rojo projects.

## Features

- **🔍 analyze-dependencies** - Detect circular dependencies in your Luau code
- **🎨 visualize-dependencies** - Generate beautiful SVG dependency graphs with Tekne-style aesthetics
- **🛡️ audit** - Run comprehensive code quality checks (auto-initializes configs on first run)

## Installation

### Via Rokit/Aftman

```bash
rokit add tekne-studio/roblox-audit
```

Or add to your `rokit.toml`:

```toml
[tools]
roblox-audit = "tekne-studio/roblox-audit@1.0.0"
```

### Manual Installation

1. Clone this repository
2. Add the `src/` directory to your PATH
3. Ensure scripts are executable: `chmod +x src/*`

## Usage

### 📊 Analyze Dependencies

Detect circular dependencies in your Roblox/Rojo project:

```bash
analyze-dependencies [directory]
```

**Examples:**
```bash
analyze-dependencies src
analyze-dependencies src/shared/Modules
```

**Output:**
- Lists all Lua files found
- Detects and reports circular dependencies
- Shows file paths involved in cycles
- Filters out self-references automatically

### 🎨 Visualize Dependencies

Generate beautiful dependency graphs with high-tech neon aesthetics:

```bash
visualize-dependencies [directory] [output] [format] [mode]
```

**Arguments:**
- `directory` - Source directory (default: `src`)
- `output` - Output filename (default: `dependency-graph.<format>`)
- `format` - `svg`, `png`, `pdf`, or `dot` (default: `svg`)
- `mode` - `detailed` for full paths and edge labels

**Examples:**
```bash
visualize-dependencies src
visualize-dependencies src graph.svg
visualize-dependencies src graph.png png
visualize-dependencies src detailed.svg svg detailed
```

**Features:**
- Deep black background (#0A0A0A)
- Neon-colored category borders (cyan, purple, green, orange)
- JetBrains Mono font throughout
- Grouped by module type (Services, Controllers, Framework, etc.)
- Orthogonal edges for clean layouts
- Highlights orphan modules (no connections)

**Requires:** Graphviz (`brew install graphviz`)

### 🛡️ Audit Code

Run comprehensive code quality checks:

```bash
audit
```

**What it does:**
- 📝 **Auto-initializes configs** - Creates `selene.toml` and `stylua.toml` if they don't exist
- 🔍 **Type checking** - Runs luau-lsp analyze
- 🔎 **Linting** - Runs Selene for code quality
- 🎨 **Style checking** - Runs StyLua for formatting
- 🔄 **Circular dependencies** - Detects dependency cycles
- 🎨 **Dependency graphs** - Generates SVG/PNG visualizations
- 📂 **Project structure** - Checks for common issues
- 📊 **Summary report** - Shows all findings in one place

**Generated reports:**
All reports are saved to the `audit/` directory:
- `audit-check.txt` - Type errors
- `audit-selene.txt` - Linting warnings
- `audit-style.txt` - Formatting issues
- `audit-circular.txt` - Circular dependencies
- `audit-graph.svg` - Dependency visualization
- `audit-tree.txt` - File structure

**First run:**
On the first run, `audit` will automatically create:
- `selene.toml` with Roblox-specific rules
- `stylua.toml` with formatting preferences

You can customize these files after they're created.

## Requirements

- **Lua 5.1+** or **LuaJIT** (for running scripts)
- **Selene** (for linting) - `rokit install Kampfkarren/selene`
- **StyLua** (for formatting) - `rokit install JohnnyMorganz/StyLua`
- **Graphviz** (for visualization) - `brew install graphviz`

## Theme & Styling

The visualization tool uses a **Tekne-inspired high-tech aesthetic**:

| Element | Style |
|---------|-------|
| Background | Deep black (#0A0A0A) |
| Framework | Cyan border (#00D9FF) |
| Bootstrap | Purple border (#CC00FF) |
| Services | Green border (#00FF88) |
| Controllers | Orange border (#FF8800) |
| Utilities | Grey border (#888888) |
| Orphans | Pink dashed border (#FF0055) |

## Module Detection

Scripts automatically detect module types:

- **Framework**: Modules in `/Framework/` directory
- **Bootstrap**: `init.lua`, `init.server.lua`, `init.client.lua`
- **Services**: Modules ending in `Service`
- **Controllers**: Modules ending in `Controller`
- **Utilities**: Everything else

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT License - See [LICENSE](LICENSE) file for details

## Related Projects

- [Rojo](https://rojo.space/) - Roblox project management
- [Selene](https://github.com/Kampfkarren/selene) - Lua linter
- [StyLua](https://github.com/JohnnyMorganz/StyLua) - Lua formatter
- [Rokit](https://github.com/rojo-rbx/rokit) - Toolchain manager
