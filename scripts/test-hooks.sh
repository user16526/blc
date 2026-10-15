#!/usr/bin/env bash
# Hermetic test harness for the template's hooks/scripts.
#   bash scripts/test-hooks.sh        (run from the project root)
# It builds a throwaway sandbox (mktemp -d) and exercises each hook's LOGIC there, so it
# NEVER touches your real AGENTS.md / CLAUDE.md, .claude/core.sha, or git repo.
# Exit 0 = all green. Exit 1 = at least one failure (see the ✗ lines).
set -uo pipefail

ROOT="$(pwd)"
SCRIPTS="$ROOT/scripts"
pass=0; fail=0
ok(){ echo "  ✓ $1"; pass=$((pass+1)); }
no(){ echo "  ✗ $1"; fail=$((fail+1)); }

# ── temp containment (v8.3.27, BACKLOG #11) ──
# Everything the suite creates lands UNDER one directory in the real temp folder, and the
# suite's last assertions are that this directory is gone and the real temp folder holds
# nothing new. A run left unreadable directories in a Windows %TEMP% (2026-09-07), and a
# suite that cannot clean up after itself is not hermetic. Every nested mktemp (sandbox,
# stubs, the gate's step logs, the sheriff scratch) honours TMPDIR, so it lands here — as
# a SIBLING of the sandbox, never inside it: the sheriff wrapper refuses a scratch inside
# the repo root. Cleanup clears read-only bits first (git objects are read-only).
REAL_TMP="${TMPDIR:-/tmp}"
tmp_snapshot(){ ls -A "$REAL_TMP" 2>/dev/null | grep -E '^(tmp\.|qg\.|th\.)' | sort; }
TMP_BEFORE="$(tmp_snapshot)"
TH_TMP="$(mktemp -d "$REAL_TMP/th.XXXXXX")" || { echo "cannot create a temp dir in $REAL_TMP"; exit 1; }
# TMP and TEMP too (v8.3.31, #95): native Windows tools read only those, never TMPDIR.
export TMPDIR="$TH_TMP" TMP="$TH_TMP" TEMP="$TH_TMP"
th_cleanup(){ cd "$ROOT" 2>/dev/null || cd /; chmod -R u+w "$TH_TMP" 2>/dev/null; rm -rf "$TH_TMP"; }

# ── 0. scripts present AND executable ──
# Direct guard against the defect that broke v8.1.3: an archive shipped without the Unix
# execute bit, so every hook silently no-op'd after extraction. This catches that.
echo "── 0. scripts present & executable ──"
for s in guard.sh state-freshness.sh check-core.sh check-claude-md-size.sh core-baseline.sh \
         quality-gate.sh precompact-snapshot.sh install-git-hooks.sh pre-commit test-hooks.sh \
         sheriff-review.sh; do
  if [ ! -f "$SCRIPTS/$s" ]; then no "$s missing"; continue; fi
  [ -x "$SCRIPTS/$s" ] && ok "$s executable" || no "$s NOT executable (run: bash setup.sh)"
done
bash -n "$SCRIPTS/integration/sheriff-isolation-live.sh" && ok "sheriff-isolation-live.sh syntax (manual canary, not run here)" \
                                             || no "sheriff-isolation-live.sh syntax"
# watch-transition.sh is project machinery, not Context Guard; its syntax check used
# to ride along in the Context Guard suite, which broke the moment the two releases
# were split apart. It belongs here, with the rest of the project scripts.
bash -n "$SCRIPTS/watch-transition.sh" && ok "watch-transition.sh syntax" \
                                       || no "watch-transition.sh syntax"

SANDBOX="$(mktemp -d)"
trap th_cleanup EXIT
cp -r "$SCRIPTS" "$SANDBOX/scripts"
cd "$SANDBOX" || { echo "cannot enter sandbox"; exit 1; }

# ── 1. guard.sh (PreToolUse) ──
echo "── 1. guard.sh ──"
g(){ printf '%s' "$1" | bash scripts/guard.sh >/dev/null 2>&1; echo $?; }
[ "$(g '{"tool_name":"Write","content":"key=sk-abcdefghijklmnop1234567890"}')" = "2" ] \
  && ok "blocks a hardcoded secret (any tool)" || no "did NOT block a secret"
[ "$(g '{"tool_name":"Bash","command":"rm -rf /tmp/x"}')" = "2" ] \
  && ok "blocks rm -rf in a Bash command" || no "did NOT block rm -rf"
[ "$(g '{"tool_name":"Write","content":"hello world, just prose"}')" = "0" ] \
  && ok "allows a benign write" || no "false-blocked a benign write"
# The v8.1.x over-broad-guard bug: a DOC that merely MENTIONS rm -rf must not be blocked.
[ "$(g '{"tool_name":"Write","content":"The command rm -rf is dangerous; never run it."}')" = "0" ] \
  && ok "does NOT false-block a doc mentioning rm -rf" || no "false-blocked a doc (over-broad guard regressed)"
[ "$(g '{"tool_name":"Bash","command":"git add .env"}')" = "2" ] \
  && ok "blocks staging a real .env" || no "did NOT block staging .env"
[ "$(g '{"tool_name":"Bash","command":"git add .env.example"}')" = "0" ] \
  && ok "allows staging .env.example" || no "false-blocked .env.example"
# Adversarial: MODERN credential families (the v8.1.9 regex missed all of these).
[ "$(g '{"tool_name":"Write","content":"OPENAI_API_KEY=sk-proj-AbCd1234EfGh5678IjKl9012MnOp3456"}')" = "2" ] \
  && ok "blocks sk-proj- (modern OpenAI)" || no "MISSED sk-proj- key"
[ "$(g '{"tool_name":"Write","content":"key=sk-ant-api03-AbCd1234EfGh5678IjKl9012MnOp"}')" = "2" ] \
  && ok "blocks sk-ant- (Anthropic)" || no "MISSED sk-ant- key"
[ "$(g '{"tool_name":"Write","content":"token=ghp_AbCdEfGh1234567890AbCdEfGh12345678"}')" = "2" ] \
  && ok "blocks ghp_ (GitHub)" || no "MISSED ghp_ token"
[ "$(g '{"tool_name":"Write","content":"t=github_pat_11AAAA0abcdefghijklmnopqrstuvwx"}')" = "2" ] \
  && ok "blocks github_pat_" || no "MISSED github_pat_"
[ "$(g '{"tool_name":"Write","content":"slack=xoxb-1234567890-1234567890123-AbCdEfGhIjKl"}')" = "2" ] \
  && ok "blocks xoxb- (Slack)" || no "MISSED xoxb- token"
