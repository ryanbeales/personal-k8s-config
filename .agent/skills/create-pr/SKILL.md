---
name: create-pr
description: create a new branch and PR for changes
---

# Create Pull Request

Use this skill to safely commit changes and create a Pull Request on GitHub.

## Instructions

1. Sync the local `main` branch with `origin/main`:
   ```powershell
   git checkout main
   git pull origin main
   ```
2. Create a new branch for the changes:
   ```powershell
   git checkout -b <branch-name>
   ```
3. Stage and commit the changes:
   ```powershell
   git add .
   git commit -m "<commit-message>"
   ```
4. Push the new branch to GitHub:
   ```powershell
   git push -u origin <branch-name>
   ```
5. Create a new pull request and enable auto-merge:
   ```powershell
   gh pr create --fill
   gh pr merge --auto --merge
   ```
6. **Wait for PR Merge**: Pause until the PR checks pass and the auto-merge completes. Use `gh pr checks --watch` to monitor CI.
   - If checks pass, verify the merge status:
     ```powershell
     gh pr view --json state -q .state
     ```
   - **If checks fail**, retrieve the logs to investigate:
     ```powershell
     gh run view --log-failed
     ```
   Only proceed once the state is `MERGED`.
7. Switch back to the default branch and pull the latest changes:
   ```powershell
   git checkout main
   git pull origin main
   ```
