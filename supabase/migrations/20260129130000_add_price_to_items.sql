alter table if exists public.items
  add column if not exists price numeric(12, 2) not null default 0;
