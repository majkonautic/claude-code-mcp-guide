# Claude Code MCP Guide

Connect Claude Code to any remote MCP (Model Context Protocol) server with **one simple command**. Choose between direct HTTP connections or a universal bridge - all configured automatically with our setup wizard.

## 🎯 What This Does

This tool makes connecting Claude Code to remote MCP servers **incredibly easy**. Just run one script, answer a few questions, and you're connected! The setup wizard handles all the complexity - Python environments, credential management, security configurations, and protocol setup.

## ⚡ Super Quick Start - One Command Setup

```bash
# Clone and run - that's it!
git clone https://github.com/majkonautic/claude-code-mcp-guide.git
cd claude-code-mcp-guide
./add_remote_mcp.sh
```

**The setup wizard will:**
- ✅ Create Python virtual environment automatically
- ✅ Install all required dependencies  
- ✅ Let you choose your connection method (HTTP or Bridge)
- ✅ Guide you through credential setup with clear prompts
- ✅ Configure security and `.gitignore` automatically
- ✅ Test your connection to ensure it works
- ✅ Set up multiple MCP servers in one session

**In 2-3 minutes, you'll have a working MCP connection!**

## 🔌 Choose Your Connection Method

The setup wizard offers two approaches - pick what works best for you:

### Option 1: Direct HTTP Connection (.mcp.json)
**Perfect for**: Simple setups, single-user scenarios, direct server access

**What it does**: Connects directly to MCP servers using JSON configuration
```json
{
  "mcpServers": {
    "airtable": {
      "type": "http",
      "url": "https://your-mcp-server.com/",
      "headers": {
        "x-api-key": "your-server-key",
        "x-airtable-api-key": "your-airtable-key"
      }
    }
  }
}
```

**Benefits**:
- ✅ **Fastest setup** - Direct connection
- ✅ **Simple configuration** - Just JSON headers
- ✅ **Minimal overhead** - No bridge processes
- ✅ **Standard approach** - Uses Claude Code's native HTTP support

### Option 2: Universal Bridge (Advanced)
**Perfect for**: Production environments, team setups, secure credential handling

**What it does**: Uses a Python bridge to securely manage credentials and connect to shared MCP servers

```bash
# Bridge configuration (.env)
MCP_URL=https://your-team-mcp-server.com/
MCP_API_KEY=shared-server-auth-key
AIRTABLE_API_KEY=your-personal-airtable-key
baseId=your-personal-base-id
```

**Benefits**:
- ✅ **Multi-user support** - Many users, one server
- ✅ **Secure by design** - Credentials never stored on server
- ✅ **Production ready** - Scalable Docker architecture
- ✅ **Universal compatibility** - Works with any MCP server

## 🏗️ Universal Bridge Architecture (Advanced Users)

When you choose the bridge option, you get a sophisticated architecture:

```
┌─────────────────┐    HTTP Headers     ┌─────────────────┐    Spawn Process    ┌─────────────────┐
│   Claude Code   │ ──────────────────> │  MCP Server     │ ─────────────────> │ airtable-mcp-   │
│   + Bridge      │   (User API Keys)   │  (Docker)       │   (With User Creds) │ server          │
└─────────────────┘                     └─────────────────┘                     └─────────────────┘
```

**Why this is powerful**:
- **Server-side**: Docker container handles MCP protocol, only stores server auth
- **Client-side**: Bridge passes your personal credentials securely per request  
- **Security**: Your API keys never stored permanently on the server
- **Scalability**: One server supports unlimited users with their own data

## 📋 Prerequisites

- macOS, Linux, or WSL on Windows
- Python 3.6 or higher  
- Claude Code CLI (`npm install -g @anthropic-ai/claude-code`)

That's it! The setup script handles everything else.

## 🚀 Detailed Setup Process

### Step 1: Run the Magic Script
```bash
git clone https://github.com/majkonautic/claude-code-mcp-guide.git
cd claude-code-mcp-guide
./add_remote_mcp.sh
```

