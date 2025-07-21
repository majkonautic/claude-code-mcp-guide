#!/bin/bash

echo "🚀 Claude Remote MCP Setup Wizard"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd "$(dirname "$0")"
SCRIPT_DIR="$(pwd)"
PROJECT_ROOT="$(pwd)/.."
TARGET_DIR="$PROJECT_ROOT/.claude/mcp"

echo ""
# Step 0: Set up virtualenv
if [ ! -d "$PROJECT_ROOT/.venv" ]; then
  echo "📦 Creating Python virtual environment..."
  python3 -m venv "$PROJECT_ROOT/.venv"
  if [ $? -ne 0 ]; then
    echo "❌ Failed to create virtual environment. Make sure Python 3 is installed."
    exit 1
  fi
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
  if [ ! -f "mcp/mcp-http-bridge.py" ]; then
    echo "❌ Error: mcp/mcp-http-bridge.py not found in setup directory"
    exit 1
  fi
  cp mcp/mcp-http-bridge.py "$TARGET_DIR/"
  echo "📦 Copied mcp-http-bridge.py to .claude/mcp/"
else
  echo "✅ Bridge already present"
fi

# Step 3: Prompt for MCP
echo ""
echo "📝 MCP Configuration"
echo "────────────────────"
read -p "📛 MCP name (e.g. airtable, aws, supabase): " MCP_NAME

# Validate MCP name
if [[ -z "$MCP_NAME" ]]; then
  echo "❌ MCP name cannot be empty"
  exit 1
fi

read -p "🌐 MCP URL (e.g. https://your-mcp-server.com/): " MCP_URL
read -p "🔑 MCP API Key (for x-api-key header): " MCP_API_KEY

# Collect service-specific environment variables
echo ""
echo "📝 Add service-specific environment variables"
echo "   Examples:"
echo "   - For Airtable: AIRTABLE_API_KEY=patXXXX, baseId=appXXXX"
echo "   - For AWS: AWS_ACCESS_KEY_ID=AKIAXXXX, AWS_SECRET_ACCESS_KEY=xxxx, AWS_DEFAULT_REGION=us-east-1"
echo "   - For Supabase: SUPABASE_URL=https://xxx.supabase.co, SUPABASE_SERVICE_ROLE_KEY=xxx"
echo ""

EXTRA_VARS=()
while true; do
  read -p "   Variable name (or press Enter to finish): " VAR_NAME
  [[ -z "$VAR_NAME" ]] && break
  read -p "   Value for $VAR_NAME: " VAR_VALUE
  if [[ -n "$VAR_VALUE" ]]; then
    EXTRA_VARS+=("$VAR_NAME=$VAR_VALUE")
  fi
done

# Step 4: Write .env (for bridge-based MCPs)
MCP_FOLDER="$TARGET_DIR/$MCP_NAME"
mkdir -p "$MCP_FOLDER"
ENV_FILE="$MCP_FOLDER/.env"

echo "MCP_URL=$MCP_URL" > "$ENV_FILE"
[ -n "$MCP_API_KEY" ] && echo "MCP_API_KEY=$MCP_API_KEY" >> "$ENV_FILE"

# Add service-specific variables
for var in "${EXTRA_VARS[@]}"; do 
  echo "$var" >> "$ENV_FILE"
done

# Step 5: Summary
echo ""
echo "✅ Created .env at: $ENV_FILE"
echo "────────────────────────────────────────────────────────"
cat "$ENV_FILE"
echo "────────────────────────────────────────────────────────"

# Step 6: Update or create .mcp.json
MCP_JSON_FILE="$PROJECT_ROOT/.mcp.json"
echo ""
echo "📄 Updating .mcp.json configuration..."

# Create Python script to update JSON
cat > /tmp/update_mcp_json.py << EOPYTHON
import json
import sys
import os

config_file = sys.argv[1]
mcp_name = sys.argv[2]
mcp_url = sys.argv[3]
mcp_api_key = sys.argv[4] if len(sys.argv) > 4 else ""

# Parse extra vars from remaining arguments
extra_vars = {}
for i in range(5, len(sys.argv)):
    if '=' in sys.argv[i]:
        key, value = sys.argv[i].split('=', 1)
        extra_vars[key] = value

# Read existing configuration or create new
if os.path.exists(config_file):
    with open(config_file, 'r') as f:
        config = json.load(f)
else:
    config = {}

# Ensure mcpServers key exists
if "mcpServers" not in config:
    config["mcpServers"] = {}

# Create the MCP configuration
mcp_config = {
    "type": "sse",
    "url": mcp_url
}

# Add headers if API key provided
if mcp_api_key:
    mcp_config["headers"] = {
        "x-api-key": mcp_api_key
    }

# Add env vars if any
if extra_vars:
    mcp_config["env"] = extra_vars

# Add to config
config["mcpServers"][mcp_name] = mcp_config

# Write updated configuration
with open(config_file, 'w') as f:
    json.dump(config, f, indent=2)

print(json.dumps(mcp_config, indent=2))
EOPYTHON

# Run the Python script with all parameters
python /tmp/update_mcp_json.py "$MCP_JSON_FILE" "$MCP_NAME" "$MCP_URL" "$MCP_API_KEY" "${EXTRA_VARS[@]}"

