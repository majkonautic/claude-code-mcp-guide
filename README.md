
# Claude Code MCP (Model Context Protocol) Guide

A complete guide for adding MCP servers to Claude Code, including both cloud-based and local Docker-based MCPs.

---

## 📁 Project Structure

Clone this repo into the **root folder of your Claude Code project**.

```

your-claude-code-project/
├── .claude/
│   └── mcp/
│       ├── airtable/
│       │   ├── .env
│       └── mcp-http-bridge.py
├── add\_remote\_mcp.sh            # 🆕 Script to easily add new cloud MCPs
├── mcp/
│   └── mcp-http-bridge.py       # Original copy (used once, then copied to .claude)
├── README.md
└── your-project-files/

````

> 🧠 The `add_remote_mcp.sh` script will create `.claude/mcp/` for you — so **always run the clone and the script from the project root**, not from elsewhere.

---

## 🛠️ Initial Setup

1. From your Claude Code project root:

```bash
git clone https://github.com/majkonautic/claude-code-mcp-guide
cd claude-code-mcp-guide
````

2. Run the interactive setup wizard to add your first remote MCP:

```bash
./add_remote_mcp.sh
```

This will:

* Create `.claude/mcp/`
* Ask for MCP name, URL, API key, and any other secrets
* Copy `mcp-http-bridge.py` into `.claude/mcp/`
* Build a `.env` file inside `.claude/mcp/[your-mcp-name]/`

---

## 🧪 Registering the MCP

Once created, you **must register the MCP from your core project root**, like this:

```bash
cd your-claude-code-project
claude mcp add [name] python3 .claude/mcp/mcp-http-bridge.py
```

✅ Do **not** run this command from `.claude/mcp/[name]/` — Claude stores paths relative to project root.

---

## MCP Onboarding Script: `add_remote_mcp.sh`

To add more MCPs in the future:

```bash
./add_remote_mcp.sh
```

It will:

* Prompt you for MCP name + URL
* Ask for an optional API key
* Let you enter any number of service-specific secrets
* Create `.env` file inside `.claude/mcp/[name]/`
* Offer the Claude command for registering the MCP

---

## Example

### Create Airtable MCP

```bash
./add_remote_mcp.sh
# name: airtable
# url: https://airtable.mcp.example.com
# key: sk_test_airtable_123
# extra: AIRTABLE_BASE_ID=appXXXX
# extra: AIRTABLE_API_KEY=patYYYY
```

Then from **project root**:

```bash
claude mcp add airtable python3 .claude/mcp/mcp-http-bridge.py
```

---

## ✅ Why Folder-Based MCPs Work

Each MCP is:

* Isolated in its own folder (`.claude/mcp/[name]`)
* Powered by the shared `mcp-http-bridge.py`
* Fully driven by the `.env` in that folder

Supports:

* Airtable, Supabase, AWS, Notion, etc.
* Any number of services
* Clean separation of secrets

---

## MCP Types

### 1. HTTP Bridge MCPs (Cloud)

Use `.claude/mcp/[name]/.env` + `mcp-http-bridge.py`.

### 2. Local MCPs (Docker)

Place inside `mcp/[name]/` and register as:

```bash
claude mcp add my-local-mcp python3 mcp/my-local-mcp/mcp-server.py
```

---

## Managing MCPs

```bash
claude mcp list
claude mcp remove [name]
claude mcp logs [name]
```

---

## Security Notes

* Do not commit `.env` files to Git
* Each `.claude/mcp/[name]/.env` is local-only
* API keys are injected automatically by `mcp-http-bridge.py`

---

## Contributing

PRs welcome with:

* `.env.example` templates
* New service integrations
* Shell script improvements


