alter table public.clients
add column if not exists clinic_id uuid references public.clinics(id) on delete set null;
