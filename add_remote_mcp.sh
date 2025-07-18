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
read -p "🔑 MCP API Key: " MCP_API_KEY

# Collect service-specific environment variables
echo ""
echo "📝 Add service-specific environment variables"
echo "   Examples:"
echo "   - For Airtable: AIRTABLE_BASE_ID=appXXXX"
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

# Step 4: Write .env
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

# Step 6: Update .gitignore
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

# Step 7: Claude registration
echo ""
echo "🤖 Claude Code MCP Registration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "To use this MCP in Claude Code, you need to register it."
echo ""

read -p "Do you want to register this MCP in Claude Code now? (y/n): " CONFIRM
if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo ""
  echo "💡 Running Claude registration..."
  
  cd "$PROJECT_ROOT"
  
  # Register with Claude Code
  # The bridge will load the .env from the specified folder
  claude mcp add "$MCP_NAME" \
    "$(pwd)/.venv/bin/python" \
    "$(pwd)/.claude/mcp/mcp-http-bridge.py" \
    "$(pwd)/.claude/mcp/$MCP_NAME/"
  
  if [ $? -eq 0 ]; then
    echo ""
    echo "✅ MCP '$MCP_NAME' registered successfully with Claude Code!"
    echo ""
    echo "🔍 Registration details:"
    echo "   Name: $MCP_NAME"
    echo "   Python: $(pwd)/.venv/bin/python"
    echo "   Bridge: $(pwd)/.claude/mcp/mcp-http-bridge.py"
    echo "   Config: $(pwd)/.claude/mcp/$MCP_NAME/.env"
    echo ""
    echo "📝 To verify: claude mcp list"
    echo "🧪 To test: claude mcp test $MCP_NAME"
  else
    echo ""
    echo "⚠️  Registration may have failed. Try manual registration below."
  fi
else
  echo ""
  echo "📝 Manual Registration Instructions"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "To register this MCP manually, run the following command from your project root:"
  echo ""
  echo "cd $PROJECT_ROOT"
  echo ""
  echo "claude mcp add $MCP_NAME \\"
  echo "  \"$(pwd)/.venv/bin/python\" \\"
  echo "  \"$(pwd)/.claude/mcp/mcp-http-bridge.py\" \\"
  echo "  \"$(pwd)/.claude/mcp/$MCP_NAME/\""
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "After registration:"
  echo "- Verify with: claude mcp list"
  echo "- Test with: claude mcp test $MCP_NAME"
  echo "- Remove with: claude mcp remove $MCP_NAME"
fi

# Step 8: Usage instructions
echo ""
echo "🎉 Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📚 How it works:"
echo "   1. Your MCP secrets are stored in: .claude/mcp/$MCP_NAME/.env"
echo "   2. The bridge script loads these secrets using python-dotenv"
echo "   3. Claude Code uses your virtual environment Python"
echo "   4. All communication goes through your secure MCP server"
echo ""
echo "🔧 Troubleshooting:"
echo "   - Connection issues: Check your MCP_URL and MCP_API_KEY"
echo "   - Module errors: Make sure you're using the venv Python"
echo "   - List all MCPs: claude mcp list"
echo "   - View logs: claude mcp logs $MCP_NAME"
echo ""
echo "🔐 Security notes:"
echo "   - Never commit .env files (they're gitignored)"
echo "   - Keep your API keys secure"
echo "   - Each MCP has isolated credentials"

# Step 9: Move to project root
echo ""
echo "📍 Moving to project root directory..."
cd "$PROJECT_ROOT"
echo "📍 You're now in: $(pwd)"

# Step 10: Ask about removing the setup folder
echo ""
read -p "🗑️  Do you want to remove the claude-code-mcp-guide setup folder? (y/n): " REMOVE_CONFIRM
if [[ "$REMOVE_CONFIRM" =~ ^[Yy]$ ]]; then
  echo "🧹 Removing claude-code-mcp-guide folder..."
  rm -rf "$SCRIPT_DIR"
  echo "✅ Setup folder removed."
else
  echo "📁 Keeping claude-code-mcp-guide folder for future reference."
fi

echo ""
echo "👋 All done! Your MCP is ready to use in Claude Code."
echo ""
echo "💡 Next steps:"
echo "   - Start Claude Code in this project"
echo "   - Your MCP tools will be available automatically"
echo "   - Type '/' in Claude to see available MCP commands"
echo ""
