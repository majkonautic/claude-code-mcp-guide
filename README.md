# Claude Code MCP (Model Context Protocol) Guide

A complete guide for adding MCP servers to Claude Code, including both cloud-based and local Docker-based MCPs.

## ⚠️ Important: Environment Variables

### For Cloud MCPs
- `.env` file must be in your **Claude Code project folder** (root directory)
- Never commit actual API keys to version control

### For Local MCPs  
- `.env` file goes **inside the MCP folder** (e.g., `supabase-cli-mcp/.env`)
- This is handled during the setup process

## What is MCP?

MCP (Model Context Protocol) allows Claude to interact with external tools and services. This guide shows you how to set up both cloud MCPs and local MCPs.

## Quick Start

### For Cloud MCPs (HTTP-based)

```bash
claude mcp add [name] python3 mcp-http-bridge.py [server-url]
```

Example:
```bash
claude mcp add notion python3 mcp-http-bridge.py https://notion.mcp.example.com/
```

### For Local MCPs (Docker-based)

```bash
git clone https://github.com/majkonautic/Supabase-CLI-MCP-template.git supabase-cli-mcp
cd supabase-cli-mcp
./setup.sh
cd ..
claude mcp add supabase-local python3 supabase-cli-mcp/mcp-server.py
```

## Available MCP Types

### 1. HTTP Bridge MCPs (Cloud Services)

Use `mcp-http-bridge.py` for cloud-based MCP servers:

* **Airtable**: Database operations
* **Notion**: Workspace search and management
* **Supabase**: Database and function management
* **AWS**: Cloud resource management

### 2. Local Docker MCPs

For services that need local execution:

* **Supabase CLI**: Edge function deployment
* **Custom tools**: Your own local services

## Setting Up Cloud MCPs

1. Download the bridge:
```bash
curl -O https://raw.githubusercontent.com/majkonautic/claude-code-mcp-guide/main/mcp-http-bridge.py
chmod +x mcp-http-bridge.py
```

2. **Create `.env` file in your Claude Code project folder** with the required variables for your MCP:
```bash
# Example .env file (in Claude Code project root)
# AWS MCP
AWS_ACCESS_KEY_ID=your_access_key_here
AWS_SECRET_ACCESS_KEY=your_secret_key_here
AWS_DEFAULT_REGION=us-east-1
AWS_REGION=us-east-1
AWS_ACCOUNT_ID=your_account_id_here

# Airtable MCP
AIRTABLE_API_KEY=your_api_key_here
AIRTABLE_BASE_ID=your_base_id_here
AIRTABLE_TABLE_NAME="your_table_name"

# Add other service credentials as needed
```

3. Add to Claude:
```bash
claude mcp add [service-name] python3 mcp-http-bridge.py [service-url]
```

## Setting Up Local MCPs

See our [Supabase CLI MCP Template](https://github.com/majkonautic/Supabase-CLI-MCP-template) for a complete example.

**Important:** For local MCPs, the `.env` file should be placed **inside the MCP folder** (e.g., `supabase-cli-mcp/.env`). This is handled as part of the setup process.

## Managing MCPs

List all MCPs:
```bash
claude mcp list
```

Remove an MCP:
```bash
claude mcp remove [name]
```

Check MCP logs:
```bash
claude mcp logs [name]
```

## Creating Your Own MCP

MCPs must implement the MCP protocol (version 2024-11-05 or later). See `examples/` for templates.

## Troubleshooting

* **Connection failed**: Check Docker is running (for local MCPs)
* **Protocol version error**: Update to latest protocol version
* **Tool not found**: Verify MCP is registered with `claude mcp list`

## Contributing

Feel free to submit PRs with new MCP examples or improvements!
