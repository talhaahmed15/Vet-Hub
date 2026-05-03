alter table if exists public.items
  add column if not exists clinic_id uuid references public.clinics(clinic_id) on delete cascade;

create index if not exists items_clinic_id_idx
  on public.items (clinic_id);

alter table if exists public.inventory_txns
  add column if not exists clinic_id uuid references public.clinics(clinic_id) on delete cascade;

create index if not exists inventory_txns_clinic_id_idx
  on public.inventory_txns (clinic_id);
