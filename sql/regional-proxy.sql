-- REGIONAL PROXY
drop table if exists public.regional_proxy;
create table public.regional_proxy (
  id            bigint generated always as identity primary key,
  account_id    uuid   not null,

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


-- REGIONAL PROXY
create policy "Allow select access" on public.regional_proxy
  for insert with check (auth.uid() = account_id);
create policy "Allow insert access" on public.regional_proxy
  for update with check (auth.uid() = account_id);
create policy "Allow individual read access" on public.regional_proxy
  for select using (true);


-- inserts a row into public.users and assigns roles
create or replace function public.handle_new_user()
returns trigger as
$$
    begin
        if position('.proxy@thinkmay.net' in new.email) > 0 then
            insert into public.regional_proxy(account_id) 
                values (new.id);
        else
        end if;

        return new;
    end;
$$ language plpgsql security invoker;

-- trigger the function every time a user is created
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
