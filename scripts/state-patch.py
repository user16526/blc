#!/usr/bin/env python3
"""state-patch.py — deterministic merge of LLM-proposed patches into the
authoritative execution state (SKILL.state-style, v8.3.16).

    python3 scripts/state-patch.py --patch '<json>'     # or --patch-file f.json
    python3 scripts/state-patch.py --show               # print current state
    python3 scripts/state-patch.py --self-test          # exit 0 iff suite passes

Division of labor (the whole point):
  LLM PROPOSES a patch  ->  this script VALIDATES against the schema and
  invariants  ->  deterministic MERGE  ->  ATOMIC write of current.json  ->
  render of the human view current.md.
The LLM never rewrites the state file directly, so "Claude accidentally
rewrote half the state" (68% of small-model failures in arXiv:2608.26263)
is structurally impossible.

Patch format (either key optional, unknown keys rejected):
  {"set":    {"dot.path": value, ...},
   "append": {"listpath": value_or_list, ...},
   "delete": ["dot.path", ...]}

Invariants enforced here, not by convention:
  I1  Only schema-listed top-level keys exist. Unknown key -> REJECT.
  I2  "next" is a single non-empty line after merge (exactly ONE action).
  I3  "failed_rejected" entries can be added, never deleted or overwritten
      without --allow-forget (they are the anti-repeat memory; the paper's
      tested_hypotheses field is what bought its accuracy gain).
  I4  Values type-checked against the schema (string vs list vs object).
  I5  Whole-state replacement is not a patch. REJECT "set": {"": ...}.
State files: .agent/state/current.json (authoritative), current.md (rendered
view, keeps the "Last updated:" line other hooks grep). Schema:
.agent/state/state-schema.json.
"""
import argparse, json, os, sys, tempfile, datetime

# Field project C finding D3 (2026-09-01): under a cp1252 console the "\u2713" marks killed
# --self-test with UnicodeEncodeError at the first assertion — the release's own
# stated verification step was unusable on Windows. Same fix build-release.py
# already carries: force utf-8 with replacement, never crash on printing.
for _s in (sys.stdout, sys.stderr):
    try:
        _s.reconfigure(encoding="utf-8", errors="replace")
    except (AttributeError, ValueError):
        pass

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STATE = os.path.join(ROOT, ".agent", "state", "current.json")
VIEW = os.path.join(ROOT, ".agent", "state", "current.md")
VIEW_ALT = os.path.join(ROOT, ".agent", "state", "state-view.md")
RENDER_MARK = "RENDERED VIEW"
SCHEMA = os.path.join(ROOT, ".agent", "state", "state-schema.json")

FALLBACK_SCHEMA = {
    "goal": "string", "constraints": "list", "verified": "object",
    "working_set": "list", "decisions": "list", "failed_rejected": "list",
    "open_loops": "list", "latest_evidence": "string", "next": "string",
    "meta": "object",
}
EMPTY = {"goal": "", "constraints": [], "verified": {}, "working_set": [],
         "decisions": [], "failed_rejected": [], "open_loops": [],
         "latest_evidence": "", "next": "", "meta": {}}


def load_schema():
    try:
        with open(SCHEMA, encoding="utf-8") as f:
            return json.load(f)["fields"]
    except Exception:
        return dict(FALLBACK_SCHEMA)


class StateUnreadable(Exception):
    """current.json exists but is not a readable JSON object (sheriff [1],
    2026-09-02): the old code returned EMPTY here, so the next valid patch would
    have atomically overwritten the authoritative state. Only a MISSING file
    starts empty; anything else is refused without writing."""


def load_state(path=STATE):
    try:
        with open(path, encoding="utf-8") as f:
            d = json.load(f)
    except FileNotFoundError:
        return json.loads(json.dumps(EMPTY))
    except (OSError, ValueError) as ex:
        raise StateUnreadable("%s exists but cannot be read as JSON (%s)" % (path, ex))
    if not isinstance(d, dict):
        raise StateUnreadable("%s is not a JSON object" % path)
    return d


def type_ok(kind, v):
    return {"string": lambda x: isinstance(x, str),
            "list": lambda x: isinstance(x, list),
            "object": lambda x: isinstance(x, dict)}.get(kind, lambda x: False)(v)


def walk_set(state, schema, path, value, errors, allow_forget=False):
    parts = [p for p in path.split(".") if p != ""]
    if not parts:
        errors.append("I5: empty path — whole-state replacement is not a patch")
        return
    top = parts[0]
    if top not in schema:
        errors.append("I1: unknown top-level key %r" % top)
        return
    if len(parts) == 1:
        if top == "failed_rejected" and not isinstance(value, list):
            errors.append("failed_rejected is a list; use append")
            return
        if top == "failed_rejected" and not allow_forget:
            # sheriff [2] (2026-09-02): a length check let an equal-length or longer
            # list REPLACE every entry. Every existing entry must survive the set.
            lost = [x for x in state.get(top, []) if x not in value]
            if lost:
                errors.append("I3: set on failed_rejected drops %d existing entr%s "
                              "(%r) — needs --allow-forget"
                              % (len(lost), "y" if len(lost) == 1 else "ies", lost[0]))
                return
        if not type_ok(schema[top], value):
            errors.append("I4: %r must be %s" % (top, schema[top]))
            return
        state[top] = value
        return
    # nested path: only into object-typed fields
    if schema[top] != "object":
        errors.append("nested path into non-object %r" % top)
        return
    node = state.setdefault(top, {})
    for p in parts[1:-1]:
        node = node.setdefault(p, {})
        if not isinstance(node, dict):
            errors.append("path %r crosses a non-object" % path)
            return
    node[parts[-1]] = value


