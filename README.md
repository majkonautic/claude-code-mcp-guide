# Claude Code MCP (Model Context Protocol) Guide

A complete guide for adding MCP servers to Claude Code, including both cloud-based and local Docker-based MCPs.

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

2. Add to Claude:
```bash
claude mcp add [service-name] python3 mcp-http-bridge.py [service-url]
```

## Setting Up Local MCPs

See our [Supabase CLI MCP Template](https://github.com/majkonautic/Supabase-CLI-MCP-template) for a complete example.

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
