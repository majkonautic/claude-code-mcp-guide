#!/usr/bin/env python3
"""
MCP HTTP Bridge – Shared Bridge for Claude <-> Remote MCPs
Loads .env from the current working directory
"""

import sys
import json
import urllib.request
import ssl
import os
from dotenv import load_dotenv

# Load .env from the current working directory
load_dotenv(dotenv_path=os.path.join(os.getcwd(), ".env"))

# Load required values
server_url = os.getenv("MCP_URL") or (sys.argv[1] if len(sys.argv) > 1 else None)
api_key = os.getenv("MCP_API_KEY")

if not server_url or not api_key:
    print(json.dumps({"error": "Missing MCP_URL or MCP_API_KEY"}))
    sys.exit(1)

ssl_context = ssl.create_default_context()

def main():
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
                            "name": "Claude MCP Bridge",
                            "version": "1.0.0"
                        }
                    }
                }
                print(json.dumps(response))
                sys.stdout.flush()
                continue

            if "notification" in method:
                continue

            if method in ["prompts/list", "resources/list"]:
                response = {
                    "jsonrpc": "2.0",
                    "id": request.get("id"),
                    "result": {"prompts": [] if "prompts" in method else {"resources": []}}
                }
                print(json.dumps(response))
                sys.stdout.flush()
                continue

            if method == "tools/list":
                response = {
                    "jsonrpc": "2.0",
                    "id": request.get("id"),
                    "result": {"tools": [
                        {
                            "name": "call",
                            "description": "Call a remote MCP tool",
                            "inputSchema": {
                                "type": "object",
                                "properties": {
                                    "tool": {"type": "string"},
                                    "inputs": {"type": "object"}
                                },
                                "required": ["tool", "inputs"]
                            }
                        }
                    ]}
                }
                print(json.dumps(response))
                sys.stdout.flush()
                continue

            if method == "tools/call":
                params = request.get("params", {})
                if params.get("name") == "call":
                    args = params.get("arguments", {})
                    payload = {"tool": args.get("tool"), "inputs": args.get("inputs", {})}
                else:
                    payload = {"tool": params.get("name"), "inputs": params.get("arguments", {})}

                data = json.dumps(payload).encode("utf-8")
                headers = {"Content-Type": "application/json", "X-API-Key": api_key}

                req = urllib.request.Request(server_url, data=data, headers=headers, method="POST")

                with urllib.request.urlopen(req, context=ssl_context, timeout=30) as resp:
                    result = json.loads(resp.read().decode("utf-8"))

                print(json.dumps({
                    "jsonrpc": "2.0",
                    "id": request.get("id"),
                    "result": result.get("result", result)
                }))
                sys.stdout.flush()
        except Exception as e:
            print(json.dumps({
                "jsonrpc": "2.0",
                "id": request.get("id"),
                "error": {"code": -32603, "message": str(e)}
            }))
            sys.stdout.flush()

if __name__ == "__main__":
    main()