def walk_delete(state, schema, path, allow_forget, errors):
    parts = [p for p in path.split(".") if p != ""]
    if not parts or parts[0] not in schema:
        errors.append("I1: unknown/empty delete path %r" % path)
        return
    if parts[0] == "failed_rejected" and not allow_forget:
        errors.append("I3: deleting from failed_rejected needs --allow-forget")
        return
    if len(parts) == 1:
        state[parts[0]] = json.loads(json.dumps(EMPTY[parts[0]])) \
            if parts[0] in EMPTY else ""
        return
    node = state.get(parts[0], {})
    for p in parts[1:-1]:
        node = node.get(p, {})
        if not isinstance(node, dict):
            return  # deleting a non-existent path is a no-op, per merge semantics
    if isinstance(node, dict):
        node.pop(parts[-1], None)


def apply_patch(state, patch, schema, allow_forget=False):
    errors = []
    for k in patch:
        if k not in ("set", "append", "delete"):
            errors.append("unknown patch section %r" % k)
    for path, value in (patch.get("set") or {}).items():
        walk_set(state, schema, path, value, errors, allow_forget)
    for path, value in (patch.get("append") or {}).items():
        top = path.split(".")[0]
        if top not in schema or schema[top] != "list":
            errors.append("append target %r is not a list field" % path)
            continue
        state.setdefault(top, [])
        state[top].extend(value if isinstance(value, list) else [value])
    for path in (patch.get("delete") or []):
        walk_delete(state, schema, path, allow_forget, errors)
    nxt = state.get("next", "")
    if not isinstance(nxt, str) or not nxt.strip() or "\n" in nxt.strip():
        errors.append("I2: 'next' must end up exactly one non-empty line")
    return errors


def atomic_write(path, text):
    d = os.path.dirname(path)
    os.makedirs(d, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=d, prefix=".state-", suffix=".cg-tmp")
    with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    os.replace(tmp, path)


def render(state):
    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
    L = ["# Current State",
         "<!-- RENDERED VIEW. Authoritative state: current.json, merged only via",
         "     scripts/state-patch.py (LLM proposes, script merges). Hand-edits here",
         "     are lost on the next render — patch instead. -->",
         "", "Last updated: %s" % now, "",
         "## Goal", "- %s" % (state["goal"] or "—"), ""]
    def sec(title, items):
        L.append("## %s" % title)
        L.extend(["- %s" % i for i in items] or ["-"])
        L.append("")
    sec("Constraints", state["constraints"])
    L.append("## Verified (evidence, not memory)")
    L.extend(["- %s: %s" % (k, v) for k, v in state["verified"].items()] or ["-"])
    L.append("")
    sec("Working set", state["working_set"])
    sec("Decisions (1-liners; reasoning -> decisions.md)", state["decisions"])
    sec("Failed / rejected (do NOT retry)", state["failed_rejected"])
    sec("Open loops", state["open_loops"])
    L += ["## Latest evidence", "- %s" % (state["latest_evidence"] or "—"), "",
          "## Next (exactly one action)", "- %s" % (state["next"] or "—"), ""]
    return "\n".join(L)


def view_target(view=VIEW, alt=VIEW_ALT):
    """Never overwrite a hand-maintained current.md (field project B, 2026-09-02: the first
    patch in an EXISTING project replaced a 656-line narrative with a 34-line
    render). A file without the render marker is the owner's; render beside it."""
    if os.path.isfile(view):
        try:
            with open(view, encoding="utf-8", errors="replace") as f:
                head = f.read(600)
        except OSError:
            return alt
        if RENDER_MARK not in head:
            return alt
    return view


