#!/usr/bin/env python3
"""
MCP HTTP Bridge - Secure Version with API Key Support
"""
import sys
import json
import urllib.request
import ssl
import os

def main():
    if len(sys.argv) < 2:
        print(json.dumps({"error": "No server URL provided"}))
        sys.exit(1)
    
    server_url = sys.argv[1]
    ssl_context = ssl.create_default_context()
    
    # Determine which API key to use based on server URL
    api_key = None
    if 'supabase' in server_url:
        api_key = os.environ.get('MCP_API_KEY_SUPABASE')
    elif 'airtable' in server_url:
        api_key = os.environ.get('MCP_API_KEY_AIRTABLE')
    elif 'aws' in server_url:
        api_key = os.environ.get('MCP_API_KEY_AWS')
    elif 'notion' in server_url:
        api_key = os.environ.get('MCP_API_KEY_NOTION')
    else:
        api_key = os.environ.get('MCP_API_KEY')
    
    while True:
        try:
            line = sys.stdin.readline()
            if not line:
                break
            
            line = line.strip()
            if not line:
                continue
                
            request = json.loads(line)
            method = request.get("method", "")
            
            # Handle initialization
            if method == "initialize":
                client_version = request.get("params", {}).get("protocolVersion", "2024-11-05")
                response = {
                    "jsonrpc": "2.0",
                    "id": request.get("id"),
                    "result": {
                        "protocolVersion": client_version,
                        "capabilities": {
                            "tools": {},
                            "resources": {},
                            "prompts": {}
                        },
                        "serverInfo": {
                            "name": "HTTP-MCP Bridge (Secure)",
                            "version": "1.1.0"
                        }
                    }
                }
                print(json.dumps(response))
                sys.stdout.flush()
                continue
            
            # Ignore notifications
            if "notification" in method:
                continue
            
            # Handle prompts/list
            if method == "prompts/list":
                response = {
                    "jsonrpc": "2.0",
                    "id": request.get("id"),
                    "result": {"prompts": []}
                }
                print(json.dumps(response))
                sys.stdout.flush()
                continue
            
            # Handle resources/list
            if method == "resources/list":
                response = {
                    "jsonrpc": "2.0",
                    "id": request.get("id"),
                    "result": {"resources": []}
                }
                print(json.dumps(response))
                sys.stdout.flush()
                continue
            
            # Handle tools/list
            if method == "tools/list":
                tools = [
                    {
                        "name": "call",
                        "description": "Call any tool on the HTTP MCP server",
                        "inputSchema": {
                            "type": "object",
                            "properties": {
                                "tool": {"type": "string", "description": "Tool name to call"},
                                "inputs": {"type": "object", "description": "Tool inputs"}
                            },
                            "required": ["tool", "inputs"]
                        }
                    }
                ]
                
                # Add service-specific tools
                if "airtable" in server_url:
                    tools.extend([
                        {
                            "name": "list_tables",
                            "description": "List tables in Airtable base",
                            "inputSchema": {
                                "type": "object",
                                "properties": {
                                    "baseId": {"type": "string"}
                                },
                                "required": ["baseId"]
                            }
                        },
                        {
                            "name": "list_records",
                            "description": "List records from table",
                            "inputSchema": {
                                "type": "object",
                                "properties": {
                                    "baseId": {"type": "string"},
                                    "tableId": {"type": "string"}
                                },
                                "required": ["baseId", "tableId"]
                            }
                        }
                    ])
                elif "supabase" in server_url:
                    tools.extend([
                        {
                            "name": "list_tables",
                            "description": "List database tables",
                            "inputSchema": {"type": "object"}
                        },
                        {
                            "name": "query_table",
                            "description": "Query records from a table",
                            "inputSchema": {
                                "type": "object",
                                "properties": {
                                    "table": {"type": "string"},
                                    "limit": {"type": "number"}
                                },
                                "required": ["table"]
                            }
                        },
                        {
                            "name": "insert_record",
                            "description": "Insert a record into a table",
                            "inputSchema": {
                                "type": "object",
                                "properties": {
                                    "table": {"type": "string"},
                                    "record": {"type": "object"}
                                },
                                "required": ["table", "record"]
                            }
                        },
                        {
                            "name": "update_record",
                            "description": "Update records in a table",
                            "inputSchema": {
                                "type": "object",
                                "properties": {
                                    "table": {"type": "string"},
                                    "updates": {"type": "object"},
                                    "match": {"type": "object"}
                                },
                                "required": ["table", "updates", "match"]
                            }
                        },
                        {
                            "name": "delete_record",
                            "description": "Delete records from a table",
                            "inputSchema": {
                                "type": "object",
                                "properties": {
                                    "table": {"type": "string"},
                                    "match": {"type": "object"}
                                },
                                "required": ["table", "match"]
                            }
                        }
                    ])
                
                response = {
                    "jsonrpc": "2.0",
                    "id": request.get("id"),
                    "result": {"tools": tools}
                }
                print(json.dumps(response))
                sys.stdout.flush()
                continue
            
            # Handle tools/call
            if method == "tools/call":
                params = request.get("params", {})
                
                # Handle the generic "call" tool
                if params.get("name") == "call":
                    args = params.get("arguments", {})
                    http_request = {
                        "tool": args.get("tool"),
                        "inputs": args.get("inputs", {})
                    }
                else:
                    # Direct tool call
                    http_request = {
                        "tool": params.get("name"),
                        "inputs": params.get("arguments", {})
                    }
                
                try:
                    data = json.dumps(http_request).encode('utf-8')
                    
                    # Prepare headers with API key if available
                    headers = {'Content-Type': 'application/json'}
                    if api_key:
                        headers['X-API-Key'] = api_key
                    
                    req = urllib.request.Request(
                        server_url,
                        data=data,
                        headers=headers,
                        method='POST'
                    )
                    
                    with urllib.request.urlopen(req, context=ssl_context, timeout=30) as response:
                        result = json.loads(response.read().decode('utf-8'))
                    
                    response = {
                        "jsonrpc": "2.0",
                        "id": request.get("id"),
                        "result": result.get("result", result)
                    }
                except urllib.error.HTTPError as e:
                    error_msg = f"HTTP {e.code}: {e.reason}"
                    if e.code == 403:
                        error_msg = "Authentication failed. Check your API key configuration."
                    response = {
                        "jsonrpc": "2.0",
                        "id": request.get("id"),
                        "error": {"code": -32603, "message": error_msg}
                    }
                except Exception as e:
                    response = {
                        "jsonrpc": "2.0",
                        "id": request.get("id"),
                        "error": {"code": -32603, "message": str(e)}
                    }
                
                print(json.dumps(response))
                sys.stdout.flush()
                continue
                
        except json.JSONDecodeError:
            pass
        except Exception:
            pass

if __name__ == "__main__":
    main()