### Step 2: Choose Your Adventure
The wizard will ask:
```
🔌 Choose connection method:
1) Direct HTTP (.mcp.json) - Simple, fast setup
2) Universal Bridge - Advanced, secure, multi-user
3) Both - Maximum flexibility

Your choice [1-3]:
```

### Step 3: Service Selection
```
📋 Which MCP service would you like to configure?
1) Airtable
2) AWS
3) Supabase  
4) Custom MCP server
5) I'll configure manually later

Your choice [1-5]:
```

### Step 4: Automatic Configuration
The script automatically:
- Creates Python virtual environment in `.venv/`
- Installs `python-dotenv` for credential management
- Sets up the appropriate configuration files
- Updates `.gitignore` to protect your credentials
- Tests the connection to ensure it works

### Step 5: Add More Services (Optional)
```
✅ Airtable MCP configured successfully!

🔄 Would you like to add another MCP server? [y/N]:
```

Keep adding services until you have everything you need!

## 📁 What Gets Created

After running the setup script:

```
your-project/
├── .venv/                        # Python environment (auto-created)
│   ├── bin/python3               # Python interpreter  
│   └── lib/python*/site-packages/python-dotenv  # Dependencies
├── .mcp.json                     # HTTP configurations (if chosen)
├── .claude/
│   └── mcp/
│       ├── mcp-http-bridge.py    # Universal bridge (auto-downloaded)
│       ├── airtable/
│       │   └── .env              # Your Airtable credentials
│       └── aws/
│           └── .env              # Your AWS credentials  
└── .gitignore                    # Auto-updated for security
```

**Everything is automatic** - no manual file creation needed!

## 🛠️ Why Our Setup Script is Game-Changing

### Before This Tool
Setting up remote MCP connections required:
- Manual Python environment setup
- Understanding MCP protocol details
- Writing bridge scripts from scratch
- Configuring authentication properly
- Setting up security measures
- Debugging connection issues

**Result**: Hours of work, lots of frustration

### After This Tool
```bash
./add_remote_mcp.sh
# Answer 3-4 questions
# Done in 2 minutes!
```

**The script handles**:
- ✅ **Environment setup** - Python venv, dependencies, paths
- ✅ **Protocol complexity** - JSON-RPC, authentication, headers
- ✅ **Security best practices** - Gitignore, credential isolation
- ✅ **Testing & validation** - Ensures everything works before finishing
- ✅ **Multiple services** - Add as many MCP servers as you need
- ✅ **Error handling** - Clear messages if something goes wrong

### Real User Experience

**Sarah (Marketing Manager)**:
```bash
$ ./add_remote_mcp.sh
# Chooses Airtable, enters API key
# 2 minutes later: "List all my marketing campaigns"
✅ Works perfectly!
```

**Dev Team (10 developers)**:
```bash
# Each developer runs:
$ ./add_remote_mcp.sh  
# Chooses bridge mode, enters team server URL
# Everyone connected to shared infrastructure in minutes
✅ Entire team productive immediately!
```

## 🤖 Using Your MCP Connection

Once setup is complete, just ask Claude naturally:

```
# Airtable
"List all tables in my Airtable base"
"Show me records from the Marketing Campaigns table"  
"Create a new campaign with test data"

# AWS  
"List my S3 buckets"
"Show EC2 instances in us-east-1"

# Supabase
"Query my users table"
"Show database schema"
```

Claude automatically uses the right MCP server based on your request!

## 🔧 Advanced Configuration

### Supporting Your Own MCP Server

The setup script supports custom servers:

```bash
$ ./add_remote_mcp.sh
# Choose "Custom MCP server"
# Enter your server URL and authentication
✅ Connected to your proprietary MCP service!
```

### Team Deployment (Bridge Mode)

For teams using the bridge architecture:

