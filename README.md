# Claude Code MCP (Model Context Protocol) Guide

A complete guide for adding MCP servers to Claude Code, including both cloud-based and local Docker-based MCPs.

## 📁 Project Structure

Organize all your MCPs in a single `mcp` folder within your Claude Code project:

```
your-claude-code-project/
├── mcp/
│   ├── .env                    # Global env vars for cloud MCPs
│   ├── mcp-http-bridge.py      # HTTP bridge for cloud MCPs
│   ├── supabase-cli-mcp/       # Local MCP example
│   │   ├── .env               # Local env vars for this MCP
│   │   ├── mcp-server.py
│   │   └── ...
│   └── other-local-mcp/        # Another local MCP
│       ├── .env
│       └── ...
└── your-project-files/
```

## What is MCP?

MCP (Model Context Protocol) allows Claude to interact with external tools and services. This guide shows you how to set up both cloud MCPs and local MCPs.

## Initial Setup

1. Create the MCP directory structure:
```bash
mkdir mcp
cd mcp
```

2. Download the HTTP bridge:
```bash
curl -O https://raw.githubusercontent.com/majkonautic/claude-code-mcp-guide/main/mcp-http-bridge.py
chmod +x mcp-http-bridge.py
```

3. Create global `.env` for cloud MCPs:
```bash
# mcp/.env
# AWS MCP
AWS_ACCESS_KEY_ID=your_access_key_here
AWS_SECRET_ACCESS_KEY=your_secret_key_here
AWS_DEFAULT_REGION=us-east-1

# Airtable MCP
AIRTABLE_API_KEY=your_api_key_here
AIRTABLE_BASE_ID=your_base_id_here

# Add other cloud service credentials as needed
```

## Quick Start

### For Cloud MCPs (HTTP-based)

```bash
claude mcp add [name] python3 mcp/mcp-http-bridge.py [server-url]
```

Example:
```bash
claude mcp add notion python3 mcp/mcp-http-bridge.py https://notion.mcp.example.com/
```

### For Local MCPs (Docker-based)

```bash
# From your project root
cd mcp
git clone https://github.com/majkonautic/Supabase-CLI-MCP-template.git supabase-cli-mcp
cd supabase-cli-mcp
./setup.sh
# Configure the local .env file here
cd ../..

# Add the MCP
claude mcp add supabase-local python3 mcp/supabase-cli-mcp/mcp-server.py
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

1. Ensure the HTTP bridge is in your `mcp/` folder
2. Add credentials to `mcp/.env`
3. Register with Claude Code:

```bash
# Examples
claude mcp add aws python3 mcp/mcp-http-bridge.py https://aws.mcp.example.com/
claude mcp add airtable python3 mcp/mcp-http-bridge.py https://airtable.mcp.example.com/
claude mcp add notion python3 mcp/mcp-http-bridge.py https://notion.mcp.example.com/
```

## Setting Up Local MCPs

1. Clone into the `mcp/` directory:
```bash
cd mcp
git clone [repository-url] [mcp-name]
cd [mcp-name]
```

2. Run setup and configure local `.env`:
```bash
./setup.sh
# Edit .env file with required credentials
```

3. Register with Claude Code (from project root):
```bash
claude mcp add [name] python3 mcp/[mcp-name]/mcp-server.py
```

### Example: Supabase CLI MCP

```bash
cd mcp
git clone https://github.com/majkonautic/Supabase-CLI-MCP-template.git supabase-cli-mcp
cd supabase-cli-mcp
./setup.sh
# Configure supabase-cli-mcp/.env with your credentials
cd ../..
claude mcp add supabase-local python3 mcp/supabase-cli-mcp/mcp-server.py
```

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

## Environment Variables

### Cloud MCPs
- Place in `mcp/.env`
- Used by all cloud MCPs via `mcp-http-bridge.py`
- Example:
  ```bash
  # mcp/.env
  AWS_ACCESS_KEY_ID=your_key
  AIRTABLE_API_KEY=your_key
  NOTION_API_KEY=your_key
  ```

### Local MCPs
- Place in `mcp/[mcp-name]/.env`
- Specific to each local MCP
- Example:
  ```bash
  # mcp/supabase-cli-mcp/.env
  SUPABASE_PROJECT_ID=your_project_id
  SUPABASE_API_KEY=your_api_key
  ```

## Creating Your Own MCP

MCPs must implement the MCP protocol (version 2024-11-05 or later). Place your custom MCPs in the `mcp/` directory following the same structure.

## Troubleshooting

* **Connection failed**: Check Docker is running (for local MCPs)
* **Protocol version error**: Update to latest protocol version
* **Tool not found**: Verify MCP is registered with `claude mcp list`
* **Path issues**: Ensure you're running commands from the project root
* **Env vars not loaded**: Check `.env` file location and format

## Contributing

Feel free to submit PRs with new MCP examples or improvements!
