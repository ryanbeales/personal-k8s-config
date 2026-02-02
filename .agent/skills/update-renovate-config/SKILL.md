---
name: update-renovate-config
description: update the list of repositories that Renovate bot scans
---

# Update Renovate Configuration

Use this skill when you need to add or remove repositories from the Renovate bot's scanning list.

## Instructions

1. Locate the Renovate CronJob manifest at `ai-services/renovate/cronjob.yaml` (or similar).
2. Find the `RENOVATE_REPOSITORIES` environment variable under the `renovate-bot` container.
3. Modify the `value` field:
   - It is a comma-separated list of GitHub repositories (e.g., `user/repo1,user/repo2`).
   - Add new repositories or remove existing ones as requested.
4. Follow the `create-pr` skill to stage, commit, and push the changes.
