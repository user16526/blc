# Rule: Local-First Development

## Core Principle

Develop locally first, migrate to cloud only after the schema stabilizes.

## Workflow

### Phase 1 — Local SQLite

1. Create the schema in SQLite
2. Write migrations
3. Implement CRUD and business logic
4. Iterate until the schema is stable across multiple changes

A schema mistake locally can be fixed in seconds with zero consequences.

### Phase 2 — Cloud Migration (only after stabilization)

1. Convert the schema to PostgreSQL/Supabase-compatible SQL
2. Create migration scripts
3. Test on staging
4. Deploy to production — **requires user confirmation**

Use `/db-migrate` to automate the SQLite → cloud transition.

## Rationale

Local SQLite allows immediate iteration without network delays or external dependencies. Schema changes that take seconds locally can take minutes in cloud environments and carry data loss risk.

## Exception

If the project already uses a cloud database — do not force SQLite adoption. Instead, maintain a staging copy and follow the staging → production pathway.
