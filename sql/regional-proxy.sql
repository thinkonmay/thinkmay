-- REGIONAL PROXY
drop table if exists public.regional_proxy;
create table public.regional_proxy (
  id            bigint generated always as identity primary key,
  ip            text not null,

  inserted_at   timestamp with time zone default timezone('utc'::text, now()) not null,
  last_update   timestamp with time zone default timezone('utc'::text, now()) not null,

  metadata      jsonb default '{}'
);
comment on table public.regional_proxy   is 'Regional proxy';


-- WORKER METRIC
drop table if exists public.worker_metric;
create table public.worker_metric (
  id            bigint generated always as identity  primary key,

  worker_id     bigint,

  get_at        timestamp with time zone default timezone('utc'::text, now()) not null,
  val           jsonb default '{}' not null
);
comment on table public.worker_metric is 'Worker metric reported by workers';





-- RLS
-- SECURE ALL THE TABLES
do
$$
declare
    row record;
begin
    for row in select tablename from pg_tables as t
        where t.schemaname = 'public' -- WITH "PUBLIC.*" SCHEMA
    loop
        execute format('alter table %I enable row level security;', row.tablename); -- ENABLE RLS FOR TABLES
    end loop;
end;
$$;