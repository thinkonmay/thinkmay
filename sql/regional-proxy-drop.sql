drop table if exists public.regional_proxy;
drop table if exists public.worker_metric;

delete from auth.users where true;
drop trigger if exists on_auth_user_created on auth.user;
drop function if exists public.handle_new_user;