[ "$(g '{"tool_name":"Write","content":"see https://github.com/openai/gpt-4 and tokens like ghp_ (redacted)"}')" = "0" ] \
  && ok "does NOT false-block prose mentioning token prefixes" || no "false-blocked prose"
# -- 1b. CASE SENSITIVITY (v8.3.24) --
# The block list is two greps now, and the split is load-bearing: in a UNIX flag the
# case IS the meaning, so folding it blocked the SAFE sibling of a dangerous command.
# A guard that blocks safe commands does not make people careful, it makes them reword
# until it stops recognising them -- which is how a guard stops being one.
[ "$(g '{"tool_name":"Bash","command":"git branch -D feature/x"}')" = "2" ] \
  && ok "blocks force-delete of a branch (upper-case flag destroys unmerged work)" \
  || no "did NOT block a force branch delete"
[ "$(g '{"tool_name":"Bash","command":"git branch -d feature/x"}')" = "0" ] \
  && ok "ALLOWS the safe merged-branch delete (lower-case flag refuses unmerged)" \
  || no "false-blocked the safe branch delete (case fold regressed)"
[ "$(g '{"tool_name":"Bash","command":"git branch --delete --force feature/x"}')" = "2" ] \
  && ok "blocks the long-form force delete too" || no "long-form force delete slipped through"
# Cross-vendor review, round 2: delete-plus-force also has a short CLUSTER spelling and
# a short-plus-long spelling. Both force-delete an unmerged branch. The old case-folded
# pattern caught them BY ACCIDENT (folding made it match their lower-case d), so the
# first cut of the split silently un-blocked them. They are named explicitly now.
for spelling in \
  "git branch -df feature/x" \
  "git branch -fd feature/x" \
  "git branch -drf origin/topic" \
  "git branch -d --force feature/x" \
  "git branch --force -d feature/x" \
  "git branch --delete --force feature/x" \
  "git branch --force --delete feature/x" \
  "git branch -d -f feature/x" \
  "git branch -f -d feature/x" \
  "git branch --delete -f feature/x" \
  "git branch -f --delete feature/x" \
  "git branch -r -D origin/topic" \
  "git branch -Dq feature/x" \
  "git branch --delete --forc feature/x" \
  "git branch --delete --for feature/x" \
  "git branch -D feature/x"; do
  [ "$(g "{\"tool_name\":\"Bash\",\"command\":\"$spelling\"}")" = "2" ] \
    && ok "blocks force-delete spelling: $spelling" \
    || no "force-delete spelling ESCAPED the guard: $spelling"
done
# ...and none of that may cost the safe delete, which is the whole reason for the change.
for safe in \
  "git branch -d feature/x" \
  "git branch -d fix/typo" \
  "git branch -d topic/fix" \
  "git branch -rd origin/merged" \
  "git branch -d --quiet feature/x" \
  "git branch --delete feature/x" \
  "git branch --list" \
  "git branch --format=%(refname)" \
  "git branch -a"; do
  [ "$(g "{\"tool_name\":\"Bash\",\"command\":\"$safe\"}")" = "0" ] \
    && ok "allows safe branch command: $safe" \
    || no "FALSE-BLOCKED a safe branch command: $safe"
done
[ "$(g '{"tool_name":"Bash","command":"iptables -F"}')" = "2" ] \
  && ok "blocks the iptables flush (upper-case F drops every rule)" || no "did NOT block an iptables flush"
[ "$(g '{"tool_name":"Bash","command":"iptables -f -L INPUT"}')" = "0" ] \
  && ok "allows the iptables fragment flag (lower-case f is harmless)" || no "false-blocked a harmless iptables flag"
[ "$(g '{"tool_name":"Bash","command":"git clean -xdf"}')" = "2" ] \
  && ok "blocks a force git clean inside a mixed flag cluster" || no "git clean force slipped through"
[ "$(g '{"tool_name":"Bash","command":"git clean -n"}')" = "0" ] \
  && ok "allows a git clean dry run" || no "false-blocked a git clean dry run"
# The raw disk-copy command is a two-letter LOWER-CASE name. Folding its case made the
# upper-case day field of an ISO date template match it, so writing a dated document
# through a heredoc was refused as destructive. Found while authoring this release.
[ "$(g '{"tool_name":"Bash","command":"cat > report.md <<EOF ; # run at {YYYY-MM-DD HH:MM}"}')" = "0" ] \
  && ok "does NOT false-block a doc carrying an ISO date placeholder" \
  || no "false-blocked an ISO date placeholder (disk-copy case fold regressed)"
[ "$(g '{"tool_name":"Bash","command":"dd if=/dev/zero of=/dev/sdb bs=1M"}')" = "2" ] \
  && ok "still blocks the raw disk-copy command itself" || no "MISSED the raw disk-copy command"
# NEGATIVE CONTROLS for the split. Moving the WHOLE list to a case-sensitive grep
# would silently un-block these, which is a far worse bug than the one being fixed:
# the recursive-remove flag has a valid upper-case spelling, and SQL is conventionally
# written lower-case. These four must stay blocked no matter how the split is edited.
[ "$(g '{"tool_name":"Bash","command":"rm -Rf /tmp/x"}')" = "2" ] \
  && ok "still blocks recursive remove with the upper-case flag spelling" || no "rm -Rf slipped through (the split went too far)"
[ "$(g '{"tool_name":"Bash","command":"psql -c \"drop database prod\""}')" = "2" ] \
  && ok "still blocks lower-case SQL drop database" || no "lower-case drop database slipped through"
[ "$(g '{"tool_name":"Bash","command":"psql -c \"truncate table users\""}')" = "2" ] \
  && ok "still blocks lower-case SQL truncate" || no "lower-case truncate slipped through"
[ "$(g '{"tool_name":"Bash","command":"git reset --HARD origin/main"}')" = "2" ] \
  && ok "still blocks a shouted git reset --hard" || no "upper-case git reset --hard slipped through"
# An ordinary word ending in the disk-copy command's two letters must not match it.
[ "$(g '{"tool_name":"Bash","command":"git commit -m \"Add support for retries\""}')" = "0" ] \
  && ok "does NOT false-block a word ending in those two letters" || no "false-blocked an ordinary word (boundary too loose)"
# -- 1c. FORCED PUSH, every spelling and position (v8.3.25) --
# --force-with-lease used to be caught only as a prefix of --force, and only straight
# after `push`; a force flag written after the remote and branch slipped through.
for spelling in \
  "git push --force-with-lease" \
  "git push origin main --force-with-lease=main:abc123" \
  "git push origin feature --force" \
  "git push origin -f" \
  "git push -uf origin main" \
  "git push origin +main" \
  "git -C repo push --force" \
  "git -c push.default=current push -f" \
  "git --no-pager push --force" \
  "git -P push -f" \
  "git --git-dir=.git push origin +main" \
  "git -C 'my repo' push --force" \
  "git -c alias.unused='!echo x;y' push --force" \
  "git -C /tmp/my\\\\ repo push --force" \
  "git --no-pager -C repo push --force-with-lease"; do
  [ "$(g "{\"tool_name\":\"Bash\",\"command\":\"$spelling\"}")" = "2" ] \
    && ok "blocks forced push: $spelling" || no "forced push ESCAPED the guard: $spelling"
done
# v8.3.26: the prefix before `push` is ANY git global option, quoted value included.
[ "$(g '{"tool_name":"Bash","command":"git -C \"my repo\" push -f"}')" = "2" ] \
  && ok "blocks forced push behind a double-quoted -C path" || no "forced push ESCAPED behind a quoted -C path"
for safe in \
  "git push --follow-tags origin main" \
  "git push -u origin feature/fix" \
  "git push origin fix-force-flag" \
  "git --no-pager log --oneline -5" \
  "git -C 'my repo' push origin main" \
  "git -c alias.x='!echo x;y' status && git push origin main" \
  "git --no-pager log --grep push --force" \
  "git add ':!x' src/app.ts" \
  "git --no-pager push -u origin main"; do
  [ "$(g "{\"tool_name\":\"Bash\",\"command\":\"$safe\"}")" = "0" ] \
    && ok "allows ordinary push: $safe" || no "FALSE-BLOCKED an ordinary push: $safe"
done
# -- 1c2. FORCED PUSH from parsed tokens (v8.3.27, #8) --
# Two sheriff rounds on v8.3.26 each found one shell-word shape the text regex missed.
# The tokens are what the shell hands git, so a QUOTED flag is caught now; the text
# rules stay as the backstop and are the whole answer without python3.
for spelling in \
  "git push \\\"--force\\\"" \
  "git push origin '+main'" \
  "git -c x.y=z push \\\"-f\\\" origin main" \
  "git push --force-with-lease=main:abc origin main" \
  "git push -- origin +main" \
  "git push -o ci.skip -f origin main"; do
  [ "$(g "{\"tool_name\":\"Bash\",\"command\":\"$spelling\"}")" = "2" ] \
    && ok "blocks forced push (parsed tokens): $spelling" || no "forced push ESCAPED the parser: $spelling"
done
# --force-if-includes is a SAFETY flag (it refuses a lease that skips fetched commits), not
# a force: the TOKENIZER must not read it as one (corpus false positive, v8.3.27). The text
# backstop is a separate, unchanged answer: `push … --force` has no boundary after `force`,
# so the plain spelling still blocks — as v8.3.26 did (fail-closed; a candidate for v8.3.28).
# `git.exe` is the spelling the text prefix does not match, so it isolates the tokenizer.
[ "$(g '{"tool_name":"Bash","command":"git.exe push --force-if-includes origin main"}')" = "0" ] \
  && ok "tokenizer: push --force-if-includes is not a force (git.exe isolates it from the text backstop)" \
  || no "tokenizer read push --force-if-includes as a force"
[ "$(g '{"tool_name":"Bash","command":"git push --force-if-includes origin main"}')" = "2" ] \
  && ok "text backstop still blocks the plain push --force-if-includes (v8.3.26 answer, unchanged)" \
  || no "the text backstop changed: plain push --force-if-includes no longer blocks"
[ "$(g '{"tool_name":"Bash","command":"git.exe push --force-with-lease --force-if-includes origin main"}')" = "2" ] \
  && ok "blocks --force-with-lease beside --force-if-includes" || no "--force-if-includes hid a lease push"
# -- 1c3. git merge with a message from stdin (v8.3.27, #19) --
# `git merge` reads no message from stdin: the merge dies AFTER the branch switch. Sessions
# typed `-F -` live despite the UPGRADE prose, so it is a guard rule. `git commit -F -`
# stays allowed — commit does read stdin.
for spelling in \
  "git merge -F - feature" \
  "git merge --file - feature" \
  "git merge --file=- feature" \
  "git merge -F- feature" \
  "git -C repo --no-pager merge --no-ff -F - feature" \
  "cd app && git merge -F - feature"; do
  [ "$(g "{\"tool_name\":\"Bash\",\"command\":\"$spelling\"}")" = "2" ] \
    && ok "blocks merge with a stdin message: $spelling" || no "merge -F - ESCAPED the guard: $spelling"
done
for safe in \
  "git merge -m 'merge: feature' feature" \
  "git merge -F msg.txt feature" \
  "git merge --no-ff feature" \
  "git commit -F -" \
  "git commit --file=-" \
  "git log --grep 'merge -F -'"; do
  [ "$(g "{\"tool_name\":\"Bash\",\"command\":\"$safe\"}")" = "0" ] \
    && ok "allows: $safe" || no "FALSE-BLOCKED: $safe"
done
# -- 1d. A COMMIT MESSAGE IS PROSE (v8.3.25) --
# A heredoc message with a QUOTED delimiter is not scanned for command shapes: it blocked
# a commit whose message described an earlier, correctly-blocked .env staging, and the
# only way out was rewording until the guard stopped recognising it. JSON carries the
# newlines as \n escapes, exactly as the real hook input does.
h(){ printf '{"tool_name":"Bash","command":"%s"}' "$1" | bash scripts/guard.sh >/dev/null 2>&1; echo $?; }
[ "$(h $'git commit -m \\"$(cat <<\'EOF\'\\nchore: never git add -A while a .env exists\\nEOF\\n)\\"')" = "0" ] \
  && ok "commit message heredoc may describe a blocked .env staging" || no "commit message prose was scanned as a command (.env)"
[ "$(h $'git commit -F - <<\'EOF\'\\nwhy we refused rm -rf and git push --force\\nEOF')" = "0" ] \
  && ok "commit -F - heredoc may mention destructive commands" || no "commit message prose was scanned as a command (destructive)"
[ "$(h $'git tag -a v1 -F - <<\\"EOF\\"\\nnotes: git reset --hard was blocked\\nEOF')" = "0" ] \
  && ok "tag message heredoc (double-quoted delimiter) is prose too" || no "tag message prose was scanned as a command"
# ...and none of that may open a hole: each of these RUNS the destructive command.
for evil in \
  $'git commit -F - <<EOF\\n$(rm -rf /tmp/x)\\nEOF' \
  $'bash <<\'EOF\'\\nrm -rf /tmp/x\\nEOF' \
  $'git commit -F - <<\'EOF\'\\nmsg\\nEOF\\nrm -rf /tmp/x' \
  $'bash <<\'X\' ; git commit -F - <<\'EOF\'\\nrm -rf /tmp/x\\nX\\nmsg\\nEOF' \
  $'git commit -F - <<<\'x\'\\nrm -rf /tmp/x\\nx' \
  $'git commit $(perl -F - <<\'EOF\'\\nrm -rf /tmp/x\\nEOF\\n)' \
  $'git commit -m \\"$(bash <<\'EOF\'\\nrm -rf /tmp/x\\nEOF\\n)\\"' \
  $'# git commit -F - <<\'EOF\'\\nrm -rf /tmp/x' \
  $'sh -s git commit -F - <<\'EOF\'\\nrm -rf /tmp/x\\nEOF' \
  $'git commit -m \\"$(cat <<\'EOF\' | sh\\nrm -rf /tmp/x\\nEOF\\n)\\"' \
  $'git commit -F - <<\'EOF\'X\\nmsg\\nEOFX\\nrm -rf /tmp/x' \
  $'git commit -F - <<-\'EOF\'\\nmsg\\n\\tEOF\\nrm -rf /tmp/x' \
  $'echo \\"git commit -F - <<\'EOF\'\\\\n\\"; rm -rf /tmp/x' \
  $'git commit -m \\"foo -F - <<\'EOF\'\\nbar\\"; rm -rf /tmp/x\\nEOF' \
  $'git commit # -F - <<\'EOF\'\\nrm -rf /tmp/x\\nEOF' \
  $'git commit -F - <<\'EOF\'\\nmsg\\nEOF\\r\\nrm -rf /tmp/x' \
  $'git branch -v \\\\\\n -D feature' \
  $'git add -v -f \\\\\\n.env' \
  $'git commit -F - <<\'EOF\' && rm -rf /tmp/x\\nmsg\\nEOF'; do
  [ "$(h "$evil")" = "2" ] && ok "still blocks: ${evil%%\\n*}…" || no "heredoc exemption opened a hole: $evil"
done
[ "$(h $'git merge -F - feature <<\'EOF\'\\nmsg\\nEOF')" = "2" ] \
  && ok "merge -F - behind a heredoc is blocked too (the commit/tag exemption does not cover merge, #19)" \
  || no "merge -F - slipped through behind a heredoc"
# -- 1e. .env is a `git add` PATH ARGUMENT, not text (v8.3.26) --
# v8.3.25 fired on any command holding `git add -A` / `git add .` / a dot-path plus ".env"
# anywhere, so a commit message describing the .env blocker was refused with nothing
# staged; and `.env.example` anywhere in the command cleared a real .env beside it.
for evil in \
  "git add .env" \
  "git add -f config/.env.local" \
  "git add .env.example .env" \
  "git add -- .env" \
  "git add -A .env" \
  "git -C repo add .env" \
  "git --no-pager add -f .ENV" \
  "git add .env*" \
  "cd app && git add .env" \
  "git add x; git add -f .env.production" \
  "git add 'config/.env'" \
  "git add \\\".env\\\"" \
  "git add \$(echo .env)" \
  "git add docs/a.md 'config\\\\.env'"; do
  # (Quoted on purpose: unquoted, bash itself drops the backslash — `config\.env` IS
  # `config.env` — so only the quoted form hands git a Windows-style path to .env.)
  [ "$(g "{\"tool_name\":\"Bash\",\"command\":\"$evil\"}")" = "2" ] \
    && ok "blocks staging a real .env: $evil" || no ".env staging ESCAPED the guard: $evil"
done
for safe in \
  "git add README.md && git commit -m 'describe the .env blocker'" \
  "git add .claude/rules/x.md && git commit -m 'guard: the template .env/secret blocker'" \
  "git add -A && git commit -m 'never stage .env'" \
  "git add .env.example" \
  "git add .env.example docs/env-setup.md" \
  "git commit -m 'mention .env in prose'"; do
  [ "$(g "{\"tool_name\":\"Bash\",\"command\":\"$safe\"}")" = "0" ] \
    && ok "allows (no real .env staged): $safe" || no "FALSE-BLOCKED, no .env was staged: $safe"
done
# Security review, round 1 (v8.3.26): shell syntax a regex segmenter missed, plus spellings
# every earlier version missed. Each of these really stages .env in git.
for evil in \
  "git add {README.md,.env}" \
  "git add -f {README.md,.env}" \
  "git add -f ':(top).env'" \
  "git add -f ':(literal).env'" \
  "git add -f ':!x;y' .env" \
  "git add -f \$':!a\\\\nb' .env" \
  "git add -f .en[v]" \
  "git add -f \$'.env'" \
  "git add -f '.e?v'" \
  "git add -f .{env,x}" \
  "git stage -f .env" \
  "git.exe add -f .env" \
  "git  add .env" \
  "git -C my\\\\ repo add .env" \
  "git add -f ." \
  "git add -f -A" \
  "git add --force --all" \
  "git add -f ././" \
  "git add -f config/ # .env" \
  "f=.env; git add -f config/" \
  "git add -f :!x" \
  "git add -f ':(exclude)x'" \
  "git add -f ':^x' ':!y'" \
  "git add --force config/ && git commit -m 'mention .env'" \
  "git add -- .\\ngit add -f ." \
  "f=.env; git add -f \\\"\$f\\\"" \
  "git add \\\".env"; do
  [ "$(g "{\"tool_name\":\"Bash\",\"command\":\"$evil\"}")" = "2" ] \
    && ok "blocks (shell syntax): $evil" || no ".env staging ESCAPED via shell syntax: $evil"
done
[ "$(h $'git commit -F - <<\'EOF\'\\nmsg\\nEOF\\ngit add -f {a,.env}')" = "2" ] \
  && ok "blocks a brace-list .env after a quoted-heredoc commit message" \
  || no "brace-list .env ESCAPED on the heredoc-exempt path"
for safe in \
  "git add -f config/.env.example" \
  "git add src/app.env.ts" \
  "git add '*.md'" \
  "git add -f dist/app.js" \
  "git add \\\"\$FILE\\\"" \
  "git add -A" \
  "git add ."; do
  [ "$(g "{\"tool_name\":\"Bash\",\"command\":\"$safe\"}")" = "0" ] \
    && ok "allows: $safe" || no "FALSE-BLOCKED: $safe"
done
# A quoted -C value followed by a bare suffix must still count as a global option.
[ "$(g '{"tool_name":"Bash","command":"git -C '"'"'/d/my'"'"'/repo push --force"}')" = "2" ] \
  && ok "blocks forced push behind a quoted-then-bare -C path" || no "forced push ESCAPED behind '/d/my'/repo"
[ "$(h $'git commit -F - <<\'EOF\'\\nm\\nEOF\\ngit -C \'/d/my\'/repo push --force')" = "2" ] \
  && ok "…and on the decoded (heredoc-exempt) path" || no "forced push ESCAPED on the decoded path"
# No usable python3 (missing, or a Windows Store stub): the text fallback must still see a
# real .env beside .env.example — v8.3.25's fallback let that pair through.
STUBPY="$(mktemp -d)"; printf '#!/bin/sh\nexit 1\n' > "$STUBPY/python3"; chmod +x "$STUBPY/python3"
gs(){ printf '%s' "$1" | PATH="$STUBPY:$PATH" bash scripts/guard.sh >/dev/null 2>&1; echo $?; }
[ "$(gs '{"tool_name":"Bash","command":"git add -f .env.example .env"}')" = "2" ] \
  && ok "broken python3: fallback still blocks .env beside .env.example" \
  || no "broken python3: fallback let .env through beside .env.example"
[ "$(gs '{"tool_name":"Bash","command":"git add .env.example"}')" = "0" ] \
  && ok "broken python3: fallback still allows .env.example alone" || no "broken python3: fallback false-blocked .env.example"
for evil in "git add -f ." "git add -f .env.production" "git stage -f -A" "git -C . add -f .env" "git add -f :!x"; do
  [ "$(gs "{\"tool_name\":\"Bash\",\"command\":\"$evil\"}")" = "2" ] \
    && ok "broken python3: fallback blocks $evil" || no "broken python3: fallback let through $evil"
done
for safe in "git add -f dist/app.js" "git add -A"; do
  [ "$(gs "{\"tool_name\":\"Bash\",\"command\":\"$safe\"}")" = "0" ] \
    && ok "broken python3: fallback allows $safe" || no "broken python3: fallback false-blocked $safe"
done
[ "$(gs '{"tool_name":"Bash","command":"git merge -F - feature"}')" = "2" ] \
  && ok "broken python3: text rule still blocks merge -F -" || no "broken python3: merge -F - let through"
[ "$(gs '{"tool_name":"Bash","command":"git merge -m msg feature"}')" = "0" ] \
  && ok "broken python3: text rule allows merge -m" || no "broken python3: false-blocked merge -m"
find "$STUBPY" -mindepth 0 -delete 2>/dev/null

# -- 1f. The PowerShell tool is inspected too (v8.3.27, #7a) --
# Until v8.3.26 only "tool_name":"Bash" got the command checks, so on a Windows host a
# PowerShell tool call could stage .env or force-push past the guard. Same git rules for
# both shells; a PowerShell-native destructive list only for the PowerShell tool.
ps(){ printf '{"tool_name":"PowerShell","tool_input":{"command":"%s"}}' "$1" | bash scripts/guard.sh >/dev/null 2>&1; echo $?; }
for evil in \
  "git add .env" \
  "git push --force" \
  "git push origin +main" \
  "git merge -F - feature" \
  "git branch -D feature" \
  "git reset --hard" \
  "Remove-Item -Recurse -Force .\\\\build" \
  "Remove-Item .\\\\build -Force -Recurse" \
  "rm -r -fo build" \
  "ri -Rec -Fo build" \
  "del -Recurse -Force build; git status" \
  "Remove-Item -Recurse:\$true -Force build" \
  "Get-ChildItem | Remove-Item -Force -Recurse" \
  "Get-ChildItem -Recurse | Remove-Item -Force" \
  "gci -r | ri -fo" \
  "Remove-Item –Recurse –Force build" \
  "Write-Host x\\nRemove-Item -Recurse -Force build" \
  "\\nRemove-Item -Recurse -Force build" \
  "Write-Host x\\r\\nRemove-Item -Recurse -Force build" \
  "Write-Host x\\tRemove-Item -Recurse -Force build" \
  "rd /s /q C:\\\\build" \
  "cmd /c del /f /s /q C:\\\\build\\\\*" \
  "Format-Volume -DriveLetter D" \
  "Clear-Disk -Number 1" \
  "Remove-Item C:\\\\work -Re -Fo" \
  "Remove-Item -Fo -Re C:\\\\work" \
  "Remove-Item 'C:\\\\R&D\\\\project' -Recurse -Force" \
  "Remove-Item \\\"C:\\\\a;b|c\\\" -Recurse -Force" \
  "Get-ChildItem 'C:\\\\R&D' -Recurse | Remove-Item -Force" \
  "rd /s /q 'C:\\\\R&D'"; do
  [ "$(ps "$evil")" = "2" ] && ok "PowerShell: blocks $evil" || no "PowerShell: let through $evil"
done
# A payload naming both tools gets MORE rules, never fewer (security review F3).
[ "$(g '{"tool_name":"PowerShell","tool_input":{"tool_name":"Bash","command":"Remove-Item -Recurse -Force build"}}')" = "2" ] \
  && ok "PowerShell: a nested Bash tool_name key does not switch the PS list off" \
  || no "PowerShell: a nested tool_name key disabled the PS list"
for safe in \
  "git status" \
  "git push origin main" \
  "git add .env.example" \
  "git merge -m msg feature" \
  "Remove-Item -Recurse .\\\\build" \
  "Remove-Item -Force notes.txt" \
  "Remove-Item -Filter *.log -Recurse .\\\\logs" \
  "Get-ChildItem -Recurse -Force" \
  "Get-ChildItem -Recurse | Select-Object Name" \
  "Remove-Item -Recurse .\\\\build\\nGet-ChildItem -Force" \
  "Remove-Item -Recurse 'a;b'; Get-ChildItem -Force" \
  "Get-ChildItem -Recurse 'x|y' | Select-Object Name; Remove-Item -Force notes.txt" \
  "Get-ChildItem -Recurse | Select-Object Name\\nRemove-Item -Force notes.txt" \
  "Get-Help Remove-Item -Full\\nGet-ChildItem -Recurse -Force" \
  "npm test"; do
  [ "$(ps "$safe")" = "0" ] && ok "PowerShell: allows $safe" || no "PowerShell: FALSE-BLOCKED $safe"
done
# (re-check) a newline is a SEPARATOR, so two safe lines never fuse; a JSON-escaped dash
# and a single-quoted cmdlet name are decoded / anchored too.
[ "$(ps 'Remove-Item \u2013Recurse \u2013Force build')" = "2" ] \
  && ok "PowerShell: a \\u2013-escaped en dash is decoded before the match" || no "PowerShell: \\u2013 dash escaped the rule"
# (re-check 3) a backtick before the newline is a line CONTINUATION, not a separator.
[ "$(ps 'Remove-Item -Recurse `\n -Force build')" = "2" ] \
  && ok "PowerShell: a backtick line continuation does not sever the pair" || no "PowerShell: backtick continuation severed the rule"
[ "$(ps 'Remove-Item -Recurse `\r\n -Force build')" = "2" ] \
  && ok "PowerShell: a backtick CRLF continuation does not sever the pair" || no "PowerShell: backtick CRLF continuation severed the rule"
[ "$(ps "&'Remove-Item' -Recurse -Force build")" = "2" ] \
  && ok "PowerShell: a single-quoted cmdlet name is anchored too" || no "PowerShell: &'Remove-Item' escaped the rule"
[ "$(g '{"tool_name": "PowerShell", "tool_input": {"command": "Remove-Item -Recurse -Force build"}}')" = "2" ] \
  && ok "PowerShell: tool name matched with a space after the colon too" || no "PowerShell: spaced JSON form not recognised"
[ "$(g '{"tool_name":"Bash","command":"Remove-Item -Recurse -Force build"}')" = "0" ] \
  && ok "the PowerShell-native list does not apply to the Bash tool" || no "PowerShell-native list leaked onto Bash"

# ── 2. check-claude-md-size.sh (PostToolUse) ──
echo "── 2. check-claude-md-size.sh ──"
seq 1 251 > AGENTS.md
bash scripts/check-claude-md-size.sh >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && ok "flags >250 lines (exit 2)" || no "did NOT flag 251 lines (rc=$rc)"
seq 1 100 > AGENTS.md
bash scripts/check-claude-md-size.sh >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && ok "passes a 100-line file" || no "false-flagged a 100-line file (rc=$rc)"

# ── 3. check-core.sh + core-baseline.sh ──
echo "── 3. check-core.sh + core-baseline.sh ──"
mkdir -p .claude
cat > AGENTS.md <<'EOF'
# test kernel
<!-- CORE:START -->
rule one
rule two
<!-- CORE:END -->
non-core tail
EOF
bash scripts/core-baseline.sh >/dev/null 2>&1
[ -f .claude/core.sha ] && ok "core-baseline writes .claude/core.sha" || no "core-baseline did not write a baseline"
bash scripts/check-core.sh >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && ok "matching CORE passes" || no "matching CORE failed (rc=$rc)"
sed -i 's/rule two/rule two CHANGED/' AGENTS.md
bash scripts/check-core.sh >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && ok "tampered CORE → STOP (exit 2)" || no "tampered CORE not caught (rc=$rc)"
# A non-CORE edit (below CORE:END) must NOT trip the gate.
cat > AGENTS.md <<'EOF'
# test kernel
<!-- CORE:START -->
rule one
rule two
<!-- CORE:END -->
non-core tail EDITED FREELY
EOF
bash scripts/check-core.sh >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && ok "non-CORE edit does NOT trip the gate" || no "non-CORE edit wrongly tripped the gate (rc=$rc)"
# -- 3b. core-baseline.sh argument handling (v8.3.24) --
# This script used to parse nothing and re-baseline unconditionally, so EVERY argument
# was silently ignored. A session ran it with --check expecting a dry run and it
# rewrote the baseline instead, over an unapproved kernel edit. The hash then matched,
# check-core went green, and the protection was gone with no error anywhere. A flag
# that is ignored is worse than one that does not exist: it reads as a promise.
cp .claude/core.sha .claude/core.sha.keep
cp AGENTS.md AGENTS.md.keep
# "Compare only, never write" has to include "never CREATE": with no baseline on disk,
# --check must report that and leave the directory as it found it.
mv .claude/core.sha .claude/core.sha.away
bash scripts/core-baseline.sh --check >/dev/null 2>&1; rc=$?
[ "$rc" -ne 0 ] && ok "--check with no baseline reports failure" || no "--check passed with no baseline at all"
[ ! -f .claude/core.sha ] && ok "--check did NOT create a baseline out of thin air" || no "--check CREATED a baseline"
mv .claude/core.sha.away .claude/core.sha
bash scripts/core-baseline.sh --check >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && ok "--check passes on a matching CORE" || no "--check failed on a matching CORE (rc=$rc)"
sed -i 's/rule one/rule one MOVED/' AGENTS.md
bash scripts/core-baseline.sh --check >/dev/null 2>&1; rc=$?
[ "$rc" -eq 1 ] && ok "--check reports a changed CORE (exit 1)" || no "--check did not report a changed CORE (rc=$rc)"
cmp -s .claude/core.sha .claude/core.sha.keep \
  && ok "--check did NOT rewrite the baseline (the whole point of the flag)" \
  || no "--check REWROTE the baseline (the v8.3.23 defect regressed)"
bash scripts/core-baseline.sh --dry-run >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && ok "an unknown argument is fatal (exit 2)" || no "an unknown argument was ignored (rc=$rc)"
cmp -s .claude/core.sha .claude/core.sha.keep \
  && ok "an unknown argument did NOT rewrite the baseline" || no "an unknown argument REWROTE the baseline"
bash scripts/core-baseline.sh >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && ok "a bare run still re-baselines (the approved-change path)" || no "a bare run stopped working (rc=$rc)"
mv AGENTS.md.keep AGENTS.md
mv .claude/core.sha.keep .claude/core.sha

# -- 3c. the CLAUDE.md stub (v8.3.28, #42) --
# The kernel is AGENTS.md; Claude Code reaches it only through the one-line import in
# CLAUDE.md (its own AGENTS.md fallback never fires below a directory with a CLAUDE.md).
# A stub that lost the import is a session with no kernel: SessionStart must say so.
printf '<!-- stub -->\n@AGENTS.md\n' > CLAUDE.md
sf="$(printf '{"source":"startup"}' | bash scripts/state-freshness.sh 2>&1)"
echo "$sf" | grep -q "did NOT load the project kernel" \
  && no "#42: state-freshness warned although CLAUDE.md imports AGENTS.md" \
  || ok "#42: state-freshness is quiet when CLAUDE.md imports AGENTS.md"
printf '# a rewritten CLAUDE.md with no import\n' > CLAUDE.md
sf="$(printf '{"source":"startup"}' | bash scripts/state-freshness.sh 2>&1)"
echo "$sf" | grep -q "did NOT load the project kernel" \
  && ok "#42: state-freshness warns when CLAUDE.md lost the @AGENTS.md import" \
  || no "#42: a CLAUDE.md without the import went unnoticed at SessionStart"
printf '<!-- stub -->\n@AGENTS.md\n' > CLAUDE.md

# ── 4. precompact-snapshot.sh (PreCompact) ──
echo "── 4. precompact-snapshot.sh ──"
mkdir -p .agent/state
printf '# Current State\nLast updated: 2026-01-01\n## Now working on\n- the-sentinel-task\n' > .agent/state/current.md
printf '# Open loops\n- the-sentinel-loop\n' > .agent/state/open-loops.md
printf '%s' '{"session_id":"abc","transcript_path":"/tmp/sentinel.jsonl","source":"auto"}' \
  | bash scripts/precompact-snapshot.sh >/dev/null 2>&1
if [ -f .agent/state/handoff.md ] \
   && grep -q "the-sentinel-task" .agent/state/handoff.md \
   && grep -q "/tmp/sentinel.jsonl" .agent/state/handoff.md; then
  ok "writes handoff.md with current state + transcript path"
else
  no "handoff.md missing or incomplete"
fi

# ── 5. state-freshness.sh resume-surfacing (SessionStart) ──
echo "── 5. state-freshness.sh resume-surfacing ──"
out_c="$(printf '%s' '{"source":"compact"}' | bash scripts/state-freshness.sh 2>/dev/null)"
echo "$out_c" | grep -q "Restoring working state" && ok "surfaces handoff on source=compact" \
  || no "did NOT surface handoff on compact"
out_s="$(printf '%s' '{"source":"startup"}' | bash scripts/state-freshness.sh 2>/dev/null)"
if echo "$out_s" | grep -q "state-freshness" && ! echo "$out_s" | grep -q "Restoring working state"; then
  ok "normal startup: freshness only, no handoff"
else
  no "startup behavior wrong (handoff surfaced when it shouldn't be)"
fi

# ── 6. pre-commit (git hook) ──
echo "── 6. pre-commit ──"
git init -q . 2>/dev/null
git config user.email t@t.t 2>/dev/null; git config user.name t 2>/dev/null
cp scripts/pre-commit .git/hooks/pre-commit 2>/dev/null; chmod +x .git/hooks/pre-commit 2>/dev/null
echo "SECRET=value" > .env; git add -f .env 2>/dev/null
if git commit -qm "should be blocked" >/dev/null 2>&1; then
  no "pre-commit let a real .env through"
else
  ok "pre-commit blocks a real .env"
fi
git rm -q --cached .env >/dev/null 2>&1; rm -f .env
echo "hello" > ok.txt; git add ok.txt 2>/dev/null
if git commit -qm "clean commit" >/dev/null 2>&1; then
  ok "pre-commit allows a clean commit"
else
  no "pre-commit blocked a clean commit"
fi
# Field project C finding D1 (2026-09-01): the suite carries synthetic secrets as negative
# controls, so a project's FIRST commit — which stages this very file — must
# not be blocked by the secret scan. And the exclusion must stay NARROW.
git add -f scripts/test-hooks.sh 2>/dev/null
if git commit -qm "first commit incl. the suite" >/dev/null 2>&1; then
  ok "pre-commit allows committing test-hooks.sh (synthetic secrets are negative controls)"
else
  no "D1 regressed: the suite's own synthetic secrets block the first commit"
fi
printf 'key = "sk-%s"\n' "0123456789abcdefghijklmnop" > leak.py; git add leak.py 2>/dev/null
if git commit -qm "should be blocked" >/dev/null 2>&1; then
  no "D1 exclusion is NOT narrow: a synthetic secret outside the suite slipped through"
else
  ok "the D1 exclusion is narrow: a secret in any OTHER file still blocks"
fi
git rm -q --cached leak.py >/dev/null 2>&1; rm -f leak.py
# Field project C finding D2 (2026-09-01): a report written exactly to the shipped template
# (verdict on the line AFTER "## Verdict") must yield a parsable verdict.
printf '## Verdict\nGREEN ✅\n## Inputs\nx\n## Findings\nx\n## Artifacts\nx\n' > d2-report.md
rv=$(awk 'f{print; exit} tolower($0)~/verdict/{print; f=1}' d2-report.md | grep -oEi 'GREEN|YELLOW|RED' | head -1)
[ "$rv" = "GREEN" ] && ok "verdict parses from the line after the header (gate's own extraction)" \
                    || no "D2 regressed: template-style report has no parsable verdict"
rm -f d2-report.md
# v8.3.27: the Verdict HEADING wins over an earlier prose line that mentions a verdict.
printf '# Run 004\nRe-run after the earlier RED verdict of run 003.\n## Verdict\nGREEN ✅\n## Inputs\nx\n' > d2-report.md
rv=$(awk 'tolower($0) ~ /^#+[ \t]*verdict/ {print; getline; print; exit}' d2-report.md | grep -oEi 'GREEN|YELLOW|RED' | head -1)
[ "$rv" = "GREEN" ] && ok "the Verdict heading wins over a summary line mentioning an earlier RED verdict" \
                    || no "verdict read from a prose line above the heading (got '$rv')"
rm -f d2-report.md

# -- 6b. install-git-hooks.sh (v8.3.25) --
# It used to cp into .git/hooks unconditionally. With core.hooksPath set git never runs
# that file, so the .env/secret blocker was silently off; in a worktree (.git is a FILE)
# the script refused to run at all.
ih="$(mktemp -d)"
( cd "$ih" && git init -q . && git config user.email t@t.t && git config user.name t \
  && mkdir scripts && cp "$SANDBOX/scripts/pre-commit" "$SANDBOX/scripts/install-git-hooks.sh" scripts/ ) >/dev/null 2>&1
( cd "$ih" && bash scripts/install-git-hooks.sh ) >/dev/null 2>&1 && [ -x "$ih/.git/hooks/pre-commit" ] \
  && ok "install-git-hooks installs into git's own hooks folder" || no "install-git-hooks did not install the hook"
rm -f "$ih/.git/hooks/pre-commit"; git -C "$ih" config core.hooksPath .githooks
( cd "$ih" && bash scripts/install-git-hooks.sh ) >/dev/null 2>&1; rc=$?
[ "$rc" -eq 1 ] && [ ! -e "$ih/.git/hooks/pre-commit" ] && [ ! -e "$ih/.githooks/pre-commit" ] \
  && ok "refuses (exit 1, writes nothing) when core.hooksPath would shadow the hook" \
  || no "wrote a hook git will never run, or touched the project's own hooks (rc=$rc)"
git -C "$ih" config --unset core.hooksPath
git -C "$ih" commit -q --allow-empty -m init >/dev/null 2>&1 && git -C "$ih" worktree add -q "$ih-wt" >/dev/null 2>&1
( cd "$ih-wt" && mkdir -p scripts && cp "$SANDBOX/scripts/pre-commit" "$SANDBOX/scripts/install-git-hooks.sh" scripts/ \
  && bash scripts/install-git-hooks.sh ) >/dev/null 2>&1 && [ -x "$ih/.git/hooks/pre-commit" ] \
  && ok "works from a worktree (.git is a file), into the shared hooks folder" || no "install-git-hooks fails in a worktree"
printf '#!/bin/sh\necho foreign hook\n' > "$ih/.git/hooks/pre-commit"
( cd "$ih" && bash scripts/install-git-hooks.sh ) >/dev/null 2>&1; rc=$?
[ "$rc" -eq 1 ] && grep -q 'foreign hook' "$ih/.git/hooks/pre-commit" \
  && ok "refuses to overwrite a foreign pre-commit (husky / pre-commit framework)" \
  || no "overwrote a foreign pre-commit hook (rc=$rc)"
printf '#!/usr/bin/env bash\n# Git pre-commit hook: last line of defense. (older copy)\n' > "$ih/.git/hooks/pre-commit"
( cd "$ih" && bash scripts/install-git-hooks.sh ) >/dev/null 2>&1 && cmp -s "$ih/scripts/pre-commit" "$ih/.git/hooks/pre-commit" \
  && ok "replaces its OWN older hook copy" || no "did not update its own older hook copy"
rm -rf "$ih" "$ih-wt"

# ── 7. quality-gate.sh — smoke + ADVERSARIAL (fake proof must NOT pass) ──
echo "── 7. quality-gate.sh ──"
qout="$(bash scripts/quality-gate.sh --trivial 2>&1)"
echo "$qout" | grep -qi "quality gate" && ok "quality-gate runs (--trivial)" || no "quality-gate did not run"
# 7a. RED verdict in the report + empty {} json → gate must BLOCK (the v8.1.9 GREEN-on-RED bug)
mkdir -p _reports/runs
printf 'Verdict: RED\nInputs: x\nFindings: failed\nArtifacts: none\n' > _reports/runs/t_red.md
echo '{}' > _reports/runs/latest.json
if bash scripts/quality-gate.sh >/dev/null 2>&1; then
  no "gate passed a RED report + empty latest.json (GREEN-on-RED regressed)"
else
  ok "gate BLOCKS a RED report + empty latest.json"
fi
# 7b. A well-formed GREEN run bound to HEAD → gate must pass (with checks waived for this non-code sandbox)
# Canonical flow: write report → COMMIT code+report → write latest.json(head_sha=HEAD) → gate.
# Sandbox scaffolding (scripts/, AGENTS.md, CLAUDE.md, .agent/, .claude/) is gitignored here, NOT
# `git add -A`-ed: test-hooks.sh itself contains fake secret literals and the installed
# pre-commit hook would (correctly) refuse to commit it.
printf '%s\n' '/scripts/' '/.agent/' '/.claude/' '/CLAUDE.md' '/AGENTS.md' '/_reports/runs/latest.json' > .gitignore
mkdir -p .claude/agents/_archive && for a in block-executor verifier security-reviewer infra-security-reviewer devops-operator; do printf -- '---\nname: %s\n---\n' "$a" > ".claude/agents/$a.md"; done; printf -- '---\nname: ui-ux-qa\n---\n' > .claude/agents/_archive/ui-ux-qa.md
printf '## Verdict: GREEN ✅\n## Inputs\nx\n## Findings\nnone\n## Artifacts\nok\n' > _reports/runs/t_green.md   # the shipped RUN_REPORT_TEMPLATE shape
git add .gitignore _reports/runs/t_red.md _reports/runs/t_green.md 2>/dev/null
git commit -qm "code + report" >/dev/null 2>&1
sha="$(git rev-parse HEAD 2>/dev/null || echo '')"
printf '{"run_id":"t1","timestamp":"now","verdict":"GREEN","head_sha":"%s","report":"_reports/runs/t_green.md","row":"NORMAL","builder":"block-executor","reviewers":["verifier"]}' "$sha" > _reports/runs/latest.json
if QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh >/dev/null 2>&1; then
  ok "gate passes a genuine GREEN run bound to HEAD (clean tree, latest.json exempt)"
else
  no "gate blocked a legitimate GREEN run"
fi
# 7c. GREEN json but head_sha of a DIFFERENT commit → stale proof must BLOCK
printf '{"run_id":"t1","timestamp":"now","verdict":"GREEN","head_sha":"deadbeefdeadbeefdeadbeefdeadbeefdeadbeef","report":"_reports/runs/t_green.md","row":"NORMAL","builder":"block-executor","reviewers":["verifier"]}' > _reports/runs/latest.json
if QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh >/dev/null 2>&1; then
  no "gate accepted proof from a DIFFERENT commit (stale-proof hole)"
else
  ok "gate rejects proof bound to a different commit"
fi
# 7d. THE DIRTY-TREE LOOPHOLE (external review, v8.1.9-p1-lean): valid GREEN proof
# bound to HEAD + an UNVERIFIED unstaged change made AFTER verification → must BLOCK.
printf '{"run_id":"t1","timestamp":"now","verdict":"GREEN","head_sha":"%s","report":"_reports/runs/t_green.md","row":"NORMAL","builder":"block-executor","reviewers":["verifier"]}' "$sha" > _reports/runs/latest.json
echo "tampered after verification" >> ok.txt
if QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh >/dev/null 2>&1; then
  no "gate went GREEN with a dirty tree (proof-for-old-state loophole regressed)"
else
  ok "gate BLOCKS unverified changes on top of a valid proof (dirty tree)"
fi
git checkout -q -- ok.txt 2>/dev/null

# ---------------------------------------------------------------------------
# test-hooks.sh SECTION 8 -- sheriff-review.sh reviewer-isolation guarantees
# Splice-ready fragment (field project A, 2026-08-30, post sheriff round 5).
# 29 assertions; verified standalone against this contract: PASS: 29, FAIL: 0.
# New since v8.3.4: the single-spelling check (round 5) -- see NOTE.md.
#
# CONTRACT (corrected -- the v8.3.4 export's "needs only ok/no and $SANDBOX" was
# INCOMPLETE, and splicing it on that basis yields spurious failures):
#   1. the harness's `ok` / `no` helpers
#   2. $SANDBOX, a mktemp dir
#   3. cwd == $SANDBOX at entry  -- the wrapper finds no git repo there and falls back
#      to $PWD as its protected root, which is what makes "$SANDBOX/..." the
#      inside-the-repo case. Run it from a real repo root instead and three containment
#      assertions invert.
#   4. $SANDBOX/scripts is a copy of the repo's scripts/ (`cp -r "$SCRIPTS" "$SANDBOX/scripts"`)
#      -- the fragment invokes `bash scripts/sheriff-review.sh` relatively.
# Splice after section 7, before the totals, and keep steps 3-4 in place.
# ---------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# test-hooks.sh SECTION 8 - splice-ready fragment, round 6 (2026-08-31)
#
# SPLICE CONTRACT (unchanged from r5 - the fragment assumes all of it):
#   - the `ok` / `no` helpers exist and count into $pass / $fail
#   - $SANDBOX is a temp dir that is NOT a git repo; cwd == $SANDBOX at entry
#   - scripts/ has been copied into $SANDBOX (so `scripts/sheriff-review.sh` runs)
#   - $SCRIPTS points at the REAL scripts dir (used for the integration/ canary)
#   - the wrapper falls back to $PWD as its root here, which is what makes
#     "$SANDBOX/..." the inside-the-repo case
# Assertions in this fragment: 44. Full suite in the field project: 92/0.
# -----------------------------------------------------------------------------
# 7e-7w. F2 (v8.3.23): the independent review is enforced by the gate, not hoped for.
# Field project A, week of 2026-09-01: ~19 of 20 NORMAL+ runs had no reviewer except the
# builder itself; latest.json even listed the builder as the "reviewer". Nothing caught it.
# 7e. NORMAL run with NO reviewers -> BLOCK
printf '{"run_id":"t1","timestamp":"now","verdict":"GREEN","head_sha":"%s","report":"_reports/runs/t_green.md","row":"NORMAL","builder":"block-executor","reviewers":[]}' "$sha" > _reports/runs/latest.json
if QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh >/dev/null 2>&1; then
  no "F2: gate accepted a NORMAL run with no reviewers"
else
  ok "F2: gate BLOCKS a NORMAL run with no reviewers"
fi
# 7f. reviewer == builder -> BLOCK (self-review is not a review)
printf '{"run_id":"t1","timestamp":"now","verdict":"GREEN","head_sha":"%s","report":"_reports/runs/t_green.md","row":"NORMAL","builder":"devops-operator","reviewers":["devops-operator (live SSH session)"]}' "$sha" > _reports/runs/latest.json
if QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh >/dev/null 2>&1; then
  no "F2: gate accepted the builder as its own reviewer"
else
  ok "F2: gate BLOCKS reviewer == builder"
fi
# 7f2. missing builder -> BLOCK (independence cannot be checked)
printf '{"run_id":"t1","timestamp":"now","verdict":"GREEN","head_sha":"%s","report":"_reports/runs/t_green.md","row":"NORMAL","reviewers":["verifier"]}' "$sha" > _reports/runs/latest.json
if QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh >/dev/null 2>&1; then
  no "F2: gate accepted a run that never named its builder"
else
  ok "F2: gate BLOCKS a run with no 'builder'"
fi
# 7g. HIGH with 2 risks and 1 distinct reviewer -> BLOCK
printf '{"run_id":"t1","timestamp":"now","verdict":"GREEN","head_sha":"%s","report":"_reports/runs/t_green.md","row":"HIGH","builder":"block-executor","risks":["security","infra"],"reviewers":["security-reviewer","security-reviewer (second pass)"]}' "$sha" > _reports/runs/latest.json
if QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh >/dev/null 2>&1; then
  no "F2: gate accepted a HIGH run with fewer distinct reviewers than risks"
else
  ok "F2: gate BLOCKS a HIGH run with 1 distinct reviewer for 2 risks"
fi
# 7g2. HIGH with one independent reviewer per risk -> pass
printf '{"run_id":"t1","timestamp":"now","verdict":"GREEN","head_sha":"%s","report":"_reports/runs/t_green.md","row":"HIGH","builder":"block-executor","risks":["security","infra"],"reviewers":["security-reviewer","infra-security-reviewer","verifier"]}' "$sha" > _reports/runs/latest.json
if QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh >/dev/null 2>&1; then
  ok "F2: gate passes a HIGH run with one independent reviewer per risk"
else
  no "F2: gate blocked a HIGH run that satisfies one-reviewer-per-risk"
fi
# 7h. HIGH with no risks listed -> BLOCK (the row demands them)
printf '{"run_id":"t1","timestamp":"now","verdict":"GREEN","head_sha":"%s","report":"_reports/runs/t_green.md","row":"HIGH","builder":"block-executor","reviewers":["verifier"]}' "$sha" > _reports/runs/latest.json
if QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh >/dev/null 2>&1; then
  no "F2: gate accepted a HIGH run with no risks listed"
else
  ok "F2: gate BLOCKS a HIGH run that lists no risks"
fi

# 7i-7u. F2 hardening from the functional-verifier's adversarial pass (v8.3.23):
# type confusion and junk tokens must not turn the self-review check into a no-op.
# 7i. builder given as a LIST (LLM slip) with itself as reviewer -> BLOCK (F-1, was GREEN)
printf '{"run_id":"t1","timestamp":"now","verdict":"GREEN","head_sha":"%s","report":"_reports/runs/t_green.md","row":"NORMAL","builder":["verifier"],"reviewers":["verifier"]}' "$sha" > _reports/runs/latest.json
if QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh >/dev/null 2>&1; then
  no "F2: a list-typed builder let the builder review itself"
else
  ok "F2: gate BLOCKS a non-string builder (type confusion no longer bypasses self-review)"
fi
# 7j. HIGH, 2 risks, reviewers are junk tokens -> BLOCK (F-2)
printf '{"run_id":"t1","timestamp":"now","verdict":"GREEN","head_sha":"%s","report":"_reports/runs/t_green.md","row":"HIGH","builder":"block-executor","risks":["security","infra"],"reviewers":["(pending)","security-reviewer"]}' "$sha" > _reports/runs/latest.json
if QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh >/dev/null 2>&1; then
  no "F2: junk reviewer token counted as an independent reviewer"
else
  ok "F2: gate BLOCKS a reviewer entry that is not an agent name"
fi
# 7k. HIGH, DUPLICATE risk entries, one reviewer -> pass (F-3: duplicates must not inflate the requirement)
printf '{"run_id":"t1","timestamp":"now","verdict":"GREEN","head_sha":"%s","report":"_reports/runs/t_green.md","row":"HIGH","builder":"block-executor","risks":["infra","Infra"],"reviewers":["infra-security-reviewer"]}' "$sha" > _reports/runs/latest.json
if QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh >/dev/null 2>&1; then
  ok "F2: duplicate risks do not demand a second reviewer"
else
  no "F2: duplicate risk entries inflated the reviewer requirement"
fi
# 7l. bullet-prefixed reviewer entry is read as its agent name -> pass (F-5)
printf '{"run_id":"t1","timestamp":"now","verdict":"GREEN","head_sha":"%s","report":"_reports/runs/t_green.md","row":"NORMAL","builder":"block-executor","reviewers":["- verifier"]}' "$sha" > _reports/runs/latest.json
if QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh >/dev/null 2>&1; then
  ok "F2: a bullet-prefixed reviewer entry resolves to the agent name"
else
  no "F2: bullet prefix misread as the reviewer name"
fi
# 7m. pseudo-reviewer "orchestrator" -> BLOCK
printf '{"run_id":"t1","timestamp":"now","verdict":"GREEN","head_sha":"%s","report":"_reports/runs/t_green.md","row":"NORMAL","builder":"block-executor","reviewers":["orchestrator"]}' "$sha" > _reports/runs/latest.json
if QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh >/dev/null 2>&1; then
  no 'F2: "orchestrator" accepted as an independent reviewer'
else
  ok "F2: gate BLOCKS a pseudo-reviewer (orchestrator)"
fi
# 7n. unknown row value -> BLOCK
printf '{"run_id":"t1","timestamp":"now","verdict":"GREEN","head_sha":"%s","report":"_reports/runs/t_green.md","row":"MEDIUM","builder":"block-executor","reviewers":["verifier"]}' "$sha" > _reports/runs/latest.json
if QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh >/dev/null 2>&1; then
  no "F2: unknown row value accepted"
else
  ok "F2: gate BLOCKS an unknown row value"
fi
# 7o. declared LOW row on a NON-trivial gate run -> BLOCK (LOW means --trivial; otherwise it is the cheapest F2 escape)
printf '{"run_id":"t1","timestamp":"now","verdict":"GREEN","head_sha":"%s","report":"_reports/runs/t_green.md","row":"LOW","builder":"block-executor","reviewers":[]}' "$sha" > _reports/runs/latest.json
if QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh >/dev/null 2>&1; then
  no "F2: a self-declared LOW row skipped the review check on a non-trivial gate run"
else
  ok "F2: gate BLOCKS a self-declared LOW row on a non-trivial run (LOW = --trivial)"
fi
# 7p. builder null -> BLOCK (independence uncheckable; code-reviewer HIGH)
printf '{"run_id":"t1","timestamp":"now","verdict":"GREEN","head_sha":"%s","report":"_reports/runs/t_green.md","row":"NORMAL","builder":null,"reviewers":["block-executor"]}' "$sha" > _reports/runs/latest.json
if QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh >/dev/null 2>&1; then
  no "F2: null builder passed as a named builder"
else
  ok "F2: gate BLOCKS a null builder"
fi
# 7q. reviewer entries that are objects -> BLOCK
printf '{"run_id":"t1","timestamp":"now","verdict":"GREEN","head_sha":"%s","report":"_reports/runs/t_green.md","row":"NORMAL","builder":"devops-operator","reviewers":[{"name":"verifier"}]}' "$sha" > _reports/runs/latest.json
if QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh >/dev/null 2>&1; then
  no "F2: an object counted as a reviewer"
else
  ok "F2: gate BLOCKS reviewer entries that are not strings"
fi
# 7r. self-review spelled with a space ("block executor") -> BLOCK (ADV-1)
printf '{"run_id":"t1","timestamp":"now","verdict":"GREEN","head_sha":"%s","report":"_reports/runs/t_green.md","row":"NORMAL","builder":"block-executor","reviewers":["block executor (self-review)"]}' "$sha" > _reports/runs/latest.json
if QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh >/dev/null 2>&1; then
  no "F2: "block executor" passed as a different agent than "block-executor""
else
  ok "F2: gate BLOCKS a self-review disguised by space-vs-hyphen spelling"
fi
# 7s. invented reviewer names on HIGH -> BLOCK (ADV-7)
printf '{"run_id":"t1","timestamp":"now","verdict":"GREEN","head_sha":"%s","report":"_reports/runs/t_green.md","row":"HIGH","builder":"block-executor","risks":["security","infra","data"],"reviewers":["abc","def","ghi"]}' "$sha" > _reports/runs/latest.json
if QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh >/dev/null 2>&1; then
  no "F2: three invented names satisfied one-reviewer-per-risk"
else
  ok "F2: gate BLOCKS reviewers that are not active agents"
fi
# 7t. an agent on leave (_archive) offered as reviewer -> BLOCK
printf '{"run_id":"t1","timestamp":"now","verdict":"GREEN","head_sha":"%s","report":"_reports/runs/t_green.md","row":"NORMAL","builder":"block-executor","reviewers":["ui-ux-qa"]}' "$sha" > _reports/runs/latest.json
if QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh >/dev/null 2>&1; then
  no "F2: an agent on leave counted as an active reviewer"
else
  ok "F2: gate BLOCKS an archived agent as reviewer"
fi
# 7u. free-form entries that START with a roster name -> pass
printf '{"run_id":"t1","timestamp":"now","verdict":"GREEN","head_sha":"%s","report":"_reports/runs/t_green.md","row":"HIGH","builder":"orchestrator (main session)","risks":["functional","security"],"reviewers":["Verifier consolidated the evidence","security-reviewer (app+infra) PASS"]}' "$sha" > _reports/runs/latest.json
if QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh >/dev/null 2>&1; then
  ok "F2: free-form reviewer entries resolve to their roster agent"
else
  no "F2: a legitimate free-form reviewer entry was rejected"
fi
# 7v. EMPTY active roster -> BLOCK (SHERIFF [1]: shape-only fallback let invented names through)
mv .claude/agents .claude/agents.off
printf '{"run_id":"t1","timestamp":"now","verdict":"GREEN","head_sha":"%s","report":"_reports/runs/t_green.md","row":"NORMAL","builder":"block-executor","reviewers":["totally-invented-agent"]}' "$sha" > _reports/runs/latest.json
if QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh >/dev/null 2>&1; then
  no "F2: an empty active roster let an invented reviewer pass"
else
  ok "F2: gate BLOCKS when there are no active agents to have reviewed"
fi
mv .claude/agents.off .claude/agents
# 7w. validator cannot run (python3 broken/absent) -> BLOCK, never "latest.json present" (SHERIFF [2])
printf '{"run_id":"t1","timestamp":"now","verdict":"GREEN","head_sha":"%s","report":"_reports/runs/t_green.md","row":"NORMAL","builder":"block-executor","reviewers":["verifier"]}' "$sha" > _reports/runs/latest.json
stub="$(mktemp -d)"; printf '#!/usr/bin/env bash\nexit 127\n' > "$stub/python3"; chmod +x "$stub/python3"
if PATH="$stub:$PATH" QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh >/dev/null 2>&1; then
  no "gate went GREEN although the latest.json validator never ran"
else
  ok "gate BLOCKS when the latest.json validator cannot run"
fi
rm -rf "$stub"

# 7x. THE SHIPPED SKELETON MUST SATISFY THE VALIDATOR (v8.3.24).
# Every other test in this section writes its own latest.json by hand, so the suite
# stayed fully green while the shipped _reports/runs/latest.json.template was missing
# two fields the gate had begun requiring. A project that used the skeleton exactly as
# intended got a BLOCK it had done nothing to earn, and nothing here noticed.
# The fill below only ever replaces keys the skeleton ALREADY declares -- it never adds
# one -- so a field added to the validator and forgotten in the skeleton fails here.
tpl="$ROOT/_reports/runs/latest.json.template"
if [ ! -f "$tpl" ]; then
  no "shipped _reports/runs/latest.json.template is missing"
else
  miss="$(python3 - "$tpl" <<'PY'
import json, sys
d = json.load(open(sys.argv[1], encoding="utf-8"))
need = ["run_id","timestamp","verdict","head_sha","report","row","builder","reviewers","risks"]
print(",".join(k for k in need if k not in d))
PY
)"
  [ -z "$miss" ] && ok "shipped skeleton declares every field the gate can require" \
                 || no "shipped skeleton is missing gate fields: $miss"
  python3 - "$tpl" "$sha" > _reports/runs/latest.json <<'PY'
import json, sys
d = json.load(open(sys.argv[1], encoding="utf-8"))
fill = {"run_id": "t-skeleton", "timestamp": "now", "task": "skeleton validation",
        "verdict": "GREEN", "head_sha": sys.argv[2],
        "report": "_reports/runs/t_green.md", "spec": "",
        "row": "NORMAL", "builder": "block-executor",
        "reviewers": ["verifier"], "risks": [], "gate": "PASS"}
out = {k: (fill[k] if k in fill else v) for k, v in d.items() if not k.startswith("$")}
print(json.dumps(out))
PY
  qx="$(QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh 2>&1)"
  if echo "$qx" | grep -q "independent review (F2)"; then
    ok "the SHIPPED skeleton, filled in, satisfies the gate validator"
  else
    no "the shipped skeleton does NOT satisfy the gate: $(echo "$qx" | grep -i 'latest.json' | head -2 | tr '\n' ' ')"
  fi
fi

# 7y. BUILDER resolved against the ACTIVE roster (v8.3.25). Reviewers always were; the
# builder was only required to be non-empty, so a run built by an archived agent was
# certified as long as its reviewers were real.
for b in "ui-ux-qa" "made-up-builder" "self"; do
  printf '{"run_id":"t1","timestamp":"now","verdict":"GREEN","head_sha":"%s","report":"_reports/runs/t_green.md","row":"NORMAL","builder":"%s","reviewers":["verifier"]}' "$sha" "$b" > _reports/runs/latest.json
  if QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh >/dev/null 2>&1; then
    no "F2: builder '$b' (archived / invented / pseudo) was accepted"
  else
    ok "F2: gate BLOCKS builder '$b' — not an active agent"
  fi
done
printf '{"run_id":"t1","timestamp":"now","verdict":"GREEN","head_sha":"%s","report":"_reports/runs/t_green.md","row":"NORMAL","builder":"orchestrator","reviewers":["verifier"]}' "$sha" > _reports/runs/latest.json
if QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh >/dev/null 2>&1; then
  ok "F2: the main session ('orchestrator') is a legitimate builder"
else
  no "F2: the main session was refused as a builder"
fi

# 7z. No kernel (AGENTS.md since v8.3.28) -> a visible BLOCK. It used to crash awk on
# stderr and skip the CORE check without a line on stdout (v8.3.25).
mv AGENTS.md AGENTS.md.away
qx="$(bash scripts/quality-gate.sh --trivial 2>&1)"; rc=$?
if [ "$rc" -ne 0 ] && echo "$qx" | grep -q "no AGENTS.md" && ! echo "$qx" | grep -qi "fatal"; then
  ok "gate BLOCKS, visibly, when there is no AGENTS.md (no silent CORE skip)"
else
  no "missing AGENTS.md did not produce a visible BLOCK (rc=$rc)"
fi
mv AGENTS.md.away AGENTS.md
# #42: a CLAUDE.md that lost its @AGENTS.md import means Claude Code runs with no kernel.
cp CLAUDE.md CLAUDE.md.stub; printf '# rewritten by /init, no import
' > CLAUDE.md
qx="$(bash scripts/quality-gate.sh --trivial 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && echo "$qx" | grep -q "no '@AGENTS.md' line"   && ok "#42: gate BLOCKS a CLAUDE.md without the @AGENTS.md import"   || no "#42: gate accepted a CLAUDE.md that does not import the kernel (rc=$rc)"
mv CLAUDE.md.stub CLAUDE.md
qx="$(bash scripts/quality-gate.sh --trivial 2>&1)"
echo "$qx" | grep -q "CLAUDE.md is the kernel stub" && ok "#42: gate confirms the stub imports the kernel"                                                     || no "#42: gate did not confirm the stub"
# Security review: the stub is exactly the import. A second import loads unreviewed text
# beside the kernel, outside the CORE hash.
cp CLAUDE.md CLAUDE.md.stub; printf '<!-- stub -->\n@AGENTS.md\n@notes.md\n' > CLAUDE.md
qx="$(bash scripts/quality-gate.sh --trivial 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && echo "$qx" | grep -q "carries more than the '@AGENTS.md' line" \
  && ok "#42: gate BLOCKS a stub that carries a second import" || no "#42: a stub with an extra import passed (rc=$rc)"
mv CLAUDE.md.stub CLAUDE.md
# ...and a kernel whose CORE block vanished while a baseline exists is a removed kernel,
# not "no CORE yet" (it used to pass both the gate and the hook).
cp AGENTS.md AGENTS.md.core; grep -v 'CORE:START\|CORE:END' AGENTS.md.core > AGENTS.md
qx="$(bash scripts/quality-gate.sh --trivial 2>&1)"; rc=$?
[ -f .claude/core.sha ] && [ "$rc" -ne 0 ] && echo "$qx" | grep -q "no CORE block but a CORE baseline exists" \
  && ok "gate BLOCKS an AGENTS.md whose CORE block was removed while a baseline exists" || no "a removed CORE block passed the gate (rc=$rc)"
bash scripts/check-core.sh >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && ok "check-core.sh STOPs (exit 2) on a removed CORE block" || no "check-core.sh let a removed CORE block through (rc=$rc)"
# Mid-upgrade (UPGRADE s.3b): CORE still in CLAUDE.md — the hook notes it, it does not STOP
# every Write/Edit of the upgrade session (review F4). The gate above still BLOCKS.
cp CLAUDE.md CLAUDE.md.stub; cp AGENTS.md.core CLAUDE.md
bash scripts/check-core.sh >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && ok "check-core.sh only notes a CORE still in CLAUDE.md mid-upgrade" || no "check-core.sh STOPs mid-upgrade (rc=$rc)"
mv CLAUDE.md.stub CLAUDE.md
# ...and a DELETED kernel with a baseline on disk is a removed kernel too (sheriff).
mv AGENTS.md AGENTS.md.gone
bash scripts/check-core.sh >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && ok "check-core.sh STOPs (exit 2) on a deleted AGENTS.md while a baseline exists" || no "check-core.sh let a deleted kernel through (rc=$rc)"
mv AGENTS.md.gone AGENTS.md
mv AGENTS.md.core AGENTS.md

# 7z2. Every step keeps its OWN log (v8.3.25). One shared /tmp/qg.out let the next step
# overwrite a failing step's evidence before anyone read it.
stub="$(mktemp -d)"; printf '#!/usr/bin/env bash\necho "output of make $1"; exit 1\n' > "$stub/make"; chmod +x "$stub/make"
printf 'lint:\n\ttrue\ntest:\n\ttrue\n' > Makefile
qx="$(PATH="$stub:$PATH" bash scripts/quality-gate.sh --trivial 2>&1)"
l1="$(echo "$qx" | grep -o 'lint (make) FAILED (log: [^)]*)' | sed 's/.*log: //; s/)$//')"
l2="$(echo "$qx" | grep -o 'test (make) FAILED (log: [^)]*)' | sed 's/.*log: //; s/)$//')"
if [ -n "$l1" ] && [ -n "$l2" ] && [ "$l1" != "$l2" ] && grep -q "make lint" "$l1" 2>/dev/null && grep -q "make test" "$l2" 2>/dev/null; then
  ok "each failing gate step keeps its own log, which survives the next step"
else
  no "gate step logs are shared or lost (lint log '$l1', test log '$l2')"
fi
rm -f Makefile; rm -rf "$stub"; [ -n "$l1" ] && rm -rf "$(dirname "$l1")"

# 7z3. Self-location (v8.3.27, #24): the gate runs the tree it lives in, never another.
# A field board carried "the gate mixed trees" for a release: run from another project's
# root it scored that project's git state against its own roster and CORE.
other="$(mktemp -d)"; cp -r scripts "$other/scripts"
qx="$(bash "$other/scripts/quality-gate.sh" --trivial 2>&1)"; rc=$?
if [ "$rc" -ne 0 ] && echo "$qx" | grep -q "never mix trees" && ! echo "$qx" | grep -q "GATE: GREEN"; then
  ok "gate refuses to run from another tree's scripts/ (never mix trees)"
else
  no "gate ran against a tree it does not belong to (rc=$rc)"
fi
find "$other" -mindepth 0 -delete 2>/dev/null
# ...but a project that is a directory INSIDE a larger repository gates from its own root.
mkdir -p sub && cp -r scripts sub/scripts
qx="$(cd sub && bash scripts/quality-gate.sh --trivial 2>&1)"
echo "$qx" | grep -q "never mix trees" && no "self-location refused a project rooted in a subdirectory of its repository" \
                                       || ok "self-location accepts a project rooted in a subdirectory of its repository"
find sub -mindepth 0 -delete 2>/dev/null

# 7z4. A verdict value line that itself says "verdict" (v8.3.27, #12): `grep -A1 -m1`
# stops at the first match and drops a trailing context line that also matches, so a
# valid report BLOCKed with "no parsable verdict" (field, 2026-09-15).
printf '## Verdict\nGREEN — the verdict consolidated by verifier\n## Inputs\nx\n## Findings\nnone\n## Artifacts\nok\n' > _reports/runs/t_verdict.md
git add _reports/runs/t_verdict.md 2>/dev/null; git commit -qm "report whose value line says verdict" >/dev/null 2>&1
sha="$(git rev-parse HEAD 2>/dev/null || echo '')"
touch -d "@$(( $(date +%s) + 120 ))" _reports/runs/t_verdict.md   # newest by mtime = the report the gate reads
printf '{"run_id":"t1","timestamp":"now","verdict":"GREEN","head_sha":"%s","report":"_reports/runs/t_verdict.md","row":"NORMAL","builder":"block-executor","reviewers":["verifier"]}' "$sha" > _reports/runs/latest.json
if QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh >/dev/null 2>&1; then
  ok "gate parses a verdict whose value line also contains the word verdict (#12)"
else
  no "#12 regressed: a value line mentioning 'verdict' left the report with no parsable verdict"
fi

# 7z5. Test runner by FILE TYPE, and MY COMMANDS first (v8.3.27, #10): a tests/ dir alone
# used to select pytest, so a node project with tests/*.test.mjs got a RED it could not pass.
mkdir -p tests; : > tests/app.test.mjs
qx="$(bash scripts/quality-gate.sh --trivial 2>&1)"
echo "$qx" | grep -q "test (pytest)" && no "#10: a tests/ dir holding only *.test.mjs still selected pytest" \
                                     || ok "#10: tests/*.test.mjs does not select pytest"
echo "$qx" | grep -q "test (node --test)" && ok "#10: tests/*.test.mjs selects node --test" \
  || no "#10: tests/*.test.mjs selected no runner: $(echo "$qx" | grep -i 'test' | head -2 | tr '\n' ' ')"
find tests -mindepth 0 -delete 2>/dev/null
mkdir -p tests; : > tests/README.md
qx="$(bash scripts/quality-gate.sh --trivial 2>&1)"
echo "$qx" | grep -q "no test command detected" && ok "#10: a tests/ dir with no test files selects nothing" \
                                                 || no "#10: a tests/ dir without test files still selected a runner"
: > tests/test_x.py
qx="$(bash scripts/quality-gate.sh --trivial 2>&1)"
echo "$qx" | grep -q "test (pytest)" && ok "#10: tests/test_*.py selects pytest" || no "#10: tests/test_*.py did not select pytest"
find tests -mindepth 0 -delete 2>/dev/null
# MY COMMANDS wins over auto-detection; a placeholder or an empty value is not a command.
# It is taken ONLY from a tracked, committed, unmodified AGENTS.md (security review +
# re-check): untracked, staged-only or edited → ignored, visibly.
printf 'lint:\n\ttrue\n' > Makefile
cp AGENTS.md AGENTS.md.keep
printf '\n## MY COMMANDS  <!-- real commands -->\n- Test: echo my-test-ran\n- Lint: <fill in>\n- Build: n/a\n' >> AGENTS.md
qx="$(bash scripts/quality-gate.sh --trivial 2>&1)"
if echo "$qx" | grep -q "MY COMMANDS test ignored" && ! echo "$qx" | grep -q "my-test-ran"; then
  ok "#10: an UNTRACKED AGENTS.md supplies no command (MY COMMANDS ignored, visibly)"
else
  no "#10: an untracked AGENTS.md MY COMMANDS line was executed"
fi
git add -f AGENTS.md 2>/dev/null; git commit -qm "kernel with MY COMMANDS" >/dev/null 2>&1
qx="$(bash scripts/quality-gate.sh --trivial 2>&1)"
echo "$qx" | grep -q "test (AGENTS.md MY COMMANDS: echo my-test-ran) passed" \
  && ok "#10: a committed MY COMMANDS Test: runs the owner's command first, and the output names the command" \
  || no "#10: MY COMMANDS Test: not used or not shown: $(echo "$qx" | grep -i 'test' | head -2 | tr '\n' ' ')"
echo "$qx" | grep -q "lint (make)" && ok "#10: a placeholder MY COMMANDS Lint: falls through to auto-detection" \
                                   || no "#10: the placeholder Lint: was taken as a command"   # (make may be absent: the label is the proof)
echo "$qx" | grep -q "no build command detected" && ok "#10: a MY COMMANDS Build: of 'n/a' selects nothing (not run as a command)" \
                                                 || no "#10: Build: n/a was taken as a command"
# ...an uncommitted EDIT of the committed file must not run shell in the gate either — the
# COMMITTED line runs, the edit is named; even hidden from `git diff` by assume-unchanged
# (sheriff: the blob is the source, not the working file).
sed -i 's/echo my-test-ran/echo injected-uncommitted/' AGENTS.md
git update-index --assume-unchanged AGENTS.md 2>/dev/null
qx="$(bash scripts/quality-gate.sh --trivial 2>&1)"
git update-index --no-assume-unchanged AGENTS.md 2>/dev/null
if echo "$qx" | grep -q "differs from HEAD" && echo "$qx" | grep -q "MY COMMANDS: echo my-test-ran) passed" \
   && ! echo "$qx" | grep -q "injected-uncommitted"; then
  ok "#10: an uncommitted (assume-unchanged) AGENTS.md edit never runs: the committed line does, and the edit is named"
else
  no "#10: an uncommitted AGENTS.md MY COMMANDS line was executed, or the committed one was not: $(echo "$qx" | grep -i 'MY COMMANDS' | head -2 | tr '\n' ' ')"
fi
# ...and a token on the MY COMMANDS line is redacted in the output and absent from the
# log path (re-check: the label used to name the log file). Token built at runtime.
tok="ghp_$(printf 'A%.0s' $(seq 30))"
sed -i "s/echo injected-uncommitted/TOKEN=$tok false/" AGENTS.md
git commit -qn -am "kernel with a token on the test line" >/dev/null 2>&1
qx="$(bash scripts/quality-gate.sh --trivial 2>&1)"
if ! echo "$qx" | grep -q "$tok" && echo "$qx" | grep -q "MY COMMANDS: TOKEN=<redacted> false) FAILED (log: [^)]*/test.log)"; then
  ok "#10: a token on the MY COMMANDS line is redacted in the output and the log is keyed by step"
else
  no "#10: the MY COMMANDS token leaked into the output or the log path: $(echo "$qx" | grep -i 'MY COMMANDS' | head -1 | cut -c1-120)"
fi
# #29 (v8.3.28): the MY COMMANDS line format. A value STARTING with none / n/a / a dash is no
# command; when the line has backticks, the first pair is the command and notes are not run.
sed -i -E 's/^- Test: .*/- Test: `echo bt-ran` (unit tests; these notes never run)/; s/^- Lint: .*/- Lint: n\/a (docs only)/' AGENTS.md
git commit -qn -am "MY COMMANDS line format" >/dev/null 2>&1
qx="$(bash scripts/quality-gate.sh --trivial 2>&1)"
echo "$qx" | grep -q "MY COMMANDS: echo bt-ran) passed" && ! echo "$qx" | grep -q "these notes never run)" \
  && ok "#29: the first backtick pair is the command; the notes around it are not run" \
  || no "#29: backticks + notes: $(echo "$qx" | grep -i 'MY COMMANDS' | head -1 | cut -c1-120)"
echo "$qx" | grep -q "lint (make)" && ok "#29: 'n/a (docs only)' is no command — falls through to auto-detection" \
                                   || no "#29: 'n/a (docs only)' was taken as a command"
sed -i -E 's/^- Test: .*/- Test: none yet/' AGENTS.md; git commit -qn -am "none yet" >/dev/null 2>&1
qx="$(bash scripts/quality-gate.sh --trivial 2>&1)"
echo "$qx" | grep -q "no test command detected" && ! echo "$qx" | grep -q "MY COMMANDS: none" \
  && ok "#29: 'none yet' is no command (it used to run as shell)" || no "#29: 'none yet' was taken as a command"
# #26 (v8.3.28): a project SECRET_REGEX holding a '/' used to end the redaction sed's `s/…/`
# early — the gate crashed on the MY COMMANDS label. The delimiter is now \001.
cp scripts/secret-patterns.sh scripts/secret-patterns.sh.keep
printf '%s\n' 'SECRET_REGEX="${SECRET_REGEX}|tok/[a-z]{6,}"' >> scripts/secret-patterns.sh
sed -i -E 's/^- Test: .*/- Test: TOKEN=tok\/abcdefgh true/' AGENTS.md; git commit -qn -am "slash token" >/dev/null 2>&1
qx="$(bash scripts/quality-gate.sh --trivial 2>&1)"
if echo "$qx" | grep -q "MY COMMANDS: TOKEN=<redacted> true) passed" && ! echo "$qx" | grep -q "tok/abcdefgh"; then
  ok "#26: a project secret regex with '/' redacts, and the gate does not crash"
else
  no "#26: slash in SECRET_REGEX: $(echo "$qx" | grep -iE 'MY COMMANDS|sed' | head -2 | tr '\n' ' ' | cut -c1-160)"
fi
mv scripts/secret-patterns.sh.keep scripts/secret-patterns.sh
# Security review (v8.3.28): a line the gate cannot read ONE way BLOCKS — it never guesses
# which part is the command. awk, not sed: the values carry `&` and backticks.
myc(){ awk -v v="$1" '/^- Test: /{print "- Test: " v; next} {print}' AGENTS.md > AGENTS.md.new && mv AGENTS.md.new AGENTS.md
  git commit -qn -am "MY COMMANDS variant" >/dev/null 2>&1; qx="$(bash scripts/quality-gate.sh --trivial 2>&1)"; rc=$?; }
for v in 'false  # run with `CI=1`' 'make test && echo `date`' '`` (empty pair)' '`echo unpaired' '`   ` (blank pair)'; do
  myc "$v"
  [ "$rc" -ne 0 ] && echo "$qx" | grep -q "MY COMMANDS test: ambiguous line" \
    && ok "#29: an ambiguous MY COMMANDS line BLOCKS: $v" || no "#29: ambiguous line was run or ignored (rc=$rc): $v"
done
myc '(none — evidence per deliverable)'
echo "$qx" | grep -q "reads as no command" && ! echo "$qx" | grep -q "MY COMMANDS: (none" \
  && ok "#29: '(none — …)' is no command (a field project BLOCKED on it)" || no "#29: '(none — …)' was run as a command"
myc 'none!; echo bang-ran'
echo "$qx" | grep -q "reads as no command" && ! echo "$qx" | grep -q "MY COMMANDS: none!" \
  && ok "#29: 'none!; …' is no command (any punctuation after the word)" || no "#29: 'none!; …' ran as shell"
myc 'todo_lint=1 echo todo-var-ran'
echo "$qx" | grep -q "MY COMMANDS: todo_lint=1 echo todo-var-ran) passed" \
  && ok "#29: a command that merely starts with 'todo_' is still a command" || no "#29: 'todo_…' was read as no command"
# A `- Test:` line inside a multi-line HTML comment is invisible in the rendered file, so
# it is invisible to the gate too; the visible line after it is the command.
awk '/^- Test: /{print "<!--"; print "- Test: echo hidden-ran"; print "-->"; print "- Test: echo visible-ran"; next} {print}' AGENTS.md > AGENTS.md.new && mv AGENTS.md.new AGENTS.md
git commit -qn -am "commented-out Test line" >/dev/null 2>&1; qx="$(bash scripts/quality-gate.sh --trivial 2>&1)"
echo "$qx" | grep -q "MY COMMANDS: echo visible-ran) passed" && ! echo "$qx" | grep -q "hidden-ran" \
  && ok "#29: a Test line inside a multi-line comment is not run" || no "#29: a commented-out Test line ran, or the visible one did not"
git rm -q --cached AGENTS.md >/dev/null 2>&1; git commit -qm "untrack kernel" >/dev/null 2>&1
mv AGENTS.md.keep AGENTS.md; rm -f Makefile


# -- 7q. WHICH verdict (v8.3.28, #40) --
# A /run-spec report is one file with a section appended per step. The gate used to read
# the newest file's FIRST Verdict heading, so it printed GREEN from a stale section while
# the current run was RED. Now: the report latest.json names, and in it the heading that
# names latest.json's run_id as a whole token; none or several naming it BLOCK.
printf '## Verdict — run s-S01: GREEN ✅\n## Inputs\nx\n## Findings\nnone\n## Artifacts\nok\n### Verdict — run s-S02\nRED 🔴\n' > _reports/runs/t_multi.md
git add _reports/runs/t_multi.md 2>/dev/null; git commit -qm "multi-run report" >/dev/null 2>&1
jl(){ # $1 run_id, $2 report, $3 extra json members
  printf '{"run_id":"%s","timestamp":"now","verdict":"GREEN","head_sha":"%s","report":"%s","row":"NORMAL","builder":"block-executor","reviewers":["verifier"]%s}' \
    "$1" "$(git rev-parse HEAD)" "$2" "${3:-}" > _reports/runs/latest.json; }
jl s-S02 _reports/runs/t_multi.md
qx="$(QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && echo "$qx" | grep -q "report verdict is RED" \
  && ok "#40: a multi-run report is read at THIS run's Verdict (RED), not its first heading (GREEN)" \
  || no "#40: the stale first Verdict was read: $(echo "$qx" | grep -i verdict | head -2 | tr '\n' ' ')"
jl s-S01 _reports/runs/t_multi.md
qx="$(QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && echo "$qx" | grep -q "reading the one that names this run (s-S01)" \
  && ok "#40: the Verdict heading naming this run_id is the one read (GREEN passes)" \
  || no "#40: this run's GREEN heading was not the one read (rc=$rc)"
jl s-S0 _reports/runs/t_multi.md
qx="$(QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && echo "$qx" | grep -q "and 0 name this run's run_id" \
  && ok "#40: a run_id that is only a PREFIX of a heading's id matches nothing — BLOCKED" \
  || no "#40: run_id s-S0 was matched inside s-S01 (rc=$rc)"
jl "" _reports/runs/t_multi.md
qx="$(QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && echo "$qx" | grep -q "none in latest.json" \
  && ok "#40: several Verdict headings and no run_id — BLOCKED, never a guess" || no "#40: no run_id, several headings, not blocked (rc=$rc)"
printf '## Verdict: RED 🔴\n## Inputs\nx\n## Findings\nx\n## Artifacts\nx\n' > _reports/runs/t_newer_red.md
git add _reports/runs/t_newer_red.md 2>/dev/null; git commit -qm "a newer, unrelated report" >/dev/null 2>&1
jl t1 _reports/runs/t_green.md
qx="$(QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && echo "$qx" | grep -q "run report: _reports/runs/t_green.md" \
  && ok "#40: the report latest.json names is read, not the newest file" || no "#40: the newest file won over latest.json's report (rc=$rc)"
# Security review: the named report is a repo-relative file under _reports/runs/ that HEAD
# holds — an absolute path, a path out of the tree, or an uncommitted file proves nothing.
printf '## Verdict\nGREEN\n## Inputs\nx\n## Findings\nnone\n## Artifacts\nok\n' > _reports/runs/t_uncommitted.md
for r in "$PWD/_reports/runs/t_green.md" "_reports/runs/../../outside.md" "_reports/runs/t_uncommitted.md"; do
  jl t1 "$r"; qx="$(QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh 2>&1)"; rc=$?
  [ "$rc" -ne 0 ] && echo "$qx" | grep -qE "must be a repo-relative path under _reports/runs/|not a regular file committed in HEAD" \
    && ok "#40: latest.json report '$r' BLOCKS" || no "#40: latest.json report '$r' was accepted (rc=$rc)"
done
git add _reports/runs/t_uncommitted.md 2>/dev/null; git commit -qm "commit the fixture: a dirty tree fails the next cases" >/dev/null 2>&1
# ...and a run_id that holds a verdict word never becomes the verdict (-w matched `red` in
# `fix-red-S01` on the heading line itself).
printf '## Verdict — run fix-red-S01\nGREEN ✅\n## Inputs\nx\n## Findings\nnone\n## Artifacts\nok\n' > _reports/runs/t_word.md
git add _reports/runs/t_word.md 2>/dev/null; git commit -qm "run_id with a verdict word" >/dev/null 2>&1
jl fix-red-S01 _reports/runs/t_word.md; qx="$(QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && ok "#40: a run_id containing 'red' does not poison a GREEN verdict" || no "#40: run_id fix-red-S01 turned GREEN into RED/ambiguous (rc=$rc): $(echo "$qx" | grep -i verdict | head -1)"
# ...and a report whose ONLY heading names another run is not this run's proof (review F1).
jl fix-red-S02 _reports/runs/t_word.md; qx="$(QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && echo "$qx" | grep -q "only Verdict heading names another run" \
  && ok "#40: a single Verdict heading naming the PREVIOUS step BLOCKS" || no "#40: the previous step's only heading passed for this run (rc=$rc)"
# Sheriff round 2: (a) the verdict is read from HEAD — a skip-worktree working copy saying
# GREEN over a committed RED is not the proof;
printf '## Verdict\nRED\n## Inputs\nx\n## Findings\nx\n## Artifacts\nx\n' > _reports/runs/t_head.md
git add _reports/runs/t_head.md 2>/dev/null; git commit -qm "committed RED" >/dev/null 2>&1
git update-index --skip-worktree _reports/runs/t_head.md 2>/dev/null; sed -i 's/^RED$/GREEN/' _reports/runs/t_head.md
jl t1 _reports/runs/t_head.md; qx="$(QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh 2>&1)"; rc=$?
git update-index --no-skip-worktree _reports/runs/t_head.md 2>/dev/null; git checkout -q -- _reports/runs/t_head.md 2>/dev/null
[ "$rc" -ne 0 ] && echo "$qx" | grep -q "report verdict is RED" \
  && ok "#40: the report verdict is read from HEAD, not a skip-worktree working copy" || no "#40: a skip-worktree GREEN beat the committed RED (rc=$rc)"
# (b) a run_id repeated inside a longer id is not "named" (S02 vs S02S02);
printf '### Verdict — run S02S02\nGREEN\n### Verdict — run S01\nRED\n## Inputs\nx\n## Findings\nx\n## Artifacts\nx\n' > _reports/runs/t_rep.md
git add _reports/runs/t_rep.md 2>/dev/null; git commit -qm "repeated id" >/dev/null 2>&1
jl S02 _reports/runs/t_rep.md; qx="$(QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && echo "$qx" | grep -q "and 0 name this run's run_id" \
  && ok "#40: run_id S02 does not match inside S02S02 — BLOCKED" || no "#40: S02 matched S02S02 (rc=$rc)"
# (c) the run_id is stripped from the value line too ("green-S02: RED" is RED).
printf '### Verdict — run green-S02\ngreen-S02: RED\n## Inputs\nx\n## Findings\nx\n## Artifacts\nx\n' > _reports/runs/t_val.md
git add _reports/runs/t_val.md 2>/dev/null; git commit -qm "id on the value line" >/dev/null 2>&1
jl green-S02 _reports/runs/t_val.md; qx="$(QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && ! echo "$qx" | grep -q "report verdict: GREEN" \
  && ok "#40: a run_id on the value line is not read as the verdict (green-S02 is one token: BLOCK)" || no "#40: 'green-S02: RED' read as GREEN (rc=$rc)"
# Sheriff round 3: (d) a run_id with a literal backslash-n is matched and stripped as those
# bytes (awk -v used to turn it into a newline);
printf '### Verdict — run s\\nS02\nGREEN\n## Inputs\nx\n## Findings\nx\n## Artifacts\nx\n' > _reports/runs/t_bs.md
git add _reports/runs/t_bs.md 2>/dev/null; git commit -qm "backslash id" >/dev/null 2>&1
printf '{"run_id":"s\\\\nS02","timestamp":"now","verdict":"GREEN","head_sha":"%s","report":"_reports/runs/t_bs.md","row":"NORMAL","builder":"block-executor","reviewers":["verifier"]}' "$(git rev-parse HEAD)" > _reports/runs/latest.json
qx="$(QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && echo "$qx" | grep -q "report verdict: GREEN" \
  && ok "#40: a run_id holding a literal backslash-n matches as those bytes (not a newline)" || no "#40: backslash run_id did not match its own heading (rc=$rc)"
# Sheriff round 4: (f) a run_id that IS a verdict word is only the run's name — the value is
# read after it. (The fixture named a second verdict word, "previous result was GREEN",
# until v8.3.29 made that a BLOCK of its own — grammar rows below.)
printf '## Verdict — run RED\nRED — tests failed\n## Inputs\nx\n## Findings\nx\n## Artifacts\nx\n' > _reports/runs/t_vw.md
git add _reports/runs/t_vw.md 2>/dev/null; git commit -qm "verdict-word id" >/dev/null 2>&1
jl RED _reports/runs/t_vw.md; qx="$(QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && echo "$qx" | grep -q "report verdict is RED" \
  && ok "#40: run_id 'RED' is only the run's name; the value after it is read (RED)" || no "#40: run_id RED misread (rc=$rc)"
# (g) a heading names a run only as 'run <id>': run_id "run" does not match "run S01";
printf '## Verdict — run S01\nGREEN\n## Inputs\nx\n## Findings\nx\n## Artifacts\nx\n' > _reports/runs/t_rw.md
git add _reports/runs/t_rw.md 2>/dev/null; git commit -qm "run-word id" >/dev/null 2>&1
jl run _reports/runs/t_rw.md; qx="$(QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && echo "$qx" | grep -q "only Verdict heading names another run" \
  && ok "#40: run_id 'run' does not match the word run in 'run S01'" || no "#40: run_id 'run' matched another run's heading (rc=$rc)"
# Sheriff round 5: (i) the run_id is stripped as a WHOLE token only ("field" never cuts
# "greenfield" down to "green");
printf '### Verdict — run field\ngreenfield: RED\n## Inputs\nx\n## Findings\nx\n## Artifacts\nx\n' > _reports/runs/t_tok.md
git add _reports/runs/t_tok.md 2>/dev/null; git commit -qm "id inside a word" >/dev/null 2>&1
jl field _reports/runs/t_tok.md; qx="$(QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && ! echo "$qx" | grep -q "report verdict: GREEN" \
  && ok "#40: 'greenfield: RED' is never GREEN (one token: BLOCK)" || no "#40: run_id 'field' turned greenfield into GREEN (rc=$rc)"
# (j) a heading indented by up to 3 spaces is a heading (Markdown) — counted and selectable.
printf '### Verdict\nGREEN\n  ### Verdict — run S02\nRED\n## Inputs\nx\n## Findings\nx\n## Artifacts\nx\n' > _reports/runs/t_ind.md
git add _reports/runs/t_ind.md 2>/dev/null; git commit -qm "indented heading" >/dev/null 2>&1
jl S02 _reports/runs/t_ind.md; qx="$(QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && echo "$qx" | grep -q "report verdict is RED" \
  && ok "#40: an indented '  ### Verdict — run S02' heading is found and read (RED)" || no "#40: the indented heading was missed (rc=$rc)"
# Sheriff round 6: (k) verdict words are whole TOKENS with the id boundary — an old id on
# the heading ("green-S02-old") never reads as GREEN;
printf '## Verdict — run green-S02 (previous: green-S02-old)\nRED\n## Inputs\nx\n## Findings\nx\n## Artifacts\nx\n' > _reports/runs/t_old.md
git add _reports/runs/t_old.md 2>/dev/null; git commit -qm "old id on heading" >/dev/null 2>&1
jl green-S02 _reports/runs/t_old.md; qx="$(QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && echo "$qx" | grep -q "report verdict is RED" \
  && ok "#40: an older id on the heading (green-S02-old) is not read as GREEN" || no "#40: green-S02-old read as GREEN (rc=$rc)"
# (l) code is not prose: an indented or fenced example verdict is never the verdict.
printf '    ## Verdict — run S01\n    GREEN\n\nVerdict: RED\nInputs Findings Artifacts\n' > _reports/runs/t_code.md
printf '```\n### Verdict — run S02\nGREEN\n```\n### Verdict — run S02\nRED\n## Inputs\nx\n## Findings\nx\n## Artifacts\nx\n' > _reports/runs/t_fence.md
git add _reports/runs/t_code.md _reports/runs/t_fence.md 2>/dev/null; git commit -qm "code examples" >/dev/null 2>&1
for r in t_code t_fence; do
  jl S02 "_reports/runs/$r.md"; qx="$(QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh 2>&1)"; rc=$?
  [ "$rc" -ne 0 ] && echo "$qx" | grep -q "report verdict is RED" \
    && ok "#40: a code-block example verdict is skipped ($r)" || no "#40: a code-block example was read as the verdict ($r, rc=$rc)"
done
# Sheriff round 7: (m) CommonMark fences — a ~~~ line never closes a ``` fence;
printf '```text\n~~~\n## Verdict — run S02\nGREEN\n```\n## Verdict — run S02\nRED\n## Inputs\nx\n## Findings\nx\n## Artifacts\nx\n' > _reports/runs/t_mix.md
# (n) the value is the next non-blank line and never code; (o) '(run S01)' names a run;
printf '## Verdict — run S02\n    GREEN\nRED\n## Inputs\nx\n## Findings\nx\n## Artifacts\nx\n' > _reports/runs/t_ival.md
printf '## Verdict — (run S01)\nGREEN\n## Inputs\nx\n## Findings\nx\n## Artifacts\nx\n' > _reports/runs/t_paren.md
# (p) an unclosed fence hides everything after it — BLOCK, never a guess.
printf '## Verdict — run S02\nGREEN\n```\n## Inputs\nx\n## Findings\nx\n## Artifacts\nx\n' > _reports/runs/t_open.md
git add _reports/runs/t_mix.md _reports/runs/t_ival.md _reports/runs/t_paren.md _reports/runs/t_open.md 2>/dev/null
git commit -qm "fence and value-line fixtures" >/dev/null 2>&1
for c in "t_mix|report verdict is RED" "t_ival|report verdict is RED" "t_paren|only Verdict heading names another run" "t_open|unclosed code fence"; do
  r="${c%%|*}"; want="${c#*|}"
  jl S02 "_reports/runs/$r.md"; qx="$(QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh 2>&1)"; rc=$?
  [ "$rc" -ne 0 ] && echo "$qx" | grep -q "$want" && ! echo "$qx" | grep -q "report verdict: GREEN" \
    && ok "#40: $r BLOCKS ($want)" || no "#40: $r did not block as '$want' (rc=$rc): $(echo "$qx" | grep -iE 'verdict|fence' | head -1)"
done
# Stand-in review for sheriff round 8 (strict grammar): every row is <run_id>|<GREEN|RED|BLOCK>|
# <report as a printf format>. BLOCK = any refusal that is not "report verdict: GREEN".
S='## Inputs\nx\n## Findings\nnone\n## Artifacts\nok\n'; vc=0
while IFS='|' read -r vid want fmt; do
  vc=$((vc+1)); f="_reports/runs/t_v$vc.md"; printf "$fmt" > "$f"
  git add "$f" 2>/dev/null; git commit -qm "verdict grammar case $vc" >/dev/null 2>&1
  jl "$vid" "$f"; qx="$(QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh 2>&1)"; rc=$?
  case "$want" in
    GREEN) [ "$rc" -eq 0 ] && echo "$qx" | grep -q "report verdict: GREEN" ;;
    RED)   [ "$rc" -ne 0 ] && echo "$qx" | grep -q "report verdict is RED" ;;
    BLOCK) [ "$rc" -ne 0 ] && ! echo "$qx" | grep -q "report verdict: GREEN" ;;
  esac && ok "#40 grammar case $vc → $want" || no "#40 grammar case $vc expected $want (rc=$rc): $(echo "$qx" | grep -iE 'verdict|fence' | head -1) — $fmt"
done <<EOF
t1|RED|## Verdict\n<!-- one of: GREEN ✅ / YELLOW 🟡 / RED 🔴 — on the header line or the next;\n     the gate reads both -->\nRED 🔴\n$S
t1|BLOCK|## Verdict\nNot GREEN — 2 tests fail\n$S
S02|RED|## Verdict — run S02 (S01 was GREEN)\nRED 🔴\n$S
s-S02|BLOCK|**Verdict — run s-S01:** GREEN\n**Verdict — run s-S02:** RED\n$S
t1|BLOCK|Previous step S01 verdict: GREEN\n## Final verdict\nRED\n$S
t1|RED|## Verdict\n \tGREEN\nRED\n$S
t1|BLOCK|\`\`\`inline\`\`\` note\n## Verdict\nRED\n\`\`\`\n## Verdict\nGREEN\n$S
t1|GREEN|## Verdict\nGREEN\n## Inputs\nx\n## Findings\nnone\n## Artifacts\n- \`\`\`\n  make test\n  \`\`\`\n
S02|GREEN|## Verdict (after the second run of the suite)\nGREEN\n$S
t1|GREEN|## Verdict\n\`\`\`\n\$ make test\nPASS\n\`\`\`\nGREEN\n$S
t1|GREEN|## Verdict\nGREEN ✅ — all good\n$S
t1|RED|## Verdict: RED 🔴\n$S
026-add-login-S02|GREEN|### Verdict — run 026-add-login-S02\n\nGREEN\n## Inputs\n\`\`\`\nnpm test\n\`\`\`\n## Findings\nnone\n## Artifacts\nok\n
t1|GREEN|# Run\n- **Verdict:** 🟢 GREEN — published live\n$S
t1|GREEN|**Date:** 2026-09-20 · **Row:** NORMAL · **Verdict:** GREEN · **Builder:** orchestrator\n$S
t1|RED|Previous step S01 verdict: GREEN\n## Final verdict\nRED\n$S
t1|BLOCK|- Verdict: GREEN (S01)\n- Verdict: RED (S02)\n$S
t1|BLOCK|## Verdict\n~~GREEN~~ RED — regression found\n$S
t1|BLOCK|## Verdict\nGREEN → RED\n$S
RED|BLOCK|## Verdict — run RED\nRED — tests failed; previous result was GREEN\n$S
t1|GREEN|## Verdict\nGREEN — security GREEN, functional GREEN\n$S
S02|BLOCK|## Verdict — run S02 \`<!--\`\nRED\n\`-->\` GREEN\n$S
t1|BLOCK|Status <!--\nVerdict: GREEN\n--> pending\n\nResult: RED\n$S
t1|BLOCK|> <!--\n> Verdict: GREEN\n> -->\n\nResult: RED\n$S
S02|BLOCK|1. <!--\n   ## Verdict — run S02: GREEN\n   -->\n\n## Verdict — run S01: RED\n$S
t1|GREEN|<!-- a note -->\r\n## Verdict: GREEN\r\n$S
t1|GREEN|## Verdict: GREEN\n\n- Verdict confirmed.\n---\n$S
t1|BLOCK|## Verdict: ~~GREEN~~\n$S
t1|BLOCK|## Verdict\n~~GREEN~~ BLOCKED — gate refused\n$S
t1|BLOCK|## Verdict: \`<!--\` RED \`-->\` GREEN\n$S
t1|RED|## Verdict: <!-- GREEN -->\nRED\n$S
t1|BLOCK|<!-- note --> ## Verdict: GREEN\n## Verdict: RED\n$S
t1|BLOCK|Verdict\n---\nRED\n\n## Verdict\nGREEN\n$S
t1|GREEN|## Verdict: GREEN ✅\n<!-- One of GREEN ✅ / YELLOW 🟡 / RED 🔴,\n     on the heading line -->\n$S
EOF
# Head check, v8.3.29: the SHIPPED template must pass its own reader, LF and CRLF — its
# research comment opened mid-line and closed on the next, which the new reader BLOCKS.
for nl in lf crlf; do
  f="_reports/runs/t_tpl_$nl.md"
  awk '/^```markdown$/{p=1;next} /^```$/{p=0} p' "$ROOT/docs/RUN_REPORT_TEMPLATE.md" > "$f"
  [ "$nl" = crlf ] && sed -i 's/$/\r/' "$f"
  git -c core.autocrlf=false add "$f" 2>/dev/null; git commit -qm "the shipped template, $nl" >/dev/null 2>&1
  jl t1 "$f"; qx="$(QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh 2>&1)"; rc=$?
  [ -s "$f" ] && echo "$qx" | grep -q "report verdict: GREEN" \
    && ok "#40: the shipped RUN_REPORT_TEMPLATE reads GREEN through its own reader ($nl)" \
    || no "#40: the shipped template is not read as GREEN ($nl): $(echo "$qx" | grep -iE 'verdict|comment|fence' | head -1)"
done
jl t1 _reports/runs/t_green.md
# (h) an executable (100755) report is a regular file and is accepted.
cp _reports/runs/t_green.md _reports/runs/t_exec.md; git add _reports/runs/t_exec.md 2>/dev/null
git update-index --chmod=+x _reports/runs/t_exec.md 2>/dev/null; git commit -qm "exec report" >/dev/null 2>&1
jl t1 _reports/runs/t_exec.md; qx="$(QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && ok "#40: a report committed as 100755 is accepted" || no "#40: a 100755 report was refused (rc=$rc): $(echo "$qx" | grep '✗' | head -1)"
# (e) latest.json paths are exact: "t  sp.md" (two spaces) never reads "t sp.md".
printf '## Verdict\nGREEN\n## Inputs\nx\n## Findings\nx\n## Artifacts\nx\n' > "_reports/runs/t sp.md"
git add "_reports/runs/t sp.md" 2>/dev/null; git commit -qm "one-space report" >/dev/null 2>&1
jl t1 "_reports/runs/t  sp.md"; qx="$(QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && echo "$qx" | grep -q "not a regular file committed in HEAD" \
  && ok "#40: a report path is taken exactly (two spaces never read the one-space file)" || no "#40: the report path was normalised (rc=$rc)"
jl t1 _reports/runs/t_green.md

# -- 7r. spec lint (v8.3.28, #35 D) — the spec latest.json names, format 2 only --
# Every variant gets a fresh specs/tN directory, so no fixture is ever removed.
sn=0
spec_begin(){ sn=$((sn+1)); SD="specs/t$sn"; mkdir -p "$SD/research"
  printf '# Spec\n- **Spec id:** t%s\n- **Spec format:** %s\n\n## Steps\n' "$sn" "${1:-2}" > "$SD/spec.md"; }
step(){ printf '### %s — x\n- **Kind:** %s\n- **Research:** %s\n- **Deliverable:** %s\n- **DoD:** %s\n- **Row:** NORMAL\n\n' "$@" >> "$SD/spec.md"; }
brief(){ # $1 step, $2 regex of the lines to leave out of an otherwise complete brief
  printf '# %s — q\nOptions: A | B\nRecommendation: A — why\nEvidence:\n- claim — repo path x\nWhat would change this recommendation: a check\nRejected because: B — no\nConfidence: high\nSpent: 1 searches, 0 fetches, 0 experiments\n' "$1" \
    | grep -vE "${2:-^\$^}" > "$SD/research/$1.md"; }
spec_gate(){ printf '## Non-goals\n- none\n' >> "$SD/spec.md"
  git add "$SD" >/dev/null 2>&1; git commit -qm "spec variant $sn" >/dev/null 2>&1
  jl t1 _reports/runs/t_green.md ",\"spec\":\"$SD/spec.md\""
  qx="$(QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh 2>&1)"; rc=$?; }
spec_begin; brief S01; step S01 choice "$SD/research/S01.md" src/a.py 'pytest -q passes'; step S02 build — src/b.py 'make test passes'; spec_gate
[ "$rc" -eq 0 ] && echo "$qx" | grep -q "spec lint: $SD/spec.md — 2 step(s), 1 choice" \
  && ok "#35: a valid format-2 spec (choice + brief, build) passes the lint" || no "#35: a valid spec was refused (rc=$rc): $(echo "$qx" | grep 'spec lint' | head -2 | tr '\n' ' ')"
spec_begin; printf '### S01 — x\n- **Deliverable:** a\n- **DoD:** b\n\n' >> "$SD/spec.md"; spec_gate
[ "$rc" -ne 0 ] && echo "$qx" | grep -q "spec lint: S01: Kind is missing" && ok "#35: a step without Kind BLOCKS" || no "#35: a step without Kind passed (rc=$rc)"
spec_begin; step S01 choice — a b; spec_gate
[ "$rc" -ne 0 ] && echo "$qx" | grep -q "Kind choice needs a Research brief" && ok "#35: Kind choice without a research brief BLOCKS" || no "#35: choice without a brief passed (rc=$rc)"
spec_begin; brief S01 '^What would change'; step S01 choice "$SD/research/S01.md" a b; spec_gate
[ "$rc" -ne 0 ] && echo "$qx" | grep -q "has no 'What would change this recommendation:' line" && ok "#35: a brief with no falsifier line BLOCKS" || no "#35: a brief without 'What would change' passed (rc=$rc)"
spec_begin; brief S01 '^- claim'; step S01 choice "$SD/research/S01.md" a b; spec_gate
[ "$rc" -ne 0 ] && echo "$qx" | grep -q "has zero Evidence lines" && ok "#35: a brief with zero Evidence lines BLOCKS" || no "#35: a brief without evidence passed (rc=$rc)"
spec_begin; for n in S01 S02 S03; do brief $n; step $n choice "$SD/research/$n.md" a b; done; spec_gate
[ "$rc" -ne 0 ] && echo "$qx" | grep -q "split: design spec first" && ok "#35: a third choice step BLOCKS with the split message" || no "#35: 3 choice steps passed (rc=$rc)"
spec_begin; brief S01; step S01 fix "$SD/research/S01.md" a b; spec_gate
[ "$rc" -eq 0 ] && echo "$qx" | grep -q "research on a fix = scope creep" && ok "#35: research on a fix WARNs and does not block" || no "#35: fix + research: no warning, or it blocked (rc=$rc)"
spec_begin; step S01 build — a b; printf ' ### S02 — x\n- **Kind:** choice\n- **Deliverable:** a\n- **DoD:** b\n\n' >> "$SD/spec.md"; spec_gate
[ "$rc" -ne 0 ] && echo "$qx" | grep -q "S02: Kind choice needs a Research brief" && ok "#35: an indented step heading is still a step (sheriff)" || no "#35: ' ### S02' hid a step from the lint (rc=$rc)"
# (sheriff round 7) a ``` line inside a ```` fence does not close it, so S02 is still a step
spec_begin; step S01 build — a b; printf '````markdown\n```\n````\n### S02 — x\n- **Kind:** choice\n- **Deliverable:** a\n- **DoD:** b\n```text\nexample\n```\n\n' >> "$SD/spec.md"; spec_gate
[ "$rc" -ne 0 ] && echo "$qx" | grep -q "S02: Kind choice needs a Research brief" && ok "#35: a shorter fence inside a longer one does not hide the next step" || no "#35: a nested fence hid S02 (rc=$rc)"
for h in '```sh``` marks shell examples.\n\n### S02 — x' '###  S02 — x' '###\tS02 — x'; do   # stand-in review
  spec_begin; step S01 build — a b; printf "$h"'\n- **Kind:** choice\n- **Deliverable:** a\n- **DoD:** b\n\n' >> "$SD/spec.md"; spec_gate
  [ "$rc" -ne 0 ] && echo "$qx" | grep -q "S02: Kind choice needs a Research brief" && ok "#35: S02 stays a step: $h" || no "#35: S02 hidden from the lint (rc=$rc): $h"
done
spec_begin; step S01 build — a b; printf '```\n### S02 — x\n' >> "$SD/spec.md"; spec_gate
[ "$rc" -ne 0 ] && echo "$qx" | grep -q "unclosed code fence" && ok "#35: an unclosed fence in a spec BLOCKS" || no "#35: an unclosed fence passed (rc=$rc)"
spec_begin; step S01 build — src/c.py 'the request timeout is 30 s'; spec_gate
[ "$rc" -eq 0 ] && echo "$qx" | grep -q "constant or formula" && ok "#35: a bare number next to a timeout in a build step WARNs" || no "#35: trigger-1 lint silent, or it blocked (rc=$rc)"
spec_begin 1; step S01 build — a b; spec_gate
[ "$rc" -eq 0 ] && echo "$qx" | grep -q "spec lint skipped" && ok "#35: a pre-v8.3.28 spec is named as not linted, and does not block" || no "#35: an old-format spec blocked or went silent (rc=$rc)"
# Security review: a lint that crashes has not passed (a non-UTF-8 byte used to kill the
# python silently, and the gate went GREEN with no lint line at all).
spec_begin; step S01 build — a 'b'; printf '\377\n' >> "$SD/spec.md"; spec_gate
[ "$rc" -ne 0 ] && echo "$qx" | grep -q "spec lint crashed" && ok "#35: a spec the lint cannot read BLOCKS (crash is not a pass)" || no "#35: a crashing lint passed (rc=$rc)"
# ...and a lint that stops before its completion line (an interrupt) BLOCKS (sheriff): a
# python3 shim drops the lint's last line; every other python3 call passes through.
realpy="$(command -v python3)"; shim="$(mktemp -d)"
printf '#!/usr/bin/env bash\nif [ "$1" = "-" ]; then s="$(cat)"; case "$s" in *LINT-END*) s="$(printf "%%s\\n" "$s" | grep -v "LINT-END")" ;; esac\n  printf "%%s\\n" "$s" | "%s" "$@"; else exec "%s" "$@"; fi\n' "$realpy" "$realpy" > "$shim/python3"; chmod +x "$shim/python3"
spec_begin; step S01 build — a b; printf '## Non-goals\n- none\n' >> "$SD/spec.md"
git add "$SD" >/dev/null 2>&1; git commit -qm "spec variant $sn" >/dev/null 2>&1
# (sheriff round 3) a committed DIRECTORY named as the spec BLOCKS — git show lists a tree
jl t1 _reports/runs/t_green.md ",\"spec\":\"$SD\""
qx="$(QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && echo "$qx" | grep -q "not a repo-relative file committed in HEAD" && ok "#35: a directory named as the spec BLOCKS (not skipped as an old spec)" || no "#35: a tree passed as the spec (rc=$rc)"
for sp in "$SD/" "$SD/."; do   # (sheriff round 4) ls-tree lists a child blob for these
  jl t1 _reports/runs/t_green.md ",\"spec\":\"$sp\""
  qx="$(QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh 2>&1)"; rc=$?
  [ "$rc" -ne 0 ] && echo "$qx" | grep -q "not a repo-relative file committed in HEAD" && ok "#35: spec '$sp' (a tree in disguise) BLOCKS" || no "#35: spec '$sp' passed (rc=$rc)"
done
jl t1 _reports/runs/t_green.md ",\"spec\":\"$SD/spec.md\""
qx="$(PATH="$shim:$PATH" QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && echo "$qx" | grep -q "spec lint did not finish" && ok "#35: a lint without its completion line BLOCKS" || no "#35: an unfinished lint passed (rc=$rc)"
find "$shim" -mindepth 0 -delete 2>/dev/null
# ...and the spec latest.json names must be a repo-relative file committed in HEAD.
spec_begin; step S01 build — a b; printf '## Non-goals\n- none\n' >> "$SD/spec.md"
jl t1 _reports/runs/t_green.md ",\"spec\":\"$SD/spec.md\""
qx="$(QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && echo "$qx" | grep -q "not a repo-relative file committed in HEAD" && ok "#35: an uncommitted spec BLOCKS" || no "#35: an uncommitted spec was linted from the working tree (rc=$rc)"
git add "$SD" >/dev/null 2>&1; git commit -qm "spec variant $sn" >/dev/null 2>&1
jl t1 _reports/runs/t_green.md

# -- 8. sheriff-review.sh -- reviewer-isolation guarantees --
# These are the STATIC half. The wrapper exists because the same guarantees, written as
# prose in .claude/commands/sheriff.md, lost a different boundary to each of two review
# rounds (2026-08-30). Prose cannot be regression-tested; this can.
# The BEHAVIOURAL half -- does the sandbox actually block, does --cd actually stop
# project-context loading -- needs a live model call and lives OUT of the gate, in
# scripts/integration/sheriff-isolation-live.sh. A capability probe proves a flag EXISTS,
# never that it BEHAVES; do not let these assertions imply otherwise.
echo "-- 8. sheriff-review.sh (reviewer isolation) --"
sr(){ printf 'ACCEPTANCE: t\nDIFF: t\n' | bash scripts/sheriff-review.sh "$@" >/dev/null 2>&1; echo $?; }
# In this sandbox there is no git repo, so the wrapper falls back to $PWD as its root --
# which makes "$SANDBOX/..." the inside-the-repo case. Hermetic, no real repo touched.
[ "$(sr --author codex)" = "4" ] \
  && ok "refuses a same-vendor author (codex reviewing codex)" || no "accepted a SAME-VENDOR review"
[ "$(sr --author OpenAI)" = "4" ] \
  && ok "same-vendor check is case-insensitive and covers vendor aliases" || no "vendor alias slipped through"
[ "$(sr)" = "2" ] \
  && ok "requires --author (cannot review without knowing the author)" || no "ran without --author"
[ "$(sr --author claude --out "$SANDBOX/findings.txt")" = "3" ] \
  && ok "refuses a findings path inside the repo root" || no "accepted a findings path INSIDE the repo"
[ "$(sr --author claude --package "$SANDBOX/pkg.txt")" = "3" ] \
  && ok "refuses a package path inside the repo root" || no "accepted a package path INSIDE the repo"
[ "$(sr --author claude --scratch "$SANDBOX/scratch")" = "3" ] \
  && ok "refuses a scratch dir inside the repo root" || no "accepted a scratch dir INSIDE the repo"
# Relative spellings must not evade containment: ./findings.txt resolves into the root too.
[ "$(sr --author claude --out ./findings.txt)" = "3" ] \
  && ok "containment resolves relative paths (./ does not evade it)" || no "a relative path evaded containment"
# ORDERING GUARANTEE: the vendor check must precede every filesystem and CLI step, so it
# stays provable on a machine with no codex installed. Same-vendor + a repo path must
# report the vendor refusal (4), never the path refusal (3).
[ "$(sr --author codex --out "$SANDBOX/findings.txt")" = "4" ] \
  && ok "vendor check runs BEFORE path/CLI work (provable without codex)" || no "vendor check is not first"
# POSITIVE PATH, via a STUB CLI. It must NOT depend on a real codex being installed:
# a CI worker without one would otherwise pass the gate with -C, -s or -o deleted from
# the wrapper, i.e. the guarantee that matters most would be asserted exactly nowhere.
# The stub advertises the required flags and records the argv it was called with, so
# these assertions test the REAL invocation path and run identically on every machine.
STUBDIR="$(mktemp -d)"
mkdir -p "$STUBDIR/good" "$STUBDIR/crippled"
write_stub(){ # $1 = dir, $2 = 1 to advertise --cd
  {
    echo '#!/usr/bin/env bash'
    echo 'if [ "${1:-}" = "exec" ] && [ "${2:-}" = "--help" ]; then'
    echo '  echo "  -s, --sandbox <MODE>"'
    [ "$2" = "1" ] && echo '  echo "  -C, --cd <DIR>"'
    echo '  echo "      --skip-git-repo-check"'
    echo '  echo "      --ephemeral"'
    echo '  echo "      --ignore-rules"'
    echo '  echo "  -o, --output-last-message <FILE>"'
    echo '  exit 0'
    echo 'fi'
    echo 'printf "%s\n" "$*" > "$STUB_ARGV_LOG"'
    echo 'out=""; prev=""'
    echo 'for a in "$@"; do [ "$prev" = "-o" ] && out="$a"; prev="$a"; done'
    echo 'cat >/dev/null'
    echo '[ -n "$out" ] && printf "STUB FINDINGS\n" > "$out"'
    echo 'exit 0'
  } > "$1/codex"
  chmod +x "$1/codex"
}
write_stub "$STUBDIR/good" 1
write_stub "$STUBDIR/crippled" 0
# A CLI that RENAMED an isolation flag: advertises --cd-root, not --cd. A substring
# match would score this as compliant and run a review with no work-root isolation.
mkdir -p "$STUBDIR/renamed"
{
  echo '#!/usr/bin/env bash'
  echo 'if [ "${1:-}" = "exec" ] && [ "${2:-}" = "--help" ]; then'
  echo '  echo "  -s, --sandbox <MODE>"'
  echo '  echo "  -C, --cd-root <DIR>"'
  echo '  echo "      --skip-git-repo-check"'
  echo '  echo "  -o, --output-last-message <FILE>"'
  echo '  exit 0'
  echo 'fi'
  echo 'exit 0'
} > "$STUBDIR/renamed/codex"
chmod +x "$STUBDIR/renamed/codex"

export STUB_ARGV_LOG="$STUBDIR/argv.txt"
SR_SCRATCH="$(mktemp -d)"
SR_RC="$(printf 'ACCEPTANCE: t\nDIFF: t\n' \
  | PATH="$STUBDIR/good:$PATH" bash scripts/sheriff-review.sh \
      --author claude --scratch "$SR_SCRATCH" >/dev/null 2>&1; echo $?)"
[ "$SR_RC" = "0" ] && ok "wrapper drives the CLI end-to-end against a stub (rc 0)" \
                   || no "wrapper failed against a conforming stub (rc=$SR_RC)"
ARGV="$(cat "$STUB_ARGV_LOG" 2>/dev/null)"
miss=""
for f in "-s read-only" "--skip-git-repo-check" "-C " "-o " "--ephemeral"; do
  printf '%s' "$ARGV" | grep -q -- "$f" || miss="$miss [$f]"
done
[ -z "$miss" ] && ok "every isolation flag reaches the CLI (recorded argv, not a dry run)" \
              || no "wrapper did NOT pass isolation flag(s):$miss"
printf '%s' "$ARGV" | grep -q "empty-workroot" \
  && ok "reviewer work root is a dedicated empty dir" || no "no isolated work root in argv"
[ -d "$SR_SCRATCH/empty-workroot" ] && [ -z "$(ls -A "$SR_SCRATCH/empty-workroot" 2>/dev/null)" ] \
  && ok "the work root handed to the reviewer is genuinely EMPTY" \
  || no "work root missing or not empty (project context could load)"
case "$ARGV" in
  *"-o $SANDBOX"*) no "findings path pointed INSIDE the repo root" ;;
  *) ok "findings path stayed outside the repo root" ;;
esac
# FAIL CLOSED FOR AUTOMATION ONLY: a CLI lacking a required isolation flag must refuse
# to auto-run (exit 5) AND still print the manual package, so the review is gated but
# never silently skipped.
SR_RC="$(printf 'ACCEPTANCE: t\nDIFF: t\n' \
  | PATH="$STUBDIR/crippled:$PATH" bash scripts/sheriff-review.sh --author claude >/dev/null 2>&1; echo $?)"
[ "$SR_RC" = "5" ] && ok "a CLI missing an isolation flag fails closed for automation (exit 5)" \
                   || no "weakened CLI did not fail closed (rc=$SR_RC)"
# NOTE: capture, then grep. Under `set -o pipefail` a direct `... | grep -q` inherits
# the wrapper's deliberate non-zero exit (5), so the assertion would fail on a wrapper
# that behaved perfectly.
MANUAL_OUT="$(printf 'ACCEPTANCE: t\nDIFF: t\n' \
  | PATH="$STUBDIR/crippled:$PATH" bash scripts/sheriff-review.sh --author claude 2>/dev/null)"
printf '%s' "$MANUAL_OUT" | grep -q "MANUAL SHERIFF PACKAGE" \
  && ok "gated automation still emits the manual package (review not skipped)" \
  || no "automation gated AND no manual package - the review would be silently dropped"
printf '%s' "$MANUAL_OUT" | grep -q "You are SHERIFF" \
  && ok "the manual package carries the full reviewer contract" \
  || no "manual package emitted without the reviewer contract"
# --probe: the standalone readiness check the upgrade procedure calls. Same exit
# contract as a real run (0 available / 5 missing a required flag / 6 no CLI) and it
# must need NO author and NO stdin, or it cannot be used before a review exists.
PROBE_OUT="$(PATH="$STUBDIR/good:$PATH" bash scripts/sheriff-review.sh --probe 2>&1)"
PROBE_RC="$(PATH="$STUBDIR/good:$PATH" bash scripts/sheriff-review.sh --probe >/dev/null 2>&1; echo $?)"
[ "$PROBE_RC" = "0" ] && ok "--probe reports automation available against a conforming CLI" \
                      || no "--probe failed on a conforming CLI (rc=$PROBE_RC)"
printf '%s' "$PROBE_OUT" | grep -q "EXIST, not that they BEHAVE" \
  && ok "--probe states its own limit (flags exist != flags behave)" \
  || no "--probe overclaims: no exists-vs-behaves caveat"
PROBE_RC="$(PATH="$STUBDIR/crippled:$PATH" bash scripts/sheriff-review.sh --probe >/dev/null 2>&1; echo $?)"
[ "$PROBE_RC" = "5" ] && ok "--probe fails closed on a CLI missing an isolation flag (exit 5)" \
                      || no "--probe did not fail closed on a weakened CLI (rc=$PROBE_RC)"
PROBE_OUT="$(PATH="$STUBDIR/crippled:$PATH" bash scripts/sheriff-review.sh --probe 2>&1)"
printf '%s' "$PROBE_OUT" | grep -q -- "--cd" \
  && ok "--probe names the missing flag" || no "--probe did not name the missing flag"

# A RENAMED flag must not pass as present: --cd-root is not --cd.
PROBE_RC="$(PATH="$STUBDIR/renamed:$PATH" bash scripts/sheriff-review.sh --probe >/dev/null 2>&1; echo $?)"
[ "$PROBE_RC" = "5" ] && ok "a renamed isolation flag (--cd-root) does NOT satisfy --cd" \
                      || no "substring match accepted a renamed flag (rc=$PROBE_RC)"
SR_RC="$(printf 'ACCEPTANCE: t\nDIFF: t\n' \
  | PATH="$STUBDIR/renamed:$PATH" bash scripts/sheriff-review.sh --author claude >/dev/null 2>&1; echo $?)"
[ "$SR_RC" = "5" ] && ok "the review path also rejects a renamed isolation flag" \
                   || no "review ran against a CLI missing the real flag (rc=$SR_RC)"

# The wrapper must name its CLI ONCE. Two spellings of the same tool is how a probe
# ends up validating a different executable than the review runs (sheriff round 5).
# Comments and the closed AUTHOR-IDENTITY set legitimately contain the vendor word, so
# this looks only at lines that INVOKE something.
STRAY="$(grep -nE '(^|[^_[:alnum:]"$])codex[[:space:]]+(exec|--version)|command -v codex' \
         scripts/sheriff-review.sh | grep -v '^[0-9]*:#' || true)"
[ -z "$STRAY" ] && ok "wrapper invokes its CLI through \$SHERIFF_TOOL only (one spelling)" \
                || no "wrapper still hard-codes the CLI name somewhere: $STRAY"

# Closed-set author identities: an unrecognised spelling must fail CLOSED, and a
# same-vendor spelling that matches no wildcard must still be caught.
[ "$(sr --author ChatGPT)" = "4" ] && ok "closed set catches a same-vendor alias (ChatGPT)" \
                                  || no "same-vendor alias ChatGPT was ACCEPTED"
[ "$(sr --author o3)" = "4" ] && ok "closed set catches a same-vendor model codename (o3)" \
                             || no "same-vendor codename o3 was ACCEPTED"
[ "$(sr --author totally-unknown-thing)" = "4" ] \
  && ok "an unrecognised author identity fails CLOSED" || no "unknown author identity was accepted"
# A different vendor must get THROUGH the vendor gate. Asserted against the crippled
# stub so the gate can never fire a real, billable model call: exit 5 means the vendor
# check passed and it stopped later, at the capability probe.
SR_RC="$(printf 'ACCEPTANCE: t\nDIFF: t\n' \
  | PATH="$STUBDIR/crippled:$PATH" bash scripts/sheriff-review.sh --author gemini >/dev/null 2>&1; echo $?)"
[ "$SR_RC" = "5" ] && ok "a genuinely different vendor passes the vendor gate" \
                   || no "a different vendor was wrongly refused (rc=$SR_RC)"
# #95 (v8.3.31): in a Claude Code session the default scratch lands in that session's own
# scratchpad, and nothing else stays in the temp folder (the private dir goes on exit).
# An id that is not a UUID is never a path component: the old place stays.
SESS_TMP="$(mktemp -d)"; sid="0b5e1d2c-1111-4222-8333-444455556666"
mkdir -p "$SESS_TMP/claude/D--x-proj/$sid"
sr_sess(){ printf 'ACCEPTANCE: t\nDIFF: t\n' | TMPDIR="$SESS_TMP" CLAUDE_CODE_SESSION_ID="$1" \
  PATH="$STUBDIR/good:$PATH" bash scripts/sheriff-review.sh --author claude 2>/dev/null | tail -1; }
out="$(sr_sess "$sid")"
case "$out" in
  "$SESS_TMP/claude/D--x-proj/$sid/scratchpad/sheriff."*/sheriff-findings.txt)
    grep -q "STUB FINDINGS" "$out" && [ "$(ls -A "$SESS_TMP")" = "claude" ] \
      && ok "#95: in a session the sheriff scratch lands in its scratchpad; nothing else in the temp folder" \
      || no "#95: session scratch: no findings, or the temp folder holds more: $(ls -A "$SESS_TMP" | tr '\n' ' ')" ;;
  *) no "#95: in a session the sheriff scratch did not land in the session's scratchpad: $out" ;;
esac
out="$(sr_sess "../$sid")"
case "$out" in
  "$SESS_TMP"/tmp.*/sheriff-findings.txt) ok "#95: a session id that is not a UUID is never a path (old place)" ;;
  *) no "#95: a malformed session id steered the sheriff scratch: $out" ;;
esac
# ...and a link on the path is never followed (sheriff, v8.3.31): a scratchpad link, then a
# linked project dir. The old place is used and nothing lands in the link's target. A
# junction on Windows (Git Bash `ln -s` copies), a symlink elsewhere.
mklink_dir(){ # $1 = link, $2 = target
  ln -s "$2" "$1" 2>/dev/null && [ -L "$1" ] && return 0
  rm -rf "$1" 2>/dev/null
  command -v cygpath >/dev/null 2>&1 \
    && cmd //c "mklink /J $(cygpath -w "$1") $(cygpath -w "$2")" >/dev/null 2>&1 && [ -L "$1" ]; }
OUTSIDE="$(mktemp -d)"; pad="$SESS_TMP/claude/D--x-proj/$sid/scratchpad"
rm -rf "$pad"
if mklink_dir "$pad" "$OUTSIDE"; then
  out="$(sr_sess "$sid")"
  case "$out" in
    "$SESS_TMP"/tmp.*/sheriff-findings.txt) [ -z "$(ls -A "$OUTSIDE")" ] \
        && ok "#95: a scratchpad that is a link is not followed (old place, link target untouched)" \
        || no "#95: the scratchpad link's target received: $(ls -A "$OUTSIDE" | tr '\n' ' ')" ;;
    *) no "#95: a scratchpad link steered the sheriff scratch: $out" ;;
  esac
  rm -f "$pad"; rm -rf "$SESS_TMP/claude/D--x-proj"
  mkdir -p "$OUTSIDE/$sid"
  if mklink_dir "$SESS_TMP/claude/D--link-proj" "$OUTSIDE"; then
    out="$(sr_sess "$sid")"
    case "$out" in
      "$SESS_TMP"/tmp.*/sheriff-findings.txt) [ -z "$(ls -A "$OUTSIDE/$sid")" ] \
          && ok "#95: a linked project dir above the session is not followed (old place)" \
          || no "#95: the linked project dir received: $(ls -A "$OUTSIDE/$sid" | tr '\n' ' ')" ;;
      *) no "#95: a linked project dir steered the sheriff scratch: $out" ;;
    esac
    rm -f "$SESS_TMP/claude/D--link-proj"
  else
    no "#95: a project-dir link could not be made although a scratchpad link could"
  fi
else
  ok "#95: link cases SKIPPED (no symlink or junction support here) - known limit"
fi
find "$OUTSIDE" -mindepth 0 -delete 2>/dev/null
find "$SESS_TMP" -mindepth 0 -delete 2>/dev/null
# #95 (v8.3.31): the state-patch self-test leaves nothing in the temp folder (it left 2
# dirs per run; release-check runs it twice).
SP_TMP="$(mktemp -d)"
spx="$(TMPDIR="$SP_TMP" python3 scripts/state-patch.py --self-test 2>&1)"
case "$spx" in
  *"self-test: GREEN"*) [ -z "$(ls -A "$SP_TMP")" ] \
      && ok "#95: state-patch --self-test is GREEN and leaves nothing in the temp folder" \
      || no "#95: state-patch --self-test left: $(ls -A "$SP_TMP" | tr '\n' ' ')" ;;
  *) no "#95: state-patch --self-test is not GREEN: $(echo "$spx" | tail -2 | tr '\n' ' ')" ;;
