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

## Troubleshooting Helm Issues

If the build fails due to missing charts or dependency issues:

1. **Update Dependencies**: Navigate to the directory containing `Chart.yaml` (if applicable) or the kustomization, and run:
   ```powershell
   helm dependency update
   ```
2. **Check Helm Repo**: Ensure the required repositories are added:
   ```powershell
   helm repo list
   ```
3. **Environment**: If `kustomize` cannot find the `helm` binary, verify the path or explicitly set `--helm-command` to the full path of the helm executable.
