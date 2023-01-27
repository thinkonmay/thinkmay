/**
 * REALTIME SUBSCRIPTIONS
 * Only allow realtime listening on public tables.
 */

-- Send "previous data" on change
alter table public.session_mail         replica identity full;
alter table public.account_mail         replica identity full;
alter table public.regional_proxy       replica identity full;
alter table public.worker_profile       replica identity full;
alter table public.worker_application   replica identity full;
alter table public.worker_metric        replica identity full;

begin;
  -- remove the realtime publication
  drop publication if exists supabase_realtime;

  -- re-create the publication but don't enable it for any tables
  create publication supabase_realtime;
commit;

-- add tables to the publication
alter publication supabase_realtime add table public.session_mail;
alter publication supabase_realtime add table public.account_mail;
alter publication supabase_realtime add table public.regional_proxy;
alter publication supabase_realtime add table public.worker_profile;
alter publication supabase_realtime add table public.worker_application;
alter publication supabase_realtime add table public.worker_metric;