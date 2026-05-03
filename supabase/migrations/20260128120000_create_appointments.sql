create extension if not exists "pgcrypto";

create table if not exists public.appointments (
  id uuid primary key default gen_random_uuid(),
  client_id uuid references public.clients(id) on delete set null,
  pet_id uuid references public.pets(id) on delete set null,
  appointment_reason text,
  condition_status text,
  condition_notes text,
  temperature text,
  heart_rate text,
  prescriptions jsonb,
  created_at timestamptz default now()
);
