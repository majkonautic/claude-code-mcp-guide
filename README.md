# Claude Remote MCP Bridge

Connect Claude Code to any remote MCP (Model Context Protocol) server with secure credential management.

## 🎯 What This Does

This tool enables Claude Code to interact with remote MCP servers (like Airtable, AWS, Supabase, etc.) through a secure HTTP bridge. Your API keys and credentials stay local on your machine and are never exposed.

## 🚀 Quick Start

1. Clone this repository into your project:
   ```bash
   git clone https://github.com/majkonautic/claude-remote-mcp.git
   ```

2. Run the setup wizard:
   ```bash
   cd claude-remote-mcp
   ./add_remote_mcp.sh
   ```

3. Follow the prompts to configure your MCP connection

4. Start using your MCP tools in Claude Code!

## 📋 Prerequisites

- macOS, Linux, or WSL on Windows
- Python 3.6 or higher
- Claude Code CLI (`npm install -g @anthropic-ai/claude-code`)

## 📁 Project Structure

After setup:
```
your-project/
├── .venv/                    # Python virtual environment
├── .claude/
│   └── mcp/
│       ├── mcp-http-bridge.py    # Universal bridge script
│       ├── airtable/
│       │   └── .env              # Airtable credentials
│       └── aws/
│           └── .env              # AWS credentials
└── .gitignore                    # Auto-updated to exclude .env files
```

## 🛠️ How It Works

1. **Setup Script** (`add_remote_mcp.sh`):
   - Creates a Python virtual environment
   - Installs required dependencies (python-dotenv)
   - Sets up the bridge script in `.claude/mcp/`
   - Stores your credentials securely in `.env` files
   - Registers the MCP with Claude Code

2. **Universal HTTP Bridge** (`mcp-http-bridge.py`):
   - Translates between Claude's MCP protocol and remote servers
   - Loads credentials from local `.env` files
   - Auto-detects server types (standard MCP vs custom APIs)
   - Handles authentication via `X-API-Key` header
   - Supports environment variable passthrough

3. **Security**:
   - API keys stored locally in `.env` files
   - `.gitignore` automatically updated
   - Each MCP has isolated credentials
   - No credentials sent to Claude

## 📚 Supported Services

### ✅ Airtable
Full support for all Airtable operations:
- List/search records
- Create/update/delete records
- List bases and tables
- Create tables and fields

Example `.env`:
```bash
MCP_URL=https://your-airtable-mcp.com/
MCP_API_KEY=your-api-key
AIRTABLE_API_KEY=patXXXXXXXXXXXX
AIRTABLE_BASE_ID=appXXXXXXXXXXXX
```

### ⚠️ AWS
Limited support (non-standard API):
- S3: List buckets, list objects
- EC2: Describe/start/stop instances
- Lambda: Invoke functions
- CloudWatch: Get logs
- IAM: Get identity, assume role

Example `.env`:
```bash
MCP_URL=https://your-aws-mcp.com/
MCP_API_KEY=your-api-key
AWS_ACCESS_KEY_ID=AKIAXXXXXXXXX
AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxx
AWS_DEFAULT_REGION=us-east-1
```

### 🔜 Coming Soon
- Supabase
- Google Sheets
- Firebase
- Stripe

## 🔧 Troubleshooting

### Connection Timeout
```
Error: Connection to MCP server "name" timed out
```
- Ensure all print statements in bridge have `flush=True`
- Check you're in the project root when running Claude
- Verify the bridge script has execute permissions

### Invalid API Key (403)
```
Error: Remote MCP server error (HTTP 403): {"error":"Invalid API Key"}
```
- Verify `X-API-Key` header is expected by server
- Check API key in `.env` file
- Some servers may expect different header names

### No Tools Available
- Check if server implements standard MCP protocol
- AWS servers use custom format (handled automatically)
- Run `claude mcp test your-mcp-name` to debug

### Testing Manually
```bash
# Test the bridge directly
source .venv/bin/activate
python .claude/mcp/mcp-http-bridge.py .claude/mcp/airtable/

# In another terminal, check the .env was loaded
cat .claude/mcp/airtable/.env
```

## 🤖 Using in Claude Code

Once registered, just ask Claude:
```
I have an Airtable MCP configured. Please list all records in my Tasks table.
```

Or for AWS:
```
I have an AWS MCP set up. Can you list my S3 buckets?
```

## 🧰 MCP Management Commands

```bash
# List all registered MCPs
claude mcp list

# Test an MCP connection
claude mcp test your-mcp-name

# View MCP logs
claude mcp logs your-mcp-name

# Remove an MCP
claude mcp remove your-mcp-name

# Remove from specific scope
claude mcp remove your-mcp-name -s local
claude mcp remove your-mcp-name -s project
```

## 🔐 Security Best Practices

1. **Never commit `.env` files** - They're automatically gitignored
2. **Use minimal permissions** - Only grant what's needed
3. **Rotate API keys** - Every 90 days recommended
4. **Monitor usage** - Check your provider's logs
5. **One service per MCP** - Isolate credentials

## 🛠️ Manual Setup

If you prefer manual setup over the wizard:

```bash
# 1. Create virtual environment
python3 -m venv .venv
source .venv/bin/activate
pip install python-dotenv

# 2. Set up MCP directory
mkdir -p .claude/mcp/my-service
cp claude-remote-mcp/mcp/mcp-http-bridge.py .claude/mcp/

# 3. Create .env file
cat > .claude/mcp/my-service/.env << EOF
MCP_URL=https://my-service-mcp.com/
MCP_API_KEY=my-api-key
SERVICE_SPECIFIC_KEY=value
EOF

# 4. Register with Claude
claude mcp add my-service \
  "$(pwd)/.venv/bin/python" \
  "$(pwd)/.claude/mcp/mcp-http-bridge.py" \
  "$(pwd)/.claude/mcp/my-service/"
```

## 📝 Creating Your Own MCP Server

MCP servers should implement:
- `initialize` - Protocol handshake
- `tools/list` - Return available tools
- `tools/call` - Execute tool with parameters

Expected response format:
```json
{
  "tools": [
    {
      "name": "tool_name",
      "description": "What this tool does",
      "inputSchema": {
        "type": "object",
        "properties": {...},
        "required": [...]
      }
    }
  ]
}
```

Authentication should use `X-API-Key` header.

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Test with at least one MCP server
4. Submit a pull request

Areas for contribution:
- Additional service examples
- Bridge improvements
- Documentation
- Test scripts

## 📄 License

MIT License - see LICENSE file for details

## 🙏 Acknowledgments

- Built for the Claude Code community
- Thanks to @bartoszmajewski for extensive testing
- Inspired by the Model Context Protocol specification

---

**Need help?** Open an issue on GitHub or reach out to the community.