if [ $? -eq 0 ]; then
    echo "✅ Updated .mcp.json with $MCP_NAME configuration"
    echo ""
    echo "📋 Full .mcp.json contents:"
    echo "────────────────────────────────────────────────────────"
    cat "$MCP_JSON_FILE"
    echo ""
    echo "────────────────────────────────────────────────────────"
else
    echo "❌ Failed to update .mcp.json"
fi

# Clean up
rm -f /tmp/update_mcp_json.py

# Step 7: Update .gitignore
if [ -f "$PROJECT_ROOT/.gitignore" ]; then
  # Check if .env is already ignored
  if ! grep -q "^\.env$" "$PROJECT_ROOT/.gitignore" && ! grep -q "^\*\.env$" "$PROJECT_ROOT/.gitignore"; then
    echo "" >> "$PROJECT_ROOT/.gitignore"
    echo "# MCP secrets" >> "$PROJECT_ROOT/.gitignore"
    echo ".env" >> "$PROJECT_ROOT/.gitignore"
    echo "*.env" >> "$PROJECT_ROOT/.gitignore"
    echo ".claude/mcp/*/.env" >> "$PROJECT_ROOT/.gitignore"
    echo "✅ Added .env files to .gitignore"
  fi
else
  cat > "$PROJECT_ROOT/.gitignore" << 'EOF'
# MCP secrets
.env
*.env
.claude/mcp/*/.env

# Python
__pycache__/
*.py[cod]
.venv/
venv/
EOF
  echo "✅ Created .gitignore with .env exclusions"
fi

# Step 8: Claude registration
echo ""
echo "🤖 Claude Code MCP Registration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Your MCP has been configured in .mcp.json"
echo "Claude Code will automatically load it when you start claude in this directory."
echo ""

# Check for known compatibility issues
COMPATIBILITY_NOTE=""
if [[ "$MCP_URL" == *"aws"* ]]; then
  COMPATIBILITY_NOTE="⚠️  Note: AWS MCP servers may use a non-standard API format."
fi

if [[ -n "$COMPATIBILITY_NOTE" ]]; then
  echo "$COMPATIBILITY_NOTE"
  echo ""
fi

# Ask if user wants to register bridge-based MCP (for local testing)
read -p "Do you also want to register a bridge-based version for testing? (y/n): " CONFIRM
if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo ""
  echo "💡 Running Claude registration for bridge..."
  
  cd "$PROJECT_ROOT"
  
  # Register with Claude Code
  # The bridge will load the .env from the specified folder
  claude mcp add "${MCP_NAME}-bridge" \
    "$(pwd)/.venv/bin/python" \
    "$(pwd)/.claude/mcp/mcp-http-bridge.py" \
    "$(pwd)/.claude/mcp/$MCP_NAME/"
  
  if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Bridge MCP '${MCP_NAME}-bridge' registered successfully!"
    echo ""
    echo "🔍 Registration details:"
    echo "   Name: ${MCP_NAME}-bridge"
    echo "   Python: $(pwd)/.venv/bin/python"
    echo "   Bridge: $(pwd)/.claude/mcp/mcp-http-bridge.py"
    echo "   Config: $(pwd)/.claude/mcp/$MCP_NAME/.env"
    echo ""
    echo "📝 To verify: claude mcp list"
    echo "🧪 To test: claude mcp test ${MCP_NAME}-bridge"
  else
    echo ""
    echo "⚠️  Bridge registration may have failed."
  fi
fi

# Step 9: Usage instructions
echo ""
echo "🎉 Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📚 Your MCP is configured in two ways:"
echo "   1. Native SSE in .mcp.json (recommended)"
echo "   2. Bridge-based in .env (optional, for testing)"
echo ""
echo "🚀 To use your MCP:"
echo "   1. Start Claude Code: claude"
echo "   2. Check status: /mcp"
echo "   3. Your $MCP_NAME tools will be available"
echo ""
echo "🔧 Troubleshooting:"
echo "   - Connection issues: Check your MCP_URL and API key"
echo "   - View .mcp.json: cat .mcp.json"
echo "   - Test specific MCP: /mcp and select your server"
echo ""
echo "🔐 Security notes:"
echo "   - Never commit .env files or .mcp.json with real keys"
echo "   - Keep your API keys secure"
echo "   - Each MCP has isolated credentials"

# Step 10: Move to project root
echo ""
echo "📍 Moving to project root directory..."
cd "$PROJECT_ROOT"
echo "📍 You're now in: $(pwd)"

# Step 11: Ask about removing the setup folder
echo ""
read -p "🗑️  Do you want to remove the claude-remote-mcp setup folder? (y/n): " REMOVE_CONFIRM
if [[ "$REMOVE_CONFIRM" =~ ^[Yy]$ ]]; then
  echo "🧹 Removing claude-remote-mcp folder..."
  rm -rf "$SCRIPT_DIR"
  echo "✅ Setup folder removed."
else
  echo "📁 Keeping claude-remote-mcp folder for future reference."
fi

echo ""
echo "👋 All done! Your MCP is ready to use in Claude Code."
echo ""
echo "💡 Next steps:"
echo "   - Start Claude Code in this project"
echo "   - Your MCP tools will be available automatically"
echo "   - Type '/' in Claude to see available MCP commands"
echo ""
