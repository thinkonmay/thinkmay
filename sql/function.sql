

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
$$ language plpgsql security definer;

-- trigger the function every time a user is created
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
