#!/usr/bin/env python3
"""Generate a child-simple project map: docs/project-map.html + docs/project-map.txt.

Rooms = top-level folders. Workers = agents on active board tasks.
This is a SNAPSHOT of recorded state (board.md, current.md), not live telemetry.
Stdlib only. Degrades gracefully when files are missing. Run from project root:
    python3 scripts/project-map.py
"""
import datetime
import html
import re
import sys
from pathlib import Path

ROOT = Path.cwd()
SERVICE = {"tasks": "список справ", ".agent": "пам'ять", "_reports": "докази",
           "scripts": "охорона", "docs": "документи", "specs": "спеки фіч"}
SKIP = {"node_modules", "dist", "build", "__pycache__", ".git", ".claude", ".specify", "temp", "tmp"}


def read(p):
    try:
        return (ROOT / p).read_text(encoding="utf-8")
    except OSError:
        return ""


def domains():
    """Top-level dirs that are 'rooms' (not service, not hidden). name -> tagline."""
    out = {}
    for d in sorted(ROOT.iterdir()):
        if not d.is_dir() or d.name in SKIP or d.name in SERVICE or d.name.startswith("."):
            continue
        tag = ""
        sub = read(f"{d.name}/CLAUDE.md")
        if sub:
            first = sub.strip().splitlines()[0].lstrip("# ").strip()
            tag = re.sub(r"^[\w./-]+\s*[—-]\s*", "", first)[:60]
        out[d.name] = tag
    return out


def board_tasks():
    """Active tasks from tasks/board.md: list of (status, text)."""
    txt = read("tasks/board.md")
    active = txt.split("## Done")[0] if txt else ""
    tasks = []
    for m in re.finditer(r"^- \[(\w+)\]\s*(.+)$", active, re.M):
        status, rest = m.group(1).lower(), m.group(2).strip()
        if status in ("todo", "doing", "review") and "(example)" not in rest:
            tasks.append((status, rest))
    return tasks


def agents():
    """(active, available, archived). Rule: the map shows only what it can READ from
    recorded state — if a field doesn't parse, say 'не заповнено', NEVER guess.
    Active team = the 'Active team:' field in CLAUDE.md (the onboarded subset);
    available = files in .claude/agents/ (the catalog); archived = _archive/."""
    adir = ROOT / ".claude" / "agents"
    available = sorted(p.stem for p in adir.glob("*.md")) if adir.is_dir() else []
    archived = sorted(p.stem for p in (adir / "_archive").glob("*.md")) if (adir / "_archive").is_dir() else []
    m = re.search(r"^- Active team:\s*(.*)$", read("CLAUDE.md"), re.M)
    raw = re.sub(r"<!--.*?-->", "", m.group(1)).strip() if m else ""
    active = [a.strip() for a in re.split(r"[,;]", raw) if a.strip()] if raw else []
    return active, available, archived


def automode():
    """Default automode from CLAUDE.md PROJECT (session toggles are not recorded state)."""
    m = re.search(r"^- Default automode:\s*(.*)$", read("CLAUDE.md"), re.M)
    raw = re.sub(r"<!--.*?-->", "", m.group(1)).strip().lower() if m else ""
    return raw if raw in ("on", "off") else "не заповнено"


def assign(tasks, doms):
    """Attach tasks to a domain when the task text mentions it; else root bucket."""
    per, root_bucket = {d: [] for d in doms}, []
    for status, text in tasks:
        hit = next((d for d in doms if re.search(rf"\b{re.escape(d)}\b|{re.escape(d)}/", text, re.I)), None)
        (per[hit] if hit else root_bucket).append((status, text))
    return per, root_bucket


STATUS_UA = {"doing": "у роботі", "review": "на перевірці", "todo": "у черзі"}


def txt_map(name, stamp, aut, doms, per, root_bucket, roster):
    L = [f"ПРОЄКТ: {name}    знімок: {stamp} · automode (дефолт): {aut}",
         "=" * 62,
         f"{name}/  ← дім проєкту (CLAUDE.md — правила дому)", "|"]
    for d, tag in doms.items():
        mark, ts = ("·", ["вільно"]) if not per[d] else ("▶", [f"[{STATUS_UA[s]}] {t}" for s, t in per[d]])
        L.append(f"+-- {d + '/':<12} {tag:<28} {mark} {ts[0]}")
        L += [f"    {'':<41} {t}" for t in ts[1:]]
    for s, t in root_bucket:
        L.append(f"+-- (дім)        [{STATUS_UA[s]}] {t}")
    L.append("|")
    row = [f"{k}/ {v}" for k, v in SERVICE.items() if (ROOT / k).is_dir()]
    for i in range(0, len(row), 2):
        L.append("+-- " + "   ".join(f"{c:<28}" for c in row[i:i + 2]).rstrip())
    active, available, archived = roster
    if active:
        L += ["", "Активна команда: " + ", ".join(active)]
        extra = [a for a in available if a not in active]
        if extra:
            L.append("Доступні (не активовані): " + ", ".join(extra))
    elif available:
        L += ["", "⚑ КОМАНДА НЕ СФОРМОВАНА — прожени FIRST RUN onboarding із CLAUDE.md.",
              "  (у каталозі доступні: " + ", ".join(available) + ")"]
    if archived:
        L.append("В архіві: " + ", ".join(archived))
    L += ["-" * 62, "Як читати: тека = кімната · ▶ = у роботі · це знімок, не телеметрія"]
    return "\n".join(L) + "\n"


