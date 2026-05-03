do $$
begin
  if not exists (select 1 from pg_type where typname = 'account_status') then
    create type account_status as enum ('under_review', 'active', 'blocked');
  end if;
end $$;

alter table clinic_users
  add column if not exists account_status account_status
  not null
  default 'under_review';

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'clinic_users'
      and policyname = 'clinic_users_select_own'
  ) then
    create policy "clinic_users_select_own"
      on clinic_users
      for select
      to authenticated
      using (auth.uid() = auth_user_id);
  end if;
end $$;
