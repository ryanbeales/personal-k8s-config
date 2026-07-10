# n8n Automation Platform

This directory contains the Kubernetes manifests to deploy n8n.

## Manual Secret Provisioning

Before n8n can start, it requires an encryption key to securely store sensitive credentials (like API keys) in its database. 
You must create a Kubernetes Secret containing this key manually.

1. Generate a secure random string for your encryption key.
2. Run the following command in your terminal:

```bash
kubectl create secret generic n8n-secrets -n n8n --from-literal=N8N_ENCRYPTION_KEY="<your-secure-random-string>"
```

Once this secret is created, ArgoCD will successfully start the n8n pod, and you can visit `https://n8n.crobasaurusrex.ryanbeales.com` to set up your owner account!
