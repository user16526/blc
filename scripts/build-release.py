#!/usr/bin/env python3
"""Build the release artifacts reproducibly.

    python3 scripts/build-release.py [--out-dir <dir>]

The canonical source is this directory tree. The zips are build products, never
the thing you edit: patching an archive directly is how a "fixed" runtime and a
shipped runtime drift apart without anyone noticing.

TWO artifacts, because this tree has two audiences and mixing them is exactly
what the 4.2.1 reconciliation was about:

  <prefix>.zip                  PROJECT TEMPLATE payload — what a project is
                                stood up from. Carries NO Context Guard runtime
                                and no Context Guard hook/statusLine wiring, so
                                standing a project up cannot re-create
                                project-local Context Guard ownership.
  context-guard-<version>.zip   CONTEXT GUARD release — the runtime, the
                                installer, and the suites that prove them. This
                                is the fan-out artifact: installed once per
                                machine, never copied into a project.

Two files are in BOTH, and they are what keeps the split maintainable:
`.claude/settings.json` (the suite asserts it registers no Context Guard) and
`.claude/context-guard/config.json` (the project opt-in the installer copies).

Release gate: after building, run scripts/release-check.sh — it verifies the
UNPACKED artifact (never the tree). Green there is the only "ship" signal.

Reproducible: entries are sorted, every timestamp is pinned to SOURCE_DATE_EPOCH
(default 2026-08-27T00:00:00Z), compression is fixed. Same tree in, same sha256
out — so the hash in a report actually identifies a tree.
"""
import argparse, hashlib, json, os, sys, time, zipfile

for _s in (sys.stdout, sys.stderr):
    try:
        _s.reconfigure(encoding="utf-8", errors="replace")
    except (AttributeError, ValueError):
        pass

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PREFIX = os.path.basename(ROOT)

EXCLUDE_DIRS = {"__pycache__", ".git", ".pytest_cache", "node_modules",
                ".claude/handoffs"}
EXCLUDE_SUFFIX = (".pyc", ".pyo", ".bak", ".cg-tmp", ".orig", ".rej",
                  # Build products. The default --out-dir is outside the tree, but
                  # `--out-dir .` would drop a zip inside it and the NEXT build would
                  # ship that zip as payload. Cheaper to exclude than to remember.
                  ".zip", ".sha256")
EXCLUDE_NAMES = {".env", ".DS_Store", "Thumbs.db", "SHA256SUMS",
                 "release-blocklist.txt"}  # gate input, never payload
# Machine-local runtime files the template gitignores. The PreCompact snapshot rewrites
# handoff.md on every auto-compaction of a session working in the canonical tree, and it
# carries that session's transcript path (v8.3.25: caught by the field-name check).
EXCLUDE_PATHS = {".agent/state/handoff.md", "_reports/runs/latest.json"}

# Context Guard release only — deliberately absent from the project template.
CG_ONLY = ("context-guard/", "scripts/install-context-guard.py",
           "scripts/test-context-guard.sh", "scripts/test-onboarding.sh",
           "scripts/cg-acceptance.sh")
# In both artifacts.
SHARED = (".claude/settings.json", ".claude/context-guard/config.json")


def included(rel):
    parts = rel.split("/")
    if any(p in EXCLUDE_DIRS for p in parts):
        return False
    if "/".join(parts[:2]) in EXCLUDE_DIRS:
        return False
    if parts[-1] in EXCLUDE_NAMES or rel.endswith(EXCLUDE_SUFFIX):
        return False
    if rel in EXCLUDE_PATHS:
        return False
    return True


def is_cg(rel):
    return rel.startswith(CG_ONLY)


def collect():
    out = []
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = sorted(d for d in dirnames if d not in EXCLUDE_DIRS)
        for fn in sorted(filenames):
            full = os.path.join(dirpath, fn)
            rel = os.path.relpath(full, ROOT).replace("\\", "/")
            if included(rel):
                out.append((rel, full))
    return sorted(out)


