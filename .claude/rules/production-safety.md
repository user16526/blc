---
paths:
  - "**/deploy/**"
  - "**/infra/**"
  - "**/production/**"
  - "**/.env.production"
  - "**/Dockerfile"
  - "**/docker-compose.prod*"
---

# Rule: Production Safety

## Principle

Everything that touches production requires user confirmation. Everything else — full autonomy.

## Requires Confirmation

- Deploy to a production server
- Changes to the production database (migrations, data)
- DNS, domain, SSL changes
- Production environment variable changes
- Push to main/master (if that is the production branch)
- Package publication (npm publish, PyPI upload)
- Changes to the CI/CD pipeline for production

## Full Autonomy (never ask)

- Creating, modifying, deleting project files
- Running tests (unit, integration, E2E)
- Git operations: commit, branch, merge (except push to production)
- Staging deploy
- Local development
- Dependency installation
- Code refactoring
- Creating and updating documentation

## How to Ask

Keep it short. No unnecessary explanation:

```
Production deploy ready:
- [what will be deployed]
- [what changes]
Confirm? (y/n)
```
