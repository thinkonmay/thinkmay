-- RLS
-- SECURE THE TABLES
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




-- PGPLSQL function
-- INSERTS A ROW INTO PUBLIC.USERS AND ASSIGNS ROLES
create function public.handle_new_user()
returns trigger as
$$
  declare is_admin boolean;
  begin
    insert into public.users (id, username)
    values (new.id, new.email);

    select count(*) = 1 from auth.users into is_admin;

    if position('+supaadmin@' in new.email) > 0 then
      insert into public.user_roles (user_id, role) values (new.id, 'admin');
    elsif position('+supamod@' in new.email) > 0 then
      insert into public.user_roles (user_id, role) values (new.id, 'moderator');
    end if;

    return new;
  end;
$$ language plpgsql security definer;


-- PGPLSQL function
-- AUTHORIZE WITH ROLE-BASED ACCESS CONTROL (RBAC)
create function public.authorize(
  requested_permission app_permission,
  user_id uuid
)
returns boolean as
$$
  declare
    bind_permissions int;
  begin
    select
      count(*)
    from public.role_permissions
    inner join public.user_roles on role_permissions.role = user_roles.role
    where
      role_permissions.permission = authorize.requested_permission and
      user_roles.user_id = authorize.user_id
    into bind_permissions;

    return bind_permissions > 0;
  end;
$$
language plpgsql security definer;



-- SQL FUNCTION TRIGGER
-- EVERY TIME A USER IS CREATED
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();






-- POLICY
create policy "Allow logged-in read access" on public.users
  for select using (auth.role() = 'authenticated');
create policy "Allow individual insert access" on public.users
  for insert with check (auth.uid() = id);
create policy "Allow individual update access" on public.users
  for update using ( auth.uid() = id );
create policy "Allow logged-in read access" on public.channels
  for select using (auth.role() = 'authenticated');
create policy "Allow individual insert access" on public.channels
  for insert with check (auth.uid() = created_by);
create policy "Allow individual delete access" on public.channels
  for delete using (auth.uid() = created_by);
create policy "Allow authorized delete access" on public.channels
  for delete using (authorize('channels.delete', auth.uid()));
create policy "Allow logged-in read access" on public.messages
  for select using (auth.role() = 'authenticated');
create policy "Allow individual insert access" on public.messages
  for insert with check (auth.uid() = user_id);
create policy "Allow individual update access" on public.messages
  for update using (auth.uid() = user_id);
create policy "Allow individual delete access" on public.messages
  for delete using (auth.uid() = user_id);
create policy "Allow authorized delete access" on public.messages
  for delete using (authorize('messages.delete', auth.uid()));
create policy "Allow individual read access" on public.user_roles
  for select using (auth.uid() = user_id);




