# OpenClaw

Open source Claude-inspired alternative for AI-assisted coding and agentic workflows.

## Configuration & Authentication

This deployment uses a persistent gateway authentication token to ensure secure access to the Control UI across restarts.

### Gateway Token Secret

For security, the gateway token is NOT stored in this repository. It must be created manually in the cluster for the deployment to start correctly.

#### Creation Command

Run the following command in your terminal to create the required secret:

```bash
kubectl create secret generic openclaw-secret -n openclaw --from-literal=OPENCLAW_GATEWAY_AUTH_TOKEN=f19f6a8e3b2c1d4a5b6e7f8a9c0d1e2f3b4a5c6d7e8f9a0b
```

#### Token Reference

Use the following token to log in to the dashboard:
**`f19f6a8e3b2c1d4a5b6e7f8a9c0d1e2f3b4a5c6d7e8f9a0b`**

### Repository Structure

- `values.yaml`: Helm overrides for the `serhanekicii/openclaw-helm` chart (using `app-template`).
- `kustomization.yaml`: Kustomize configuration to stitch together the namespace and Helm release.
- `httproute.yaml`: Gateway API routing configuration for external access.
