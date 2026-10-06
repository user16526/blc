"""Print ID + live price for bloodycase.com item URLs, and flag freshness repeats.
ID = Exteriors[wear].Id = client_items.item_id; price = Exteriors[wear].Price (cents) = buyout_price.
--exclude <tsv from exclusions.sql>: a skin is a REPEAT when ANY of its wears' Ids is in the set
(same skin in another wear counts as a repeat).
Usage: python site_item.py [--exclude excl.tsv] https://bloodycase.com/item/hand-wraps-cobalt-skulls#field-tested ..."""
import json, re, sys, time, urllib.request
sys.stdout.reconfigure(encoding="utf-8")

WEAR = {'factory-new': 'FactoryNew', 'minimal-wear': 'MinimalWear', 'field-tested': 'FieldTested',
        'well-worn': 'WellWorn', 'battle-scarred': 'BattleScarred', 'unknown': 'Unknown'}

args = sys.argv[1:]
excl = {}
if args[:1] == ['--exclude']:
    for line in open(args[1], encoding='utf-8'):
        f = line.rstrip('\n').split('\t')
        if f[0].isdigit():
            excl.setdefault(int(f[0]), []).append(f[1] if len(f) > 1 else '')
    args = args[2:]

for u in args:
    base, _, frag = u.partition('#')
    req = urllib.request.Request(base, headers={'User-Agent': 'Mozilla/5.0', 'Cookie': 'CurrencyCode=USD; lang=en'})
    t = urllib.request.urlopen(req, timeout=40).read().decode('utf-8')
    s = json.loads(re.search(r'<script id="server_app-state" type="application/json">(.*?)</script>', t, re.S).group(1))
    d = next(v for k, v in s.items() if k.startswith('item_details'))
    ex = d['Exteriors']
    e = ex.get(WEAR.get(frag, '')) or (next(iter(ex.values())) if len(ex) == 1 else None)
    if not e:
        print(f'?? wear "{frag}" not in {list(ex)}  {u}')
        continue
    hits = sorted({src for w in ex.values() for src in excl.get(w['Id'], [])})
    flag = ('REPEAT: ' + '; '.join(hits)) if hits else ('fresh' if excl else '')
    print(f"{e['Id']}\t${e['Price'] / 100:,.2f}\t{d['GroupName']} ({frag})\t{flag}\t{u}", flush=True)
    time.sleep(1)
