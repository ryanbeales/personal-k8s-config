# Conduit

Conduit is a lightweight Matrix homeserver written in Rust. It uses RocksDB as its database backend.

## Troubleshooting: RocksDB Database Corruption

If Conduit experiences an unclean shutdown over NFS (`crobasaurusrex-nfs`) and corrupts its RocksDB Write-Ahead Log (WAL):

```
ERROR conduit: The database couldn't be loaded or created error=RocksDbError { source: Error { message: "Corruption: missing start of fragmented record(2)" } }
```

### Automated Recovery (`repair-rocksdb` InitContainer)

`deployment.yaml` includes an idempotent `repair-rocksdb` `initContainer` that inspects `/srv/conduit/db/LOG` before Conduit starts:
- On healthy startups, it prunes any stale `LOG.old.*` files and exits immediately with zero overhead.
- If `DB::Open() failed: Corruption:` is present in `/srv/conduit/db/LOG`, it automatically backs up `/srv/conduit/db` to `/srv/conduit/db.bak`, installs `rocksdb-tools`, runs `ldb repair --db=/srv/conduit/db --verbose --ignore_unknown_options`, rotates `LOG` to `LOG.repaired`, and restores `1000:1000` ownership.

If Conduit enters a crash loop after a live WAL corruption event, restarting the pod (`kubectl rollout restart deploy/conduit -n conduit`) triggers the `initContainer` to repair the database automatically while respecting `strategy: Recreate`.
