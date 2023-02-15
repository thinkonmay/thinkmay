-- ACCOUNT SESSION
drop table if exists public.account_session;
create table public.account_session (
  id            bigint generated always as identity   primary key,

  account_id    uuid references auth.users not null,

  start_at   timestamp with time zone default timezone('utc'::text, now()) not null,
  end_at     timestamp with time zone
);
comment on table public.account_session is 'Individual messages sent by each user.';

-- ACCOUNT MAIL
drop table if exists public.account_mail;
create type public.account_mail_type as enum ('START_APP');
create table public.account_mail (
  id            bigint generated always as identity   primary key,
  inserted_at   timestamp with time zone default timezone('utc'::text, now()) not null,

  from_id       uuid references auth.users not null,
  to_id         uuid references auth.users not null,

  message_type  account_mail_type not null,
  message       jsonb default '{}'
);
comment on table public.account_mail is 'Individual messages sent from and to accounts.';



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

-- GLOBAL MAIL
create type public.global_mail_type as enum ('NEW_VERSION');
drop table if exists public.global_mail;
create table public.global_mail (
  id            bigint generated always as identity   primary key,
  inserted_at   timestamp with time zone default timezone('utc'::text, now()) not null,

  message_type  global_mail_type not null,
  message       jsonb default '{}'
);

-- REGIONAL PROXY
drop table if exists public.regional_proxy;
create table public.regional_proxy (
  id            bigint generated always as identity   primary key,

  ip            text not null,

  region        text,
  metadata      jsonb default '{}'
);
comment on table public.regional_proxy   is 'Regional proxy';

-- WORKER PROFILE
drop table if exists public.worker_profile;
create table public.worker_profile (
  id            bigint generated always as identity   primary key,

  inserted_at   timestamp with time zone default timezone('utc'::text, now()) not null,
  last_update   timestamp with time zone default timezone('utc'::text, now()) not null,

  proxy_id      bigint references public.regional_proxy,
  account_id    uuid   references auth.users            not null,

  metadata      jsonb default '{}'
);
comment on table  public.worker_profile              is 'Information of worker';
comment on column public.worker_profile.account_id   is 'public.auth column reference by account ';


-- WORKER METRIC
drop table if exists public.worker_metric;
create table public.worker_metric (
  id            bigint generated always as identity   primary key,

  worker_id     bigint not null references public.worker_profile,

  get_at        timestamp with time zone default timezone('utc'::text, now()) not null,
  val           jsonb default '{}' not null
);
comment on table public.worker_metric is 'Worker metric reported by workers';


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


-- SESSION MAIL
create type public.session_mail_type as enum ('SDP', 'ICE', 'START', 'END');
create table public.session_mail (
  id            bigint generated always as identity   primary key,
  inserted_at   timestamp with time zone default timezone('utc'::text, now()) not null,

  from_id       bigint references public.account_session not null,
  to_id         bigint references public.account_session not null,

  message_type  session_mail_type not null,
  message       jsonb default '{}'
);













