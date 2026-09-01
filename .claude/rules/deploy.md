# Deploy Safety (always on)
<!-- No `paths:` frontmatter on purpose: deploy is a command given anytime, not work
     on a specific file, so this rule must always be loaded. -->

Deploy means putting code in front of real users. Treat it as the riskiest action.

- Never deploy without my explicit go-ahead for THIS deploy. "Looks done" is not approval.
- Before deploying, run the `deploy` skill (`.claude/skills/deploy/SKILL.md`) and the
  `checkpoint` skill. Show the pre-deploy evidence; don't skip steps.
- Never deploy with a real `.env` or any secret committed to the repo. Production
  secrets are set in the host's own settings, not in git.
- Deploy from a clean, committed state on a known branch. Record the commit hash.
- State the rollback command BEFORE deploying. If anything fails mid-deploy: STOP,
  do not push more changes, roll back, report state.
- After deploy: check it's actually live and healthy (open the URL / health check /
  logs). "Deployed" without that check is not done.
