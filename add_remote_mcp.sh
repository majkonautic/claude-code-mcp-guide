#!/bin/bash

echo ""
echo "🚀 Claude Remote MCP Setup Wizard"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

cd "$(dirname "$0")"
SCRIPT_DIR="$(pwd)"
PROJECT_ROOT="$(pwd)/.."
TARGET_DIR="$PROJECT_ROOT/.claude/mcp"

# Function to set up an MCP
setup_mcp() {
  echo ""
  echo "📝 MCP Configuration"
  echo "────────────────────"
  echo ""
  
  read -p "📛 MCP name (e.g. airtable, aws, supabase): " MCP_NAME

  # Validate MCP name
  if [[ -z "$MCP_NAME" ]]; then
    echo "❌ MCP name cannot be empty"
    return 1
  fi

  echo ""
  read -p "🌐 MCP URL (e.g. https://your-mcp-server.com/): " MCP_URL
  
  echo ""
  read -p "🔑 MCP API Key (for x-api-key header): " MCP_API_KEY

  # Ask for server type
  echo ""
  echo "📡 Server Type Selection"
  echo "────────────────────────"
  echo "   1. HTTP server (recommended for remote servers)"
  echo "   2. Bridge server (for local testing)"
  echo "   3. Both (HTTP + Bridge)"
  echo ""
  read -p "   Select option (1-3): " SERVER_TYPE

  # Collect service-specific environment variables
  echo ""
  echo "📝 Add service-specific headers/environment variables"
  echo "────────────────────────────────────────────────────"
  echo ""
  echo "   Examples:"
  echo "   - For Airtable: x-airtable-api-key, x-airtable-base-id"
  echo "   - For AWS: x-aws-access-key-id, x-aws-secret-access-key"
  echo "   - For Supabase: x-supabase-url, x-supabase-service-role-key"
  echo ""

  EXTRA_HEADERS=()
  EXTRA_VARS=()
  
  while true; do
    read -p "   Header/Variable name (or press Enter to finish): " VAR_NAME
    [[ -z "$VAR_NAME" ]] && break
    read -p "   Value for $VAR_NAME: " VAR_VALUE
    if [[ -n "$VAR_VALUE" ]]; then
      # Store for both header and env format
      EXTRA_HEADERS+=("\"$VAR_NAME\": \"$VAR_VALUE\"")
      EXTRA_VARS+=("$VAR_NAME=$VAR_VALUE")
    fi
  done

  # Handle HTTP server configuration
  if [[ "$SERVER_TYPE" == "1" ]] || [[ "$SERVER_TYPE" == "3" ]]; then
    echo ""
    echo "🌐 Configuring HTTP server..."
    echo ""
    
    # Update .mcp.json for HTTP
    MCP_JSON_FILE="$PROJECT_ROOT/.mcp.json"
    
    # Create Python script to update JSON for HTTP
    cat > /tmp/update_mcp_json_http.py << EOPYTHON
import json
import sys
import os

config_file = sys.argv[1]
mcp_name = sys.argv[2]
mcp_url = sys.argv[3]
mcp_api_key = sys.argv[4] if len(sys.argv) > 4 else ""

# Read existing configuration or create new
if os.path.exists(config_file):
    with open(config_file, 'r') as f:
        config = json.load(f)
else:
    config = {}

# Ensure mcpServers key exists
if "mcpServers" not in config:
    config["mcpServers"] = {}

# Create the MCP configuration for HTTP
mcp_config = {
    "type": "http",
    "url": mcp_url,
    "headers": {}
}

# Add API key header
if mcp_api_key:
    mcp_config["headers"]["x-api-key"] = mcp_api_key

# Add extra headers from command line arguments
for i in range(5, len(sys.argv)):
    if '=' in sys.argv[i]:
        key, value = sys.argv[i].split('=', 1)
        mcp_config["headers"][key] = value

# Add to config
config["mcpServers"][mcp_name] = mcp_config

# Write updated configuration
with open(config_file, 'w') as f:
    json.dump(config, f, indent=2)
EOPYTHON

    # Run the Python script with all parameters
    python /tmp/update_mcp_json_http.py "$MCP_JSON_FILE" "$MCP_NAME" "$MCP_URL" "$MCP_API_KEY" "${EXTRA_VARS[@]}"
    
    if [ $? -eq 0 ]; then
      echo "✅ Updated .mcp.json with $MCP_NAME HTTP configuration"
    else
      echo "❌ Failed to update .mcp.json"
    fi
    
    # Clean up
    rm -f /tmp/update_mcp_json_http.py
  fi

  # Handle Bridge server configuration
  if [[ "$SERVER_TYPE" == "2" ]] || [[ "$SERVER_TYPE" == "3" ]]; then
    echo ""
    echo "🌉 Configuring Bridge server..."
    echo ""
    
    # Write .env for bridge
    MCP_FOLDER="$TARGET_DIR/$MCP_NAME"
    mkdir -p "$MCP_FOLDER"
    ENV_FILE="$MCP_FOLDER/.env"

    echo "MCP_URL=$MCP_URL" > "$ENV_FILE"
    [ -n "$MCP_API_KEY" ] && echo "MCP_API_KEY=$MCP_API_KEY" >> "$ENV_FILE"

    # Add service-specific variables
    for var in "${EXTRA_VARS[@]}"; do 
      echo "$var" >> "$ENV_FILE"
    done

    echo "✅ Created .env at: $ENV_FILE"
    
    # Register bridge with Claude Code
    cd "$PROJECT_ROOT"
    
    claude mcp add "${MCP_NAME}-bridge" \
      "$(pwd)/.venv/bin/python" \
      "$(pwd)/.claude/mcp/mcp-http-bridge.py" \
      "$(pwd)/.claude/mcp/$MCP_NAME/"
    
    if [ $? -eq 0 ]; then
      echo ""
      echo "✅ Bridge MCP '${MCP_NAME}-bridge' registered successfully!"
    else
      echo ""
      echo "⚠️  Bridge registration may have failed."
    fi
  fi

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ MCP '$MCP_NAME' configuration complete!"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
}

