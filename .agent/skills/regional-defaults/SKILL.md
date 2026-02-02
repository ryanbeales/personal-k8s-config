---
name: regional-defaults
description: follow rules for regional infrastructure deployment
---

# Regional Infrastructure Defaults

When creating or modifying cloud resources (AWS, GCP, etc.) using Crossplane or other IAC tools, follow these rules:

## Rules

1. **Default Region**: Use `us-west-2` as the default region for all resources unless explicitly requested otherwise or if the resource is global.
2. **Consistency**: Ensure all related resources (e.g., S3 buckets, SES identities, ACM certificates) in a component or application are deployed in the same region to avoid cross-region latency and complexity.
3. **Manifest Documentation**: If a resource MUST be in a specific region other than `us-west-2`, document the reason in a comment within the manifest.
