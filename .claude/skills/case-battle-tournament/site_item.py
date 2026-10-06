"""Print ID + live price for bloodycase.com item URLs, and flag freshness repeats.
ID = the wear's NORMAL item Id (= client_items.item_id), price (cents) = buyout_price; see the lookup comment below.
--exclude <tsv from exclusions.sql>: a skin is a REPEAT when ANY of its wears' Ids is in the set
(same skin in another wear counts as a repeat).
Last column: picked wear price / dearest OTHER wear price; WEAR-OUTLIER at >=5x (owner 2026-10-06:
avoid a skin whose one wear is extra expensive, e.g. AK-47 Aphrodite FN), normal items only. STATTRAK = the
wear exists only as StatTrak (owner: avoid). REPEAT checks normal AND StatTrak Ids.
Usage: python site_item.py [--exclude excl.tsv] [--wears] https://bloodycase.com/item/hand-wraps-cobalt-skulls#field-tested ..."""
import json, re, sys, time, urllib.request
sys.stdout.reconfigure(encoding="utf-8")

WEAR = {'factory-new': 'FactoryNew', 'minimal-wear': 'MinimalWear', 'field-tested': 'FieldTested',
        'well-worn': 'WellWorn', 'battle-scarred': 'BattleScarred', 'unknown': 'Unknown'}

args = [a for a in sys.argv[1:] if a != "--wears"]
excl = {}
if args[:1] == ['--exclude']:
    for line in open(args[1], encoding='utf-8'):
        f = line.rstrip('\n').split('\t')
        if f[0].isdigit():
            excl.setdefault(int(f[0]), []).append(f[1] if len(f) > 1 else '')
    args = args[2:]

for u in (a.strip() for a in args):
    base, _, frag = u.partition('#')
    req = urllib.request.Request(base, headers={'User-Agent': 'Mozilla/5.0', 'Cookie': 'CurrencyCode=USD; lang=en'})
    try:
        t = urllib.request.urlopen(req, timeout=40).read().decode('utf-8')
    except Exception as err:
        print(f'?? {err}  {u}', flush=True)
        continue
    s = json.loads(re.search(r'<script id="server_app-state" type="application/json">(.*?)</script>', t, re.S).group(1))
    d = next(v for k, v in s.items() if k.startswith('item_details'))
    # Exteriors (by wear key) may hold the StatTrak item; ExteriorList carries both: Id/Price = normal
    # unless IsStattrack, IdStattrack/PriceStattrack = StatTrak. Pick the normal item; ST only -> flagged.
    ex = d['Exteriors']
    norm, st, ids, dup = {}, {}, set(), {}
    for k, x in ex.items():  # the displayed item first
        if not x.get('IsStattrack'):
            norm[k] = (x['Id'], x['Price'])
    for x in d.get('ExteriorList') or []:
        if not x.get('IsStattrack'):
            dup.setdefault(re.sub('[^A-Za-z]', '', x['Name']), set()).add(x['Id'])
        k = re.sub('[^A-Za-z]', '', x['Name'])
        (st if x.get('IsStattrack') else norm).setdefault(k, (x['Id'], x['Price']))
        if x.get('IdStattrack') and x['IdStattrack'] != x['Id']:
            st.setdefault(k, (x['IdStattrack'], x['PriceStattrack']))
        ids |= {x['Id'], x.get('IdStattrack')}
    for k, x in ex.items():
        (st if x.get('IsStattrack') else norm).setdefault(k, (x['Id'], x['Price']))
        ids.add(x['Id'])
    key = WEAR.get(frag, '')
    if key not in norm and key not in st and len(norm) + len(st) == 1:
        key = next(iter(norm or st))
    e, only_st = (norm[key], False) if key in norm else (st.get(key), True)
    if not e:
        print(f'?? wear "{frag}" not in {sorted(set(norm) | set(st))}  {u}')
        continue
    hits = sorted({src for i in ids for src in excl.get(i, [])})
    flag = ('REPEAT: ' + '; '.join(hits)) if hits else ('fresh' if excl else '')
    others = [pr for k, (i, pr) in norm.items() if k != key and pr]
    r = e[1] / max(others) if others else 0
    wear = (f'wear x{r:.1f}' + (' WEAR-OUTLIER' if r >= 5 else '')) if others else 'one wear'
    if len(dup.get(key, ())) > 1:  # e.g. Desert Eagle | Sunset Storm 壱/弐 share one page
        wear += ' 2-VARIANTS ' + '/'.join(map(str, sorted(dup[key]))) + ' (ID = the displayed one)'
    if only_st:
        wear += ' STATTRAK (no normal item in this wear)'
    if '--wears' in sys.argv:
        wear += '  [' + ' '.join(f"{k}:{i}:${pr / 100:,.2f}" for k, (i, pr) in norm.items())
        wear += ' | ST ' + ' '.join(f"{k}:{i}:${pr / 100:,.2f}" for k, (i, pr) in st.items()) + ']'
    print(f"{e[0]}\t${e[1] / 100:,.2f}\t{d['GroupName']} ({frag})\t{flag}\t{u}\t{wear}", flush=True)
    time.sleep(1)