esac
find "$SP_TMP" -mindepth 0 -delete 2>/dev/null

find "$STUBDIR" -mindepth 0 -delete 2>/dev/null
find "$SR_SCRATCH" -mindepth 0 -delete 2>/dev/null
# The canonical prompt can never be dropped: with no prompt file reachable (this sandbox
# has none), the wrapper still writes the SHERIFF contract into the package. Round 2 found
# the manual path silently shipping without the acceptance criteria; same class.
PKGDIR="$(mktemp -d)"
printf 'ACCEPTANCE: marker-acc\nDIFF: marker-diff\n' \
  | bash scripts/sheriff-review.sh --author claude --scratch "$PKGDIR" --dry-run >/dev/null 2>&1
if [ -f "$PKGDIR/sheriff-package.txt" ]; then
  grep -q "You are SHERIFF" "$PKGDIR/sheriff-package.txt" \
    && ok "package always carries the SHERIFF contract (fallback when the file is absent)" \
    || no "package shipped WITHOUT the reviewer contract"
  grep -q "marker-acc" "$PKGDIR/sheriff-package.txt" && grep -q "marker-diff" "$PKGDIR/sheriff-package.txt" \
    && ok "package carries the acceptance criteria AND the diff from stdin" \
    || no "package dropped the criteria or the diff"
