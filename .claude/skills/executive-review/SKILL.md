---
name: executive-review
description: C-level steering review BEFORE big commitments. Auto-run for a new project, major feature, release, infra change, agency campaign, or strategy change. Also run on demand when I say "board audit".
---

# Executive Review (the "should we?" gate)

Delivery gates ask "is it built well?". This asks "should we build it at all, and is
it safe for the business?". Run it BEFORE committing effort, not after.

## When to run
- Auto: new project, major feature, release/deploy, infra change, agency campaign,
  or a strategy change.
- On demand: whenever I say **"board audit"**.
- NOT for trivial/small tasks — that would be bureaucracy. Scope-gate it.

## Review through each lens (skip lenses that truly don't apply, say which)
- **CEO** — business goal, priority, opportunity cost. Is this the right thing now?
  **Demand check:** who specifically wants this, and how do we know? "I can build it"
  is not "someone wants it." If the honest answer is "it's just for me," that's a
  valid GO — but name it, so effort matches the real audience.
- **COO** — process load, bottlenecks, handoffs. Is the approach too heavy?
- **CTO** — architecture, tech debt, scalability of this choice.
- **CIO** — data, access/permissions, retention, documentation, operational continuity.
- **CMO** — positioning, offer, conversion path, analytics (esp. agency/marketing work).
- **DevOps/SRE** — reliability target, deploy/rollback, monitoring, incident path.
- **Security** — threat model, secrets, auth, least privilege (SSDF-level thinking).

## Output (write to _reports/runs/ alongside the run report)
- **Decision: GO / REWORK / STOP**
- Top 3 risks (with the lens that raised each)
- Required reviewers for delivery (feeds the orchestration skill)
- Required evidence before "done"
- Any business stop-conditions (spend, data, provider/DNS changes)

If Decision is STOP or REWORK, do not proceed to build — bring it to me first.
A GO here is about direction; the delivery gates still apply afterwards.

## Sustainable pace (a quiet stop-condition)
Agentic speed makes it easy to ship volume nobody asked for and to vanish into the
build. If a project is being driven hard with no users, no demand signal, and at the
cost of everything else, that is itself a finding — surface it. Shipping more is not
the goal; shipping the right thing at a pace you can keep is. The empty launch is
fine; losing the people around the work is the actual risk.
