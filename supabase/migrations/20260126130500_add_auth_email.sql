alter table clinic_users add column if not exists auth_email text;

create unique index if not exists clinic_users_auth_email_idx
  on clinic_users (auth_email);
