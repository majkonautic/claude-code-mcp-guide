#!/bin/bash

echo "🚀 Claude Remote MCP Setup Wizard"

cd "$(dirname "$0")"
SCRIPT_DIR="$(pwd)"
PROJECT_ROOT="$(pwd)/.."
TARGET_DIR="$PROJECT_ROOT/.claude/mcp"

echo ""
# Step 0: Set up virtualenv
if [ ! -d "$PROJECT_ROOT/.venv" ]; then
  echo "📦 Creating Python virtual environment..."
  python3 -m venv "$PROJECT_ROOT/.venv"
else
  echo "✅ Using existing virtualenv at .venv/"
fi

# Step 0.1: Activate venv
echo "🔄 Activating virtual environment..."
source "$PROJECT_ROOT/.venv/bin/activate"

# Step 0.2: Ensure python-dotenv is installed IN THE VENV
echo "📦 Checking python-dotenv..."
if ! python -c "import dotenv" &> /dev/null; then
  echo "📦 Installing python-dotenv in virtual environment..."
  pip install python-dotenv
  
  # Verify installation
  if python -c "import dotenv; print('✅ python-dotenv installed successfully')"; then
    echo ""
  else
    echo "❌ Failed to install python-dotenv"
    exit 1
  fi
else
  echo "✅ python-dotenv already installed"
fi

echo ""

# Step 1: Ensure .claude/mcp/ exists
mkdir -p "$TARGET_DIR"
echo "✅ Ensured MCP folder at: $TARGET_DIR"

# Step 2: Copy the bridge script
if [ ! -f "$TARGET_DIR/mcp-http-bridge.py" ]; then
  cp mcp/mcp-http-bridge.py "$TARGET_DIR/"
  echo "📦 Copied mcp-http-bridge.py to .claude/mcp/"
else
  echo "✅ Bridge already present"
fi

# Step 3: Prompt for MCP
read -p "📛 MCP name (e.g. airtable): " MCP_NAME
read -p "🌐 MCP URL: " MCP_URL
read -p "🔑 MCP API Key: " MCP_API_KEY

EXTRA_SECRETS=()
while true; do
  read -p "➕ Add a service-specific secret (key=value) or press Enter to continue: " PAIR
  [[ -z "$PAIR" ]] && break
  EXTRA_SECRETS+=("$PAIR")
done

# Step 4: Write .env
MCP_FOLDER="$TARGET_DIR/$MCP_NAME"
mkdir -p "$MCP_FOLDER"
ENV_FILE="$MCP_FOLDER/.env"

echo "MCP_URL=$MCP_URL" > "$ENV_FILE"
[ -n "$MCP_API_KEY" ] && echo "MCP_API_KEY=$MCP_API_KEY" >> "$ENV_FILE"
for secret in "${EXTRA_SECRETS[@]}"; do echo "$secret" >> "$ENV_FILE"; done

# Step 5: Summary
echo ""
echo "✅ Created .env at: $ENV_FILE"
echo "-----------------------------"
cat "$ENV_FILE"
echo "-----------------------------"

# Step 6: Claude command - IMPORTANT: Using full paths with venv Python
read -p "🤖 Do you want to register this MCP in Claude now? (y/n): " CONFIRM
if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo ""
  echo "💡 Running Claude registration..."
  
  # IMPORTANT: Use absolute paths for everything
  cd "$PROJECT_ROOT"
  claude mcp add "$MCP_NAME" "$(pwd)/.venv/bin/python" "$(pwd)/.claude/mcp/mcp-http-bridge.py" "$MCP_URL" "$(pwd)/.claude/mcp/$MCP_NAME/"
  
  echo ""
  echo "✅ MCP '$MCP_NAME' registered with Claude using virtual environment!"
else
  echo ""
  echo "👉 To register manually later, run from project root:"
  echo "cd $PROJECT_ROOT"
  echo "claude mcp add $MCP_NAME \"\$(pwd)/.venv/bin/python\" \"\$(pwd)/.claude/mcp/mcp-http-bridge.py\" \"$MCP_URL\" \"\$(pwd)/.claude/mcp/$MCP_NAME/\""
fi

echo ""
echo "🎉 Done! MCP '$MCP_NAME' is ready to use in Claude."

# Step 7: Move to project root
echo ""
echo "📍 Moving to project root directory..."
cd "$PROJECT_ROOT"

# Step 8: Ask about removing the setup folder
echo ""
read -p "🗑️  Do you want to remove the claude-code-mcp-guide setup folder? (y/n): " REMOVE_CONFIRM
if [[ "$REMOVE_CONFIRM" =~ ^[Yy]$ ]]; then
  echo "🧹 Removing claude-code-mcp-guide folder..."
  rm -rf "$SCRIPT_DIR"
  echo "✅ Setup folder removed. You're now in: $(pwd)"
else
  echo "📁 Keeping claude-code-mcp-guide folder for future reference."
  echo "📍 You're now in: $(pwd)"
fi

echo ""
echo "👋 All done! Your MCP is configured and ready to use."
