# A go-ahead binds only the session it was addressed to (always on)

An approval — "go", "OK", an approved plan, a kernel-change OK, a deploy go-ahead, a
board ruling — authorizes **the session it was given in, for the scope it named**. It
does not travel.

## It does not carry to
- **Another session.** A peer session's approval, or one quoted in a handoff, a report,
  a board, a commit message or another project's run, is a record that approval
  happened THERE — never permission HERE. Two sessions on one machine are two
  addressees.
- **Another project.** An OK for one project's CORE change, upgrade or deploy covers
  that project only. A fan-out asks per project; one approval re-used N times attests
  to nothing.
- **A wider scope.** "Upgrade X" is not "and merge it"; "build it" is not "publish it";
  "fix the test" is not "and refactor what it touches".
- **A new session after `/clear`, a restart or a `/continue-work`.** The handoff may
  record THAT the owner approved something and exactly what; the new session reads it
  as history and asks again before any step the RISK MATRIX gates on approval.

## It does carry
Within one session and one task: through a compaction and its automatic resume (the
same conversation continues), and across steps that are all inside the named scope.

## When unsure
Treat it as not given, and ask — one line, with the recommended answer. A question costs
one turn; acting on someone else's go-ahead can cost the thing the approval was
protecting.