else
  no "wrapper wrote no package at all"
fi
find "$PKGDIR" -mindepth 0 -delete 2>/dev/null

# --mode (v8.3.26): picks the PROMPT and nothing else. Closed set; a decision packet gets
# the decision contract, from the prompt file when present and from the fallback when not;
# a review never gets the decision contract. (--dry-run: nothing is invoked.)
[ "$(sr --author claude --mode bogus)" = "2" ] \
  && ok "--mode is a closed set (an unknown mode is refused)" || no "an unknown --mode was accepted"
PKGDIR="$(mktemp -d)"
printf 'QUESTION: marker-q\n' \
  | bash scripts/sheriff-review.sh --author claude --mode decision --scratch "$PKGDIR" --dry-run >/dev/null 2>&1
grep -q "ONE engineering decision" "$PKGDIR/sheriff-package.txt" 2>/dev/null && grep -q "marker-q" "$PKGDIR/sheriff-package.txt" \
  && ok "decision mode: package carries the decision contract + the packet (fallback)" \
  || no "decision mode: package lacks the decision contract or the packet"
find "$PKGDIR" -mindepth 0 -delete 2>/dev/null
mkdir -p .claude/skills/cross-review/prompts
printf '# t\n```\nDECISION-FILE-MARKER\n```\n' > .claude/skills/cross-review/prompts/sheriff-decision.md
printf '# t\n```\nREVIEW-FILE-MARKER\n```\n' > .claude/skills/cross-review/prompts/sheriff-review.md
for m in decision review; do
  PKGDIR="$(mktemp -d)"
  printf 'x\n' | bash scripts/sheriff-review.sh --author claude --mode "$m" --scratch "$PKGDIR" --dry-run >/dev/null 2>&1
  M="$(echo "$m" | tr a-z A-Z)"; O="REVIEW"; [ "$m" = "review" ] && O="DECISION"
  grep -q "$M-FILE-MARKER" "$PKGDIR/sheriff-package.txt" 2>/dev/null && ! grep -q "$O-FILE-MARKER" "$PKGDIR/sheriff-package.txt" \
    && ok "--mode $m prepends ITS prompt file, not the other one" || no "--mode $m picked the wrong prompt file"
  find "$PKGDIR" -mindepth 0 -delete 2>/dev/null
