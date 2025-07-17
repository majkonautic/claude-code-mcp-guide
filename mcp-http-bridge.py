#!/usr/bin/env python3
import sys
import json
import urllib.request
import ssl

def main():
    if len(sys.argv) < 2:
        print(json.dumps({"error": "No server URL provided"}))
        sys.exit(1)
    
    server_url = sys.argv[1]
    ssl_context = ssl.create_default_context()
    
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
                            "name": "HTTP-MCP Bridge",
                            "version": "1.0.0"
                        }
                    }
                }
                print(json.dumps(response))
                sys.stdout.flush()
                continue
            
            # Ignore notifications
            if "notification" in method:
                continue
            
            # Handle prompts/list - respond immediately with empty list
            if method == "prompts/list":
                response = {
                    "jsonrpc": "2.0",
                    "id": request.get("id"),
                    "result": {"prompts": []}
                }
                print(json.dumps(response))
                sys.stdout.flush()
                continue
            
            # Handle resources/list - respond immediately with empty list
            if method == "resources/list":
                response = {
                    "jsonrpc": "2.0",
                    "id": request.get("id"),
                    "result": {"resources": []}
                }
                print(json.dumps(response))
                sys.stdout.flush()
                continue
            
            # Handle tools/list - provide generic passthrough tools
            if method == "tools/list":
                # Generic tools that work with any HTTP MCP server
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
                
                # Add common tool shortcuts based on server URL
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
                elif "notion" in server_url:
                    tools.extend([
                        {
                            "name": "search",
                            "description": "Search Notion workspace",
                            "inputSchema": {
                                "type": "object",
                                "properties": {
                                    "query": {"type": "string"}
                                },
                                "required": ["query"]
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
                            "name": "execute_sql",
                            "description": "Execute SQL query",
                            "inputSchema": {
                                "type": "object",
                                "properties": {
                                    "query": {"type": "string"}
                                },
                                "required": ["query"]
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
                    req = urllib.request.Request(
                        server_url,
                        data=data,
                        headers={'Content-Type': 'application/json'},
                        method='POST'
                    )
                    
                    with urllib.request.urlopen(req, context=ssl_context, timeout=30) as response:
                        result = json.loads(response.read().decode('utf-8'))
                    
                    response = {
                        "jsonrpc": "2.0",
                        "id": request.get("id"),
                        "result": result.get("result", result)
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