# Initial setup
echo "📦 Initial Setup"
echo "───────────────"
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

# Update .gitignore
if [ -f "$PROJECT_ROOT/.gitignore" ]; then
  # Check if .env is already ignored
  if ! grep -q "^\.env$" "$PROJECT_ROOT/.gitignore" && ! grep -q "^\*\.env$" "$PROJECT_ROOT/.gitignore"; then
    echo "" >> "$PROJECT_ROOT/.gitignore"
    echo "# MCP secrets" >> "$PROJECT_ROOT/.gitignore"
    echo ".env" >> "$PROJECT_ROOT/.gitignore"
    echo "*.env" >> "$PROJECT_ROOT/.gitignore"
    echo ".claude/mcp/*/.env" >> "$PROJECT_ROOT/.gitignore"
    echo ".mcp.json" >> "$PROJECT_ROOT/.gitignore"
    echo "✅ Added .env files and .mcp.json to .gitignore"
  fi
else
  cat > "$PROJECT_ROOT/.gitignore" << 'EOF'
# MCP secrets
.env
*.env
.claude/mcp/*/.env
.mcp.json

# Python
__pycache__/
*.py[cod]
.venv/
venv/
EOF
  echo "✅ Created .gitignore with .env exclusions"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Main loop for adding MCPs
while true; do
  setup_mcp
  
  echo ""
  read -p "🔄 Do you want to add another MCP? (y/n): " ADD_ANOTHER
  if [[ ! "$ADD_ANOTHER" =~ ^[Yy]$ ]]; then
    break
  fi
  echo ""
done

# Final summary
echo ""
echo "🎉 All Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Show final .mcp.json if it exists
if [ -f "$PROJECT_ROOT/.mcp.json" ]; then
  echo "📋 Final .mcp.json configuration:"
  echo "────────────────────────────────────────────────────────"
  cat "$PROJECT_ROOT/.mcp.json"
  echo ""
  echo "────────────────────────────────────────────────────────"
  echo ""
fi

echo "🚀 To use your MCPs:"
echo "   1. Start Claude Code: claude"
echo "   2. Check status: /mcp"
echo "   3. Your MCP tools will be available"
echo ""
echo "🔧 Troubleshooting:"
echo "   - Connection issues: Check your MCP_URL and API keys"
echo "   - View .mcp.json: cat .mcp.json"
echo "   - List all MCPs: claude mcp list"
echo "   - Test specific MCP: /mcp and select your server"
echo ""
echo "🔐 Security notes:"
echo "   - Never commit .env files or .mcp.json with real keys"
echo "   - Keep your API keys secure"
echo "   - Each MCP has isolated credentials"
echo ""

# Move to project root
cd "$PROJECT_ROOT"
echo "📍 You're now in: $(pwd)"
echo ""

# Ask about removing the setup folder
read -p "🗑️  Do you want to remove the claude-remote-mcp setup folder? (y/n): " REMOVE_CONFIRM
if [[ "$REMOVE_CONFIRM" =~ ^[Yy]$ ]]; then
  echo "🧹 Removing claude-remote-mcp folder..."
  rm -rf "$SCRIPT_DIR"
  echo "✅ Setup folder removed."
else
  echo "📁 Keeping claude-remote-mcp folder for future reference."
fi

echo ""
echo "👋 All done! Your MCPs are ready to use in Claude Code."
echo ""
