---
name: db-migrate
description: Migrate SQLite schema to PostgreSQL/Supabase with type conversion and validation
tools: [Read, Edit, Write, Glob, Grep, Bash]
disableModelInvocation: false
---

# Skill: Database Migration (SQLite → Cloud)

## Scope

Schema files, migration scripts, database directories, and SQL files across the project.

## Type Mapping

| SQLite | PostgreSQL |
|--------|-----------|
| `INTEGER PRIMARY KEY` | `SERIAL PRIMARY KEY` or `BIGSERIAL` |
| `TEXT` | `TEXT` |
| `REAL` | `NUMERIC` or `FLOAT8` |
| `DATETIME` (text) | `TIMESTAMPTZ` |
| `BLOB` | `BYTEA` |

## Workflow

1. Extract existing SQLite schema (`sqlite3 db.sqlite .schema`)
2. Transform data types to PostgreSQL equivalents
3. Generate new schema with `SERIAL` replacements and RLS policies
4. Validate: syntax, foreign keys, constraints
5. Deploy to **staging first**
6. Deploy to **production — requires user confirmation**

## Supabase Features

- Auto-generate Row Level Security (RLS) policies
- Push via Supabase CLI: `supabase db push`
- Generate TypeScript types: `supabase gen types typescript --local > types/supabase.ts`

## Safety

Staging validation is mandatory before any production change. Never skip the staging step.
