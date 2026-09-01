# Plugins & MCP — when to use (reference)
<!-- No paths: this loads every session but it's short. Move to docs/ if CLAUDE.md gets tight. -->

A **plugin** is a one-command install that bundles ready-made skills + agents +
hooks + MCP servers — like installing an app. A plugin is a *delivery method*, not
a separate feature: it gives you the same kinds of things we build by hand. The
official marketplace (`claude-plugins-official`) is built in — nothing to connect.

## When to reach for a plugin (in order)
1. Do we already have a skill/agent/hook for this? → use it, install nothing.
2. Is there an **official** plugin that fits a real, repeated need? → consider it.
   Useful official ones: `code-review`, `security-guidance`, `feature-dev`,
   `frontend-design`; partner: GitHub, Vercel, Supabase, Figma, Linear, Sentry.
3. Only a non-official source has it? → default to NO unless I explicitly approve.

## How (ask Claude to do it, or run it)
- Browse: `/plugin` → Discover tab.
- Install official: `/plugin install <name>@claude-plugins-official`.
- Scope: pick **local** (this repo only) unless I want it everywhere.

## Safety (important — read before installing)
- Plugins can run arbitrary code on the machine with your privileges. Install ONLY
  from sources we trust — for us that means the official Anthropic marketplace.
- Never add a third-party marketplace or a random GitHub plugin without my explicit
  approval. Treat it like installing an unknown app.
- A plugin is not a shortcut around quality: it still goes through the same verify
  step. Don't install a heavy plugin just for one small function — prefer a small
  local skill.

Rule of thumb: simplest thing that works. A plugin is worth it only when it saves
real, repeated effort and comes from a trusted source.
