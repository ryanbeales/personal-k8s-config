# OpenClaw

Open source Claude-inspired alternative for AI-assisted coding and agentic workflows.

### Gateway Token Secret

For security, the gateway token is NOT stored in this repository. It must be created manually in the cluster for the deployment to start correctly.

#### Creation Command

Run the following command in your terminal to create the required secret:

```bash
kubectl create secret generic openclaw-secret -n openclaw \
  --from-literal=OPENCLAW_GATEWAY_TOKEN=<token>
```
