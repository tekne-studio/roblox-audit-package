#!/bin/bash
set -e

echo "🔨 Building roblox-audit..."

# Determine which darklua to use
DARKLUA_CMD=""

# Check if darklua exists in current directory
if [ -f "./darklua" ]; then
    DARKLUA_CMD="./darklua"
# Check if darklua is in PATH
elif command -v darklua &> /dev/null; then
    DARKLUA_CMD="darklua"
else
    # Download darklua
    echo "📦 Downloading darklua..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - detect architecture
        if [[ $(uname -m) == "arm64" ]]; then
            curl -L https://github.com/seaofvoices/darklua/releases/latest/download/darklua-macos-aarch64.zip -o darklua.zip
        else
            curl -L https://github.com/seaofvoices/darklua/releases/latest/download/darklua-macos-x86_64.zip -o darklua.zip
        fi
    else
        # Linux
        curl -L https://github.com/seaofvoices/darklua/releases/latest/download/darklua-linux-x86_64.zip -o darklua.zip
    fi
    unzip -o darklua.zip
    chmod +x darklua
    rm darklua.zip
    DARKLUA_CMD="./darklua"
    echo "✅ darklua downloaded"
fi

echo "Using darklua at: $DARKLUA_CMD"

# Create dist directory
mkdir -p dist

# Bundle with darklua
echo "📦 Bundling scripts..."
$DARKLUA_CMD process --config .darklua.json5 src/audit.lua dist/audit-bundled-temp.lua

# Add shebang to the bundled output
echo "📝 Adding shebang..."
echo '#!/usr/bin/env lua' > dist/audit-bundled.lua
cat dist/audit-bundled-temp.lua >> dist/audit-bundled.lua
rm dist/audit-bundled-temp.lua
chmod +x dist/audit-bundled.lua

echo "✅ Build complete!"
echo ""
echo "Generated file: dist/audit-bundled.lua"
echo ""
echo "To test:"
echo "  ./dist/audit-bundled.lua"
echo "  or: lua dist/audit-bundled.lua"
