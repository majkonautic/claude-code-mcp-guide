#!/bin/bash

echo "🚀 Claude Remote MCP Setup Wizard"
echo ""

# Step 1: Determine target directory (.claude/mcp/)
cd "$(dirname "$0")"
PROJECT_ROOT="$(pwd)/.."
TARGET_DIR="$PROJECT_ROOT/.claude/mcp"

mkdir -p "$TARGET_DIR"
echo "✅ Ensured MCP folder at: $TARGET_DIR"

# Step 2: Copy the bridge script (if not already there)
if [ ! -f "$TARGET_DIR/mcp-http-bridge.py" ]; then
  cp mcp/mcp-http-bridge.py "$TARGET_DIR/"
  echo "📦 Copied mcp-http-bridge.py to .claude/mcp"
else
  echo "📦 Bridge already exists at .claude/mcp"
fi

# Step 3: Get user input
read -p "📛 Enter MCP name (e.g. airtable): " MCP_NAME
read -p "🌐 Enter MCP URL (e.g. https://your-mcp.example.com): " MCP_URL
read -p "🔑 Enter MCP API Key (optional): " MCP_API_KEY

# Step 4: Add extra secrets
EXTRA_SECRETS=()
while true; do
  read -p "➕ Add a service-specific secret (key=value), or press Enter to finish: " SECRET
  [[ -z "$SECRET" ]] && break
  EXTRA_SECRETS+=("$SECRET")
done

# Step 5: Create MCP folder and .env
MCP_FOLDER="$TARGET_DIR/$MCP_NAME"
mkdir -p "$MCP_FOLDER"
ENV_FILE="$MCP_FOLDER/.env"

echo "MCP_URL=$MCP_URL" > "$ENV_FILE"
[ -n "$MCP_API_KEY" ] && echo "MCP_API_KEY=$MCP_API_KEY" >> "$ENV_FILE"
for item in "${EXTRA_SECRETS[@]}"; do echo "$item" >> "$ENV_FILE"; done

echo ""
echo "✅ Created .env at: $ENV_FILE"
echo "-----------------------------"
cat "$ENV_FILE"
echo "-----------------------------"

# Step 6: Show Claude command
echo ""
read -p "🤖 Do you want to register this MCP in Claude now? (y/n): " CONFIRM
if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo ""
  echo "💡 From your project root, run:"
  echo ""
  echo "claude mcp add $MCP_NAME python3 .claude/mcp/mcp-http-bridge.py $MCP_URL .claude/mcp/$MCP_NAME/"
  echo ""
else
  echo "👉 You can register later with:"
  echo "cd to your project root, then run:"
  echo "claude mcp add $MCP_NAME python3 .claude/mcp/mcp-http-bridge.py $MCP_URL .claude/mcp/$MCP_NAME/"
fi

echo ""
echo "🎉 All done! Your MCP '$MCP_NAME' is ready."

