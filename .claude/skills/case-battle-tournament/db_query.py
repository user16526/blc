"""Read-only SQL against the BLC replica when the postgres MCP is down (tunnel must be UP:
scripts/pg-tunnel-ensure.ps1). Reads PG* keys from the project .env, never prints them.
Usage: uv run --no-project --with "psycopg[binary]" python db_query.py <file.sql>   (statements split on ';\n')"""
import os, re, sys, psycopg

env = {}
for line in open(os.path.join(os.path.dirname(__file__), '../../../.env'), encoding='utf-8'):
    m = re.match(r'^(PG[A-Z_]*)=(.*)$', line.strip())
    if m:
        env[m[1]] = m[2].strip().strip('"\'')
sql = open(sys.argv[1], encoding='utf-8').read()
with psycopg.connect(host='127.0.0.1', port=int(env.get('PG_LOCAL_PORT') or 5432), dbname=env['PGDATABASE'],
                     user=env['PGUSER'], password=env['PGPASSWORD'],
                     options='-c default_transaction_read_only=on -c statement_timeout=60000') as c:
    for stmt in (s for s in sql.split(';\n') if s.strip() and not all(l.strip().startswith('--') or not l.strip() for l in s.splitlines())):
        cur = c.execute(stmt)
        if cur.description:
            print('\t'.join(d.name for d in cur.description))
            for r in cur.fetchall():
                print('\t'.join('' if v is None else str(v) for v in r))
