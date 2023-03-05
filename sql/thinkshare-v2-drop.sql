drop table if exists public.user_session;
drop table if exists public.worker_session;
drop table if exists public.session_relationship;
drop table if exists public.account_session;

drop table if exists public.worker_profile;
drop table if exists public.user_profile;
drop table if exists public.account_relationship;
delete from auth.users where true;

drop trigger if exists on_auth_user_created on auth.users;
drop trigger if exists on_session_created   on public.account_session;
drop trigger if exists on_user_session_created on public.user_session;

drop function if exists public.handle_new_user;
drop function if exists public.handle_session;
drop function if exists public.session_owner;
drop function if exists public.authorize_account;
drop function if exists public.authorize_session;

drop type  if exists  public.relationship;
drop type  if exists  public.session_relationship_type;