done
rm -rf .claude/skills   # later assertions expect NO prompt file in the sandbox
# A trailing value flag used to spin the argument loop forever (`shift 2` with one left).
[ "$(printf 'x\n' | timeout 10 bash scripts/sheriff-review.sh --author claude --mode >/dev/null 2>&1; echo $?)" = "2" ] \
  && ok "a value flag with no value is refused (exit 2), not an endless loop" \
  || no "a trailing value flag hangs or is accepted"
# Nothing secret-shaped leaves the machine (v8.3.26): refused before the CLI call and before
# any manual package. The key is assembled at run time — no secret-shaped literal in this file.
FAKEKEY="sk-$(printf 'x%.0s' $(seq 1 24))"
PKGDIR="$(mktemp -d)"
SR_OUT="$(printf 'DIFF: key=%s\n' "$FAKEKEY" \
  | bash scripts/sheriff-review.sh --author claude --scratch "$PKGDIR" --dry-run 2>&1; echo "rc=$?")"
case "$SR_OUT" in
  *"rc=2") ok "a package holding secret-shaped text is refused (exit 2)" ;;
  *) no "a secret-shaped package was NOT refused: ${SR_OUT##*rc=}" ;;
esac
printf '%s' "$SR_OUT" | grep -q -- "$FAKEKEY" \
  && no "the refused package's secret was printed" || ok "the refused package is not printed anywhere"
