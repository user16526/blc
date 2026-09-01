#!/usr/bin/env python3
"""
READ-ONLY  —  TEMPLATE STUB, IMPLEMENT FOR THIS PROJECT.

Print the LIVE truth for the facts that go stale fastest in this project and that a
wrong note would make costly. Run this BEFORE trusting any live-system fact in
current.md / CLAUDE.md. See .claude/rules/verify-external-state.md.

Fill in checks for your stack, e.g.:
  - the deployed app version / git SHA actually running in production
  - a published config version (analytics container, feature flags, CDN)
  - an external API / DB / queue's current state (feed scheme, row count, depth)
Each check should print the LIVE value and, where possible, flag when current.md
disagrees with it. Keep every check READ-ONLY.

Run:  python scripts/check_live_state.py
"""
import datetime


def main():
    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
    print(f"=== LIVE STATE (source of truth) — {now} ===")
    print("TODO: implement live checks for this project's external systems.")
    print("Until implemented, verify each live-system fact by hand before acting on a note.")
    print("If current.md / CLAUDE.md disagree with the live system, THEY are stale — trust live.")


if __name__ == "__main__":
    main()
