-- ACCOUNT SESSION
drop table if exists public.account_session;
create table public.account_session (
  id            bigint generated always as identity   primary key,

  account_id    uuid references auth.users not null,

  start_at   timestamp with time zone default timezone('utc'::text, now()) not null,
  end_at     timestamp with time zone
);
comment on table public.account_session is 'Individual messages sent by each user.';


-- USER PROFILE
drop table if exists public.user_profile;
create table public.user_profile (
  id          bigint generated always as identity primary key not null, 
  account_id  uuid references auth.users not null,

  email       text,
  phone       text,

  metadata    jsonb default '{}' 
);
comment on table  public.user_profile                    is 'Profile data for each user.';
comment on column public.user_profile.id                 is 'References the internal Supabase Auth user.';




-- WORKER PROFILE
drop table if exists public.worker_profile;
create table public.worker_profile (
  id            bigint generated always as identity   primary key,

  inserted_at   timestamp with time zone default timezone('utc'::text, now()) not null,
  last_update   timestamp with time zone default timezone('utc'::text, now()) not null,

  account_id    uuid   references auth.users            not null,

  metadata      jsonb default '{}'
);


comment on table  public.worker_profile              is 'Information of worker';
comment on column public.worker_profile.account_id   is 'public.auth column reference by account ';



-- account relationship
create type public.relationship as enum ('OWNER');
drop table if exists public.account_relationship;
create table public.account_relationship (
  id            bigint generated always as identity   primary key,

  worker_account     uuid not null references auth.users,
  user_account       uuid not null references auth.users,

  created_at    timestamp with time zone default timezone('utc'::text, now()) not null,
  ended_at      timestamp with time zone,

  o_type        relationship,
  metadata      jsonb default '{}'
);
comment on table public.account_relationship is 'Ownership orchestra accessability between specific worker and user';













-- WORKER APPLICATION
drop table if exists public.worker_session;
create table public.worker_session (
  id               bigint generated always as identity   primary key,

  session_id       bigint references public.account_session not null,

  manifest         jsonb default '{}',
  metadata         jsonb default '{}'
);
-- USER APPLICATION
drop table if exists public.user_session;
create table public.user_session (
  id               bigint generated always as identity   primary key,

  session_id       bigint references public.account_session,

  metadata         jsonb default '{}'
);



-- SESSION RELATIONSHIP
create type public.session_relationship_type as enum ('REMOTE');
drop table if exists public.session_relationship;
create table public.session_relationship (
  id               bigint generated always as identity   primary key,

  worker_session   bigint not null references public.account_session,
  user_session     bigint not null references public.account_session,

  realtionship     session_relationship_type default 'REMOTE' not null,
  metadata         jsonb default '{}'
);



























-- inserts a row into public.users and assigns roles
create or replace function public.handle_new_user()
returns trigger as
$$
    begin
        if position('@worker.com' in new.email) > 0 then

            insert into public.worker_profile (account_id) 
                values (new.id);

        else
            insert into public.user_profile(account_id, metadata, email) 
                values (new.id,new.raw_user_meta_data,new.email);

            -- TODO insert admin relationship
        end if;

        return new;
    end;
$$ language plpgsql security invoker;

-- trigger the function every time a user is created
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();





-- inserts a row into public.users and assigns roles
create or replace function public.handle_session()
returns trigger as
$$
    declare
        account auth.users%rowtype;
    begin

        select * from auth.users
        into account where id = new.account_id;


        if position('@worker.com' in account.email) > 0 then -- is worker session
          insert into public.worker_session (session_id)
          values ( new.id );
        else 
          insert into public.user_session (session_id)
          values ( new.id );
        end if;
        return new;
    end;
$$ language plpgsql security invoker;

-- trigger the function every time a user is created
drop trigger if exists on_session_created on public.worker_session;
create trigger on_session_created
  after insert on public.account_session
  for each row execute procedure public.handle_session();






























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

create function public.authorize_session(
  user_session   bigint,
  worker_session bigint,
  relation       session_relationship_type
)
returns boolean as
$$
  declare
    count int;
  begin
    select count(*) from public.account_relationship
    where
      worker_account = authorize_session.worker_session and
      user_account   = authorize_session.user_session and
      relationship       = authorize_session.relationship
    into count;

    return count > 0;
  end;
$$
language plpgsql security definer;




-- AUTHORIZE ACCOUNT
create function public.authorize_account(
  user_account   uuid,
  worker_account uuid,
  relation       relationship
)
returns boolean as
$$
  declare
    bind_permissions int;
  begin
    select count(*) from public.account_relationship
    where
      worker_account = authorize_account.worker_account and
      user_account   = authorize_account.user_account and
      relation       = authorize_account.relation
    into bind_permissions;


    return bind_permissions > 0;
  end;
$$
language plpgsql security definer;


create function public.session_owner(id bigint)
returns uuid as
$$
  declare
    _session public.account_session%rowtype;
  begin
    select * from public.account_session
    into _session where id = id;

    return _session.account_id;
  end;
$$
language plpgsql security definer;



-- SESSION RELATIONSHIP
create policy "Allow user select access" on public.session_relationship
  for select using (auth.uid() = session_owner(user_session));





-- ACCOUNT SESSION
create policy "Allow account insert access" on public.account_session
  for insert with check (auth.uid() = account_id);
create policy "Allow account read   access" on public.account_session
  for select using (auth.uid() = account_id);
create policy "Allow account update access" on public.account_session
  for update with check (auth.uid() = account_id);


-- WORKER APPLICATION
create policy "Validate worker application and image" on public.worker_session
  for insert with check (session_owner(session_id) = auth.uid());
create policy "Allow worker application" on public.worker_session
  for select using (session_owner(session_id) = auth.uid());

-- USER APPLICATION
create policy "Allow authorized user read session" on public.user_session
  for select using (session_owner(session_id) = auth.uid());
create policy "Allow authorized user update session" on public.user_session
  for update with check (session_owner(session_id) = auth.uid());
create policy "Allow authorized user insert session" on public.user_session
  for insert with check (session_owner(session_id) = auth.uid());



-- ACCOUNT RELATIONSHIP
create policy "Allow owner insert access" on public.account_relationship
  for insert with check (authorize_account(auth.uid(),worker_account,'OWNER'));
create policy "Allow owner update access" on public.account_relationship
  for update with check (authorize_account(auth.uid(),worker_account,'OWNER'));
create policy "Allow user select access" on public.account_relationship

  for select using (auth.uid() = user_account);
-- WORKER PROFILE
create policy "Allow individual read access" on public.worker_profile
  for select using (authorize_account(auth.uid(),account_id,'OWNER') or account_id = auth.uid());

-- USER PROFILE
create policy "Allow individual insert access" on public.user_profile
  for insert with check (auth.uid() = account_id);
create policy "Allow individual update access" on public.user_profile
  for update with check (auth.uid() = account_id);
create policy "Allow individual read access" on public.user_profile
  for select using (auth.uid() = account_id);