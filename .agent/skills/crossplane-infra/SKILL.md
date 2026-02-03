---
name: crossplane-infra
description: managing infrastructure resources via crossplane
---

# Crossplane Infrastructure Management

Use this skill when interacting with cloud resources managed via Crossplane.

## Resource Lifecycle

1. **Claims**: Interact with the high-level `Claim` resources first.
2. **Managed Resources**: Check the underlying cloud resources (e.g., `Bucket.s3.aws.upbound.io`) for provider-specific errors.
3. **Reconciliation**: Monitor the `SYNCED` and `READY` status.
   ```powershell
   kubectl get managed
   kubectl get claim
   ```

## Rules for New Infrastructure

- **Region Consistency**: Default to `us-west-2` as defined in `regional-defaults`.
- **Secret Management**: Ensure matching `ExternalSecret` or `Secret` resources are provisioned for cross-cluster connectivity.
- **Provider Families**: Group provider configurations in individual files (e.g., `provider-aws-s3.yaml`).

## Debugging

If a resource is stuck in `READY: False`:
1. **Describe the Resource**: Look for the `Events` section which often contains the cloud provider's error message.
   ```powershell
   kubectl describe <kind> <name>
   ```
2. **Check Provider Logs**: Inspect the logs of the specific Crossplane provider pod in the `crossplane-system` namespace.
