---
description: follow rules for verifying changes after merge
---

# Change Verification Workflow

Before performing any verification steps (e.g., `kubectl get`, `aws ses describe`, checking UI) after making changes that require a PR:

1. **Check Merge Status**: Use `gh pr view` or ask the user to confirm if the PR has been merged into the main branch.
2. **Confirm Deployment**: Ask the user to confirm that the changes have been applied to the environment (e.g., via ArgoCD or manual apply).
3. **Wait for Approval**: Do NOT proceed with verification tool calls until the user explicitly states the changes are applied/merged.
4. **Pull Latest Changes**: If working locally, ensure `main` is up to date:
   ```powershell
   git checkout main
   git pull origin main
   ```
5. **Verify**: Only after confirmation, proceed with the verification steps outlined in the implementation plan.