def build(out_path, prefix, files, epoch):
    dt = time.gmtime(epoch)
    date_time = (dt.tm_year, dt.tm_mon, dt.tm_mday, dt.tm_hour, dt.tm_min, dt.tm_sec)
    tmp = out_path + ".building"
    with zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for rel, full in files:
            zi = zipfile.ZipInfo(prefix + "/" + rel, date_time=date_time)
            zi.compress_type = zipfile.ZIP_DEFLATED
            zi.external_attr = 0o644 << 16
            if rel.endswith((".sh", ".py")):
                zi.external_attr = 0o755 << 16
            with open(full, "rb") as f:
                z.writestr(zi, f.read())
    os.replace(tmp, out_path)

    h = hashlib.sha256()
    with open(out_path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    digest = h.hexdigest()
    with open(out_path.rsplit(".", 1)[0] + ".sha256", "w",
              encoding="utf-8", newline="\n") as f:
        f.write("%s  %s\n" % (digest, os.path.basename(out_path)))
    return digest


def build_bundle(out_path, members, epoch):
    """Zip the already-built artifacts FLAT (no folder prefix), so that unpacking the
    bundle into one directory makes `sha256sum -c SHA256SUMS` work with no arguments."""
    dt = time.gmtime(epoch)
    date_time = (dt.tm_year, dt.tm_mon, dt.tm_mday, dt.tm_hour, dt.tm_min, dt.tm_sec)
    tmp = out_path + ".building"
    with zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for full in members:
            zi = zipfile.ZipInfo(os.path.basename(full), date_time=date_time)
            zi.compress_type = zipfile.ZIP_DEFLATED
            zi.external_attr = 0o644 << 16
            with open(full, "rb") as f:
                z.writestr(zi, f.read())
    os.replace(tmp, out_path)
    h = hashlib.sha256()
    with open(out_path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    digest = h.hexdigest()
    with open(out_path.rsplit(".", 1)[0] + ".sha256", "w",
              encoding="utf-8", newline="\n") as f:
        f.write("%s  %s\n" % (digest, os.path.basename(out_path)))
    return digest


def sha256_of(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


# Where each artifact is published, relative to --published-root. Context Guard zips
# live in a subfolder so "the newest template zip at the top level" can never resolve
# to one; the top level is checked too, for anything published before that split.
PUBLISHED_AT = {"template": ("",), "context-guard": ("context-guard-releases", "")}


def published_clashes(root, built):
    """[(name, published path)] for every built artifact whose NAME is already
    published under `root` with DIFFERENT bytes. Identical bytes are a rebuild, fine."""
    out = []
    for kind, path in built:
        for sub in PUBLISHED_AT[kind]:
            pub = os.path.join(root, sub, os.path.basename(path))
            if os.path.isfile(pub) and sha256_of(pub) != sha256_of(path):
                out.append((os.path.basename(path), pub))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out-dir", default=os.path.dirname(ROOT))
    ap.add_argument("--published-root", default=None,
                    help="the shared releases folder; refuse any artifact whose name is "
                         "already published there with different bytes (v8.3.25)")
    ap.add_argument("--template-name", default=None,
                    help="template zip filename; default derives from "
                         "TEMPLATE_VERSION (fallback: the source dir name) — "
                         "never a hard-coded release name (field project B finding, "
                         "2026-08-30: the old literal default would os.replace "
                         "new content onto an OLD archived artifact)")
    # 2026-08-27T00:00:00Z — pinned so the same tree always hashes the same
    ap.add_argument("--epoch", type=int,
                    default=int(os.environ.get("SOURCE_DATE_EPOCH", 1787788800)))
    a = ap.parse_args()
    # A build writes (os.replace) before it can compare, so building INTO the published
    # folder would overwrite the very artifact the check protects, and then compare it
    # with itself. Refuse that before anything is written.
    if a.published_root:
        pr, od = os.path.realpath(a.published_root), os.path.realpath(a.out_dir)
        if od == pr or od.startswith(pr.rstrip(os.sep) + os.sep):
            sys.exit("REFUSING: --out-dir %s is inside --published-root %s — a build never "
                     "writes where published artifacts live" % (a.out_dir, a.published_root))

    ver = json.load(open(os.path.join(ROOT, "context-guard", "version.json"),
                         encoding="utf-8"))
    rv = ver["runtime_version"]
    files = collect()
    tpl = [(r, f) for r, f in files if not is_cg(r)]
    cg = [(r, f) for r, f in files if is_cg(r) or r in SHARED]

    # A template artifact that carries a runtime is the defect this split exists
    # to make impossible; refuse to ship one rather than warn about it.
    leaked = [r for r, _ in tpl if is_cg(r)]
    if leaked:
        sys.exit("REFUSING: template artifact carries Context Guard release files: %s"
                 % ", ".join(leaked))

    os.makedirs(a.out_dir, exist_ok=True)
    tv_path = os.path.join(ROOT, "TEMPLATE_VERSION")
    tv = open(tv_path).read().strip() if os.path.isfile(tv_path) else ""
    if not a.template_name:
        if tv:
            # Versioning policy (owner decision, 2026-09-01, v8.3.15): the artifact
            # name is the TEMPLATE_VERSION and nothing else — bump the last number
            # by 1 each release. No runtime suffix: the cg4/cg5 suffix scheme
            # produced two same-version artifacts with different names (a fork).
            # CG runtime pairing is recorded where it is enforced instead:
            # config.json min_runtime + the "runtime_version" line this build prints
            # + the CHANGELOG entry of the release.
            a.template_name = "%s.zip" % tv.replace(".", "_")
        else:
            a.template_name = "%s.zip" % PREFIX.replace(".", "_")
    tpl_out = os.path.join(a.out_dir, a.template_name)
    cg_out = os.path.join(a.out_dir, "context-guard-%s.zip" % rv)

    tpl_sha = build(tpl_out, PREFIX, tpl, a.epoch)
    cg_sha = build(cg_out, "context-guard-%s" % rv, cg, a.epoch)

    # ---- a published NAME is a promise about its bytes (v8.3.25) ----------------
    # v8.3.24 produced a second, byte-different context-guard-4.2.6.zip: the Context
    # Guard artifact also carries the SHARED settings.json, so a template-only edit gave
    # new bytes under an already-published runtime name, and anyone who had verified the
    # published hash now held a checksum for a file that no longer matched its name.
    # Nothing noticed, because the gate only ever inspected what it had just built.
    # Different bytes need a different name: bump runtime_version (Context Guard) or
    # TEMPLATE_VERSION (template). The refused artifacts are deleted, not left beside
    # the published ones where they could be picked up by name.
    if a.published_root:
        clashes = published_clashes(a.published_root,
                                    (("template", tpl_out), ("context-guard", cg_out)))
        if clashes:
            # ...and so is the bundle of any EARLIER build in this out-dir: left behind, it
            # would be the one file a human might still hand over.
            stale = [tpl_out, cg_out, os.path.join(a.out_dir, "SHA256SUMS"),
                     os.path.join(a.out_dir, "release_%s.zip" % (tv or PREFIX))]
            for pth in stale:
                for f in (pth, pth.rsplit(".", 1)[0] + ".sha256"):
                    if os.path.isfile(f):
                        os.remove(f)
            sys.exit("REFUSING: already published under the same name with DIFFERENT "
                     "bytes:\n" + "\n".join("  %s  (published: %s)" % c for c in clashes)
                     + "\nBump the version that names it — never overwrite a published "
                       "artifact.")

    # ---- the publishing bundle (v8.3.24) -------------------------------------
    # ONE file to hand over: both artifacts plus a SHA256SUMS covering exactly those
    # two, with a single outer .sha256 over the bundle itself.
    #
    # The manifest names the two artifacts EXPLICITLY and is never built from a glob.
    # A glob evaluated after the bundle exists would list the bundle inside its own
    # manifest, and a manifest that contains its own container cannot be verified.
    #
    # The bundle name deliberately does NOT match the `v8_3_*.zip` shape. The
    # workspace rule is "the current template is the newest zip of that shape at the
    # top level", so a bundle named to that pattern would silently BECOME the current
    # template the moment it was published, and the next upgrade would unpack a
    # wrapper where it expected a tree.
    manifest = "".join("%s  %s\n" % (h, os.path.basename(pth))
                       for pth, h in ((tpl_out, tpl_sha), (cg_out, cg_sha)))
    sums_out = os.path.join(a.out_dir, "SHA256SUMS")
    with open(sums_out, "w", encoding="utf-8", newline="\n") as f:
        f.write(manifest)
    bundle_out = os.path.join(a.out_dir, "release_%s.zip" % (tv or PREFIX))
    bundle_sha = build_bundle(bundle_out, (tpl_out, cg_out, sums_out), a.epoch)

    dt = time.gmtime(a.epoch)
    print("runtime_version : %s" % rv)
    print("schema_version  : %s" % ver["schema_version"])
    print("source_date     : %s (SOURCE_DATE_EPOCH=%d)"
          % (time.strftime("%Y-%m-%dT%H:%M:%SZ", dt), a.epoch))
    print()
    print("template artifact      : %s" % tpl_out.replace("\\", "/"))
    print("  files                : %d  (no CG runtime, no CG hook wiring)" % len(tpl))
    print("  sha256               : %s" % tpl_sha)
    print()
    print("context-guard artifact : %s" % cg_out.replace("\\", "/"))
    print("  files                : %d  (runtime + installer + suites)" % len(cg))
    print("  sha256               : %s" % cg_sha)
    print()
    print("release bundle         : %s" % bundle_out.replace("\\", "/"))
    print("  contains             : %s, %s, SHA256SUMS"
          % (os.path.basename(tpl_out), os.path.basename(cg_out)))
    print("  sha256               : %s" % bundle_sha)
    return 0


if __name__ == "__main__":
    sys.exit(main())
