---
name: k8s-diagnostic
description: diagnostic routines for troubleshooting k8s home lab issues
---

# K8s Diagnostic Routine

Use this skill to diagnose common failures in a Kubernetes home lab environment.

## Diagnostic Steps

1. **Check Pod Status**:
   ```powershell
   kubectl get pods -n <namespace>
   ```
2. **Describe for Events**: Use this for `CrashLoopBackOff` or `Pending` pods.
   ```powershell
   kubectl describe pod <pod-name> -n <namespace>
   ```
3. **Inspect Logs**: Check both current and previous logs if a pod is crashing.
   ```powershell
   kubectl logs <pod-name> -n <namespace> --tail=50
   kubectl logs <pod-name> -n <namespace> --previous
   ```
4. **Node Affinity & Resources**: For `Pending` pods, check node resources and affinities (especially for GPU/NVIDIA nodes).
   ```powershell
   kubectl get nodes -o custom-columns=NAME:.metadata.name,GPU:.status.allocatable."nvidia\.com/gpu"
   ```

## Advanced Observability

If pod-level diagnostics are insufficient, use the cluster's observability stack:

### Prometheus (Metrics & Querying)
- **Access**: Available on the local network via its `HTTPRoute` hostname.
- **Proxy**: If the hostname is unreachable, use a port-forward:
  ```powershell
  kubectl port-forward -n monitoring svc/prometheus-k8s 9090
  ```
- **Usage**: Query for resource pressure, networking issues, or specific application metrics to identify trends or correlates for failures.

### Loki (Log Aggregation)
- **Usage**: Use Loki when `kubectl logs` (even with `--previous`) is insufficient or when you need to correlate logs across multiple replicas or services.
- **Access**: Typically accessed via the Grafana dashboard.

## Common Failure Patterns

- **NFS Provisioning Failure** (`mount.nfs: Cannot allocate memory`):
  - **Symptoms**: Pods stuck in `ContainerCreating` or PVCs stuck in `Pending` with events showing "failed to provision volume ... mount failed: exit status 32 ... Cannot allocate memory".
  - **Rectification**: Restart the storage-nfs components:
    ```powershell
    kubectl rollout restart ds -n storage-nfs
    kubectl rollout restart deploy -n storage-nfs
    ```
- **Generic MountVolume.SetUp failed**: Check NFS server availability or PVC name mismatches.
- **ImagePullBackOff**: Verify the tag exists and Renovate bot hasn't pushed a non-existent version.
- **OOMKilled**: Compare `kubectl top pod` results with the `resources.limits` defined in the manifest.
