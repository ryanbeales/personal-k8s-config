# Windmill

Runs [Windmill](https://www.windmill.dev/) (`ghcr.io/windmill-labs/windmill`) — a code-first developer platform for turning Python, TypeScript, Go, and Bash scripts into workflows, UIs, webhooks, scheduled jobs, and MCP tools.

## Architecture

- **`windmill` (`deployment.yaml`)**: Windmill API & Web UI server (`MODE=server`, port `8000`), including the native Streamable HTTP MCP Server (`/api/mcp/...`).
- **`windmill-worker` (`worker-deployment.yaml`)**: Runs both a `default` worker (`WORKER_GROUP=default`) and a `native` fast worker (`WORKER_GROUP=native`, `NATIVE_MODE=true`).
- **`windmill-extra` (`lsp-deployment.yaml`)**: Provides Language Server Protocol (`/ws/`) autocomplete and interactive debugging (`/ws_debug/`) in the browser editor.
- **`windmill-postgres` (`postgres-deployment.yaml`)**: Dedicated PostgreSQL 16 database backed by `windmill-nfs-pvc`.

## External URLs

- `https://windmill.crobasaurusrex.ryanbeales.com`
- `https://windmill.crobceratops.ryanbeales.com`
- Default initial login: `admin@windmill.dev` / `changeme`

---

## Windmill MCP Server Setup

Windmill includes a built-in **Streamable HTTP MCP server** that allows AI agents (such as **Antigravity** and **Hermes**) to list workspaces, search/inspect scripts & flows, trigger jobs, and read execution logs.

### 1. Generate a Windmill MCP Token

1. Log in to `https://windmill.crobasaurusrex.ryanbeales.com`.
2. Open **Account Settings** (bottom-left user menu) -> **Tokens**.
3. Click **New Token** -> **Generate MCP URL** (choose either a specific workspace like `starter` or **All workspaces**).
4. Copy the generated Streamable HTTP MCP URL:
   - **Workspace-scoped**: `https://windmill.crobasaurusrex.ryanbeales.com/api/mcp/w/<workspace_id>/mcp?token=<your_token>`
   - **Multi-workspace gateway**: `https://windmill.crobasaurusrex.ryanbeales.com/api/mcp/gateway?token=<your_token>`

### 2. Connect Antigravity (`mcp_config.json`)

In `C:\Users\Ryan\.gemini\antigravity\mcp_config.json`, add the `windmill` entry under `mcpServers`:

```json
{
  "mcpServers": {
    "windmill": {
      "url": "https://windmill.crobasaurusrex.ryanbeales.com/api/mcp/gateway?token=<your_token>"
    }
  }
}
```

### 3. Connect Hermes Agent (In-Cluster)

From inside the `hermes` pod (or via `kubectl exec -n hermes deploy/hermes -c hermes -- ...`), register Windmill's internal cluster MCP URL:

```bash
hermes mcp add windmill --url "http://windmill.windmill.svc.cluster.local:8000/api/mcp/gateway?token=<your_token>"
```