-- APPLICATION IMAGE
drop type if exists public.application_mode;
create type public.application_mode as enum ('SINGLETON','DAEMON','APPLICATION');
drop table if exists public.application_image;
create table public.application_image (
  id               bigint generated always as identity   primary key,
  worker_id        bigint references public.worker_profile not null, 
  mode 			   application_mode not null,

  inserted_at      timestamp with time zone default timezone('utc'::text, now()) not null,
  deactivated_at   timestamp with time zone default timezone('utc'::text, now()) not null,

  name             text not null,
  manifest         jsonb default '{}',

  metadata         jsonb default '{}'
);
-- WORKER APPLICATION
drop table if exists public.worker_application;
create table public.worker_application (
  id               bigint generated always as identity   primary key,

  session_id       bigint references public.account_session not null,
  app              bigint references public.application_image not null,

  manifest         jsonb default '{}',
  metadata         jsonb default '{}'
);
-- USER APPLICATION
drop table if exists public.user_application;
create table public.user_application (
  id            bigint generated always as identity   primary key,

  session_id         bigint references public.account_session,

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
create or replace function public.handle_new_worker_session()
returns trigger as
$$
    declare
        account auth.users%rowtype;
    begin
        select * from auth.users
        into account where id = auth.uid();


        if position('@worker.com' in account.email) > 0 then
        else 
            raise 'Cannot insert user session.';  
        end if;

        insert into public.account_session (account_id)
        values ( auth.uid()) returning id;

        new.session_id = id;

        return new;
    end;
$$ language plpgsql security invoker;

-- trigger the function every time a user is created
drop trigger if exists on_worker_session_created on public.worker_application;
create trigger on_worker_session_created
  after insert on public.worker_application
  for each row execute procedure public.handle_new_worker_session();






-- inserts a row into public.users and assigns roles
create or replace function public.handle_new_user_session()
returns trigger as
$$
    declare
        account auth.users%rowtype;
        id int;
    begin
        select * from auth.users
        into account where id = auth.uid();


        if position('@worker.com' in account.email) > 0 then
            raise 'Cannot insert worker session.';  
        else
        end if;

        insert into public.account_session (account_id)
        values ( auth.uid()) returning id;

        new.session_id = id;

        return new;
    end;
$$ language plpgsql security invoker;

-- trigger the function every time a user is created
drop trigger if exists on_user_session_created on public.user_application;
create trigger on_user_session_created
  after insert on public.user_application
  for each row execute procedure public.handle_new_user_session();










/**
 * REALTIME SUBSCRIPTIONS
 * Only allow realtime listening on public tables.
 */

-- Send "previous data" on change
alter table public.session_mail         replica identity full;
alter table public.account_mail         replica identity full;

begin;
  -- remove the realtime publication
  drop publication if exists supabase_realtime;

  -- re-create the publication but don't enable it for any tables
  create publication supabase_realtime;
commit;

-- add tables to the publication
alter publication supabase_realtime add table public.session_mail;
alter publication supabase_realtime add table public.account_mail;





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


create function public.validate_image(
  image_id bigint,
  worker_account uuid)
returns boolean as
$$
  declare
    profile public.worker_profile%rowtype;
    image   public.application_image%rowtype;
  begin
    select * from public.application_image
    into image where id = validate_image.image_id;

    select * from public.worker_profile
    into profile where id = image.worker_id;

    return profile.account_id = worker_account;
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



create function public.find_worker_account(id bigint)
returns uuid as
$$
  declare
    worker public.worker_profile%rowtype;
  begin
    select * from public.worker_profile
    into worker where id = id;

    return worker.account_id;
  end;
$$
language plpgsql security definer;


-- IS USER ACCOUNT
create function public.is_user_account(id uuid)
returns boolean as
$$
  declare
    account auth.users%rowtype;
  begin
    select * from auth.users
    into account where id = id;

    return not (position('@worker.com' in account.email) > 0);
  end;
$$
language plpgsql security definer;




-- IS WORKER ACCOUNT
create function public.is_worker_account(id uuid)
returns boolean as
$$
  declare
    account auth.users%rowtype;
  begin
    select * from auth.users
    into account where id = id;

    return position('@worker.com' in account.email) > 0;
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


-- SESSION RELATIONSHIP
create policy "Allow owner insert access" on public.session_relationship
  for insert with check (
      auth.uid() = session_owner(user_session) 
      and 
      authorize_account(
        session_owner(worker_session),
        session_owner(user_session),
        'OWNER')
    );
create policy "Allow owner update access" on public.session_relationship
  for update with check (
      auth.uid() = session_owner(user_session) 
      and 
      authorize_account(
        session_owner(worker_session),
        session_owner(user_session),
        'OWNER')
    );
create policy "Allow user select access" on public.session_relationship
  for select using (auth.uid() = session_owner(user_session));



-- ACCOUNT RELATIONSHIP
create policy "Allow owner insert access" on public.account_relationship
  for insert with check (authorize_account(auth.uid(),worker_account,'OWNER'));
create policy "Allow owner update access" on public.account_relationship
  for update with check (authorize_account(auth.uid(),worker_account,'OWNER'));
create policy "Allow user select access" on public.account_relationship
  for select using (auth.uid() = user_account);


-- WORKER APPLICATION
create policy "Validate worker application and image" on public.worker_application
  for insert with check (session_owner(session_id) = auth.uid() and validate_image(app,auth.uid()));
create policy "Allow worker application" on public.worker_application
  for select using (session_owner(session_id) = auth.uid());

-- USER APPLICATION
create policy "Allow authorized user read session" on public.user_application
  for select using (session_owner(session_id) = auth.uid());
create policy "Allow authorized user update session" on public.user_application
  for update with check (session_owner(session_id) = auth.uid());
create policy "Allow authorized user insert session" on public.user_application
  for insert with check (session_owner(session_id) = auth.uid());



-- SESSION MAIL
create policy "Allow account insert access" on public.session_mail
  for insert with check (session_owner(from_id) = auth.uid() and authorize_session(from_id,to_id,'REMOTE'));
create policy "Allow account read access" on public.session_mail
  for select using (auth.uid() = session_owner(to_id));

-- ACCOUNT SESSION
create policy "Allow account insert access" on public.account_session
  for insert with check (auth.uid() = account_id);
create policy "Allow account read   access" on public.account_session
  for select using (auth.uid() = account_id);
create policy "Allow account update access" on public.account_session
  for update with check (auth.uid() = account_id);

--- APPLICATION IMAGE
create policy "Allow individual insert access" on public.application_image
  for insert with check (authorize_account(auth.uid(),find_worker_account(worker_id),'OWNER'));
create policy "Allow worker and owner select access" on public.application_image
  for select using (authorize_account(auth.uid(),find_worker_account(worker_id),'OWNER') or (auth.uid() = find_worker_account(worker_id)));

-- WORKER METRIC
create policy "Allow worker insert access" on public.worker_metric
  for insert with check (auth.uid() = find_worker_account(worker_id));
create policy "Allow worker select access" on public.worker_metric
  for select using (authorize_account(auth.uid(),find_worker_account(worker_id),'OWNER') );

-- REGIONAL PROXY
create policy "Allow worker select access" on public.regional_proxy
  for select using (is_worker_account(auth.uid()));
create policy "Allow worker insert access" on public.regional_proxy
  for insert using (auth.uid() = 'service_role');

-- WORKER PROFILE
create policy "Allow individual read access" on public.worker_profile
  for select using (authorize_account(auth.uid(),account_id,'OWNER') or account_id = auth.uid());






-- GLOBAL MAIL
create policy "Allow logged-in read access" on public.global_mail
  for select using (auth.role() = 'authenticated');

-- USER PROFILE
create policy "Allow individual insert access" on public.user_profile
  for insert with check (auth.uid() = account_id);
create policy "Allow individual update access" on public.user_profile
  for update with check (auth.uid() = account_id);
create policy "Allow individual read access" on public.user_profile
  for select using (auth.uid() = account_id);