find "$PKGDIR" -mindepth 0 -delete 2>/dev/null

# -- round 6 (2026-08-31): three findings from the sheriff's pass on the v8.3.7 upgrade --

# [A] --ephemeral is now a REQUIRED cap, not hardening. Without it codex persists the
# session -- and the session IS the diff under review -- so a build lacking it must gate
# automation to the manual package instead of warning and running anyway.
mkdir -p "$STUBDIR/noeph"
{
  echo '#!/usr/bin/env bash'
  echo 'if [ "${1:-}" = "exec" ] && [ "${2:-}" = "--help" ]; then'
  echo '  echo "  -s, --sandbox <MODE>"'
  echo '  echo "  -C, --cd <DIR>"'
  echo '  echo "      --skip-git-repo-check"'
  echo '  echo "      --ignore-rules"'
  echo '  echo "  -o, --output-last-message <FILE>"'
  echo '  exit 0'
  echo 'fi'
  echo 'exit 0'
} > "$STUBDIR/noeph/codex"
chmod +x "$STUBDIR/noeph/codex"
NOEPH_RC="$(printf 'ACCEPTANCE: t\nDIFF: t\n' \
  | PATH="$STUBDIR/noeph:$PATH" bash scripts/sheriff-review.sh --author claude >/dev/null 2>&1; echo $?)"
[ "$NOEPH_RC" = "5" ] && ok "a CLI without --ephemeral fails closed (exit 5), not warn-and-run" \
                      || no "--ephemeral is not enforced as a required cap (rc=$NOEPH_RC)"
NOEPH_OUT="$(printf 'ACCEPTANCE: t\nDIFF: t\n' \
  | PATH="$STUBDIR/noeph:$PATH" bash scripts/sheriff-review.sh --author claude 2>&1 >/dev/null)"
printf '%s' "$NOEPH_OUT" | grep -q -- "--ephemeral" \
  && ok "the refusal names --ephemeral as the missing cap" || no "refusal did not name --ephemeral"
# The good stub was deleted with $STUBDIR above; rebuild it, or this assertion
# silently tests whatever real codex is on PATH (the round-3 class: an assertion
# that only runs when a real CLI is installed) and fails on a CLI-free machine.
mkdir -p "$STUBDIR/good"; write_stub "$STUBDIR/good" 1
PROBE_EPH="$(PATH="$STUBDIR/good:$PATH" bash scripts/sheriff-review.sh --probe 2>&1)"
printf '%s' "$PROBE_EPH" | grep -E '^ *required:' | grep -q -- "--ephemeral" \
  && ok "--probe reports --ephemeral under required, matching the decision" \
  || no "--probe still advertises --ephemeral as optional hardening"
PROBE_EPH_RC="$(PATH="$STUBDIR/noeph:$PATH" bash scripts/sheriff-review.sh --probe >/dev/null 2>&1; echo $?)"
[ "$PROBE_EPH_RC" = "5" ] && ok "--probe fails closed on a CLI without --ephemeral" \
                          || no "--probe passed a CLI missing a required cap (rc=$PROBE_EPH_RC)"

# [B] A PRE-EXISTING target is refused. Containment resolves PATHS, so a hard link --
# a second name for a tracked file's inode -- sits happily outside the repo and still
# writes into it. One rule ("the wrapper only writes targets it creates") closes the
# hard link, the symlink, and the pre-planted file without telling them apart.
EXDIR="$(mktemp -d)"
: > "$EXDIR/already-there.txt"
[ "$(sr --author claude --out "$EXDIR/already-there.txt")" = "3" ] \
  && ok "refuses a findings path that already exists" || no "wrote through a PRE-EXISTING findings file"
[ "$(sr --author claude --package "$EXDIR/already-there.txt")" = "3" ] \
  && ok "refuses a package path that already exists" || no "wrote through a PRE-EXISTING package file"
# The finding's own scenario, end to end: a hard link OUTSIDE the repo aimed at a file
# INSIDE it. Containment cannot see it; the exists rule refuses it. ln fails on some
# filesystems (FAT/exFAT, some network mounts) -- self-skip rather than fake a pass.
echo "canary-content" > "$SANDBOX/tracked-target.txt"
if ln "$SANDBOX/tracked-target.txt" "$EXDIR/hardlink.txt" 2>/dev/null; then
  [ "$(sr --author claude --out "$EXDIR/hardlink.txt")" = "3" ] \
    && ok "refuses an external HARD LINK pointing at a repo file (the round-6 finding)" \
    || no "a hard link into the repo was accepted as a findings path"
  [ "$(cat "$SANDBOX/tracked-target.txt")" = "canary-content" ] \
    && ok "the hard-linked repo file is byte-identical after the refusal" \
    || no "the repo file was modified through the hard link"
else
  ok "hard-link case SKIPPED (this filesystem cannot create hard links) - known limit"
fi
# A symlink stays refused too: the exists rule must not have replaced that guarantee.
if ln -s "$SANDBOX/tracked-target.txt" "$EXDIR/symlink.txt" 2>/dev/null; then
  [ "$(sr --author claude --out "$EXDIR/symlink.txt")" = "3" ] \
    && ok "still refuses a symlink findings path" || no "symlink refusal regressed"
else
  ok "symlink case SKIPPED (no symlink support here) - known limit"
fi
# A REUSED --scratch dir must not silently overwrite the previous review's record.
REUSE="$(mktemp -d)"
printf 'ACCEPTANCE: t\nDIFF: t\n' \
  | PATH="$STUBDIR/good:$PATH" bash scripts/sheriff-review.sh --author claude --scratch "$REUSE" >/dev/null 2>&1
REUSE_RC="$(printf 'ACCEPTANCE: t\nDIFF: t\n' \
  | PATH="$STUBDIR/good:$PATH" bash scripts/sheriff-review.sh --author claude --scratch "$REUSE" >/dev/null 2>&1; echo $?)"
[ "$REUSE_RC" = "3" ] && ok "a reused --scratch dir refuses rather than overwrite the prior findings" \
                      || no "a second run clobbered the previous review in the same scratch (rc=$REUSE_RC)"
find "$EXDIR" "$REUSE" -mindepth 0 -delete 2>/dev/null

