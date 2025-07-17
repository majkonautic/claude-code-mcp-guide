#!/bin/bash

echo "🚀 Claude MCP Setup Wizard"
echo ""

# Step 1: Locate or create .claude/mcp
cd "$(dirname "$0")"
ROOT_DIR=$(pwd)
TARGET_DIR="$ROOT_DIR/../.claude/mcp"

mkdir -p "$TARGET_DIR"
echo "✅ Ensured MCP folder at: $TARGET_DIR"

# Step 2: Copy mcp-http-bridge.py
cp "$ROOT_DIR/mcp/mcp-http-bridge.py" "$TARGET_DIR/"
echo "📦 Copied mcp-http-bridge.py into .claude/mcp"

# Step 3: Gather user input
read -p "📛 MCP name (folder name): " MCP_NAME
read -p "🌐 MCP URL (https://your-mcp.example.com): " MCP_URL
read -p "🔑 MCP API Key (optional): " MCP_API_KEY

# Step 4: Gather additional secrets
ADDITIONAL_SECRETS=()
while true; do
  read -p "➕ Add a service-specific secret (key=value) or press Enter to skip: " PAIR
  if [[ -z "$PAIR" ]]; then
    break
  fi
  ADDITIONAL_SECRETS+=("$PAIR")
done

# Step 5: Write .env file
MCP_FOLDER="$TARGET_DIR/$MCP_NAME"
mkdir -p "$MCP_FOLDER"
ENV_FILE="$MCP_FOLDER/.env"

echo "MCP_URL=$MCP_URL" > "$ENV_FILE"
if [ -n "$MCP_API_KEY" ]; then
  echo "MCP_API_KEY=$MCP_API_KEY" >> "$ENV_FILE"
fi
for secret in "${ADDITIONAL_SECRETS[@]}"; do
  echo "$secret" >> "$ENV_FILE"
done

# Step 6: Summary
echo ""
echo "✅ MCP folder created at $MCP_FOLDER"
echo "📄 .env file content:"
echo "------------------------"
cat "$ENV_FILE"
echo "------------------------"

# Step 7: Offer Claude registration
read -p "🤖 Do you want to register this MCP in Claude now? (y/n): " CONFIRM
if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo ""
  echo "💡 Run the following command:"
  echo ""
  echo "cd $MCP_FOLDER"
  echo "claude mcp add $MCP_NAME python3 ../mcp-http-bridge.py"
  echo ""
else
  echo "👉 You can register later using:"
  echo "cd $MCP_FOLDER && claude mcp add $MCP_NAME python3 ../mcp-http-bridge.py"
fi

echo ""
echo "🎉 All set! Your MCP '$MCP_NAME' is now scaffolded and ready."

