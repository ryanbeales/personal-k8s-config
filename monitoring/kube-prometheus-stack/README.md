Create secret for Grafana admin credentials:
```bash
kubectl create secret generic grafana-admin-credentials \
  --from-literal=admin-user=admin \
  --from-literal=admin-password=$(openssl rand -base64 12) \
  -n kube-prometheus-stack
```
