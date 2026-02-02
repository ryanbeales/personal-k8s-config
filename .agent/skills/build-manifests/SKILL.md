---
name: build-manifests
description: build k8s manifests using kustomize with helm support
---

# Build Manifests

Use this skill to build Kubernetes manifests when you have a `kustomization.yaml` that requires Helm chart inflation.

## Instructions

1. Navigate to the directory containing the `kustomization.yaml`.
2. Run the following command to build the manifests:
   ```powershell
   kustomize build . --enable-helm --helm-command helm
   ```
