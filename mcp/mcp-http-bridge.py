#!/usr/bin/env python3
"""
Claude MCP HTTP Bridge
- Loads secrets from .env
- Dynamically fetches tool list from remote MCP
"""

import sys
import os
import json
import urllib.request
import ssl
from dotenv import load_dotenv

# === Load .env from folder path (arg3) or cwd ===
env_dir = os.path.abspath(sys.argv[2]) if len(sys.argv) >= 3 else os.getcwd()
env_path = os.path.join(env_dir, ".env")
print(f"DEBUG: loading .env from → {env_path}")
load_dotenv(dotenv_path=env_path, verbose=True)

# === Load secrets ===
server_url = os.getenv("MCP_URL") or (sys.argv[1] if len(sys.argv) >= 2 else None)
api_key = os.getenv("MCP_API_KEY")

print("DEBUG: MCP_URL =", server_url)
print("DEBUG: MCP_API_KEY =", "************" if api_key else None)

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
                print(json.dumps({
                    "jsonrpc": "2.0",
                    "id": request.get("id"),
                    "result": {
                        "protocolVersion": request.get("params", {}).get("protocolVersion", "2024-11-05"),
                        "capabilities": {"tools": {}, "resources": {}, "prompts": {}},
                        "serverInfo": {"name": "Claude MCP HTTP Bridge", "version": "1.1.0"}
                    }
                }))
                sys.stdout.flush()
                continue

            if method in ["prompts/list", "resources/list"]:
                print(json.dumps({
                    "jsonrpc": "2.0",
                    "id": request.get("id"),
                    "result": {"prompts": [] if "prompts" in method else {"resources": []}}
                }))
                sys.stdout.flush()
                continue

            if method == "tools/list":
                try:
                    headers = {
                        "Content-Type": "application/json",
                        "X-API-Key": api_key
                    }
                    req = urllib.request.Request(server_url, data=b"{}", headers=headers, method="POST")
                    with urllib.request.urlopen(req, context=ssl_context, timeout=30) as resp:
                        remote_response = json.loads(resp.read().decode("utf-8"))

                    tools = remote_response.get("tools") or remote_response.get("result", {}).get("tools", [])

                    print(json.dumps({
                        "jsonrpc": "2.0",
                        "id": request.get("id"),
                        "result": { "tools": tools or [] }
                    }))
                    sys.stdout.flush()
                except Exception as e:
                    print(json.dumps({
                        "jsonrpc": "2.0",
                        "id": request.get("id"),
                        "error": {
                            "code": -32603,
                            "message": f"Failed to fetch remote tools: {str(e)}"
                        }
                    }))
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
                headers = {
                    "Content-Type": "application/json",
                    "X-API-Key": api_key
                }

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
                "id": request.get("id", None),
                "error": {"code": -32603, "message": str(e)}
            }))
            sys.stdout.flush()

if __name__ == "__main__":
    main()

