# Forbidden Sites (per-project denylist)
<!-- CLAUDE.md CORE references this file: "Never access domains listed here."
     It ships EMPTY by design — WebFetch/WebSearch are allowed for any domain by
     default. Add domains here only when THIS project must never touch them. -->

## How it works
- One domain per line. Lines starting with `#` are comments.
- If this list is empty, no domain is blocked (default-allow).
- Keep it specific to real reasons: a competitor's private surface you must not
  scrape, a staging host that must never be hit by an agent, a paid API you don't
  want called by accident, etc.

## Denied domains
# (none yet — add below, e.g.)
# internal-staging.example.com
# do-not-scrape.example.org