def html_map(name, stamp, aut, doms, per, root_bucket, roster):
    def room(d, tag, ts):
        busy = bool(ts)
        border = "#534AB7" if busy else "#AFA9EC"
        rows = "".join(
            f'<div style="font-size:13px;color:#3C3489;margin-bottom:4px;">&#9654; {html.escape(t)} '
            f'<span style="color:#534AB7;">({STATUS_UA[s]})</span></div>' for s, t in ts) or \
            '<div style="font-size:13px;color:#534AB7;">&middot; вільно</div>'
        return (f'<div style="background:#EEEDFE;border:1px solid {border};border-radius:8px;padding:12px;">'
                f'<div style="font-size:15px;font-weight:600;color:#3C3489;">&#128193; {html.escape(d)}/</div>'
                f'<div style="font-size:12px;color:#534AB7;margin:2px 0 8px;">{html.escape(tag)}</div>{rows}</div>')

    rooms = "".join(room(d, t, per[d]) for d, t in doms.items())
    extra = "".join(
        f'<div style="font-size:13px;color:#3C3489;margin-top:6px;">&#9654; (дім) {html.escape(t)} ({STATUS_UA[s]})</div>'
        for s, t in root_bucket)
    svc = "".join(f'<div style="background:#F1EFE8;border-radius:8px;padding:8px 10px;font-size:12px;color:#444441;">'
                  f'{k}/ — {v}</div>' for k, v in SERVICE.items() if (ROOT / k).is_dir())
    active, available, archived = roster
    def chip(a, bg, fg):
        return (f'<span style="display:inline-block;background:{bg};color:{fg};font-size:12px;'
                f'padding:3px 10px;border-radius:10px;margin:2px;">&#129302; {html.escape(a)}</span>')
    chips = "".join(chip(a, "#E1F5EE", "#085041") for a in active)
    chips += "".join(chip(a, "#F1EFE8", "#5F5E5A") for a in available if a not in active)
    banner = ""
    if not active and available:
        banner = ('<div style="background:#FDEBEC;border:1px solid #BF4D43;border-radius:8px;'
                  'padding:10px;margin-top:12px;font-size:13px;color:#8A2B24;">&#9873; Команда не '
                  'сформована — прожени FIRST RUN onboarding із CLAUDE.md. Нижче — доступний каталог, НЕ активна команда.</div>')
    return f"""<!DOCTYPE html><html lang="uk"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>Карта проєкту — {html.escape(name)}</title></head>
<body style="font-family:system-ui,sans-serif;background:#FAF9F5;color:#2C2C2A;max-width:860px;margin:2rem auto;padding:0 1rem;">
<div style="display:flex;justify-content:space-between;align-items:baseline;flex-wrap:wrap;gap:8px;">
<h1 style="font-size:22px;font-weight:600;margin:0;">&#128506; Карта проєкту — {html.escape(name)}</h1>
<div style="font-size:12px;color:#888780;">знімок: {stamp} &middot; automode (дефолт): {aut}</div></div>
<div style="border:1px solid #D3D1C7;border-radius:12px;background:#fff;padding:14px;margin-top:14px;">
<div style="font-size:14px;font-weight:600;margin-bottom:10px;">&#127968; {html.escape(name)}/ — дім проєкту
<span style="font-weight:400;color:#5F5E5A;">(CLAUDE.md — правила дому)</span></div>
<div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:10px;">{rooms}</div>{extra}
<div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:8px;margin-top:10px;">{svc}</div>
{banner}{f'<div style="margin-top:12px;font-size:12px;color:#5F5E5A;">Команда (зелені = активні, сірі = доступні):</div><div>{chips}</div>' if chips else ''}</div>
<p style="font-size:12px;color:#5F5E5A;line-height:1.6;">Як читати: кімната = тека &middot; &#9654; = зараз у роботі за board.md &middot;
зелені жетони = доступні ролі. Це знімок на момент генерації, не жива телеметрія — перегенеруй командою /map.</p>
</body></html>"""


def main():
    name = ROOT.name
    stamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
    doms = domains()
    per, root_bucket = assign(board_tasks(), doms)
    roster, aut = agents(), automode()
    out = ROOT / "docs"
    out.mkdir(exist_ok=True)
    (out / "project-map.txt").write_text(txt_map(name, stamp, aut, doms, per, root_bucket, roster), encoding="utf-8")
    (out / "project-map.html").write_text(html_map(name, stamp, aut, doms, per, root_bucket, roster), encoding="utf-8")
    print(f"OK: docs/project-map.html + docs/project-map.txt (знімок {stamp})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
