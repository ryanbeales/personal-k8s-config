# Hermes Agent

Runs the [Nous Research Hermes Agent](https://github.com/NousResearch/Hermes-Agent) inside Kubernetes. It is configured to run agentic loops and automate tasks within the cluster and your GitHub repositories.

## Architecture & Capabilities

* **Model Backend:** Connects to `vllm-gemma4-26b` (`gemma-4-26B-A4B-it-qat-W4A16`) with a context window size of **131,072 (128k) tokens**.
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

### 2. Create Kubernetes Secret
Deploy the token to the cluster as a secret in the `hermes` namespace:

```bash
kubectl create secret generic hermes-github-secret -n hermes --from-literal=GITHUB_TOKEN=ghp_YOUR_TOKEN_HERE
```
*(The `deployment.yaml` references this secret and exposes it to the agent as the `GITHUB_TOKEN` environment variable).*
