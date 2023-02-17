

drop table if exists public.user_application;
drop table if exists public.worker_application;
drop table if exists public.application_image;
drop table if exists public.worker_metric;
drop table if exists public.worker_profile;
drop table if exists public.regional_proxy;
drop table if exists public.user_profile;
drop table if exists public.global_mail;
drop table if exists public.account_relationship;
drop table if exists public.account_mail;
drop table if exists public.session_mail;
drop table if exists public.session_relationship;
drop table if exists public.account_session;

drop trigger if exists on_auth_user_created on auth.users;
drop trigger if exists on_worker_session_created on public.worker_application;
drop trigger if exists on_user_session_created on public.user_application;

drop function if exists public.authorize_session;
drop function if exists public.validate_image;
drop function if exists public.session_owner;
drop function if exists public.find_worker_account;
drop function if exists public.is_user_account;
drop function if exists public.is_worker_account;
drop function if exists public.authorize_account;

drop type  if exists  public.account_mail_type;
drop type  if exists  public.global_mail_type;
drop type  if exists  public.session_mail_type;
drop type  if exists  public.relationship;
drop type  if exists  public.session_relationship_type;

delete from auth.users
where true;
