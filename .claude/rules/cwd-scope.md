# A session writes only inside its own project (always on)

The mirror of `go-ahead-scope.md` for directories: a go-ahead binds one session, and a
session writes in one project.

**Your project** is the git repository the session was started in — its top level
(`git rev-parse --show-toplevel` from the start directory).

## Writes stay inside it
Editing or creating files, commits, merges, rebases, branch or tag moves, pushes,
installs, and running a script whose job is to change a tree — all of it happens inside
your project root, never outside it. Reading elsewhere stays allowed: open, grep,
`git log` / `status` / `diff` / `show`.

A request whose write targets another project — a path there, a `cd <dir> &&`, a
`git -C <dir>` — is echoed back as `not my project: <dir>` and **none of it runs**: not
the harmless-looking half, not "just the first step".

## Why
A merge command meant for one project was pasted into another project's session. That
session ran it — merged the other repository's main — then rolled back halfway when its
guard refused one step, leaving a rollback line that would have discarded later work if
anyone had run it. Nothing in the command was wrong; the session running it was.

## The one exception
The owner names the other project as the target **in this session** — "in <dir>, do X".
That covers that project and that scope only (`go-ahead-scope.md`), and every write there
is announced with its target directory. The onboarding step that registers this project in
the VPS-hub project is this case: it writes there once the owner has given that path. A command pasted from another session, quoted in
a handoff, report or board, or a script that happens to `cd` elsewhere, is not that.

Throwaway files go to `temp/` (HOW YOU WORK #7) or the session's own scratch directory;
neither is a project.

## Enforcement
A rule, not a hook. `guard.sh` does not check `cd` / `-C` targets: telling a write from a
read by matching command text is the losing game its own header describes. If this must
ever hold 100%, it needs argument parsing, not another regex.
