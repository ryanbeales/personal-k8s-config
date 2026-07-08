# Conduit

Conduit is a lightweight Matrix homeserver written in Rust. It uses RocksDB as its database backend.

## Troubleshooting: RocksDB Database Corruption

If Conduit fails to start and crashes with a `RocksDbError` in its logs:

```
2026-07-08T14:25:44.922233Z ERROR conduit: The database couldn't be loaded or created error=RocksDbError { source: Error { message: "Corruption: missing start of fragmented record(2)" } }
```

This error usually indicates a corruption in the RocksDB Write-Ahead Log (WAL) files, often caused by unclean shutdowns or system issues when operating on NFS storage (`crobasaurusrex-nfs`).

Follow these steps to recover the database:

### 1. Scale Down the Deployment
Scale down the Conduit deployment to release lock handles on the Persistent Volume:
```powershell
kubectl scale deploy/conduit -n conduit --replicas=0
```

### 2. Run a Debug Pod
Create a temporary debug pod to mount the Conduit Persistent Volume Claim (`conduit-pvc`).
Apply the following YAML or run a sleep pod with the PVC mounted:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: conduit-debug
  namespace: conduit
spec:
  containers:
  - name: debug
    image: ubuntu
    command: ["sleep", "3600"]
    volumeMounts:
    - name: storage
      mountPath: /srv/conduit
  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: conduit-pvc
```

```powershell
kubectl apply -f conduit-debug.yaml
```

### 3. Backup and Repair the Database
Exec into the debug pod to backup and repair the RocksDB files:

```powershell
# Exec into the debug pod
kubectl exec -it conduit-debug -n conduit -- bash

# 1. Back up the existing database directory
cp -a /srv/conduit/db /srv/conduit/db.bak

# 2. Install rocksdb-tools to get the ldb repair utility
apt-get update && apt-get install -y rocksdb-tools

# 3. Repair the database
ldb repair --db=/srv/conduit/db --verbose --ignore_unknown_options

# 4. Correct permissions back to the ubuntu user (UID 1000)
chown -R 1000:1000 /srv/conduit
```

### 4. Clean Up and Scale Up
Delete the debug pod and restore the deployment:

```powershell
# Delete the debug pod
kubectl delete pod conduit-debug -n conduit

# Scale Conduit back up
kubectl scale deploy/conduit -n conduit --replicas=1
```
