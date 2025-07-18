# Claude Code MCP (Model Context Protocol) Guide
A complete guide for adding **remote MCPs** to Claude Code, using folder-based secrets, virtual environments, and a shared bridge.

---

## 📁 Project Layout
After cloning this repo into your Claude Code project root:
```
your-project/
├── claude-code-mcp-guide/
│   ├── add_remote_mcp.sh
│   └── mcp/
│       ├── mcp-http-bridge.py
│       └── example_mcp/
│           └── .env.example
```

After running the script:
```
your-project/
├── .venv/                    # Python virtual environment
├── .claude/
│   └── mcp/
│       ├── airtable/
│       │   └── .env
│       └── mcp-http-bridge.py
```

---

## 🧠 What is this for?
Claude uses **MCPs** (Model Context Protocols) to call external services.
This setup helps you:
- Add remote (cloud-hosted) MCPs with secrets
- Isolate config per MCP in separate folders
- Use Python virtual environments to avoid system conflicts
- Share the same bridge script for all MCPs

---

## 🛠️ Initial Setup

### Automated Setup (Recommended)
1. From your project root:
```bash
git clone https://github.com/majkonautic/claude-code-mcp-guide
cd claude-code-mcp-guide
./add_remote_mcp.sh
```

The script will automatically:
- Create a Python virtual environment
- Install required dependencies
- Set up your MCP configuration
- Register it with Claude using correct paths

### Manual Setup
1. Create virtual environment:
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install python-dotenv
```

2. Create MCP directories:
```bash
mkdir -p .claude/mcp
cp claude-code-mcp-guide/mcp/mcp-http-bridge.py .claude/mcp/
```

---

## 🧪 Example: Airtable MCP
When prompted by the script:
* MCP name: `airtable`
* MCP URL: `https://codibly-airtable.mcp.majewscy.tech/`
* MCP API Key: `your-api-key-here`
* Extra secret: `AIRTABLE_BASE_ID=appXXXX`

Your `.env` will be created in:
```
.claude/mcp/airtable/.env
```

---

## 🤖 Registering with Claude

### ⚠️ IMPORTANT: Use Virtual Environment Python
From your **project root**, run:
```bash
claude mcp add airtable "$(pwd)/.venv/bin/python" "$(pwd)/.claude/mcp/mcp-http-bridge.py" "https://your-mcp-server.com/" "$(pwd)/.claude/mcp/airtable/"
```

**Critical Notes:**
- ✅ Always use `"$(pwd)/.venv/bin/python"` NOT just `python3`
- ✅ Always use absolute paths with `$(pwd)/`
- ✅ MCP name can be anything you want
- ✅ `.env` folder path defines which secrets to use

---

## 🧰 Public vs Private MCPs
| Use Case                 | Command Example                                                                             |
| ------------------------ | ------------------------------------------------------------------------------------------- |
| ✅ Public MCP (no auth)   | `claude mcp add my-public https://my-server.com`                                            |
| 🔐 Private MCP (API key) | `claude mcp add secure "$(pwd)/.venv/bin/python" "$(pwd)/.claude/mcp/mcp-http-bridge.py" "https://server.com/" "$(pwd)/.claude/mcp/secure/"` |

---

## 📦 Managing MCPs
```bash
claude mcp list
claude mcp logs [name]
claude mcp remove [name]
```

---

## 🔐 Secrets & Security
* Secrets go in `.claude/mcp/[name]/.env`
* Never commit `.env` files to version control
* Each MCP uses its own folder with isolated secrets
* Required format:
  ```
  MCP_URL=https://your-server.com/
  MCP_API_KEY=your-api-key
  # Any additional service-specific secrets
  ```

---

## 🧱 Creating a New MCP Folder Manually
```bash
# Activate virtual environment first
source .venv/bin/activate

# Create new MCP folder
mkdir -p .claude/mcp/my-service
cp claude-code-mcp-guide/mcp/example_mcp/.env.example .claude/mcp/my-service/.env

# Edit the .env file with your credentials
nano .claude/mcp/my-service/.env

# Register with Claude (from project root)
claude mcp add my-service "$(pwd)/.venv/bin/python" "$(pwd)/.claude/mcp/mcp-http-bridge.py" "https://my-service.com/" "$(pwd)/.claude/mcp/my-service/"
```

---

## 🧪 Troubleshooting

### "Connection closed" error
- Ensure you're using the virtual environment Python: `"$(pwd)/.venv/bin/python"`
- Check python-dotenv is installed: `source .venv/bin/activate && pip list | grep dotenv`
- Verify paths are absolute, not relative

### "403 Forbidden" error
- Check your API key in `.claude/mcp/[name]/.env`
- Ensure `MCP_API_KEY` (not `AIRTABLE_MCP_KEY` or other names)
- Verify the MCP_URL format matches server requirements

### Testing manually
```bash
source .venv/bin/activate
python .claude/mcp/mcp-http-bridge.py https://your-server.com/ .claude/mcp/your-service/
# Then type: {"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2024-11-05"}}
```

---

## 🧠 Prompt Claude to Use It
```markdown
I have an MCP server configured called `airtable`. It's already set up and connected. 
Please use it to [your task here].
```

---

## 📋 Requirements
The setup script automatically installs:
- `python-dotenv` - For loading .env files

---

## 🤝 Contributing
Feel free to open a PR with:
* More `.env.example` templates for different services
* Additional MCP integrations
* Improvements to `add_remote_mcp.sh`
* Documentation improvements

---

## 📄 License
MIT License - see LICENSE file for details
