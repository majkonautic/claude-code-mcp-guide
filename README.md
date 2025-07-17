# Claude Code MCP (Model Context Protocol) Guide

A complete guide for adding MCP servers to Claude Code, including both cloud-based and local Docker-based MCPs.

## 📁 Project Structure

Organize all your MCPs in a single `mcp` folder within your Claude Code project:

```
your-claude-code-project/
├── mcp/
│   ├── .env                    # Global env vars for cloud MCPs
│   ├── mcp-http-bridge.py      # HTTP bridge for cloud MCPs (with API key support)
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

2. Download the HTTP bridge (now with API key authentication):
```bash
curl -O https://raw.githubusercontent.com/majkonautic/claude-code-mcp-guide/main/mcp-http-bridge.py
chmod +x mcp-http-bridge.py
```

3. Create global `.env` for cloud MCPs:
```bash
# mcp/.env
# Service credentials
AWS_ACCESS_KEY_ID=your_access_key_here
AWS_SECRET_ACCESS_KEY=your_secret_key_here
AWS_DEFAULT_REGION=us-east-1

# Airtable credentials
AIRTABLE_API_KEY=your_api_key_here
AIRTABLE_BASE_ID=your_base_id_here

# MCP API Keys for authentication (REQUIRED for security)
MCP_API_KEY_SUPABASE=your_supabase_mcp_auth_key
MCP_API_KEY_AIRTABLE=your_airtable_mcp_auth_key
MCP_API_KEY_AWS=your_aws_mcp_auth_key
MCP_API_KEY_NOTION=your_notion_mcp_auth_key
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
  # Service credentials
  AWS_ACCESS_KEY_ID=your_key
  AWS_SECRET_ACCESS_KEY=your_secret
  AIRTABLE_API_KEY=your_key
  NOTION_API_KEY=your_key
  
  # MCP API Keys for authentication
  MCP_API_KEY_SUPABASE=your_supabase_mcp_auth_key
  MCP_API_KEY_AIRTABLE=your_airtable_mcp_auth_key
  MCP_API_KEY_AWS=your_aws_mcp_auth_key
  MCP_API_KEY_NOTION=your_notion_mcp_auth_key
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
* **403 Forbidden**: Check your MCP API key configuration
* **Authentication failed**: Verify X-API-Key header is set correctly

## Security

All cloud MCP servers are protected with API key authentication:
- Each MCP server requires an `X-API-Key` header
- Keys are stored in your local `.env` file
- Never commit API keys to version control
- Use different keys for each MCP service
- The `mcp-http-bridge.py` automatically handles authentication

---

# ⚙️ Claude Code Terminal Prompting Framework

*Best practices for working with Claude Code and MCP discovery*

## 📐 Prompt Template (Claude MCP-Aware)

When working with Claude Code, structure your prompts as follows:

```markdown
### 🧭 Objective
What do you want Claude to do? Be clear and goal-oriented.

### 📂 Context
- Tech stack and architecture
- Files and folders involved
- Feature or ticket reference
- Relevant data models

### 🛠️ Requirements
- Functional behavior needed
- Security/performance constraints
- Integration requirements
- Business rules

### 🧠 MCP Discovery & Usage
Tell Claude to:
- List available MCPs: `claude mcp list`
- Identify relevant tools for the task
- Use appropriate MCP resources
- Explain which MCPs were selected and why

### ✅ Acceptance Criteria
- [ ] Define successful output
- [ ] Include edge cases
- [ ] Specify error handling
- [ ] Ensure testability

### 🧪 Testing Instructions
- Test cases to cover
- Sample input/output
- Edge case expectations
- Testing framework preferences

### 🗃️ Tools / MCP / Clients Involved
List expected MCPs and tools

### 🧱 Documentation Requirements
- Docstring updates
- README modifications
- API documentation updates

### 🚫 Exclusions / Warnings
- What NOT to modify
- Security boundaries
- Performance considerations
```

## 💡 Prompting Best Practices

| Phase        | Action                                                              |
| ------------ | ------------------------------------------------------------------- |
| **Plan**     | Ask Claude to identify available MCPs and propose approach          |
| **Act**      | Claude writes code using selected MCPs                              |
| **Validate** | Claude explains testing, dependencies, and integration              |

## Example MCP-Aware Prompt

```markdown
### 🧭 Objective
Create an endpoint to upload files to S3 and track in database

### 📂 Context
FastAPI backend with Supabase database and AWS S3 storage

### 🛠️ Requirements
- Accept file uploads via POST
- Validate file type and size
- Upload to S3 with unique key
- Store metadata in Supabase

### 🧠 MCP Discovery & Usage
Claude should:
- Run `claude mcp list`
- Use AWS MCP for S3 operations
- Use Supabase MCP for database
- Explain tool selection

### ✅ Acceptance Criteria
- [ ] Files uploaded to S3 successfully
- [ ] Metadata stored in database
- [ ] Proper error handling
- [ ] Returns S3 URL to client

### 🧪 Testing Instructions
- Test with various file types
- Test size limits
- Verify S3 upload
- Check database entry
```

## MCP Discovery Commands

Start your Claude Code session with:

```bash
# List all available MCPs
claude mcp list

# Check specific MCP status
claude mcp logs [mcp-name]

# For local development
claude --dev
```

## Contributing

Feel free to submit PRs with new MCP examples or improvements!
