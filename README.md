
# Claude Code MCP (Model Context Protocol) Guide

A complete guide for adding **remote MCPs** to Claude Code, using folder-based secrets and a shared bridge.

---

## 📁 Project Layout

After cloning this repo into your Claude Code project root:

```

your-project/
├── claude-code-mcp-guide/
│   ├── add\_remote\_mcp.sh
│   └── mcp/
│       ├── mcp-http-bridge.py
│       └── example\_mcp/
│           └── .env.example

```

After running the script:

```

├── .claude/
│   └── mcp/
│       ├── airtable/
│       │   └── .env
│       └── mcp-http-bridge.py

````

---

## 🧠 What is this for?

Claude uses **MCPs** (Model Context Protocols) to call external services.

This setup helps you:
- Add remote (cloud-hosted) MCPs with secrets
- Isolate config per MCP
- Use the same bridge for all MCPs

---

## 🛠️ Initial Setup

1. From your project root:

```bash
git clone https://github.com/majkonautic/claude-code-mcp-guide
````

2. Set up Python environment:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r claude-code-mcp-guide/mcp/requirements.txt
```

3. Add your first MCP:

```bash
cd claude-code-mcp-guide
./add_remote_mcp.sh
```

---

## 🧪 Example: Airtable MCP

When prompted:

* MCP name: `airtable`
* MCP URL: `https://codibly-airtable.mcp.majewscy.tech/`
* MCP API Key: (paste securely)
* Extra secret: `AIRTABLE_BASE_ID=appXXXX`

Your `.env` will be created in:

```
.claude/mcp/airtable/.env
```

---

## 🤖 Registering with Claude

From your **project root**, run:

```bash
claude mcp add airtable python3 .claude/mcp/mcp-http-bridge.py https://codibly-airtable.mcp.majewscy.tech/ .claude/mcp/airtable/
```

✅ MCP name can be anything
✅ `.env` folder path defines which secrets to use
✅ `MCP_URL` can be passed or loaded from `.env`

---

## 🧰 Public vs Private MCPs

| Use Case                 | Command Example                                                                             |
| ------------------------ | ------------------------------------------------------------------------------------------- |
| ✅ Public MCP (no auth)   | `claude mcp add my-public https://my-server.com`                                            |
| 🔐 Private MCP (API key) | `claude mcp add secure python3 .claude/mcp/mcp-http-bridge.py $MCP_URL .claude/mcp/secure/` |

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
* Never commit `.env` to version control
* Each MCP uses its own folder

---

## 🧱 Creating a New MCP Folder Manually

You can copy the example:

```bash
cp -r claude-code-mcp-guide/mcp/example_mcp .claude/mcp/my-service
mv .claude/mcp/my-service/.env.example .env
# Fill in your own MCP_URL, MCP_API_KEY, etc.
```

---

## 🧪 Requirements

```txt
# claude-code-mcp-guide/mcp/requirements.txt
python-dotenv>=1.0.0
```

---

## 🧠 Prompt Claude to Use It

```markdown
I'm using a remote MCP named `airtable`. Please list its tools and use them via:

claude mcp add airtable python3 .claude/mcp/mcp-http-bridge.py https://codibly-airtable.mcp.majewscy.tech/ .claude/mcp/airtable/
```

---

## 🤝 Contributing

Feel free to open a PR with:

* More `.env.example` templates
* Additional integrations
* Improvements to `add_remote_mcp.sh`
