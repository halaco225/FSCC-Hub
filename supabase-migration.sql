-- ============================================================
-- FSCC Hub — Supabase Migration
-- Store 039376 · Run this in your Supabase SQL Editor
-- ============================================================

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ── 1. 60-Day Tracker entries ──────────────────────────────
create table if not exists entries (
  id            text primary key,
  date          date not null,
  person        text,
  status        text check (status in ('Assigned','In Progress','Complete','Not Completed','')),
  rgm_schedule  text,
  dm_schedule   text,
  tasks         text,
  audit_desc    text,
  notes         text,
  updated_at    timestamptz default now(),
  updated_by    text,
  created_at    timestamptz default now()
);

-- ── 2. Finding resolutions ─────────────────────────────────
create table if not exists finding_resolutions (
  finding_id    text primary key,
  done          boolean default false,
  notes         text,
  resolved_by   text,
  resolved_date timestamptz,
  updated_at    timestamptz default now()
);

-- ── 3. Daily checklist log ─────────────────────────────────
create table if not exists checklist_logs (
  id            uuid primary key default uuid_generate_v4(),
  date          date not null,
  item_id       text not null,
  done          boolean default false,
  value         text,
  logged_time   text,
  unique (date, item_id)
);

-- ── 4. Temperature logs ────────────────────────────────────
create table if not exists temp_logs (
  id            text primary key,
  date          date not null,
  time          text,
  equipment     text not null,
  temp          numeric(5,1) not null,
  logged_by     text,
  notes         text,
  created_at    timestamptz default now()
);

-- ── 5. Pest walks ──────────────────────────────────────────
create table if not exists pest_walks (
  id            text primary key,
  date          date not null,
  week_of       date,
  completed_by  text,
  vendor        text default 'Orkin',
  result        text,
  notes         text,
  created_at    timestamptz default now()
);

-- ── 6. Uploaded files (metadata) ──────────────────────────
--   Actual blobs go in Supabase Storage bucket "fscc-files"
create table if not exists uploaded_files (
  id            text primary key,
  file_name     text not null,
  ext           text,
  size          bigint,
  category      text default 'Other',
  description   text,
  uploaded_by   text,
  date          date,                        -- date extracted from filename or set manually
  entry_id      text references entries(id) on delete set null,
  storage_path  text,                        -- path in Supabase Storage bucket
  created_at    timestamptz default now()
);

-- ── Indexes ────────────────────────────────────────────────
create index if not exists idx_entries_date       on entries (date);
create index if not exists idx_entries_person     on entries (person);
create index if not exists idx_entries_status     on entries (status);
create index if not exists idx_checklist_date     on checklist_logs (date);
create index if not exists idx_temp_logs_date     on temp_logs (date);
create index if not exists idx_pest_walks_date    on pest_walks (date);
create index if not exists idx_files_date         on uploaded_files (date);
create index if not exists idx_files_entry        on uploaded_files (entry_id);

-- ── Row-Level Security (optional, enable when using auth) ──
-- alter table entries enable row level security;
-- alter table uploaded_files enable row level security;

-- ── Supabase Storage bucket ────────────────────────────────
-- In Supabase dashboard → Storage → New bucket:
--   Name: fscc-files
--   Public: false (authenticated access only)
--   Max file size: 50MB

-- ============================================================
-- MIGRATION NOTES
-- To migrate existing localStorage data:
-- 1. Export from browser console: JSON.stringify(Object.fromEntries(
--      Object.entries(localStorage).filter(([k]) => k.startsWith('fscc_'))))
-- 2. Paste into a migration script using the Supabase JS client
-- ============================================================
