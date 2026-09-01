---
description: Safely deploy using the checkpoint + deploy skills.
---
Run the checkpoint skill first (clean committed state, branch, backup, rollback
written). Then the deploy skill for this project's host. Deploy is high-risk: get my
explicit go-ahead for THIS deploy regardless of matrix row or automode. After deploy, verify
live (URL/health/logs) and record the result in the run report.
