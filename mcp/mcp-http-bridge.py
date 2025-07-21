#!/usr/bin/env python3
"""
Universal MCP HTTP Bridge
A community tool for connecting Claude to remote MCP servers
Handles standard MCP protocol with secure credential management

Repository: https://github.com/[your-username]/claude-remote-mcp
License: MIT
"""

import sys
import os
import json
import urllib.request
import ssl
import logging
from pathlib import Path

# Set up logging (logs to stderr so it doesn't interfere with JSON-RPC)
logging.basicConfig(
    level=logging.ERROR,
    format='%(asctime)s - %(levelname)s - %(message)s',
    stream=sys.stderr
)

try:
    from dotenv import load_dotenv
except ImportError:
    logging.error("python-dotenv not installed. Please run: pip install python-dotenv")
    print(json.dumps({
        "jsonrpc": "2.0",
        "id": None,
        "error": {
            "code": -32603,
            "message": "python-dotenv not installed. Please run: pip install python-dotenv"
        }
    }), flush=True)
    sys.exit(1)

def find_env_file(start_path=None):
    """
    Intelligently find the .env file:
    1. If a path is provided as argument, use it
    2. Check current working directory
    3. Check parent directories up to project root
    """
    if start_path and os.path.exists(start_path):
        if os.path.isfile(start_path) and start_path.endswith('.env'):
            return start_path
        elif os.path.isdir(start_path):
            env_file = os.path.join(start_path, '.env')
            if os.path.exists(env_file):
                return env_file
    
    # Fallback: check current directory
    current_dir = Path.cwd()
    env_file = current_dir / '.env'
    if env_file.exists():
        return str(env_file)
    
    # Check parent directories (useful for nested project structures)
    for parent in current_dir.parents:
        env_file = parent / '.env'
        if env_file.exists():
            return str(env_file)
        # Stop at common project root indicators
        if (parent / '.git').exists() or (parent / '.claude').exists():
            break
    
    return None

# Load environment variables
env_path = None
env_vars_from_file = {}

if len(sys.argv) > 1:
    # Try to use the provided argument
    env_path = find_env_file(sys.argv[1])
    if env_path:
        logging.info(f"Loading .env from: {env_path}")
    else:
        logging.warning(f"Could not find .env file at: {sys.argv[1]}")

if not env_path:
    # Try to find .env in current directory or parents
    env_path = find_env_file()
    if env_path:
        logging.info(f"Found .env at: {env_path}")

if env_path:
    # Load and track which vars came from the .env file
    with open(env_path) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key = line.split('=', 1)[0].strip()
                env_vars_from_file[key] = True
    
    load_dotenv(dotenv_path=env_path, override=True)
else:
    logging.warning("No .env file found. Relying on system environment variables.")

# Load configuration with helpful error messages
server_url = os.getenv("MCP_URL")
api_key = os.getenv("MCP_API_KEY")

if not server_url:
    error_msg = (
        "Missing MCP_URL environment variable. "
        "Please ensure your .env file contains: MCP_URL=https://your-mcp-server.com/"
    )
    print(json.dumps({
        "jsonrpc": "2.0",
        "id": None,
        "error": {"code": -32603, "message": error_msg}
    }), flush=True)
    sys.exit(1)

if not api_key:
    error_msg = (
        "Missing MCP_API_KEY environment variable. "
        "Please ensure your .env file contains: MCP_API_KEY=your-api-key"
    )
    print(json.dumps({
        "jsonrpc": "2.0",
        "id": None,
        "error": {"code": -32603, "message": error_msg}
    }), flush=True)
    sys.exit(1)

# Ensure URL ends with / for consistent API calls
if not server_url.endswith('/'):
    server_url += '/'

# Create SSL context with proper certificate verification
ssl_context = ssl.create_default_context()

def try_api_endpoints(method, params=None):
    """
    Try different endpoint patterns for the API call.
    Some servers use /tools, /api, or other patterns.
    """
    base_url = server_url.rstrip('/')
    
    # Common endpoint patterns to try
    endpoints = [
        "",  # Base URL
        "/tools",
        "/api",
        "/v1",
        "/mcp",
        "/json-rpc"
    ]
    
    last_error = None
    
    for endpoint in endpoints:
        try:
            url = base_url + endpoint
            if not url.endswith('/') and endpoint:
                url += '/'
                
            req_data = json.dumps({
                "jsonrpc": "2.0",
                "method": method,
                "id": f"{method}-{os.getpid()}",
                "params": params or {}
            }).encode('utf-8')

            headers = {
                "Content-Type": "application/json",
                "X-API-Key": api_key,
                "User-Agent": "Claude-MCP-Bridge/1.0"
            }

            req = urllib.request.Request(
                url,
                data=req_data,
                headers=headers,
                method="POST"
            )

            with urllib.request.urlopen(req, context=ssl_context, timeout=30) as response:
                result = json.loads(response.read().decode('utf-8'))
                # If we got a valid response, remember this endpoint for future calls
                if endpoint:
                    logging.info(f"Found working endpoint: {endpoint}")
                return result
                
        except Exception as e:
            last_error = e
            logging.debug(f"Endpoint {endpoint} failed: {e}")
            continue
    
    # If all endpoints failed, raise the last error
    if last_error:
        raise last_error
    else:
        raise Exception("No working endpoint found")

