# scripts/secret-patterns.sh — ONE regex source for all secret scanners.
# Sourced by: guard.sh (PreToolUse), pre-commit (git), quality-gate.sh (step 3).
# Update HERE, never in three places. Add a test in test-hooks.sh for every new family.
#
# Covered families (prefix-anchored, quote-independent, match anywhere in the text):
#   sk-…            OpenAI (incl. sk-proj-), Anthropic (sk-ant-…), other sk- vendors
#   ghp_/gho_/ghu_/ghs_/ghr_, github_pat_   GitHub tokens (classic + fine-grained)
#   xox[baprs]-     Slack
#   AKIA…           AWS access key id
#   glpat-          GitLab PAT
#   AIza…           Google API key
#   PRIVATE KEY     any PEM private key block
#   generic         quoted "api_key|secret|password|token" = "12+ chars"
#
# NOTE: this is a GUARDRAIL, not a security wall. Prefix regexes catch known
# families; a novel/renamed token can pass. Layer it with the git pre-commit
# hook, host-side settings for prod secrets, and (in CI) a real secret scanner.
SECRET_REGEX='(sk-[A-Za-z0-9_-]{20,}|gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|AKIA[0-9A-Z]{16}|glpat-[A-Za-z0-9_-]{20,}|AIza[0-9A-Za-z_-]{30,}|-----BEGIN [A-Z ]*PRIVATE KEY-----|"?(api[_-]?key|secret|password|token)"?[[:space:]]*[:=][[:space:]]*"[^"]{12,}")'
