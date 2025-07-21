
# Claude Remote MCP Bridge

Connect Claude Code to any remote MCP (Model Context Protocol) server with secure credential management.

## 🎯 What This Does

This tool enables Claude Code to interact with remote MCP servers (like Airtable, AWS, Supabase, etc.) through either HTTP connections or a secure Python bridge. Your API keys and credentials stay secure and are properly managed based on your chosen connection method.

## 🚀 Quick Start

1. Clone this repository into your project:
   ```bash
   git clone https://github.com/majkonautic/claude-code-mcp-guide.git
   ```

2. Run the setup wizard:
   ```bash
   cd claude-code-mcp-guide
   ./add_remote_mcp.sh
   ```

3. Follow the prompts to configure your MCP connection

4. Start using your MCP tools in Claude Code!

## 📋 Prerequisites

- macOS, Linux, or WSL on Windows
- Python 3.6 or higher
- Claude Code CLI (`npm install -g @anthropic-ai/claude-code`)

## 🔌 Connection Methods

### HTTP Server (Recommended for Remote Servers)
Direct connection to remote MCP servers using HTTP protocol with header-based authentication.

### Bridge Server (For Local Testing)
Python-based bridge that reads credentials from local `.env` files.

### Both
Configure both methods for maximum flexibility.

## 📁 Project Structure

After setup:
```
your-project/
├── .venv/                        # Python virtual environment
├── .mcp.json                     # HTTP server configurations
├── .claude/
│   └── mcp/
│       ├── mcp-http-bridge.py    # Universal bridge script
│       ├── airtable/
│       │   └── .env              # Airtable credentials (bridge mode)
│       └── aws/
│           └── .env              # AWS credentials (bridge mode)
└── .gitignore                    # Auto-updated to exclude sensitive files
```

## 🛠️ How It Works

### Setup Script (`add_remote_mcp.sh`)
- Creates a Python virtual environment
- Installs required dependencies (python-dotenv)
- Allows you to choose between HTTP, Bridge, or Both connection methods
- Stores configurations in `.mcp.json` (HTTP) or `.env` files (Bridge)
- Supports adding multiple MCP servers in one session
- Automatically updates `.gitignore` for security

### HTTP Mode Configuration
Stores configuration in `.mcp.json`:
```json
{
  "mcpServers": {
    "airtable": {
      "type": "http",
      "url": "https://your-mcp-server.com/",
      "headers": {
        "x-api-key": "your-mcp-api-key",
        "x-airtable-api-key": "patXXXXXXXXXXXX",
        "x-airtable-base-id": "appXXXXXXXXXXXX"
      }
    }
  }
}
```

### Bridge Mode Configuration
Uses local `.env` files:
```bash
MCP_URL=https://your-mcp-server.com/
MCP_API_KEY=your-mcp-api-key
AIRTABLE_API_KEY=patXXXXXXXXXXXX
AIRTABLE_BASE_ID=appXXXXXXXXXXXX
```


## 🔧 Troubleshooting

### Testing Your Connection
```bash
# Test with curl (HTTP mode)
curl -X POST https://your-mcp-server.com/ \
  -H 'Content-Type: application/json' \
  -H 'X-API-Key: your-mcp-api-key' \
  -H 'X-Airtable-API-Key: patXXXXXXXXXXXX' \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/list",
    "id": 1
  }'

# Test Claude connection
claude mcp list
/mcp  # Inside Claude Code
```

### Common Issues

#### Invalid Content Type (SSE vs HTTP)
- Error: `SSE error: Invalid content type, expected "text/event-stream"`
- Solution: Change `"type": "sse"` to `"type": "http"` in `.mcp.json`

#### Authentication Failed
- Error: `AUTHENTICATION_REQUIRED`
- Solution: Verify your API keys are correct and properly formatted
- For Airtable: Token format is `patXXXXX.XXXXXXXXXXXXXXXXXX`

#### Connection Timeout
- Ensure your MCP server implements the `initialize` method
- Check server logs for any startup errors
- Verify URL is accessible from your location

## 🤖 Using in Claude Code

Once configured, just ask Claude:
```
List all tables in my Airtable base

Show me records from the Marketing Campaigns table

Create a new campaign with test data
```

Claude will automatically use the appropriate MCP server based on your request.

## 🧰 MCP Management Commands

```bash
# List all registered MCPs
claude mcp list

# Test an MCP connection
claude mcp test your-mcp-name

# View connection status in Claude
/mcp

# Remove an MCP
claude mcp remove your-mcp-name

# Check your configuration
cat .mcp.json
```

## 🔐 Security Best Practices

1. **Never commit sensitive files** - `.mcp.json` and `.env` are automatically gitignored
2. **Use minimal permissions** - Only grant what's needed
3. **Rotate API keys** - Every 90 days recommended
4. **Use environment-specific configs** - Different keys for dev/staging/prod
5. **Monitor usage** - Check your provider's logs regularly

## 🛠️ Advanced Configuration

### Custom Headers
Your MCP server can read any headers you configure:
```json
"headers": {
  "x-api-key": "server-auth-key",
  "x-custom-header": "custom-value",
  "x-service-token": "service-specific-token"
}
```

### Environment Variables (Bridge Mode)
The bridge passes all variables from `.env` to the MCP server process.

### Multiple Environments
Create different `.mcp.json` files for different environments:
- `.mcp.json` - Local development (gitignored)
- `.mcp.staging.json` - Staging environment
- `.mcp.prod.json` - Production environment

## 📝 Creating Your Own MCP Server

Your server should handle these JSON-RPC methods:

```javascript
// Required: Protocol initialization
{
  "jsonrpc": "2.0",
  "method": "initialize",
  "params": { "protocolVersion": "2024-11-05" },
  "id": 1
}

// Required: List available tools
{
  "jsonrpc": "2.0",
  "method": "tools/list",
  "id": 2
}

// Required: Execute tool
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "tool_name",
    "arguments": { ... }
  },
  "id": 3
}
```

Response format must be JSON-RPC 2.0 compliant.

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Test with at least one MCP server
4. Submit a pull request

Areas for contribution:
- Additional service integrations
- Improved error handling
- Documentation improvements
- Example MCP server implementations

## 📄 License

MIT License - see LICENSE file for details

## 🙏 Acknowledgments

- Built for the Claude Code community
- Thanks to @bartoszmajewski for extensive testing and feedback
- Inspired by the Model Context Protocol specification

---

**Need help?** Open an issue on GitHub or reach out to the community.