1. **Deploy universal MCP server** (one time):
```bash
# Your DevOps team deploys this once
docker run -d -p 8080:8080 \
  -e AIRTABLE_MCP_KEY=team-server-key \
  your-company/universal-mcp-server
```

2. **Team members connect** (individual):
```bash
# Each team member runs
./add_remote_mcp.sh
# Chooses bridge mode
# Enters: https://mcp.company.com/, personal API keys
✅ Everyone connected with their own data access!
```

### Multiple Environments

Run the script multiple times for different environments:

```bash
# Development environment
./add_remote_mcp.sh  # Points to dev MCP servers

# Production environment  
./add_remote_mcp.sh  # Points to prod MCP servers
```

## 🔐 Security Built-In

The setup script automatically implements security best practices:

### Credential Protection
- ✅ **Auto-gitignore** - Sensitive files never committed
- ✅ **Environment isolation** - Credentials in separate `.env` files
- ✅ **Minimal permissions** - Only required access granted

### Bridge Mode Security (Advanced)
- ✅ **Per-request authentication** - Credentials passed securely per call
- ✅ **No server storage** - Your API keys never stored on shared server
- ✅ **User isolation** - Each user's data access completely separate

### Network Security
- ✅ **HTTPS enforcement** - All connections encrypted
- ✅ **API key validation** - Server authentication required
- ✅ **Header security** - Proper authentication header handling

## 🚀 Scaling and Production

### Single User (HTTP Mode)
Perfect for individual use:
- Direct connection to MCP servers
- Simple JSON configuration
- Fast and lightweight

### Team/Enterprise (Bridge Mode)
Designed for scale:
- Shared MCP server infrastructure
- Individual user credential management
- Monitoring and logging capabilities
- Multi-region deployment support

## 🛠️ Troubleshooting Made Easy

The setup script includes built-in testing:

```bash
$ ./add_remote_mcp.sh
# ... configuration steps ...
🧪 Testing connection...
✅ Successfully connected to Airtable MCP!
✅ Retrieved 12 available tools
✅ Configuration saved

🎉 Setup complete! Try: claude "list my airtable tables"
```

If something goes wrong, you'll get clear error messages:

```bash
❌ Connection failed: Invalid API key
💡 Check your Airtable Personal Access Token
📖 Visit: https://airtable.com/create/tokens
```

### Common Issues Auto-Resolved
- ✅ **Python environment** - Auto-created and configured
- ✅ **Missing dependencies** - Auto-installed
- ✅ **Permission errors** - Clear instructions provided
- ✅ **Network issues** - Connection testing with helpful error messages
- ✅ **Credential format** - Validation and format checking

## 🎯 Why This Approach Works

### For Individual Users
- **Zero complexity** - One command setup
- **Immediate productivity** - Working MCP in minutes
- **Flexible options** - Choose simple or advanced based on needs

### For Teams
- **Standardized setup** - Everyone uses the same proven process
- **Secure by default** - Best practices built-in
- **Scalable architecture** - Grows from 1 to 1000+ users

### For Developers
- **Open source** - Customize and extend as needed
- **Well documented** - Clear architecture and examples
- **Production ready** - Battle-tested patterns and security

## 🤝 Contributing

The setup script is designed to be extended:

### Adding New Services
1. Add service detection to `add_remote_mcp.sh`
2. Create configuration templates
3. Add authentication flow
4. Test with the validation system

### Improving the Experience  
- Better error messages
- Additional validation checks
- More deployment options
- Enhanced security features

## 📄 License

MIT License - see LICENSE file for details

## 🙏 Acknowledgments

- Built for the Claude Code community
- Thanks to @bartoszmajewski for architecture design and extensive testing
- Inspired by the need for **simple, secure MCP connections**
- **One command setup** makes MCP accessible to everyone

---

**Ready to get started?** Just run: `./add_remote_mcp.sh`

**Need help?** The script includes built-in troubleshooting and clear error messages.

**Building for a team?** The bridge architecture scales from 1 to 1000+ users seamlessly.