# [B2] round 6b, from the sheriff's pass on 6a: package and findings must not be the
# same file. Neither exists at check time, so the exists-rule alone cannot see it; the
# reviewer would get one file as both stdin and -o and overwrite what it must read.
COLL="$(mktemp -d)"
[ "$(sr --author claude --package "$COLL/same.txt" --out "$COLL/same.txt")" = "3" ] \
  && ok "refuses package and findings pointing at the SAME file" \
  || no "accepted one file as both the package and the findings target"
[ "$(sr --author claude --package "$COLL/p.txt" --out "$COLL/./p.txt")" = "3" ] \
  && ok "the same-file check resolves ./ spellings too" || no "a ./ spelling evaded the same-file check"
[ "$(sr --author claude --package "$COLL/a.txt" --out "$COLL/b.txt")" != "3" ] \
  && ok "two genuinely different paths are still accepted" || no "the same-file check refuses a legitimate run"
find "$COLL" -mindepth 0 -delete 2>/dev/null

# [B3] the target is RESERVED, not merely checked: after a refusal-free run the wrapper
# must have created the files itself. A check that walks away leaves a swap window.
RESV="$(mktemp -d)"
printf 'ACCEPTANCE: t\nDIFF: t\n' \
  | PATH="$STUBDIR/good:$PATH" bash scripts/sheriff-review.sh --author claude --scratch "$RESV" >/dev/null 2>&1
[ -f "$RESV/sheriff-package.txt" ] && ok "the wrapper created its own package target" \
                                   || no "no package file was created in the scratch dir"
find "$RESV" -mindepth 0 -delete 2>/dev/null

# [C] The live canary asserts repo CONTENT, not `git status` text. It needs a model call
# so the gate cannot run the canary itself -- but the manifest function is pure shell,
# so the gate CAN lift it out and prove it actually detects mutations. Grepping for the
# function name would only prove the name exists; the sheriff flagged exactly that.
CANARY_F="$SCRIPTS/integration/sheriff-isolation-live.sh"
if grep -qE '^[^#]*BEFORE="\$\(git status' "$CANARY_F"; then
  no "live canary still captures git status as its before-state"
else
  ok "the weak git-status before-state is gone from the canary"
fi
MREPO="$(mktemp -d)"
MTMP="$(mktemp -d)"
(
  cd "$MREPO" || exit 1
  git init -q . 2>/dev/null
  git config user.email t@t; git config user.name t
  mkdir -p sub; printf 'one\n' > sub/tracked.sh; printf 'ignored\n' > .gitignore
  printf 'skipme\n' > skipme; echo "skipme" >> .gitignore
  git add -A >/dev/null 2>&1; git commit -qm init >/dev/null 2>&1
  printf 'untracked\n' > loose.txt
  # shellcheck disable=SC1090
  eval "$(sed -n '/^repo_manifest(){/,/^}/p' "$CANARY_F")"
  base="$(repo_manifest "$MTMP/b")"
  # 1. content of a TRACKED file
  printf 'two\n' > sub/tracked.sh
  [ "$(repo_manifest "$MTMP/1")" != "$base" ] && echo PASS || echo FAIL
  printf 'one\n' > sub/tracked.sh
  # 2. content of an existing UNTRACKED file (the hash-tracked-only version missed this)
  printf 'changed\n' > loose.txt
  [ "$(repo_manifest "$MTMP/2")" != "$base" ] && echo PASS || echo FAIL
  printf 'untracked\n' > loose.txt
  # 3. MODE change on a tracked file, every byte identical
  chmod 755 sub/tracked.sh 2>/dev/null
  if [ -x sub/tracked.sh ]; then
    [ "$(repo_manifest "$MTMP/3")" != "$base" ] && echo PASS || echo FAIL
    chmod 644 sub/tracked.sh
  else
    echo SKIP
  fi
  # 4. a NEW file appearing
  printf 'new\n' > added.txt
  [ "$(repo_manifest "$MTMP/4")" != "$base" ] && echo PASS || echo FAIL
  find added.txt -maxdepth 0 -delete
  # 5. a tracked file DELETED
  find sub/tracked.sh -maxdepth 0 -delete
  [ "$(repo_manifest "$MTMP/5")" != "$base" ] && echo PASS || echo FAIL
  printf 'one\n' > sub/tracked.sh; chmod 644 sub/tracked.sh 2>/dev/null
  # 6. a GITIGNORED file must NOT trip it (or every build would look like a leak)
  printf 'noise\n' > skipme
  [ "$(repo_manifest "$MTMP/6")" = "$base" ] && echo PASS || echo FAIL
  # 7. stable across repeated calls with nothing changed
  [ "$(repo_manifest "$MTMP/7")" = "$base" ] && echo PASS || echo FAIL
  # 8. an mtime-only touch: identical bytes, identical mode. It must NOT trip the
  #    manifest. Regression test for the 127/2 flake: "ls -ldn" prints mtime at MINUTE
  #    resolution, so every restore above moved the hash whenever the clock happened to
  #    tick mid-block - cases 6 and 7 were a coin flip against the wall clock, ~1 run in
  #    25. The touch here forces the worst case deterministically, so it cannot come back.
  find . -path ./.git -prune -o -type f -print0 2>/dev/null | xargs -0 -r touch -d "2020-03-04 05:06:07" --
  [ "$(repo_manifest "$MTMP/8")" = "$base" ] && echo PASS || echo FAIL
  # 9. negative control: the SAME probe against the pre-fix function (--time-style
  #    stripped back out) must TRIP. Without this, assertion 8 would also pass on a
  #    manifest that had stopped looking at file metadata altogether.
  eval "$(sed -n '/^repo_manifest(){/,/^}/p' "$CANARY_F" | sed 's/ --time-style=+//; s/^repo_manifest(){/repo_manifest_pre8(){/')"
  nbase="$(repo_manifest_pre8 "$MTMP/n1")"
  find . -path ./.git -prune -o -type f -print0 2>/dev/null | xargs -0 -r touch -d "2021-07-08 09:10:11" --
  [ "$(repo_manifest_pre8 "$MTMP/n2")" != "$nbase" ] && echo PASS || echo FAIL
  # 10. FAIL-CLOSED guard (sheriff round 9). "--time-style=+" is GNU-only. If ls rejects
  #     it, stderr is discarded and a { ... } | sha256sum pipeline whose middle stream
  #     vanished still returns a valid-looking hash - so the canary would compare two
  #     hashes that describe nothing and report GREEN. Doctor the flag into one no ls
  #     accepts: the function must produce NOTHING, not a hash.
  eval "$(sed -n '/^repo_manifest(){/,/^}/p' "$CANARY_F" | sed 's/--time-style=+/--time-style=+ --no-such-flag-zz/; s/^repo_manifest(){/repo_manifest_nometa(){/')"
  [ -z "$(repo_manifest_nometa "$MTMP/x" 2>/dev/null)" ] && echo PASS || echo FAIL
) > "$MTMP/results.txt" 2>/dev/null
mres(){ sed -n "$1p" "$MTMP/results.txt" 2>/dev/null; }
c=1
for label in "a tracked file's content" "an existing UNTRACKED file's content" \
             "a MODE change with identical bytes" "a newly added file" \
             "a deleted tracked file"; do
  case "$(mres $c)" in
    PASS) ok "canary manifest detects $label" ;;
    SKIP) ok "canary manifest: $label SKIPPED (no exec-bit support here) - known limit" ;;
    *)    no "canary manifest MISSES $label - a review could mutate it and score GREEN" ;;
  esac
  c=$((c+1))
done
[ "$(mres 6)" = "PASS" ] && ok "canary manifest ignores gitignored files (no false RED)" \
                         || no "canary manifest trips on gitignored files - it would cry wolf every build"
[ "$(mres 7)" = "PASS" ] && ok "canary manifest is stable when nothing changed" \
                         || no "canary manifest is non-deterministic - unusable as an assertion"
[ "$(mres 8)" = "PASS" ] && ok "canary manifest ignores an mtime-only touch (same bytes, same mode)" \
                         || no "canary manifest hashes mtime - it is a coin flip against the wall clock"
[ "$(mres 9)" = "PASS" ] && ok "negative control: the pre-fix manifest DOES trip on mtime alone" \
                         || no "mtime negative control is inert - assertion 8 proves nothing"
[ "$(mres 10)" = "PASS" ] && ok "manifest FAILS CLOSED when ls cannot produce metadata (no silent hash)" \
                          || no "manifest still returns a hash with the metadata stream gone - fail-open"
find "$MREPO" "$MTMP" -mindepth 0 -delete 2>/dev/null


# -- round 8 (2026-08-31): sheriff round-7 findings [1]-[3], closed field-first --

# [A] round-7 [2] — the reviewer CLI must never be handed a CALLER-CONTROLLED output
# path. Reserving $OUT and then letting the CLI reopen it by name left the exclusive
# create undoable in between. The wrapper now points -o at a private file inside a 0700
# mktemp dir and copies the result out through the descriptor it has held since creating
# it. Proven on the recorded argv, not on the source.
R8DIR="$(mktemp -d)"
export STUB_ARGV_LOG="$STUBDIR/argv-r8.txt"
R8_RC="$(printf 'ACCEPTANCE: r8-marker\nDIFF: r8-marker\n' \
  | PATH="$STUBDIR/good:$PATH" bash scripts/sheriff-review.sh --author claude \
      --scratch "$R8DIR/scratch" --out "$R8DIR/findings.txt" \
      --package "$R8DIR/pkg.txt" >/dev/null 2>&1; echo $?)"
[ "$R8_RC" = "0" ] && ok "wrapper still runs end-to-end with caller-supplied --out/--package" \
                   || no "the copy-out rework broke the normal path (rc=$R8_RC)"
R8_ARGV="$(cat "$STUB_ARGV_LOG" 2>/dev/null)"
case "$R8_ARGV" in
  *"-o $R8DIR/findings.txt"*)
    no "the CLI was handed the caller's --out path — round-7 [2] is NOT closed" ;;
  *"-o "*)
    ok "the CLI never receives the caller's --out path (it writes inside a private dir)" ;;
  *)
    no "no -o reached the CLI at all — the argv assertion above is testing nothing" ;;
esac
[ "$(cat "$R8DIR/findings.txt" 2>/dev/null)" = "STUB FINDINGS" ] \
  && ok "the findings still reach the caller's --out, copied through the held descriptor" \
  || no "the caller's --out did not receive the reviewer's output"
grep -q "You are SHERIFF" "$R8DIR/pkg.txt" 2>/dev/null \
  && ok "the caller's --package still receives the full reviewer contract" \
  || no "the caller's --package is missing the reviewer contract"
grep -q "r8-marker" "$R8DIR/pkg.txt" 2>/dev/null \
  && ok "the caller's --package still carries the criteria and diff from stdin" \
  || no "the caller's --package lost the stdin content"

# The private directory is an implementation detail, so ask the wrapper where it is
# rather than guessing: --dry-run prints the exact command it would run.
R8_DRY="$(printf 'ACCEPTANCE: r8\nDIFF: r8\n' \
  | PATH="$STUBDIR/good:$PATH" bash scripts/sheriff-review.sh --author claude \
      --scratch "$R8DIR/s2" --dry-run 2>/dev/null)"
R8_PRIV="$(printf '%s' "$R8_DRY" | sed -n 's/.* -o \([^ ]*\) - <.*/\1/p' | head -1)"
[ -n "$R8_PRIV" ] && ok "--dry-run names the private findings path the CLI would be given" \
                  || no "--dry-run does not show where the CLI would actually write"
case "$R8_PRIV" in
  "$R8DIR"*) no "the private path lives inside the caller's --scratch — it is not private" ;;
  "") : ;;
  *) ok "the private working dir is independent of --scratch (caller cannot place it)" ;;
esac
[ -n "$R8_PRIV" ] && [ ! -e "$R8_PRIV" ] \
  && ok "the private working dir is removed when the wrapper exits (no findings left behind)" \
  || no "the wrapper left its private working dir on disk after exiting"

# [B] round-7 [1] — $PKG must never be REOPENED BY NAME. The exclusive descriptor makes
# the WRITE unswappable; reading the same pathname back afterwards handed the window
# straight back. Everything that reads the package now reads the private copy.
# A grep alone proves only that today's spelling is absent, so the detector is put
# through a negative control: a doctored copy that reinstates the read must be CAUGHT.
pkg_reads(){ grep -nE '^[^#]*(cat[[:space:]]+"\$PKG"|<[[:space:]]*"\$PKG")' "$1"; }
if pkg_reads scripts/sheriff-review.sh >/dev/null 2>&1; then
  no "the wrapper still reads \$PKG by name: $(pkg_reads scripts/sheriff-review.sh | head -2 | tr '\n' ' ')"
else
  ok "no code path reopens the caller's package path for reading (round-7 [1])"
fi
R8_DOCTORED="$R8DIR/doctored-wrapper.sh"
sed 's|cat "$PRIV_PKG"|cat "$PKG"|' scripts/sheriff-review.sh > "$R8_DOCTORED"
if pkg_reads "$R8_DOCTORED" >/dev/null 2>&1; then
  ok "the reopen detector actually fires on a doctored copy (negative control)"
else
  no "the reopen detector is inert — it would not catch the read being reinstated"
fi

# [C] round-7 [3] — the live canary's repo manifest was built from `git ls-files`, which
# never lists git's own administrative state, so `.git/` was invisible: a planted
# .git/hooks/pre-commit is code execution on the author's next commit and it scored GREEN.
# The canary gained a sibling git_manifest(). It needs no model call, so the gate can lift
# it out and prove it DETECTS mutations — grepping for the function name would only prove
# the name exists, which is the round-6 lesson about this exact file.
R8_CANARY="$SCRIPTS/integration/sheriff-isolation-live.sh"
grep -qE '^[^#]*BEFORE_GIT="\$\(git_manifest' "$R8_CANARY" \
  && grep -qE '^[^#]*AFTER_GIT="\$\(git_manifest' "$R8_CANARY" \
  && ok "the canary CALLS git_manifest before and after the review (not just defines it)" \
  || no "git_manifest is defined but never called across the review — the check is decorative"
grep -q "GIT METADATA MUTATED" "$R8_CANARY" \
  && ok "the canary fails loudly when git metadata changes" \
  || no "no failure message for a git-metadata mutation"

GREPO="$(mktemp -d)"; GTMP="$(mktemp -d)"
(
  cd "$GREPO" || exit 1
  git init -q . 2>/dev/null
  git config user.email t@t; git config user.name t
  mkdir -p sub; printf 'one\n' > sub/tracked.sh
  git add -A >/dev/null 2>&1; git commit -qm init >/dev/null 2>&1
  # shellcheck disable=SC1090
  eval "$(sed -n '/^git_manifest(){/,/^}/p' "$R8_CANARY")"
  base="$(git_manifest "$GTMP/b")"
  # 1. a file planted in the hooks directory
  printf '#!/bin/sh\necho pwned\n' > .git/hooks/pre-commit
  [ "$(git_manifest "$GTMP/1")" != "$base" ] && echo PASS || echo FAIL
  # 2. removing it puts the manifest back. This is the REVERT proof, and it runs before
  #    anything irreversible, so the later probes cannot borrow its result.
  find .git/hooks/pre-commit -maxdepth 0 -delete 2>/dev/null
  [ "$(git_manifest "$GTMP/2")" = "$base" ] && echo PASS || echo FAIL
  # 3. a MODE change on a hook, every byte identical. Self-skips where the filesystem has
  #    no exec-bit semantics: Git Bash on NTFS reports .git/hooks files -rwxr-xr-x whatever
  #    chmod says, and on such a platform the bit is not what gates execution anyway.
  printf '#!/bin/sh\n' > .git/hooks/pre-commit
  chmod 644 .git/hooks/pre-commit 2>/dev/null; m644="$(git_manifest "$GTMP/3a")"
  chmod 755 .git/hooks/pre-commit 2>/dev/null; m755="$(git_manifest "$GTMP/3b")"
  if [ "$m644" != "$m755" ]; then echo PASS
  elif [ "$(ls -ldn .git/hooks/pre-commit 2>/dev/null | cut -c1-10)" = "-rwxr-xr-x" ]; then echo SKIP
  else echo FAIL; fi
  find .git/hooks/pre-commit -maxdepth 0 -delete 2>/dev/null
  # 4. a .git/config change (core.hooksPath, an alias, a filter - all persistence)
  git config sheriff.canary probe
  [ "$(git_manifest "$GTMP/4")" != "$base" ] && echo PASS || echo FAIL
  # 5. a new loose ref
  git branch -q canary-ref 2>/dev/null
  [ "$(git_manifest "$GTMP/5")" != "$base" ] && echo PASS || echo FAIL
  # 6. refs moved into packed-refs - the same logical refs, different files on disk
  git pack-refs --all >/dev/null 2>&1
  [ "$(git_manifest "$GTMP/6")" != "$base" ] && echo PASS || echo FAIL
  # 7. a STAGED change: the index, hashed logically as `git ls-files --stage`
  printf 'staged\n' > sub/tracked.sh; git add sub/tracked.sh >/dev/null 2>&1
  [ "$(git_manifest "$GTMP/7")" != "$base" ] && echo PASS || echo FAIL
  # 8. .git/info/exclude - it changes what the OTHER manifest is willing to see, so a
  #    mutation there is a mutation to the check itself
  printf 'noise\n' >> .git/info/exclude
  [ "$(git_manifest "$GTMP/8")" != "$base" ] && echo PASS || echo FAIL
  # 9. determinism: two consecutive calls over an UNCHANGED repo must agree. Asserted on
  #    the mutated state on purpose - this is the property that decides whether the canary
  #    cries wolf, and it has to hold whatever the repo happens to contain. Restoring the
  #    pristine state instead would test git's own reversibility, not the manifest's.
  d1="$(git_manifest "$GTMP/9a")"; d2="$(git_manifest "$GTMP/9b")"
  [ "$d1" = "$d2" ] && echo PASS || echo FAIL
) > "$GTMP/results.txt" 2>/dev/null
gres(){ sed -n "$1p" "$GTMP/results.txt" 2>/dev/null; }
c=1
for label in "a file planted in .git/hooks" "REVERT - removing it restores the manifest" \
             "a hook MODE change with identical bytes" "a .git/config change" \
             "a new loose ref" "refs moved into packed-refs" "a STAGED index change" \
             "a .git/info/exclude change"; do
  case "$(gres $c)" in
    PASS) ok "git manifest: $label" ;;
    SKIP) ok "git manifest: $label SKIPPED (no exec-bit semantics here) - known limit" ;;
    *)    no "git manifest MISSES $label - a review could do it and score GREEN" ;;
  esac
  c=$((c+1))
done
[ "$(gres 9)" = "PASS" ] && ok "git manifest is deterministic across consecutive calls (it will not cry wolf)" \
                         || no "git manifest is non-deterministic - it would report a mutation that never happened"
find "$GREPO" "$GTMP" "$R8DIR" -mindepth 0 -delete 2>/dev/null


# -- round 8b (2026-08-31): the sheriff's pass on round 8a returned four more --

# [D] round-8 finding [1], the one this round INTRODUCED. Holding fd 8 open on the
# caller's --out from its own O_EXCL creation closed the pathname window and opened a
# worse one: a child inherits the descriptor, and an inherited fd is a write primitive
# that no pathname rule and no `-s read-only` can take back. Proven with a stub that
# TRIES the write, plus a negative control on a wrapper with the fix removed.
#
# ROUND 10 (2026-09-01) - this block's own control was rebuilt. On the template
# maintainer's Linux box the assertion "fd 8 LEAKED into the reviewer" failed once in
# ~8 full-suite runs and could not be diagnosed afterwards. Root cause, found by forcing
# each case rather than by looping: the old assertion was
#   [ "$(cat $STUB_FD8_LOG)" = "CLOSED" ] || no "fd 8 LEAKED"
# with the wrapper's rc and stderr both discarded (2>&1 into /dev/null). EVERY refusal
# path leaves that log EMPTY - a pre-existing --out (exit 3), a build missing a required
# flag (exit 5), no CLI on PATH (exit 6), an unwritable scratch (exit 2), a findings path
# inside the repo (exit 3) - and empty is not "CLOSED", so all of them printed a SECURITY
# FINDING THAT NEVER HAPPENED and threw away the one line that said why. Same class as
# round 9's empty-manifest fail-open, one turn worse: it fails LOUD in the wrong
# direction, which is exactly how a single unexplainable failure ends up in a changelog.
# The second assertion was its mirror image and a true fail-OPEN: `grep -q FD8-LEAK
# findings.txt || ok "no reviewer-written bytes reached --out"` PASSES when the wrapper
# refused and no findings file exists at all - proving nothing, loudly.
# Both now go through fd8_verdict(), which separates "did the CLI run" from "what did it
# report", and four forced controls below prove the verdicts are distinguishable.
export STUB_FD8_LOG="$STUBDIR/fd8.txt"
# Own argv log: the old block inherited whatever an earlier block had exported, which is
# the round-6 class - an assertion whose meaning depends on a distant line.
export STUB_ARGV_LOG="$STUBDIR/argv-fd8.txt"
mkdir -p "$STUBDIR/leaky"
{
  echo '#!/usr/bin/env bash'
  echo 'if [ "${1:-}" = "exec" ] && [ "${2:-}" = "--help" ]; then'
  echo '  echo "  -s, --sandbox <MODE>"'
  echo '  echo "  -C, --cd <DIR>"'
  echo '  echo "      --skip-git-repo-check"'
  echo '  echo "      --ephemeral"'
  echo '  echo "      --ignore-rules"'
  echo '  echo "  -o, --output-last-message <FILE>"'
  echo '  exit 0'
  echo 'fi'
  echo 'printf "%s\n" "$*" > "$STUB_ARGV_LOG"'
  echo 'out=""; prev=""'
  echo 'for a in "$@"; do [ "$prev" = "-o" ] && out="$a"; prev="$a"; done'
  echo 'cat >/dev/null'
  # sheriff round-10 [2]: a failed WRITE is not proof the descriptor is absent - ENOSPC,
  # a quota, or any I/O error on an INHERITED fd 8 would have scored CLOSED and falsely
  # certified the guarantee. Existence is now probed with a redirection that copies the
  # descriptor and writes no bytes; only then is the write attempted, and a present-but-
  # unwritable fd is its own verdict, never CLOSED.
  echo 'if : >&8 2>/dev/null; then'
  echo '  if printf "FD8-LEAK\n" >&8 2>/dev/null; then echo LEAK > "$STUB_FD8_LOG"; else echo LEAK-NOWRITE > "$STUB_FD8_LOG"; fi'
  echo 'else'
  echo '  echo CLOSED > "$STUB_FD8_LOG"'
  echo 'fi'
  echo '[ -n "$out" ] && printf "STUB FINDINGS\n" > "$out"'
  echo 'exit 0'
} > "$STUBDIR/leaky/codex"
chmod +x "$STUBDIR/leaky/codex"
# A stub that RUNS but never reaches the fd-8 probe (a CLI that dies mid-run). It must
# not be reported as a leak either - it is a run with no verdict.
mkdir -p "$STUBDIR/mute"
{
  echo '#!/usr/bin/env bash'
  echo 'if [ "${1:-}" = "exec" ] && [ "${2:-}" = "--help" ]; then'
  echo '  echo "  -s, --sandbox <MODE>"'
  echo '  echo "  -C, --cd <DIR>"'
  echo '  echo "      --skip-git-repo-check"'
  echo '  echo "      --ephemeral"'
  echo '  echo "      --ignore-rules"'
  echo '  echo "  -o, --output-last-message <FILE>"'
  echo '  exit 0'
  echo 'fi'
  echo 'printf "%s\n" "$*" > "$STUB_ARGV_LOG"'
  echo 'out=""; prev=""'
  echo 'for a in "$@"; do [ "$prev" = "-o" ] && out="$a"; prev="$a"; done'
  echo 'cat >/dev/null'
  echo '[ -n "$out" ] && printf "STUB FINDINGS\n" > "$out"'
  echo 'exit 0'
} > "$STUBDIR/mute/codex"
chmod +x "$STUBDIR/mute/codex"

