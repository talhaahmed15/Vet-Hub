create extension if not exists "pgcrypto";

create table if not exists packages (
  package_id uuid primary key default gen_random_uuid(),
  package_key text unique not null,
  name text not null,
  price_cents integer default 0,
  billing_cycle text default 'monthly',
  trial_days integer default 0,
  is_active boolean default true,
  created_at timestamptz default now()
);

create table if not exists clinic_subscriptions (
  subscription_id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references clinics(clinic_id) on delete cascade,
  package_id uuid not null references packages(package_id),
  status text not null default 'active',
  starts_at timestamptz default now(),
  ends_at timestamptz,
  is_trial boolean default false,
  created_at timestamptz default now()
);

alter table clinics
  add column if not exists package_id uuid references packages(package_id),
  add column if not exists package_status text default 'active',
  add column if not exists trial_end_at timestamptz;

-- Optional seed data (safe with ON CONFLICT)
insert into packages (package_key, name, price_cents, billing_cycle, trial_days, is_active)
values
  ('trial', 'Trial', 0, 'trial', 14, true),
  ('basic', 'Basic', 2900, 'monthly', 0, true),
  ('pro', 'Pro', 5900, 'monthly', 0, true)
on conflict (package_key) do nothing;
