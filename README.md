# 🔍 Roblox Audit Tools

Comprehensive audit and dependency analysis toolkit for Roblox/Rojo projects.

## Features

- 🔍 **Circular Dependency Detection** - Detect dependency cycles automatically
- 🎨 **Dependency Graphs** - Beautiful SVG visualizations with Tekne aesthetics
- 📝 **Type Checking** - Static analysis with luau-lsp
- 🔎 **Linting** - Code quality checks with Selene
- 🎨 **Style Checking** - Formatting validation with StyLua
- 🤖 **Auto-Setup** - Installs dependencies and creates configs on first run

## Installation

```bash
# Initialize Rokit in your project (if needed)
rokit init

# Add roblox-audit
rokit add tekne-studio/roblox-audit
```

Or add to `rokit.toml`:

```toml
[tools]
roblox-audit = "tekne-studio/roblox-audit"
```

## Usage

Run the audit in your project directory:

```bash
roblox-audit
```

On first run, the tool automatically:
- Installs required dependencies (luau-lsp, Selene, StyLua) via Rokit
- Creates `selene.toml` and `stylua.toml` with sensible defaults

### Generated Reports

All reports are saved to the `audit/` directory:
- `audit-check.txt` - Type errors
- `audit-selene.txt` - Linting warnings
- `audit-style.txt` - Formatting issues
- `audit-circular.txt` - Circular dependencies
- `audit-graph.svg` - Dependency visualization
- `audit-tree.txt` - Project structure

## Requirements

**Auto-installed via Rokit:**
- luau-lsp, Selene, StyLua

**Manual installation:**
- Lua 5.1+ or LuaJIT
- Graphviz (for visualization): `brew install graphviz`

## Development

### Making Changes

1. Edit files in `src/`
2. Update version in `rokit.toml`
3. Build: `./build.sh`
4. Test: `./dist/audit-bundled.lua`
5. Commit with conventional commits: `git commit -m "feat: description"`
6. Push: `git push`

### Releases

**DO NOT create tags manually.** The CI/CD system automatically:
- Detects version changes in `rokit.toml`
- Creates tags and releases
- Generates changelogs from commits
- Publishes to GitHub and Rokit

### Commit Conventions

Use [Conventional Commits](https://www.conventionalcommits.org/):
- `feat:` - New feature
- `fix:` - Bug fix
- `perf:` - Performance improvement
- `docs:` - Documentation
- `refactor:` - Code refactoring
- `chore:` - Maintenance

## Project Structure

```
src/
├── audit.lua                    # Main orchestrator
├── analyze-dependencies.lua     # Dependency detection
└── visualize-dependencies.lua   # Graph generation
dist/
└── audit-bundled.lua           # Single-file build (generated)
```

## Contributing

1. Fork and create a feature branch
2. Make changes with conventional commits
3. Update version in `rokit.toml`
4. Run `./build.sh` and test
5. Submit pull request

## License

MIT

## Related

- [Rojo](https://rojo.space/) - Roblox project management
- [Selene](https://github.com/Kampfkarren/selene) - Lua linter
- [StyLua](https://github.com/JohnnyMorganz/StyLua) - Lua formatter
- [Rokit](https://github.com/rojo-rbx/rokit) - Toolchain manager