def call_remote_mcp(method, params=None):
    """Make a request to the remote MCP server with proper error handling"""
    try:
        return try_api_endpoints(method, params)
    
    except urllib.error.HTTPError as e:
        error_body = e.read().decode('utf-8', errors='ignore')
        logging.error(f"HTTP {e.code}: {error_body}")
        raise Exception(f"Remote MCP server error (HTTP {e.code}): {error_body}")
    except urllib.error.URLError as e:
        logging.error(f"Network error: {e.reason}")
        raise Exception(f"Cannot connect to MCP server: {e.reason}")
    except json.JSONDecodeError as e:
        logging.error(f"Invalid JSON response: {e}")
        raise Exception("Remote MCP server returned invalid JSON")
    except Exception as e:
        logging.error(f"Unexpected error: {e}")
        raise

def collect_env_vars():
    """
    Collect ALL environment variables from the .env file to pass to remote MCP.
    Excludes system variables that weren't in the .env file.
    """
    env_vars = {}
    
    # Include all variables that were in the .env file
    for key, value in os.environ.items():
        # Include if it was in the .env file OR if it matches common service patterns
        if key in env_vars_from_file or key.startswith(('MCP_', 'AWS_', 'AIRTABLE_', 'SUPABASE_')):
            # Don't log sensitive values
            logging.debug(f"Including env var: {key}")
            env_vars[key] = value
    
    return env_vars

def main():
    """Main loop handling JSON-RPC communication with Claude"""
    logging.info("MCP HTTP Bridge started")
    
    while True:
        try:
            line = sys.stdin.readline()
            if not line:
                logging.info("EOF received, shutting down")
                break

            line = line.strip()
            if not line:
                continue

            logging.debug(f"Received: {line[:100]}...")
            request = json.loads(line)
            method = request.get("method", "")
            request_id = request.get("id")

            if method == "initialize":
                # Respond with capabilities
                response = {
                    "jsonrpc": "2.0",
                    "id": request_id,
                    "result": {
                        "protocolVersion": request.get("params", {}).get("protocolVersion", "2024-11-05"),
                        "capabilities": {
                            "tools": {},
                            "prompts": {}
                        },
                        "serverInfo": {
                            "name": "mcp-http-bridge",
                            "version": "1.0.0"
                        }
                    }
                }
                print(json.dumps(response), flush=True)
                logging.info("Initialized successfully")

            elif method == "tools/list":
                # Fetch available tools from remote MCP
                logging.info("Fetching tool list from remote MCP")
                remote_response = call_remote_mcp("tools/list")
                
                # Handle different response formats (some servers nest under "result")
                if "tools" in remote_response:
                    tools = remote_response.get("tools", [])
                elif "result" in remote_response and "tools" in remote_response["result"]:
                    tools = remote_response["result"]["tools"]
                else:
                    tools = []
                
                response = {
                    "jsonrpc": "2.0",
                    "id": request_id,
                    "result": {"tools": tools}
                }
                print(json.dumps(response), flush=True)
                logging.info(f"Listed {len(tools)} tools")

            elif method == "tools/call":
                # Execute tool on remote MCP
                params = request.get("params", {})
                tool_name = params.get("name")
                arguments = params.get("arguments", {})
                
                logging.info(f"Calling tool: {tool_name}")
                
                # Pass environment variables along with the request
                call_params = {
                    "name": tool_name,
                    "arguments": arguments,
                    "env": collect_env_vars()
                }
                
                remote_response = call_remote_mcp("tools/call", call_params)
                result = remote_response.get("result", {})
                
                response = {
                    "jsonrpc": "2.0",
                    "id": request_id,
                    "result": result
                }
                print(json.dumps(response), flush=True)
                logging.info(f"Tool {tool_name} executed successfully")

            elif method == "prompts/list":
                # Handle prompts/list request
                logging.info("Handling prompts/list request")
                response = {
                    "jsonrpc": "2.0",
                    "id": request_id,
                    "result": {"prompts": []}
                }
                print(json.dumps(response), flush=True)
                logging.info("Returned empty prompts list")

            else:
                # Unknown method
                response = {
                    "jsonrpc": "2.0",
                    "id": request_id,
                    "error": {
                        "code": -32601,
                        "message": f"Method not found: {method}"
                    }
                }
                print(json.dumps(response), flush=True)
                logging.warning(f"Unknown method: {method}")

        except KeyboardInterrupt:
            logging.info("Interrupted by user")
            break
        except json.JSONDecodeError as e:
            logging.error(f"Invalid JSON input: {e}")
            response = {
                "jsonrpc": "2.0",
                "id": None,
                "error": {
                    "code": -32700,
                    "message": f"Parse error: {str(e)}"
                }
            }
            print(json.dumps(response), flush=True)
        except Exception as e:
            logging.error(f"Error processing request: {e}", exc_info=True)
            response = {
                "jsonrpc": "2.0",
                "id": request_id if 'request_id' in locals() else None,
                "error": {
                    "code": -32603,
                    "message": str(e)
                }
            }
            print(json.dumps(response), flush=True)

    logging.info("MCP HTTP Bridge shutting down")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        logging.error(f"Fatal error: {e}", exc_info=True)
        sys.exit(1)
