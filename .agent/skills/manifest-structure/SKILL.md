---
name: manifest-structure
description: follow rules for manifest structure and organization
---

# Manifest Structure and Organization

When creating or modifying Kubernetes manifests in this repository, follow these standards for consistency and to ensure proper deployment via ArgoCD.

## Directory Organization

- **Service Grouping**: Resources are grouped into functional top-level directories (e.g., `ai-services`, `cluster-services`, `websites`).
- **Service Directories**: Every application or service must have its own subdirectory.
- **ArgoCD Discovery**: To register a service with ArgoCD, the directory **must** contain an `argocd.yaml` file. This file is tracked by the `ApplicationSet` in `argocd/applicationset/application-set.yaml`.
- **Kustomization**: Each service directory should include a `kustomization.yaml` file listing all resources.

## File Standards

- **One Resource Per File**: Each `.yaml` file must contain exactly one Kubernetes resource.
- **Naming Convention**: 
  - Use descriptive, lowercase names based on the resource type (e.g., `deployment.yaml`, `service.yaml`, `httproute.yaml`).
  - For specific infrastructure, use the purpose (e.g., `ollama-nfs-pvc.yaml`).
- **YAML Header**: Always include `apiVersion` and `kind` as the first two lines.

## Formatting and Metadata

- **Metadata**:
  - **Namespace**: Explicitly define the `namespace` in the `metadata` block of every resource.
  - **Labels**: Use standard labels, primarily `app.kubernetes.io/name: <service-name>`.
- **Indentation**: Use 2-space indentation.
- **Comments**: 
  - Provide descriptive comments for critical or complex configurations (e.g., resource limits, GPU requirements, or non-standard strategy types).
  - Use Renovate bot annotations for image versions:
    ```yaml
    # renovate: datasource=github-tags depname=user/repo versioning=semver
    image: user/repo:v1.0.0
    ```
- **Probes and Resources**: Always define `resources` (limits/requests) and appropriate probes (`livenessProbe`, `readinessProbe`) for Deployments to ensure stability.

## Example Structure

```mermaid
graph TD
    Root[/] --> AS[ai-services]
    AS --> OL[ollama]
    OL --> K[kustomization.yaml]
    OL --> A[argocd.yaml]
    OL --> D[deployment.yaml]
    OL --> S[service.yaml]
```
