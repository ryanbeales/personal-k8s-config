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
  - **Rectification**: Restart the NFS server deployment:
    ```powershell
    kubectl rollout restart deploy -n nfs-server
    ```

- **NFS Mount Timeout** (`MountVolume.SetUp failed ... rpc error: code = Internal desc = time out`):
  - **Symptoms**: Pods stuck in `ContainerCreating` with FailedMount events showing RPC timeout. New mount commands from the CSI node plugin hang indefinitely.
  - **Key info**: The NFS server runs in namespace `nfs-server`. The CSI NFS driver pods (`csi-nfs-node-*`, `csi-nfs-controller-*`) run in `kube-system`. The StorageClass is `crobasaurusrex-nfs` using provisioner `nfs.csi.k8s.io` with `nfsvers=4.1`.
  - **Diagnosis** (escalate through these steps):
    1. Check if the NFS server pod is running:
       ```powershell
       kubectl get pods -n nfs-server
       ```
    2. Verify NFS exports are working inside the server (NFSv4 does NOT need mountd, so `showmount -e` returning "Program not registered" is normal):
       ```powershell
       kubectl exec -n nfs-server deploy/nfs-server -- exportfs -v
       kubectl exec -n nfs-server deploy/nfs-server -- rpcinfo -p localhost
       ```
       Look for program `100003` (nfs) in rpcinfo output. Mountd (100005) NOT being registered is expected for NFSv4-only.
    3. Check if the CSI NFS node plugin on the affected node can actually mount:
       ```powershell
       # Find the CSI node plugin pod on the affected node
       kubectl get pods -n kube-system -l app=csi-nfs-node -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName
       # Test a manual mount from inside it (exit code 124 = timeout)
       kubectl exec -n kube-system <csi-nfs-node-pod> -c nfs -- sh -c "mkdir -p /tmp/nfs-test && timeout 10 mount -t nfs4 -o nfsvers=4.1 nfs-server.nfs-server.svc.cluster.local:/ /tmp/nfs-test && echo SUCCESS && umount /tmp/nfs-test"
       ```
    4. If the manual mount times out, check for stale kernel NFS state on the node:
       ```powershell
       kubectl exec -n kube-system <csi-nfs-node-pod> -c nfs -- cat /proc/fs/nfsfs/servers
       kubectl exec -n kube-system <csi-nfs-node-pod> -c nfs -- cat /proc/mounts | Select-String "nfs"
       ```
  - **Root cause**: When the NFS server pod restarts, existing kernel NFS client connections on nodes become stale. The Linux kernel NFS client holds onto the dead session and blocks ALL new NFS mounts on that node, not just the original ones.
  - **Rectification** (in order of escalation):
    1. First try restarting the NFS server: `kubectl rollout restart deploy -n nfs-server`
    2. Then restart the CSI NFS node plugin on the affected node: `kubectl delete pod -n kube-system <csi-nfs-node-pod>`
    3. Delete and recreate the affected pod to get a fresh mount attempt.
    4. **If all above fail** (stale kernel NFS state): **reboot the affected node**. This is the only reliable way to clear stale kernel NFS client state. The kernel NFS client does not recover on its own once stuck.

- **ImagePullBackOff**: Verify the tag exists and Renovate bot hasn't pushed a non-existent version.
- **OOMKilled**: Compare `kubectl top pod` results with the `resources.limits` defined in the manifest.
