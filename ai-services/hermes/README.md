# Hermes Agent

Runs the [Nous Research Hermes Agent](https://github.com/NousResearch/Hermes-Agent) inside Kubernetes. It is configured to run agentic loops and automate tasks within the cluster and your GitHub repositories.

## Architecture & Capabilities

* **Model Backend:** Connects to `llama-gemma4-26b` (`gemma-4-26B-A4B-it-qat-q4_0-gguf`) with a context window size of **131,072 (128k) tokens**.
* **Kubernetes Control (`kubectl`)**: The container automatically downloads and installs `kubectl` (`v1.35.0`) on startup. It is mounted into the shared persistent volume directory (`/opt/data/.local/bin/kubectl`) and exists on the default shell `PATH`.
* **RBAC Permissions**: Hermes is bound to a custom ServiceAccount (`hermes`) and a ClusterRole (`hermes-cluster-reader`) that grants:
  - Read-only access (`get`, `list`, `watch`) to cluster-wide and namespaced resources (pods, configmaps, namespaces, deployments, ingress, gateways, ArgoCD applications, etc.) across **all namespaces**.
  - **Secrets are explicitly excluded** from read access to maintain cluster security.
  - Pod execution privileges (`create`/`get` on `pods/exec`) so it can run commands inside containers.

---

## Setup & Prerequisites

Before deploying the Hermes agent via ArgoCD, you **must** configure a GitHub Personal Access Token (classic) to allow it to interact with your code repositories.

### 1. Generate GitHub Personal Access Token (PAT)
1. In your GitHub account settings, navigate to **Settings** > **Developer Settings** > **Personal access tokens** > **Tokens (classic)**.
2. Click **Generate new token (classic)**.
3. Name it (e.g., `hermes-agent-k8s`) and select the **`repo`** scope.
4. Generate the token and copy it.
5. Create the Kubernetes secret:
```bash
kubectl create secret generic hermes-github-secret -n hermes --from-literal=GITHUB_TOKEN=ghp_YO...
```
*(The `deployment.yaml` references this secret and exposes it to the agent as the `GITHUB_TOKEN` environment variable).*

### 2. Create Kubernetes Secret (Gemini)
To enable the Gemini integrations/models, deploy your Gemini API key as a secret in the `hermes` namespace:

```bash
kubectl create secret generic hermes-gemini-secret -n hermes --from-literal=GEMINI_API_KEY=AIzaSy...
```
*(The `deployment.yaml` references this secret and exposes it to the agent as the `GEMINI_API_KEY` environment variable).*

### 3. Create Kubernetes Secret (Dashboard Auth)
To secure the Hermes Dashboard, you must provide a basic auth username and password:

```bash
kubectl create secret generic hermes-dashboard-secret -n hermes \
  --from-literal=username=admin \
  --from-literal=password='YOUR_PASSWORD'
```
*(The `deployment.yaml` references this secret and exposes it to the agent).*

### 4. Adding SearXNG MCP Support
If you want to enable SearXNG search capabilities, add the MCP server to your Hermes configuration. 

Run the following command from a terminal with `hermes` access (e.g., within the cluster):

```bash
hermes mcp add searxng --command npx --args mcp-searxng --env SEARXNG_URL=http://searxng.searxng.svc.cluster.local:8080
```

The agent uses the [Aphrodite platform](https://github.com/NousResearch/Aphrodite) to power its tool integrations.
