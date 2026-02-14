---
name: gitops-workflow
description: complete lifecycle for making changes, from PR to ArgoCD sync
---

# GitOps Workflow

This skill covers the entire lifecycle of a change in this repository, from creating a branch to verifying the deployment in ArgoCD.

## 1. Development and PR Creation

1. **Prepare Main**: Ensure you are on the latest `main`.
   > [!IMPORTANT]
   > **NEVER push directly to `main`.** The `main` branch is protected. Always create a feature branch.

   ```powershell
   git checkout main
   git pull origin main
   ```
2. **Feature Branch**: Create a descriptive branch.
   ```powershell
   git checkout -b <branch-name>
   ```
3. **Commit & Push**:
   ```powershell
   git add .
   git commit -m "<commit-message>"
   git push -u origin <branch-name>
   ```
4. **Create PR & Auto-Merge**:
   ```powershell
   gh pr create --fill
   gh pr merge --auto --merge
   ```

## 2. CI Verification and Merge

1. **Watch Checks**: Pause until CI completes.
   ```powershell
   gh pr checks --watch
   ```
   - **If checks fail**: Investigate logs immediately:
     ```powershell
     gh run view --log-failed
     ```
2. **Verify Merge**: Confirm the PR has reached the `MERGED` state.
   ```powershell
   gh pr view --json state -q .state
   ```

## 3. Post-Merge Sync and Deployment

1. **Update Local Main**:
   ```powershell
   git checkout main
   git pull origin main
   ```
2. **Verify ArgoCD Sync**: Confirm the change is applied to the cluster.
   ```powershell
   # App name is usually the directory name or found in argocd.yaml
   kubectl get app -n argocd <app-name>
   ```
3. **Verify Health**: Ensure the application transitions to `Healthy` and `Synced`.

## Standards

- **Auto-Sync**: Most applications have `prune: true` and `selfHeal: true`.
- **Diagnostics**: If the app is not healthy, use the `k8s-diagnostic` skill to investigate.
