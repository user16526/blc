# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# BLC (BloodyCase)

## Purpose

BloodyCase is an online case-opening platform — primarily CS2 (90%), with RUST (8%) and Dota 2 (2%). Users buy or earn cases and receive randomized weapon skins with real monetary value. Core game modes: standard case opening, Case Battles, Sniper Battle, Skin Upgrader, and Trade-Up Contracts. Monetization via deposits (min $5), a 25% first-deposit bonus, and daily giveaways. Registration via Steam, Google, Discord, Facebook, Twitch.

**Claude's role here is product, marketing, and UI/UX only — no backend or frontend development.** Tasks include: UX analysis, UI design review, marketing strategy, analytics interpretation, product decisions, conversion optimization, copy, and retention mechanics.

## Architecture

**Frontend:** Angular  
**Backend:** Go  
**Analytics:** Google Analytics 4 (GA4), Microsoft Clarity  

Claude does not write or modify application code. All technical implementation is handled by the development team separately.

## Contracts & Integrations

**In scope for Claude:**
- **Google Analytics 4** — traffic, conversion, retention metrics
- **Microsoft Clarity** — session recordings, heatmaps, UX behavior analysis

**Out of scope (dev team handles):**
- Payment providers, Steam API, Provably Fair verification backend, game integrations

---

## Operating Mode

You are the manager of this project. Work autonomously.

**Input:** a technical specification from the user.

**Your actions:**
1. Decompose the task into subtasks
2. Identify which agent owns each subtask — default to `gaming-product-owner` or `gaming-ux-strategist` for any product/marketing/UX work
3. Launch subagents in parallel for independent tasks
4. Coordinate, track results, integrate
5. After each subagent: update SNAPSHOT.md
6. Report the result

**Full autonomy** in everything except production deploy — always confirm that with the user.

**Do not bother the user.** Never ask for confirmation on technical actions. The user provides a spec and expects results. File creation, running tests, commits, refactoring, approach selection, staging deploy — all of these are your decisions.

## Subsystems

| Layer | Path | Purpose |
|-------|------|---------|
| Rules | `.claude/rules/` | Operational rules, loaded contextually |
| Skills | `.claude/skills/` | Modular operations, invoked on demand |
| Agents | `.claude/agents/` | Subagents for delegation |
| Hooks | `.claude/hooks/` | Automated guardrails (run in background) |
| Logs | `.claude/logs/` | Sessions, migrations, errors (gitignored) |
| State | `.claude/SNAPSHOT.md` | Current project snapshot |
| Metadata | `manifest.md` | Project name, repo_access mode |
| Scripts | `scripts/` | Helpers for framework state and repo_access switching |

### Background Automation (hooks)

Hooks are **reminders and guardrails**, not enforcement. They fire automatically in the background:

- **PostToolUse** → checkpoint every 20 tool calls: if uncommitted files exist — reminder to commit
- **SubagentStop** → after each subagent: reminder to execute commit → SNAPSHOT → integrate cycle (logic in delegation.md)
- **PreCompact** → before compaction: auto-commit tracked (not untracked) changes + update SNAPSHOT timestamp
- **PostCompact** → after compaction: output SNAPSHOT contents + recent commits to restore context

### Standard Skills

- `/start` — session initialization (load state, report readiness)
- `/finish` — session completion (commit docs/assets, update SNAPSHOT)
- `/housekeeping` — maintenance: README, CHANGELOG, .gitignore drift (run before push)

Skills not applicable here (no code): `/testing`, `/playwright`, `/db-migrate`

### Repo Access

- `repo_access=private-solo` → framework files can live in git history
- `repo_access=public` / `private-shared` → framework files must remain local only
- Use `scripts/switch-repo-access.sh` to switch modes
- If the project already committed framework files as `private-solo`, changing `.gitignore` alone is not enough

### Agents — Routing Guide

**Primary agents for this project (use these first):**

| Agent | Trigger | Scope |
|-------|---------|-------|
| `gaming-product-owner` | Product strategy, feature prioritization, backlog, KPI definitions, marketing strategy, CS2/Rust/Dota2 domain questions, retention mechanics, referral programs, gamer psychology | CS2/Rust/Dota2 skin economics, RICE/MoSCoW scoring, GMV/conversion/churn KPIs, community-led growth, influencer/streamer strategy, SEO for gaming commerce |
| `gaming-ux-strategist` | UI/UX analysis, conversion optimization, landing page review, onboarding flows, player journey mapping, ad creative strategy, bonus/promotion UX, session recordings interpretation (Clarity) | Case opening UI, case browsing filters, trust signals, payment flow UX, FOMO mechanics, GA4 funnel analysis, A/B test design |

