---
name: deploy
description: Safe deployment procedure for this project. Use whenever I ask to deploy, ship, publish, release, or push to production.
---

# Deploy

Fill in the blanks once the host is chosen (ask me if unknown). Until then, follow
the host-agnostic steps and STOP at step 4 to ask how this project deploys.

## This project's deploy (fill in)
- Host:                  <!-- Vercel / Netlify / VPS+SSH / GitHub auto-deploy / other -->
- Deploy command or flow:
- Live URL:
- Health / SRE (fill what applies):
  - SLO / health target:
  - Error budget / downtime tolerance:
  - Health check command:
  - Log path:
  - Alert condition:
  - Backup path:  | Restore tested: yes/no
  - Rollback command:
- Where production secrets live (NOT in git):
- Rollback (how to undo this exact deploy):

## Steps (every deploy)
1. Run the `checkpoint` skill first: clean committed state, on a branch, backup if data.
2. Pre-deploy checks — show evidence:
   - build passes / tests pass (or skipped with a written reason)
   - no real `.env` or secret staged or committed
   - the commit hash being deployed is recorded
3. State the rollback command for THIS deploy and show it to me.
4. Get my explicit go-ahead for THIS deploy. (If host is still unknown, STOP here
   and ask me how this project should be deployed; do not guess.)
5. Deploy using the flow above.
6. Verify LIVE: open the URL / run the health check / read logs. Show the result.
7. If broken: STOP, roll back via the command from step 3, report state.

## Notes by host type (delete the ones you don't use)
- **Auto-deploy from GitHub** (Vercel/Netlify/etc.): deploy = `git push` to the
  tracked branch; the host rebuilds automatically. Secrets go in the host's
  dashboard (Environment Variables), never in git. Rollback = revert the commit
  or use the host's "promote previous deployment" button.
- **VPS over SSH**: deploy = connect, pull the new code, restart the service.
  Take a backup of the current release first. Rollback = restart the previous
  release. Never run destructive server commands without my approval.
