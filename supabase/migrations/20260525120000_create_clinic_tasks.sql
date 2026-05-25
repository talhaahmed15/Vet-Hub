-- Helper to read the calling user's role within a given clinic.
create or replace function public.current_clinic_user_role(target_clinic_id uuid)
returns text
language sql
security definer
stable
as $$
  select role
  from public.clinic_users
  where clinic_id = target_clinic_id
    and auth_user_id = auth.uid()
  limit 1;
$$;

revoke all on function public.current_clinic_user_role(uuid) from public;
grant execute on function public.current_clinic_user_role(uuid) to authenticated;

create table if not exists public.clinic_tasks (
  id           uuid primary key default gen_random_uuid(),
  clinic_id    uuid not null references public.clinics(clinic_id) on delete cascade,
  title        text not null check (char_length(title) between 1 and 200),
  description  text,
  assignee_id  uuid not null references public.clinic_users(id) on delete cascade,
  status       text not null default 'todo'
               check (status in ('todo','in_progress','done')),
  created_by   uuid not null references public.clinic_users(id),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index if not exists clinic_tasks_clinic_status_idx
  on public.clinic_tasks(clinic_id, status);
create index if not exists clinic_tasks_assignee_status_idx
  on public.clinic_tasks(assignee_id, status);

-- Auto-update updated_at on row updates.
create or replace function public.touch_clinic_tasks_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists clinic_tasks_touch_updated_at on public.clinic_tasks;
create trigger clinic_tasks_touch_updated_at
  before update on public.clinic_tasks
  for each row execute function public.touch_clinic_tasks_updated_at();

alter table public.clinic_tasks enable row level security;

-- SELECT: any user in the same clinic can read.
create policy clinic_tasks_select on public.clinic_tasks
  for select to authenticated
  using (
    exists (
      select 1 from public.clinic_users cu
      where cu.clinic_id = clinic_tasks.clinic_id
        and cu.auth_user_id = auth.uid()
    )
  );

-- INSERT: only owner or admin in that clinic.
create policy clinic_tasks_insert on public.clinic_tasks
  for insert to authenticated
  with check (
    public.current_clinic_user_role(clinic_id) in ('owner','admin')
  );

-- UPDATE: owner/admin of the clinic OR the assignee themselves.
create policy clinic_tasks_update on public.clinic_tasks
  for update to authenticated
  using (
    public.current_clinic_user_role(clinic_id) in ('owner','admin')
    or exists (
      select 1 from public.clinic_users cu
      where cu.id = clinic_tasks.assignee_id
        and cu.auth_user_id = auth.uid()
    )
  )
  with check (
    public.current_clinic_user_role(clinic_id) in ('owner','admin')
    or exists (
      select 1 from public.clinic_users cu
      where cu.id = clinic_tasks.assignee_id
        and cu.auth_user_id = auth.uid()
    )
  );

-- DELETE: owner/admin only.
create policy clinic_tasks_delete on public.clinic_tasks
  for delete to authenticated
  using (
    public.current_clinic_user_role(clinic_id) in ('owner','admin')
  );
