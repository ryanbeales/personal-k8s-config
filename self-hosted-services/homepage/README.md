# Homepage

Runs [Homepage](https://gethomepage.dev/) (`ghcr.io/gethomepage/homepage`) as the central cluster dashboard with automatic Kubernetes Gateway API (`HTTPRoute`) discovery enabled.

## URLs

- `https://homepage.crobasaurusrex.ryanbeales.com`
- `https://homepage.crobceratops.ryanbeales.com`

## Automatic `HTTPRoute` Discovery

Homepage is configured in `configmap.yaml` (`kubernetes.yaml`) with:

```yaml
mode: cluster
gateway: true
ingress: false
```

To expose any service on the dashboard, add `gethomepage.dev/*` annotations to its `HTTPRoute`:

```yaml
metadata:
  annotations:
    gethomepage.dev/enabled: "true"
    gethomepage.dev/name: "My App"
    gethomepage.dev/group: "AI & Automation"
    gethomepage.dev/icon: "my-app.png"
    gethomepage.dev/description: "Short description of the service"
```
