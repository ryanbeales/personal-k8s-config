<RULE[gitops-enforcement]>
**STRICT GITOPS ENFORCEMENT**:
- **NEVER** run `kubectl apply` or any other modifying `kubectl` commands (e.g., `create`, `edit`, `patch`, `delete`) directly against this cluster.
- This cluster is exclusively managed by ArgoCD. 
- All changes must be made by modifying the manifests in the repository, committing them to a feature branch, and creating a Pull Request as defined in the `gitops-workflow` skill.
- Before considering any cluster modification, you MUST explicitly confirm compliance with the GitOps workflow in your internal reasoning. Do not make exceptions for speed or testing.
</RULE[gitops-enforcement]>
