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

  username    text,
  fullname    text,

  email       text,
  phone       text,

  picture     text,

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

  proxy_id      bigint references public.regional_proxy,
  account_id    uuid   references auth.users            not null,

  active        boolean default true,
  last_update   timestamp with time zone default timezone('utc'::text, now()) not null,

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
create type public.relationship as enum ('OWNER','BORROWER','WATCHER');
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
create type public.session_mail_type as enum ('SDP', 'ICE', 'START', 'END', 'PREFLIGHT');
create table public.session_mail (
  id            bigint generated always as identity   primary key,
  inserted_at   timestamp with time zone default timezone('utc'::text, now()) not null,

  from_id       bigint references public.account_session not null,
  to_id         bigint references public.account_session not null,

  message_type  session_mail_type not null,
  message       jsonb default '{}'
);













-- APPLICATION IMAGE
drop table if exists public.application_image;
create table public.application_image (
  id               bigint generated always as identity   primary key,
  worker_id        bigint references public.worker_profile not null, 

  inserted_at      timestamp with time zone default timezone('utc'::text, now()) not null,
  deactivated_at   timestamp with time zone default timezone('utc'::text, now()) not null,

  name             text not null,
  path             text not null,
  args             jsonb default '{}',
  metadata         jsonb default '{}'
);
-- WORKER APPLICATION
drop table if exists public.worker_application;
create table public.worker_application (
  id               bigint generated always as identity   primary key,

  session_id       bigint references public.account_session not null,
  app              bigint references public.application_image not null,

  metadata         jsonb default '{}'
);
-- USER APPLICATION
drop table if exists public.user_application;
create table public.user_application (
  id            bigint generated always as identity   primary key,

  session_id         bigint references public.account_session,
  worker_app         bigint references public.worker_application,

  metadata         jsonb default '{}'
);