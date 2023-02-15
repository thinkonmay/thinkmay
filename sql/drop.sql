drop table if exists public.user_application    CASCADE;
drop table if exists public.worker_application  CASCADE;
drop table if exists public.application_image   CASCADE;
drop table if exists public.worker_metric   CASCADE;
drop table if exists public.worker_profile  CASCADE;
drop table if exists public.regional_proxy  CASCADE;
drop table if exists public.user_profile    CASCADE;
drop table if exists public.global_mail CASCADE;
drop table if exists public.account_relationship    CASCADE;
drop table if exists public.account_mail    CASCADE;
drop table if exists public.session_mail    CASCADE;
drop table if exists public.session_relationship    CASCADE;
drop table if exists public.account_session CASCADE;

drop type  if exists  public.account_mail_type;
drop type  if exists  public.global_mail_type;
drop type  if exists  public.session_mail_type;
drop type  if exists  public.relationship;
drop type  if exists  public.session_relationship_type;

delete from auth.users
where true;