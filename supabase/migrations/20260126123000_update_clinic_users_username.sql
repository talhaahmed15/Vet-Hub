do $$
begin
  if not exists (
    select 1
    from information_schema.columns
    where table_name = 'clinic_users'
      and column_name = 'username'
  ) then
    alter table clinic_users add column username text;
  end if;

  if exists (
    select 1
    from information_schema.columns
    where table_name = 'clinic_users'
      and column_name = 'email'
  ) then
    execute
      'update clinic_users set username = email where username is null';
    execute 'alter table clinic_users alter column email drop not null';
  else
    execute
      'update clinic_users set username = coalesce(phone, auth_user_id::text, full_name, gen_random_uuid()::text) where username is null';
  end if;

  execute 'alter table clinic_users alter column username set not null';
end $$;

drop index if exists clinic_users_clinic_email_idx;

create unique index if not exists clinic_users_clinic_username_idx
  on clinic_users (clinic_id, username);
