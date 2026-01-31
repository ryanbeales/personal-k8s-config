Provides NFS storage to pods in the rest of the cluster.

There are two parts:
- nfs-server to export a local filesystem as NFS
- csi-driver-nfs to automatically provision PVs in the NFS server as directories under the main nfs export.

We'll use the local `/stash` volume on crobasaurusrex (zfs mirrored on 20TB disks) for nfs-server. Kopia has `/stash` mounted and will back up all items below, including this.


When you see this error:
```
failed to provision volume with StorageClass "crobasaurusrex-nfs": rpc error: code = Internal desc = failed to mount nfs server: rpc error: code = Internal desc = mount failed: exit status 32 Mounting command: mount Mounting arguments: -t nfs -o nfsvers=4.1 nfs-server.nfs-server.svc.cluster.local:/ /tmp/pvc-8f94c5ad-107a-450a-9f73-879972a402b6 Output: mount.nfs: Cannot allocate memory
```

Restart the daemonset pods, the CSI controller, and the NFS server in this application.