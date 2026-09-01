#!/usr/bin/env python3
"""session-cost.py - where do the tokens (and dollars) of Claude Code sessions go?

Reads the session transcripts Claude Code keeps for THIS project
(~/.claude/projects/<project-slug>/*.jsonl) and prints, per session:
  API calls, user turns, token classes, an estimated cost, the recorded cost
  (when Claude Code has written its cost-state), and the biggest single items
  that entered the context (tool results, skill loads, files read).

    python scripts/session-cost.py            # newest 5 sessions
    python scripts/session-cost.py -n 10
    python scripts/session-cost.py --session 70497047   # one session, full detail

Rates (USD per 1M tokens) calibrated 2026-09-02 against Claude Code's own
cost-state records: cache WRITE = 2x input (1-hour cache TTL), cache READ as
listed. Update the table when the lineup or pricing changes - it decays.
"""
import argparse, glob, json, os, re, sys
from collections import Counter, defaultdict

RATES = {  # model-id prefix: (input, output, cache_write, cache_read)
    "claude-fable-5-1": (10.0, 50.0, 20.0, 0.25),
    "claude-fable-5":   (10.0, 50.0, 20.0, 0.25),
    "claude-opus-5":    (5.0, 25.0, 10.0, 0.50),
    "claude-opus-4":    (5.0, 25.0, 10.0, 0.50),
    "claude-sonnet-5":  (2.0, 10.0, 4.0, 0.20),
    "claude-sonnet-4":  (3.0, 15.0, 6.0, 0.30),
    "claude-haiku-4":   (1.0, 5.0, 2.0, 0.10),
}

def rate_for(model):
    m = (model or "").replace("[1m]", "")
    for k, v in RATES.items():
        if m.startswith(k): return v
    return (10.0, 50.0, 20.0, 0.25)  # unknown -> assume the most expensive tier, and say so

def analyze(path):
    calls = 0; turns = 0
    tok = Counter(); cost = 0.0; models = Counter(); unknown_models = set()
    first_ctx = None; max_ctx = 0
    seen = set()             # assistant message ids already counted
    tool_names = {}          # tool_use_id -> name
    tool_calls = Counter()
    items = []               # (tokens_est, label, time)
    recorded = None
    for line in open(path, encoding="utf-8"):
        try: d = json.loads(line)
        except Exception: continue
        t = d.get("type"); ts = d.get("timestamp", "")[11:19]
        if t == "cost-state": recorded = d
        msg = d.get("message", {}) if isinstance(d.get("message"), dict) else {}
        content = msg.get("content")
        if t == "user":
            if isinstance(content, str):
                turns += 1
                items.append((len(content) // 4, "user prompt", ts))
            elif isinstance(content, list):
                for b in content:
                    if not isinstance(b, dict): continue
                    if b.get("type") == "text":
                        txt = b.get("text", "")
                        if "Base directory for this skill" in txt or "<command-name>" in txt:
                            items.append((len(txt) // 4, "SKILL / command load", ts))
                        else:
                            turns += 1; items.append((len(txt) // 4, "user prompt", ts))
                    if b.get("type") == "tool_result":
                        r = b.get("content"); s = r if isinstance(r, str) else json.dumps(r)
                        name = tool_names.get(b.get("tool_use_id"), "tool")
                        items.append((len(s) // 4, f"result of {name}", ts))
        elif t == "assistant":
            for b in content or []:
                if isinstance(b, dict) and b.get("type") == "tool_use":
                    tool_names[b.get("id")] = b.get("name"); tool_calls[b.get("name")] += 1
                    inp = json.dumps(b.get("input", {}))
                    if len(inp) > 6000: items.append((len(inp) // 4, f"input to {b.get('name')}", ts))
            u = msg.get("usage")
            if not u: continue
            # One API response is stored as several records (one per content block),
            # each repeating the same usage -> count each message id once.
            mid = msg.get("id")
            if mid in seen: continue
            seen.add(mid)
            calls += 1
            i = u.get("input_tokens", 0); w = u.get("cache_creation_input_tokens", 0)
            r = u.get("cache_read_input_tokens", 0); o = u.get("output_tokens", 0)
            tok["input"] += i; tok["cache_write"] += w; tok["cache_read"] += r; tok["output"] += o
            model = msg.get("model", "?"); models[model] += 1
            if not any(model.replace("[1m]", "").startswith(k) for k in RATES): unknown_models.add(model)
            ri, ro, rw, rr = rate_for(model)
            cost += (i * ri + o * ro + w * rw + r * rr) / 1e6
            if first_ctx is None: first_ctx = i + w
            max_ctx = max(max_ctx, i + w + r)
    return dict(path=path, calls=calls, turns=turns, tok=tok, cost=cost, models=models,
                unknown=unknown_models, first_ctx=first_ctx or 0, max_ctx=max_ctx,
                tool_calls=tool_calls, items=sorted(items, reverse=True), recorded=recorded)

def breakdown(a):
    tok = a["tok"]; model = a["models"].most_common(1)[0][0] if a["models"] else "?"
    ri, ro, rw, rr = rate_for(model)
    parts = [("output (thinking+text+tool inputs)", tok["output"] * ro), ("cache WRITE (new context, 2x)", tok["cache_write"] * rw),
             ("cache READ (context re-sent per call)", tok["cache_read"] * rr), ("uncached input", tok["input"] * ri)]
    total = sum(v for _, v in parts) or 1
    return [(n, v / 1e6, 100 * v / total) for n, v in parts]

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-n", type=int, default=5); ap.add_argument("--session", help="session id prefix")
    ap.add_argument("--project-dir", default=os.getcwd())
    args = ap.parse_args()
    slug = re.sub(r"[^A-Za-z0-9]", "-", os.path.abspath(args.project_dir))
    base = os.path.join(os.path.expanduser("~"), ".claude", "projects", slug)
    files = sorted(glob.glob(os.path.join(base, "*.jsonl")), key=os.path.getmtime, reverse=True)
    if args.session: files = [f for f in files if os.path.basename(f).startswith(args.session)]
    files = files[: args.n]
    if not files: sys.exit(f"no session files under {base}")
    for f in files:
        a = analyze(f)
        if a["calls"] == 0: continue
        sid = os.path.basename(f)[:8]; tok = a["tok"]
        rec = f"  recorded by Claude Code: ${a['recorded']['totalCostUSD']:.2f}" if a["recorded"] else "  (session still open - no recorded cost yet)"
        print(f"\n=== {sid}  {dict(a['models'])}")
        print(f"  user turns {a['turns']}  API calls {a['calls']}  ({a['calls'] / max(a['turns'], 1):.0f} calls/turn)   "
              f"first-request context ~{a['first_ctx']:,} tok   max context {a['max_ctx']:,} tok")
        print(f"  tokens: output {tok['output']:,} | cache write {tok['cache_write']:,} | cache read {tok['cache_read']:,} | uncached {tok['input']:,}")
        print(f"  estimated ${a['cost']:.2f}{rec}")
        for n, usd, pct in breakdown(a): print(f"    {pct:5.1f}%  ${usd:6.2f}  {n}")
        if a["unknown"]: print(f"  ! unknown model(s) priced at the top tier: {a['unknown']}")
        print("  top tools:", ", ".join(f"{k}x{v}" for k, v in a["tool_calls"].most_common(6)))
        limit = 12 if args.session else 5
        print("  biggest items that entered context (est. tokens):")
        for n, label, ts in a["items"][:limit]: print(f"    {n:7,}  {ts}  {label}")

if __name__ == "__main__":
    main()