# fd8_verdict - classify ONE run. $1 = the wrapper's exit code; the two stub logs supply
# the rest. Four outcomes, and only one of them is a security finding:
#   RAN-CLOSED  the CLI ran and could NOT write to fd 8 (the guarantee holds)
#   RAN-LEAK    the CLI ran and DID write to fd 8 (the real finding)
#   RAN-MUTE    the CLI ran but wrote no verdict (inconclusive, never a leak)
#   NO-RUN      the CLI was never invoked - the wrapper refused or failed first
# sheriff round-10 [1], CRITICAL and the one that mattered: the first version returned
# NO-RUN for ANY nonzero wrapper exit, BEFORE looking at the logs. A reviewer that ran,
# inherited fd 8, recorded LEAK and then made the wrapper exit nonzero afterwards (it
# exits 1 whenever the findings file comes back empty) would have had its leak silenced
# as "never ran" - the rebuild would have hidden the very finding it exists to catch.
# Whether the CLI RAN is now decided by the argv log alone; the exit code is context for
# the message, never an input to the verdict.
fd8_verdict(){
  if [ ! -s "$STUB_ARGV_LOG" ]; then echo "NO-RUN"; return; fi
  case "$(cat "$STUB_FD8_LOG" 2>/dev/null)" in
    CLOSED)       echo "RAN-CLOSED" ;;
    LEAK)         echo "RAN-LEAK" ;;
    LEAK-NOWRITE) echo "RAN-LEAK-PRESENT" ;;
    *)            echo "RAN-MUTE" ;;
  esac
}
# sheriff round-10 [3]: fd8_run is always called inside command substitution, so it runs
# in a SUBSHELL and a plain FD8_RC= assignment dies with it - the refusal code would have
# been empty in exactly the diagnostic message this round exists to print. The rc travels
# through a file, like the other two logs, and the caller reads it back.
# sheriff round-10 second pass [1]: the wrapper is launched through an ABSOLUTE bash
# resolved once, before any control starts filtering $PATH. A control that removes the
# directory holding bash would otherwise fail to launch the wrapper at all, and a
# never-launched wrapper writes no argv log - which scores NO-RUN and passes the control
# without ever reaching the refusal it claims to test. Vacuous-pass class, again.
FD8_BASH="$(command -v bash)"
fd8_run(){ # $1 = stub dir, $2 = wrapper to run, $3 = --out path, $4 = --scratch path
  : > "$STUB_FD8_LOG"; : > "$STUB_ARGV_LOG"
  printf 'ACCEPTANCE: fd8\nDIFF: fd8\n' \
    | PATH="$1:$PATH" "$FD8_BASH" "$2" --author claude \
        --scratch "$4" --out "$3" >/dev/null 2>"$FD8ERR"
  echo $? > "$FD8RC"
  fd8_verdict
}
fd8_rc(){ cat "$FD8RC" 2>/dev/null; }

FD8DIR="$(mktemp -d)"
FD8ERR="$FD8DIR/wrapper.err"
FD8RC="$FD8DIR/wrapper.rc"
FD8_V="$(fd8_run "$STUBDIR/leaky" scripts/sheriff-review.sh "$FD8DIR/findings.txt" "$FD8DIR/s")"
case "$FD8_V" in
  RAN-CLOSED)       ok "the reviewer CLI does NOT inherit the writable descriptor on --out (fd 8 closed for the child)" ;;
  RAN-LEAK)         no "fd 8 LEAKED into the reviewer - /dev/fd/8 is a write primitive into the caller's file" ;;
  RAN-LEAK-PRESENT) no "fd 8 was INHERITED by the reviewer (its write failed for another reason, which is not containment)" ;;
  NO-RUN)           no "fd-8 check INCONCLUSIVE, NOT a leak: the CLI never ran (wrapper rc=$(fd8_rc): $(head -1 "$FD8ERR" 2>/dev/null | cut -c1-100))" ;;
  *)                no "fd-8 check INCONCLUSIVE, NOT a leak: the CLI ran but wrote no fd-8 verdict" ;;
esac
# The leaked-bytes assertion is only meaningful once the run happened - otherwise "no
# leaked bytes" is just "no file", which is what made the old version a fail-open.
if [ "$FD8_V" = "NO-RUN" ]; then
  no "leaked-bytes check INCONCLUSIVE: no run happened, so an absent findings file proves nothing"
elif grep -q "FD8-LEAK" "$FD8DIR/findings.txt" 2>/dev/null; then
  no "reviewer-written bytes reached the caller's --out through the inherited descriptor"
else
  ok "no reviewer-written bytes reached the caller's --out"
fi

# Negative control 1: strip the fd close and the SAME stub must report a LEAK. Without
# this, "CLOSED" is indistinguishable from a stub whose write simply failed for another
# reason. The doctored copy must sit in the SAME scripts/ directory as the real one. With
# no git checkout the wrapper takes the parent of its own scripts/ as the protected root
# (sheriff-review.sh:176), so a copy placed anywhere else changes that root and the run is
# refused with exit 3 before the stub is ever called - the control would then "pass" by
# never running, which is the round-3 class all over again.
FD8_DOCTORED="scripts/nofdclose-r8.sh"
sed 's/ 8>&- 9>&-//' scripts/sheriff-review.sh > "$FD8_DOCTORED"
[ "$(fd8_run "$STUBDIR/leaky" "$FD8_DOCTORED" "$FD8DIR/findings2.txt" "$FD8DIR/s2")" = "RAN-LEAK" ] \
  && ok "the fd-leak detector fires on a wrapper with the close removed (negative control)" \
  || no "the fd-leak detector is inert - it would not notice the close being deleted"

# Negative control 2a, round 10 - the CONTROL FOR THE CRITICAL FIX. The sheriff's pass on
# this rebuild found that keying "did it run" off the wrapper's exit code would silence a
# real leak: a reviewer can inherit fd 8, write through it, and THEN make the wrapper exit
# nonzero (it exits 1 whenever the findings come back empty), which the first version
# scored as NO-RUN. Forced here, both halves at once: the fd-close is removed AND the stub
# writes no findings, so the wrapper really does exit nonzero on a run that really did leak.
mkdir -p "$STUBDIR/leaky-empty"
sed 's|\[ -n "$out" \] && printf "STUB FINDINGS\\n" > "$out"|true|' \
  "$STUBDIR/leaky/codex" > "$STUBDIR/leaky-empty/codex"
chmod +x "$STUBDIR/leaky-empty/codex"
FD8_SILENCED="$(fd8_run "$STUBDIR/leaky-empty" "$FD8_DOCTORED" "$FD8DIR/findings2a.txt" "$FD8DIR/s2a")"
[ "$FD8_SILENCED" = "RAN-LEAK" ] \
  && ok "a leak is still reported when the wrapper exits nonzero afterwards (round-10 critical control)" \
  || no "a real leak was silenced by a nonzero wrapper exit (got $FD8_SILENCED) - the critical defect is back"
[ "$(fd8_rc)" != "0" ] \
  && ok "that control really did exercise the nonzero-exit path (rc=$(fd8_rc))" \
  || no "the nonzero-exit control never produced a nonzero exit - it proves nothing"

# Negative control 2, round 10 - the one that would have named the maintainer's failure on
# sight: a REFUSAL must never be reported as a leak. Forced by pre-creating --out (exit 3).
: > "$FD8DIR/pre-existing.txt"
[ "$(fd8_run "$STUBDIR/leaky" scripts/sheriff-review.sh "$FD8DIR/pre-existing.txt" "$FD8DIR/s3")" = "NO-RUN" ] \
  && ok "a wrapper REFUSAL is classified as no-run, never as an fd-8 leak (round-10 control)" \
  || no "a refusal is still being read as an fd-8 verdict - the round-10 defect is back"
# and the refusal must stay LEGIBLE: the reason has to survive, not be discarded.
grep -q "REFUSED" "$FD8ERR" 2>/dev/null \
  && ok "the refusal reason is captured, not discarded (the next failure is diagnosable)" \
  || no "the wrapper's refusal reason was thrown away - the next flake is undiagnosable again"

# Negative control 3, round 10 - the LEADING (unproven) hypothesis for the maintainer's
# single failure, made harmless by construction. Any transient failure of the wrapper's
# `codex exec --help` probe - a fork/exec that loses to EAGAIN under load, a noexec
# /tmp, an ENOSPC write - yields empty help, which the wrapper correctly reads as a build
# missing its required flags and refuses (exit 5). Under the OLD control that refusal
# printed "fd 8 LEAKED". Here it must be a no-run, and the reason must survive.
mkdir -p "$STUBDIR/emptyhelp"
{
  echo '#!/usr/bin/env bash'
  echo '# help that produces nothing, as a failed exec of the real CLI would'
  echo '[ "${1:-}" = "exec" ] && [ "${2:-}" = "--help" ] && exit 0'
  echo 'printf "%s\n" "$*" > "$STUB_ARGV_LOG"'
  echo 'cat >/dev/null'
  echo 'if : >&8 2>/dev/null; then echo LEAK > "$STUB_FD8_LOG"; else echo CLOSED > "$STUB_FD8_LOG"; fi'
  echo 'exit 0'
} > "$STUBDIR/emptyhelp/codex"
chmod +x "$STUBDIR/emptyhelp/codex"
[ "$(fd8_run "$STUBDIR/emptyhelp" scripts/sheriff-review.sh "$FD8DIR/findings6.txt" "$FD8DIR/s6")" = "NO-RUN" ] \
  && ok "a failed capability probe is classified as no-run, never as an fd-8 leak (round-10 control)" \
  || no "a failed probe is being scored as an fd-8 verdict - the maintainer's failure mode is still mislabelled"
grep -q "lacks required isolation flag" "$FD8ERR" 2>/dev/null \
  && ok "the failed-probe refusal names the missing flags (this is what the next flake will print)" \
  || no "a failed probe refuses without naming why - still undiagnosable"

# Negative control 4: a CLI that runs but writes no verdict is inconclusive, not a leak.
[ "$(fd8_run "$STUBDIR/mute" scripts/sheriff-review.sh "$FD8DIR/findings4.txt" "$FD8DIR/s4")" = "RAN-MUTE" ] \
  && ok "a CLI that runs without probing fd 8 is inconclusive, never a leak (round-10 control)" \
  || no "a silent CLI is being scored as an fd-8 verdict"

# Negative control 5: no reviewer CLI on PATH at all -> no-run, and again never a leak.
# sheriff round-10 [4]: the first version prepended an EMPTY directory to $PATH and called
# that "no CLI". It is not - a real codex further down $PATH is still found, so on a
# machine that has one this control invoked the REAL reviewer: environment-dependent, and
# a billable model call fired from the hook suite, which this file forbids everywhere
# else. It also passed vacuously (the real CLI writes no stub log, which reads as NO-RUN)
# - the round-3 class, an assertion that only means something when nothing is installed.
# $PATH is now filtered to drop every directory that actually holds a codex executable,
# and the removal is PROVEN before the control is allowed to mean anything.
nocli_path(){ # every $PATH entry that does not contain a codex executable
  local out="" d IFS=:
  for d in $PATH; do
    [ -n "$d" ] || continue
    if [ -x "$d/codex" ] || [ -x "$d/codex.exe" ] || [ -x "$d/codex.cmd" ]; then continue; fi
    out="$out${out:+:}$d"
  done
  printf '%s' "$out"
}
FD8_NOCLI="$(nocli_path)"
if [ -z "$FD8_NOCLI" ] || PATH="$FD8_NOCLI" command -v codex >/dev/null 2>&1; then
  no "the no-CLI control could not remove codex from PATH - it would test the real CLI, not a missing one"
else
  ok "the no-CLI control really has no codex on PATH (proven before it is trusted)"
  mkdir -p "$STUBDIR/nocli"
  FD8_NOCLI_V="$(PATH="$FD8_NOCLI" fd8_run "$STUBDIR/nocli" scripts/sheriff-review.sh "$FD8DIR/findings5.txt" "$FD8DIR/s5")"
  [ "$FD8_NOCLI_V" = "NO-RUN" ] \
    && ok "a missing reviewer CLI is classified as no-run, never as an fd-8 leak (round-10 control)" \
    || no "a missing CLI is being scored as an fd-8 verdict"
  # NO-RUN alone is not enough: a wrapper that never LAUNCHED also produces NO-RUN. The
  # control only means something if the wrapper ran far enough to refuse for the stated
  # reason, so assert the exit code and the message it is supposed to print.
  [ "$(fd8_rc)" = "6" ] \
    && ok "the no-CLI control really exercised the wrapper's missing-CLI refusal (exit 6)" \
    || no "the no-CLI control did not reach exit 6 (rc=$(fd8_rc)) - it proves nothing about that path"
  grep -q "not on PATH" "$FD8ERR" 2>/dev/null \
    && ok "the missing-CLI refusal names the reason (not a silent failure to launch)" \
    || no "no missing-CLI refusal message - the wrapper may never have started"
fi


# [E] round-8 finding [3]: core.hooksPath must be read with `--path`, or git's own ~
# expansion is skipped and the manifest watches a directory nothing runs hooks from.
grep -qE '^[^#]*git config --get --path core\.hooksPath' "$R8_CANARY" \
  && ok "core.hooksPath is read with --path (git's own ~ expansion applies)" \
  || no "core.hooksPath is read without --path - a ~-prefixed value would be taken literally"
[ "$(grep -cE '^[^#]*git config --get core\.hooksPath' "$R8_CANARY")" = "0" ] \
  && ok "no remaining plain --get read of core.hooksPath" \
  || no "a plain --get read of core.hooksPath survives somewhere in the canary"

# [F] round-8 findings [2] and [4]: index FLAGS, and the gitdir walk that replaced the
# hand-picked list. Same lift-and-run technique, a second throwaway repo.
G2REPO="$(mktemp -d)"; G2TMP="$(mktemp -d)"; G2HOOKS="$(mktemp -d)"
(
  cd "$G2REPO" || exit 1
  git init -q . 2>/dev/null
  git config user.email t@t; git config user.name t
  printf 'one\n' > tracked.txt
  git add -A >/dev/null 2>&1; git commit -qm init >/dev/null 2>&1
  # shellcheck disable=SC1090
  eval "$(sed -n '/^git_manifest(){/,/^}/p' "$R8_CANARY")"
  base="$(git_manifest "$G2TMP/b")"
  # 1. assume-unchanged: tells git to STOP NOTICING a working-tree change. ls-files --stage
  #    alone cannot see it; ls-files -v can.
  git update-index --assume-unchanged tracked.txt >/dev/null 2>&1
  [ "$(git_manifest "$G2TMP/1")" != "$base" ] && echo PASS || echo FAIL
  git update-index --no-assume-unchanged tracked.txt >/dev/null 2>&1
  # 2. skip-worktree, the other half of the same finding
  git update-index --skip-worktree tracked.txt >/dev/null 2>&1
  [ "$(git_manifest "$G2TMP/2")" != "$base" ] && echo PASS || echo FAIL
  git update-index --no-skip-worktree tracked.txt >/dev/null 2>&1
  # 3. operation state the hand-picked list missed entirely (MERGE_HEAD steers the next
  #    commit into recording a second parent)
  printf '%s\n' "$(git rev-parse HEAD)" > .git/MERGE_HEAD
  [ "$(git_manifest "$G2TMP/3")" != "$base" ] && echo PASS || echo FAIL
  find .git/MERGE_HEAD -maxdepth 0 -delete 2>/dev/null
  # 4. rerere data - replays a recorded conflict resolution into a future merge
  mkdir -p .git/rr-cache/aaaa; printf 'resolved\n' > .git/rr-cache/aaaa/preimage
  [ "$(git_manifest "$G2TMP/4")" != "$base" ] && echo PASS || echo FAIL
  find .git/rr-cache -mindepth 0 -delete 2>/dev/null
  # 5. the reflog: rewriting it is how a mutation hides from `git reflog`
  printf 'tampered\n' >> .git/logs/HEAD 2>/dev/null
  [ "$(git_manifest "$G2TMP/5")" != "$base" ] && echo PASS || echo FAIL
  # 6. core.hooksPath pointing OUT of the gitdir: the walk above cannot reach it, so the
  #    live hooks directory has to be scanned separately or a planted hook is invisible.
  git config core.hooksPath "$G2HOOKS"
  hbase="$(git_manifest "$G2TMP/6a")"
  printf '#!/bin/sh\necho pwned\n' > "$G2HOOKS/pre-commit"
  [ "$(git_manifest "$G2TMP/6b")" != "$hbase" ] && echo PASS || echo FAIL
  # 7. the object store is EXCLUDED on purpose - a loose object is inert until a ref or
  #    the index points at it. Assert the exclusion, so the claim and the code agree.
  mkdir -p .git/objects/ab; printf 'junk\n' > .git/objects/ab/canary
  [ "$(git_manifest "$G2TMP/7")" = "$(git_manifest "$G2TMP/7b")" ] && echo PASS || echo FAIL
  # 8. a *.lock file must NOT trip it, or the manifest races every concurrent git command
  lbase="$(git_manifest "$G2TMP/8a")"
  : > .git/some-op.lock
  [ "$(git_manifest "$G2TMP/8b")" = "$lbase" ] && echo PASS || echo FAIL
  # 9. an mtime-only touch inside the gitdir must NOT trip it either, and it matters
  #    MORE here than in the working tree: ordinary git commands rewrite .git mtimes
  #    constantly, so hashing them would paint a review RED for merely READING the repo.
  mbase="$(git_manifest "$G2TMP/9a")"
  find .git "$G2HOOKS" -type f -print0 2>/dev/null | xargs -0 -r touch -d "2020-03-04 05:06:07" --
  [ "$(git_manifest "$G2TMP/9b")" = "$mbase" ] && echo PASS || echo FAIL
  # 10. negative control for 9, same shape as the working-tree one.
  eval "$(sed -n '/^git_manifest(){/,/^}/p' "$R8_CANARY" | sed 's/ --time-style=+//; s/^git_manifest(){/git_manifest_pre8(){/')"
  gnbase="$(git_manifest_pre8 "$G2TMP/n1")"
  find .git "$G2HOOKS" -type f -print0 2>/dev/null | xargs -0 -r touch -d "2021-07-08 09:10:11" --
  [ "$(git_manifest_pre8 "$G2TMP/n2")" != "$gnbase" ] && echo PASS || echo FAIL
  # 11. the same fail-closed guard on this side (sheriff round 9).
  eval "$(sed -n '/^git_manifest(){/,/^}/p' "$R8_CANARY" | sed 's/--time-style=+/--time-style=+ --no-such-flag-zz/; s/^git_manifest(){/git_manifest_nometa(){/')"
  [ -z "$(git_manifest_nometa "$G2TMP/x" 2>/dev/null)" ] && echo PASS || echo FAIL
) > "$G2TMP/results.txt" 2>/dev/null
g2res(){ sed -n "$1p" "$G2TMP/results.txt" 2>/dev/null; }
c=1
for label in "an assume-unchanged index flag" "a skip-worktree index flag" \
             "MERGE_HEAD (operation state the curated list missed)" \
             "rerere data planted for a future merge" "an appended reflog entry" \
             "a hook planted via an out-of-gitdir core.hooksPath"; do
  [ "$(g2res $c)" = "PASS" ] && ok "git manifest detects $label" \
                             || no "git manifest MISSES $label - a review could do it and score GREEN"
  c=$((c+1))
done
[ "$(g2res 7)" = "PASS" ] && ok "git manifest ignores the object store, as its stated exclusion says" \
                          || no "git manifest trips on a loose object - the code and the stated limit disagree"
[ "$(g2res 8)" = "PASS" ] && ok "git manifest ignores *.lock files (it will not race a concurrent git)" \
                          || no "git manifest trips on a transient lock file - it would cry wolf"
[ "$(g2res 9)" = "PASS" ] && ok "git manifest ignores an mtime-only touch inside the gitdir" \
                          || no "git manifest hashes .git mtimes - ordinary git use would score RED"
[ "$(g2res 10)" = "PASS" ] && ok "negative control: the pre-fix git manifest DOES trip on mtime alone" \
                           || no "git-manifest mtime control is inert - assertion 9 proves nothing"
[ "$(g2res 11)" = "PASS" ] && ok "git manifest FAILS CLOSED when ls cannot produce metadata" \
                           || no "git manifest still returns a hash with the metadata stream gone - fail-open"
find "$G2REPO" "$G2TMP" "$G2HOOKS" "$FD8DIR" -mindepth 0 -delete 2>/dev/null


cd "$ROOT" || true
echo "── 8. the secret scans read a large input whole (v8.3.30) ──"
# guard.sh, pre-commit and the gate piped the text into `grep -q` under pipefail: grep exits
# at the first hit, the writer dies of SIGPIPE, and the pipeline reads as "no match". They
# now search a here-string. The guard row fails on v8.3.29 (rc 0). The git-fed rows did not
# miss on v8.3.29 under Windows (native git); they keep the large-input case covered.
# Fixtures live under $TH_TMP and are built from the sandbox's scripts/.
s8="$(mktemp -d)"; cd "$s8" || true
mkfx(){ # $1 = fixture dir: a git repo holding the template scripts and nothing else
  mkdir -p "$1" && cp -r "$SANDBOX/scripts" "$1/scripts" \
    && git -C "$1" init -q && git -C "$1" add -A 2>/dev/null \
    && git -C "$1" -c user.email=t@t -c user.name=t commit -qm init; }
gx(){ ( cd "$1" && bash scripts/quality-gate.sh ${2:-} 2>&1 ); }
mkfx fb
tk="sk-""abcdefghijklmnop1234567890"            # split so this file holds no secret shape
python3 - "$tk" > fb/big.json <<'PY'
import sys
rows = ['{"tool_name":"Write","tool_input":{"content":"key=%s"},' % sys.argv[1]]
rows += ['"p%d":"%s",' % (i, "a" * 70) for i in range(20000)]
rows.append('"end":1}')
sys.stdout.write("\n".join(rows))
PY
( cd fb && bash scripts/guard.sh < big.json >/dev/null 2>&1 ); rc=$?; rm -f fb/big.json
[ "$rc" = "2" ] && ok "guard: a secret on line 1 of a 1.6 MB input still blocks (here-string, no pipefail miss)" \
                || no "guard: a secret on line 1 of a large input was missed (rc=$rc)"
{ printf 'key = "%s"\n' "$tk"; python3 -c 'import sys; sys.stdout.write("x = 1\n" * 50000)'; } > fb/big.py
git -C fb add big.py 2>/dev/null
out="$(cd fb && bash scripts/pre-commit 2>&1)"; rc=$?
qx="$(gx fb --trivial)"
git -C fb rm -q --cached big.py >/dev/null 2>&1; rm -f fb/big.py
[ "$rc" -ne 0 ] && case "$out" in *"hardcoded secret"*) true ;; *) false ;; esac \
  && ok "pre-commit: a secret on line 1 of a large staged file still blocks" \
  || no "pre-commit: a secret on line 1 of a large staged file was missed (rc=$rc)"
case "$qx" in
  *"possible secret in staged changes"*) ok "gate: a secret on line 1 of a large staged file is named" ;;
  *) no "gate: a secret on line 1 of a large staged file was missed" ;;
esac
# A failed `git diff --cached` (here: a corrupt index, rc 128) is a failed check, never
# "no obvious secrets staged" (sheriff finding on the here-string change).
printf 'DIRC-broken' > fb/.git/index
qx="$(gx fb --trivial)"
case "$qx" in
  *"staged-secret scan did not run"*) ok "gate: a failed git diff is a failed check, not 'no secrets'" ;;
  *) no "gate: a failed git diff read as 'no obvious secrets staged'" ;;
esac
cd "$ROOT" || true
# ── temp containment, closing assertions (v8.3.27, #11) ──
th_cleanup
TMP_AFTER="$(tmp_snapshot)"
[ ! -e "$TH_TMP" ] && ok "temp containment: the suite's own temp dir is gone" \
                   || no "temp containment: $TH_TMP survived cleanup — unreadable leftovers (#11)"
# The shared temp dir is NOT asserted on (v8.3.28, #28): other processes create and
# delete tmp.* there mid-run, so a before==after compare failed on work that was not ours
# (field, 2026-09-17). The hard assertion is the suite's own sandbox above; new entries in
# the shared dir are named for a human to judge, never counted as a failure. Not even th.*
# or qg.*: any concurrent suite or gate run in any project makes those (the v8.3.28 review
# run caught a qg.* from a v8.3.27 gate mid-suite). Ours cannot land there — TMPDIR points
# into $TH_TMP for the whole run, and $TH_TMP's removal is asserted above.
tmp_new="$(comm -13 <(echo "$TMP_BEFORE") <(echo "$TMP_AFTER") | tr '\n' ' ')"
[ -n "${tmp_new// /}" ] && echo "  · note: new entries in $REAL_TMP during the run (possibly another process): $tmp_new"
echo "────────────────────────────"
echo "PASS: $pass   FAIL: $fail"
if [ "$fail" -eq 0 ]; then echo "HOOKS: GREEN ✅"; exit 0; else echo "HOOKS: RED 🔴 — fix the ✗ items above."; exit 1; fi
