do $$
begin
  if not exists (select 1 from pg_type where typname = 'clinic_role') then
    create type clinic_role as enum (
      'owner',
      'admin',
      'vet',
      'receptionist',
      'assistant'
    );
  end if;
end $$;

create table if not exists clinic_users (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references clinics(clinic_id) on delete cascade,
  auth_user_id uuid references auth.users(id) on delete set null,
  full_name text not null,
  email text not null,
  phone text,
  role clinic_role not null default 'vet',
  created_at timestamp with time zone default now()
);

create unique index if not exists clinic_users_clinic_email_idx
  on clinic_users (clinic_id, email);

alter table clinic_users enable row level security;