def self_test():
    import copy
    schema = dict(FALLBACK_SCHEMA)
    ok = [0]

    def t(name, cond):
        print("  %s %s" % ("\u2713" if cond else "\u2717", name))
        ok[0] += 0 if cond else 1

    s = copy.deepcopy(EMPTY)
    e = apply_patch(s, {"set": {"goal": "ship v8.3.16", "next": "run suite"}},
                    schema)
    t("basic set merges clean", not e and s["goal"] == "ship v8.3.16")
    e = apply_patch(copy.deepcopy(s), {"set": {"nonsense": 1, "next": "x"}}, schema)
    t("I1 unknown key rejected", any("I1" in x for x in e))
    e = apply_patch(copy.deepcopy(s), {"set": {"next": "a\nb"}}, schema)
    t("I2 multi-line next rejected", any("I2" in x for x in e))
    s2 = copy.deepcopy(s); s2["failed_rejected"] = ["approach A"]
    e = apply_patch(copy.deepcopy(s2), {"delete": ["failed_rejected"]}, schema)
    t("I3 forgetting failures rejected", any("I3" in x for x in e))
    e = apply_patch(s2, {"append": {"failed_rejected": "approach B"},
                         "set": {"next": "try C"}}, schema)
    t("append to failed_rejected merges", not e and len(s2["failed_rejected"]) == 2)
    s3 = copy.deepcopy(s2)
    e = apply_patch(s3, {"set": {"failed_rejected": ["approach X", "approach Y"],
                                 "next": "x"}}, schema)
    t("I3 equal-length REPLACE of failed_rejected rejected",
      any("I3" in x for x in e) and s3["failed_rejected"] == ["approach A", "approach B"])
    e = apply_patch(s3, {"set": {"failed_rejected": ["approach B", "approach A", "approach C"],
                                 "next": "x"}}, schema)
    t("set that keeps every failed_rejected entry merges", not e and len(s3["failed_rejected"]) == 3)
    e = apply_patch(copy.deepcopy(s2), {"set": {"failed_rejected": ["approach A"],
                                                "next": "x"}}, schema, allow_forget=True)
    t("--allow-forget permits a deliberate drop", not e)
    bad = os.path.join(tempfile.mkdtemp(), "current.json")
    with open(bad, "w", encoding="utf-8") as f:
        f.write("{ truncated")
    try:
        load_state(bad); corrupt_refused = False
    except StateUnreadable:
        corrupt_refused = True
    t("corrupt current.json is REFUSED, never read as empty", corrupt_refused)
    t("missing current.json starts empty", load_state(bad + ".missing")["goal"] == "")
    e = apply_patch(copy.deepcopy(s), {"set": {"constraints": "not-a-list",
                                               "next": "x"}}, schema)
    t("I4 type mismatch rejected", any("I4" in x for x in e))
    e = apply_patch(copy.deepcopy(s), {"set": {"": {"goal": "hi"}}}, schema)
    t("I5 whole-state replace rejected", any("I5" in x for x in e))
    e = apply_patch(copy.deepcopy(s), {"set": {"verified.suite": "146/0 GREEN",
                                               "next": "x"}}, schema)
    t("nested set into object works", not e)
    txt = render(s)
    t("render keeps 'Last updated:' line", "Last updated:" in txt)
    d = tempfile.mkdtemp()
    v, alt = os.path.join(d, "current.md"), os.path.join(d, "state-view.md")
    t("view: absent current.md -> render in place", view_target(v, alt) == v)
    with open(v, "w", encoding="utf-8") as f:
        f.write("# Current State\n\nLast updated: hand-written narrative\n")
    t("view: hand-maintained current.md is NEVER overwritten", view_target(v, alt) == alt)
    with open(v, "w", encoding="utf-8") as f:
        f.write(txt)
    t("view: a rendered current.md is re-rendered in place", view_target(v, alt) == v)
    print("state-patch self-test: %s" % ("GREEN" if ok[0] == 0 else "RED"))
    return ok[0]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--patch"); ap.add_argument("--patch-file")
    ap.add_argument("--show", action="store_true")
    ap.add_argument("--self-test", action="store_true")
    ap.add_argument("--allow-forget", action="store_true",
                    help="permit deletes inside failed_rejected (rare, deliberate)")
    a = ap.parse_args()
    if a.self_test:
        sys.exit(self_test())
    try:
        state = load_state()
    except StateUnreadable as ex:
        sys.exit("REJECTED: %s. State untouched — repair or move it aside first." % ex)
    if a.show:
        print(json.dumps(state, indent=2, ensure_ascii=False)); return
    raw = a.patch or (open(a.patch_file, encoding="utf-8").read()
                      if a.patch_file else None)
    if not raw:
        ap.error("need --patch / --patch-file / --show / --self-test")
    try:
        patch = json.loads(raw)
    except json.JSONDecodeError as ex:
        sys.exit("REJECTED: patch is not valid JSON (%s). State untouched." % ex)
    schema = load_schema()
    errors = apply_patch(state, patch, schema, a.allow_forget)
    if errors:
        sys.exit("REJECTED (state untouched):\n  - " + "\n  - ".join(errors))
    state.setdefault("meta", {})
    state["meta"]["last_patch"] = datetime.datetime.now().isoformat(timespec="seconds")
    state["meta"]["patch_count"] = int(state["meta"].get("patch_count", 0)) + 1
    atomic_write(STATE, json.dumps(state, indent=2, ensure_ascii=False) + "\n")
    view = view_target()
    atomic_write(view, render(state))
    print("merged: patch #%d -> %s (+ rendered %s)"
          % (state["meta"]["patch_count"], os.path.relpath(STATE, ROOT),
             os.path.relpath(view, ROOT)))


if __name__ == "__main__":
    main()