**Use `gaming-product-owner` when:** the task is about *what to build or what to prioritize* — product decisions, marketing channels, feature roadmap, game-specific domain knowledge.

**Use `gaming-ux-strategist` when:** the task is about *how it looks or converts* — UX audit, UI structure, onboarding friction, ad creative, Clarity heatmap review, funnel drop-off diagnosis.

**Both agents in parallel when:** the task spans both dimensions (e.g. "redesign our case battles page" = UX analysis + product strategy simultaneously).

**Supporting agents (infrastructure/research only):**

- `researcher` — web research, competitor analysis, fetching external data
- `implementer` — writing docs, templates, structured briefs (not code)
- `reviewer` — reviewing deliverables, strategy docs, copy

### Rules (always in context)

- `autonomy.md` — deficit → blocker → unblock cycle, anti-paralysis
- `delegation.md` — delegation criteria, mandatory commit after each subagent
- `context-management.md` — context degradation protection, pre/post compaction
- `production-safety.md` — production deploy only with user confirmation
- `local-first.md` — develop on SQLite, migrate to cloud after stabilization
- `commit-policy.md` — what to commit, what not to, three modes by project type
- `logging.md` — local logging of sessions, migrations, errors

---

## Mockup Conventions

Mockups live in `mockups/main002/`. Assets (images, CSS, fonts) are in `index_files/` relative to the mockup file — never use external CDN URLs in mockups.

**Versioning:** `index.htm` = v1 baseline (do not overwrite). New iterations are `index2.html`, `index3.html`, `index4.html` etc.

**App-shell constraint:** `index.htm` is the authenticated user view. When improving it, preserve the full two-row header, game tabs, balance widget, and nav icons. Do not convert to a landing-page layout.

**fantaicon:** BloodyCase uses a custom icon font. Files are stored at `index_files/fantaicon.woff2` and `index_files/fantaicon.woff` (sourced from `https://chipper-manatee-749c59.netlify.app/fonts/fantaicon/`). The CSS at `index_files/fantaicon.css` references them with cache-busting query strings — Python's `http.server` strips query strings automatically so the local files resolve correctly.

**Local server for Playwright:** The `file://` protocol is blocked in Playwright. Always serve mockups via `python -m http.server 8099` from the mockups directory before taking screenshots.

---

## Approved Design System (mockups)

Validated in session 2026-05-18. Apply to all future BLC HTML mockups.

**Typography:**
- Headings / hero titles: `'Russo One', sans-serif` (Google Font) — gives the gaming/esports feel
- Body / UI: existing Montserrat stack from `index_files/css2.css`

**Color tokens:**
- Cyan accent: `#00e5ff` (neon glow, CTAs, highlights)
- Gold accent: `#ffc53a` (badges, deposit button, live drop values, rarity glow)
- Surface: semi-transparent dark `rgba(10,14,23,0.85)` with `backdrop-filter: blur(12px)`

**Hero:**
- Minimum height: 420px (240px is insufficient for visual impact)
- Layout: two-column grid — content left (min 380px), weapon art right
- Weapon art: one primary (large, floating `weapon-float` keyframe) + one secondary (smaller, offset)
- CRT scanlines overlay: `repeating-linear-gradient(0deg, rgba(0,0,0,0) 0px, rgba(0,0,0,0) 2px, rgba(0,0,0,0.04) 2px, rgba(0,0,0,0.04) 4px)`
- Pulsing deposit badge: `badge-pulse` keyframe, 96px circle, top-right corner of hero

**Trust signals (approved copy):** "Provably Fair" | "Instant Withdrawal" | "From $0.06" — use these three as inline pills inside the hero below the CTAs.

**Glassmorphism header:**
```css
backdrop-filter: blur(12px);
box-shadow: inset 0 1px 0 rgba(255,255,255,0.04), 0 4px 20px rgba(0,0,0,0.3);
```

**Header accent strip:**
```css
.page-header::before {
  height: 2px;
  background: linear-gradient(90deg, transparent 0%, var(--cyan) 30%, var(--gold) 60%, var(--cyan) 80%, transparent 100%);
}
```

**Deposit bonus copy:** always "DEPOSIT +25%" — the first-deposit bonus is 25%, not 15%.

## MY RULES  <!-- you own this section -->
- **ADHD-oriented response style:** Be concise, direct, and factual. Lead with the
  key point or next action. Use short sections or bullets. Avoid repetition, filler,
  softening, unnecessary context, and extra options unless explicitly asked.
