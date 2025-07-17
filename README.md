
# Claude Code MCP (Model Context Protocol) Guide

A complete guide for adding MCP servers to Claude Code, including both cloud-based and local Docker-based MCPs.

---

## 📁 Project Structure

Clone this repo into the **root of your Claude Code project** like this:

```

your-claude-code-project/
├── claude-code-mcp-guide/
│   ├── README.md
│   ├── add\_remote\_mcp.sh
│   └── mcp/
│       ├── mcp-http-bridge.py           # Shared bridge script (copied during setup)
│       └── example\_mcp/
│           └── .env.example             # Example template for your own MCPs

```

After running the setup script, the following will be created:

```

├── .claude/
│   └── mcp/
│       ├── airtable/
│       │   └── .env                     # Your service-specific secrets
│       └── mcp-http-bridge.py          # Copied bridge used for Claude integration

````

---

## 🛠️ Initial Setup

1. From the **root of your Claude Code project**, clone this guide:

```bash
git clone https://github.com/majkonautic/claude-code-mcp-guide
````

2. Run the interactive setup wizard:

```bash
cd claude-code-mcp-guide
./add_remote_mcp.sh
```

This will:

* Prompt you for:

  * MCP name (e.g., `airtable`)
  * MCP URL (e.g., `https://airtable.mcp.example.com`)
  * MCP API key (optional)
  * Any number of service-specific secrets (e.g. `AIRTABLE_BASE_ID`, `SUPABASE_DB_URL`)
* Create a folder at `.claude/mcp/<your-name>/`
* Write all values into `.env`
* Copy the bridge script (`mcp-http-bridge.py`) to `.claude/mcp/`

---

## ✅ Registering MCPs (Always from Project Root)

After setup, **register the MCP from your project root** like this:

```bash
claude mcp add <name> python3 .claude/mcp/mcp-http-bridge.py
```

Example:

```bash
claude mcp add airtable python3 .claude/mcp/mcp-http-bridge.py
```

> 🛑 **Important:** Never run `claude mcp add` from inside `.claude/mcp/<name>/`.
> Claude stores paths relative to your current working directory — using the wrong location will break registration.

---

## 🔁 Adding More MCPs

To create and configure more MCPs, repeat:

```bash
cd claude-code-mcp-guide
./add_remote_mcp.sh
```

Each one gets:

* Its own folder under `.claude/mcp/`
* Its own `.env` file
* Shared use of `mcp-http-bridge.py`

---

## 📄 Example: Airtable MCP

```bash
cd claude-code-mcp-guide
./add_remote_mcp.sh

# MCP Name: airtable
# MCP URL: https://airtable.mcp.example.com
# MCP API Key: sk_test_airtable_123
# Additional secret: AIRTABLE_BASE_ID=appXXXX
# Additional secret: AIRTABLE_API_KEY=patYYYY
```

Then, from project root:

```bash
claude mcp add airtable python3 .claude/mcp/mcp-http-bridge.py
```

---

## 🧪 Example Template

You can use the included template at:

```
claude-code-mcp-guide/mcp/example_mcp/.env.example
```

To bootstrap your own config folders by copying and editing.

---

## 🔒 Security

* Secrets are stored only in `.claude/mcp/<name>/.env`
* `.env` files are **not committed**
* Each service is isolated
* `mcp-http-bridge.py` injects `X-API-Key` and other headers automatically

---

## 📦 Managing MCPs

```bash
claude mcp list                # List all registered MCPs
claude mcp remove <name>       # Remove an MCP
claude mcp logs <name>         # View logs for a running MCP
```

---

## 🤝 Contributing

PRs welcome for:

* New `.env.example` templates
* Service-specific integrations (e.g., Notion, AWS)
* Improvements to `add_remote_mcp.sh`

