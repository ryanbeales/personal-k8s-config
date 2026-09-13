# Obico

Smart 3D printing monitoring and AI failure detection.

## Prerequisites

### 1. Obico Secret
Obico requires a secret named `obico-secret` in the `obico` namespace containing the Django secret key (`DJANGO_SECRET_KEY`):

```powershell
kubectl create secret generic obico-secret -n obico `
  --from-literal=DJANGO_SECRET_KEY="<YOUR_SECRET_KEY>"
```
