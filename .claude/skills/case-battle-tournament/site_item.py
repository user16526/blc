"""Print ID + live price for bloodycase.com item URLs.
ID = Exteriors[wear].Id = client_items.item_id; price = Exteriors[wear].Price (cents) = buyout_price.
Usage: python site_item.py https://bloodycase.com/item/hand-wraps-cobalt-skulls#field-tested ..."""
import json, re, sys, time, urllib.request

WEAR = {'factory-new': 'FactoryNew', 'minimal-wear': 'MinimalWear', 'field-tested': 'FieldTested',
        'well-worn': 'WellWorn', 'battle-scarred': 'BattleScarred', 'unknown': 'Unknown'}

for u in sys.argv[1:]:
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
    print(f"{e['Id']}\t${e['Price'] / 100:,.2f}\t{d['GroupName']} ({frag})\t{u}", flush=True)
    time.sleep(1)
