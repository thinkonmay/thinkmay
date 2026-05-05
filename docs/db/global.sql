SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE EXTENSION IF NOT EXISTS "timescaledb" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pg_cron" WITH SCHEMA "pg_catalog";






CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgsodium";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE SCHEMA IF NOT EXISTS "stripe";


ALTER SCHEMA "stripe" OWNER TO "supabase_admin";


CREATE EXTENSION IF NOT EXISTS "http" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pg_trgm" WITH SCHEMA "public";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "wrappers" WITH SCHEMA "extensions";






CREATE TYPE "public"."afk_status" AS ENUM (
    'ACTIVE',
    'DEACTIVE'
);


ALTER TYPE "public"."afk_status" OWNER TO "postgres";


CREATE TYPE "public"."payment_status" AS ENUM (
    'CANCEL',
    'PENDING',
    'PAID'
);


ALTER TYPE "public"."payment_status" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."add_day_by_sub_and_payment"("subscription_id" bigint, "payment_request_id" bigint, "day" integer) RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$BEGIN
    UPDATE subscriptions
    SET ended_at = ended_at + (day || ' day')::interval
    WHERE subscriptions.id = subscription_id;

    UPDATE payment_request
    SET created_at = created_at + (day || ' day')::interval
    WHERE payment_request.id = payment_request_id;
END;$$;


ALTER FUNCTION "public"."add_day_by_sub_and_payment"("subscription_id" bigint, "payment_request_id" bigint, "day" integer) OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."allocate_addon_resources"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
  declare
    addon_type text;
    email text;
    cluster_id bigint;
  begin
    select addons.name into addon_type
    from addons where addons.id = NEW.addon;

    select subscriptions.user, subscriptions.cluster into email, cluster_id
    from subscriptions where subscriptions.id = NEW.subscription;

    if (addon_type = 'app_access') then
      perform grant_app_access_v1(email, 'unknown', cluster_id);
    elsif (addon_type = 'buckets') then
      perform grant_bucket_access_v1(email, cluster_id);
    elsif (addon_type = 'llm') then
      perform grant_llm_access_v1(email, cluster_id);
    end if;

    RETURN NEW;
  end;
$$;


ALTER FUNCTION "public"."allocate_addon_resources"() OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."allocate_subscription_resources_v8"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$

declare
   volume_id uuid;
   cluster_id bigint;
   cluster_domain text;
   status text;
   plan_configuration jsonb;
begin
  if (OLD.allocated_at is null and NEW.allocated_at is not null) then
    select plans.configuration
    into plan_configuration
    from payment_request
    inner join plans on plans.id = payment_request.plan

    where payment_request.subscription = OLD.id
    and payment_request.verified_at is null
    order by payment_request.created_at desc
    limit 1;

    select id,version, domain from clusters
    into cluster_id, cluster_domain
    where clusters.id = NEW.cluster;

    select gen_random_uuid() into volume_id;

    insert into job(command, arguments,cluster)
    values('create volume v7',
      jsonb_build_object(
        'id', volume_id::text,
        'email', NEW.user,
        'template', coalesce(OLD.metadata->>'template','win11') || '.template'
      )
       || COALESCE(plan_configuration, '{}'::jsonb)
      ,cluster_id);
  end if;
  return NEW;
end;

$$;


ALTER FUNCTION "public"."allocate_subscription_resources_v8"() OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."cancel_transaction"("id" bigint) RETURNS "void"
    LANGUAGE "sql" SECURITY DEFINER
    AS $$-- update transactions
  -- set status = 'CANCELLED'
  -- where transactions.id = cancel_transaction.id
  -- and transactions.status = 'PENDING'$$;


ALTER FUNCTION "public"."cancel_transaction"("id" bigint) OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."claim_mission_v2"("p_email" "text", "p_mission_code" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_mission RECORD;
    v_progress int;
    v_all_missions RECORD;
BEGIN
    -- 1. Fetch mission
    SELECT * INTO v_mission FROM public.missions
    WHERE code = p_mission_code AND is_active = true;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Mission not found or inactive';
    END IF;

    -- 2. Check claim eligibility
    IF NOT v_mission.is_repeatable THEN
        IF EXISTS (SELECT 1 FROM public.user_mission_claims WHERE email = p_email AND mission_id = v_mission.id) THEN
            RAISE EXCEPTION 'Mission already claimed';
        END IF;
    ELSIF v_mission.cooldown_days IS NOT NULL THEN
        IF EXISTS (
            SELECT 1 FROM public.user_mission_claims
            WHERE email = p_email AND mission_id = v_mission.id
            AND claimed_at > NOW() - (v_mission.cooldown_days || ' day')::interval
        ) THEN
            RAISE EXCEPTION 'Mission on cooldown';
        END IF;
    END IF;

    -- 3. Dynamically calculate progress
    SELECT um.progress INTO v_progress
    FROM public.get_user_missions_v2(p_email) um
    WHERE um.code = p_mission_code;

    IF v_progress IS NULL OR v_progress < v_mission.target_value THEN
        RAISE EXCEPTION 'Mission condition not met (Progress: %, Target: %)', COALESCE(v_progress, 0), v_mission.target_value;
    END IF;

    -- 4. Record claim
    INSERT INTO public.user_mission_claims (email, mission_id) VALUES (p_email, v_mission.id);

    -- 5. Grant stars
    INSERT INTO public.star_ledger (email, amount, source_type, source_ref)
    VALUES (p_email, v_mission.reward_stars, 'MISSION_CLAIM', v_mission.code);

    RETURN true;
END;
$$;


ALTER FUNCTION "public"."claim_mission_v2"("p_email" "text", "p_mission_code" "text") OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."clean_expired_subscription"() RETURNS "void"
    LANGUAGE "sql" SECURITY DEFINER
    AS $$update subscriptions
    set cleaned_at = now()
    where (
      subscriptions.cancelled_at is not null
      or subscriptions.cleaned_at is not null
      or subscriptions.ended_at + '2 day'::interval < now()
    )
    and subscriptions.cleaned_at is null$$;


ALTER FUNCTION "public"."clean_expired_subscription"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."clean_subscription"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
  begin
    if (NEW.cancelled_at is not null and OLD.cancelled_at is null) then
      NEW.cleaned_at = now();
    end if;

    if (NEW.cleaned_at is not null and OLD.cleaned_at is null) then
      UPDATE addon_subscriptions
      SET cancelled_at = now()
      WHERE subscription = OLD.id
      AND cancelled_at IS NULL;

      delete from payment_request
      where payment_request.verified_at is null
      and payment_request.subscription = OLD.id;

      INSERT INTO job(cluster, command, arguments)
      VALUES (
        NEW.cluster,
        'delete volume v5',
        jsonb_build_object('email', NEW.user)
      );
    end if;

    return NEW;
  end;$$;


ALTER FUNCTION "public"."clean_subscription"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_or_replace_payment"("email" "text", "plan_name" "text", "cluster_domain" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    -- Call the 4-argument version with the default template 'win11'
    PERFORM "public"."create_or_replace_payment"(
        "email",
        "plan_name",
        "cluster_domain",
        'win11'
    );
END;
$$;


ALTER FUNCTION "public"."create_or_replace_payment"("email" "text", "plan_name" "text", "cluster_domain" "text") OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."create_or_replace_payment"("email" "text", "plan_name" "text", "cluster_domain" "text", "template" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$declare
    sub_id bigint;
    cluster_id bigint;
    pocket_id bigint;
    plan_id bigint;

    total_days bigint;
    extendable boolean;
    exist_payment_request bigint;
begin
    -- Find plan ID
    select id, plans.total_days, plans.extendable into plan_id, total_days, extendable
    from plans
    where plans.name = create_or_replace_payment.plan_name;

    -- Get pocket ID
    select id into pocket_id
    from get_pocket_balance(create_or_replace_payment.email);

    -- Get existing subscription if exists
    select
        subscriptions.id
    into sub_id
    from subscriptions
    inner join payment_request
    on payment_request.subscription = subscriptions.id
    and payment_request.verified_at is not null
    inner join plans
    on plans.id = payment_request.plan
    where subscriptions.cancelled_at is null
    and subscriptions.cleaned_at is null
    and subscriptions.user = create_or_replace_payment.email
    order by subscriptions.id, payment_request.created_at desc
    limit 1;

    -- Check concurrency verification
    SELECT payment_request.id
    INTO exist_payment_request
    FROM payment_request
    INNER JOIN subscriptions
    ON subscriptions.id = payment_request.subscription
    AND subscriptions.id = sub_id
    WHERE payment_request.pocket = pocket_id
    AND payment_request.verified_at IS NULL;

    if plan_id is null then
        RAISE EXCEPTION 'plan not exists';
    elsif pocket_id is null then
        RAISE EXCEPTION 'pocket not exists';
    elsif exist_payment_request is not null  then
        if not extendable then
          raise exception 'this plan is not extendable';
        end if;

        update payment_request
        set plan = plan_id,
        created_at = now()
        where payment_request.id = exist_payment_request
        and payment_request.verified_at is null;
    else
        -- Find cluster ID
        select id into cluster_id
        from clusters
        where clusters.domain = cluster_domain;

        if cluster_id is null then
            RAISE EXCEPTION 'cluster not exists';
        end if;

        -- Insert new subscription if needed
        if sub_id is null then
            insert into subscriptions(id,"user",ended_at, cluster, metadata)
            values(
              coalesce((select max(id) + 1 from subscriptions),1),
              create_or_replace_payment.email,
              (
                case when total_days is not null
                then now() + total_days * INTERVAL '1 day'
                else NULL
                end
              ),
              cluster_id,
              jsonb_build_object('template', template)
            )
            returning id into sub_id;
        else
          if not extendable then
            raise exception 'this plan is not extendable';
          end if;
        end if;

        -- Insert payment request
        insert into payment_request(id,subscription, plan, pocket)
        values(
          coalesce((select max(id) + 1 from payment_request),1),
          sub_id,
          plan_id,
          pocket_id
        );
    end if;

    return;
end;$$;


ALTER FUNCTION "public"."create_or_replace_payment"("email" "text", "plan_name" "text", "cluster_domain" "text", "template" "text") OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."create_pocket_deposit_v4"("email" "text", "amount" double precision, "provider" "text", "currency" "text", "metadata" "jsonb", "discount_code" "text") RETURNS TABLE("id" bigint, "data" "jsonb")
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$declare
  pocket_id bigint;
  transaction_id bigint;
  discount_id bigint;
  exchange_rate numeric;
  final_credit_amount bigint;
begin
  LOCK TABLE pocket_deposits IN EXCLUSIVE MODE;
  SELECT rate_to_system_credit INTO exchange_rate
  FROM currency_rates
  WHERE currency_rates.currency = create_pocket_deposit_v4.currency;

  IF exchange_rate IS NULL THEN
      RAISE EXCEPTION 'Currency % not supported', create_pocket_deposit_v4.currency;
  END IF;

  final_credit_amount := (create_pocket_deposit_v4.amount * exchange_rate)::bigint;
  SELECT get_pocket_balance.id INTO pocket_id
  FROM get_pocket_balance(create_pocket_deposit_v4.email);

  select discounts.id into discount_id from discounts
  where create_pocket_deposit_v4.discount_code = discounts.code
  and 'deposit' = any(discounts.apply_for)
  and discounts.start_at < now() and discounts.end_at > now()
  and (discounts.discount_limit_per_user is null or (
    select count(*)
    from pocket_deposits
    inner join pockets
    on pockets.id = pocket_deposits.pocket
    and pockets.user = create_pocket_deposit_v4.email
    where pocket_deposits.discount = discounts.id
  ) < discounts.discount_limit_per_user)
  and (discounts.discount_limit is null or (
    select count(*)
    from pocket_deposits
    where pocket_deposits.discount = discounts.id)
   < discounts.discount_limit);
  select get_pocket_balance.id into pocket_id
  from get_pocket_balance(create_pocket_deposit_v4.email);

  INSERT INTO pocket_deposits(id, pocket, amount,discount,metadata)
  VALUES (
    coalesce((select max(pocket_deposits.id) + 1 from pocket_deposits),1),
    pocket_id,
    final_credit_amount,
    discount_id,
    create_pocket_deposit_v4.metadata
  )
  RETURNING transaction INTO transaction_id;
  IF transaction_id IS NULL THEN
      RAISE EXCEPTION 'Failed to retrieve transaction ID';
  END IF;
  UPDATE transactions
  SET
      currency = create_pocket_deposit_v4.currency,
      provider = create_pocket_deposit_v4.provider
  WHERE transactions.id = transaction_id;
  RETURN QUERY SELECT
    transactions.id as id,
    transactions.data as data
  FROM transactions
  WHERE transactions.id = transaction_id;
end;$$;


ALTER FUNCTION "public"."create_pocket_deposit_v4"("email" "text", "amount" double precision, "provider" "text", "currency" "text", "metadata" "jsonb", "discount_code" "text") OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."create_volume_v7"("job_id" bigint) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$declare
    email       text;
    cluster_id  bigint;

    admintoken text;
    url text;
    domain text;
    user_id text;

    volume_id   text;
    arg_configuration        jsonb;
begin
    select
      job.arguments->>'email' as email,
      job.arguments->>'id' as volume_id,
      job.arguments::jsonb as arg,
      clusters.id
    into email, volume_id, arg_configuration, cluster_id
    from job
    inner join clusters on clusters.id = job.cluster
    where job.id = create_volume_v7.job_id;

    select token,get_cluster_secrets.url,get_cluster_secrets.domain
    into admintoken, url, domain
    FROM get_cluster_secrets(cluster_id);

    select generate_account_v3 into user_id
    from generate_account_v3(email, domain);

    update job
    set
      success = request.success,
      result = request.content::jsonb
    from try_post(
      url || '/api/collections/volumes/records',
      ARRAY[extensions.http_header('Authorization',concat('Bearer ' ,admintoken))],
      jsonb_build_object(
        'user', user_id,
        'local_id', volume_id
      ) || jsonb_build_object('configuration', arg_configuration)
    ) as request
    where job.id = create_volume_v7.job_id;

    return;
    exception when others then
      UPDATE job
      SET success = false,
          result = jsonb_build_object('error', SQLERRM, 'state', SQLSTATE)
      WHERE job.id = create_volume_v7.job_id;
      return;
    end;
  $$;


ALTER FUNCTION "public"."create_volume_v7"("job_id" bigint) OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."deallocate_addon_resources"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
  declare
    addon_type text;
    email text;
    cluster_id bigint;
  begin
    if (OLD.cancelled_at is null and NEW.cancelled_at is not null) then
      select addons.name into addon_type
      from addons where addons.id = NEW.addon;

      select subscriptions.user, subscriptions.cluster into email, cluster_id
      from subscriptions where subscriptions.id = NEW.subscription;

      if (addon_type = 'app_access') then
        perform unmap_app_access(email, cluster_id);
      elsif (addon_type = 'buckets') then
        perform unmap_bucket_access(email, cluster_id);
      elsif (addon_type = 'llm') then
        perform unmap_llm_access(email, cluster_id);
      end if;
    end if;

    if (OLD.last_payment != NEW.last_payment) then
      NEW.unit_count = 0;
    end if;

    RETURN NEW;
  end;
$$;


ALTER FUNCTION "public"."deallocate_addon_resources"() OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."execute_job_v6"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$declare
    job_id bigint;
    command text;
  begin

  PERFORM pg_advisory_xact_lock(14396);
  select job.id,job.command
  into job_id, command
  from job
  where job.running_at is null
  and job.command = any(array[
    'create volume v6',
    'create volume v7',
    'update volume v7',
    'delete volume v5'
  ])
  order by id
  limit 1;

  UPDATE job
  SET running_at = now()
  where job.id = job_id;

  if command = 'create volume v6' then
    perform create_volume_v6(job_id);
  elsif command = 'create volume v7' then
    perform create_volume_v7(job_id);
  elsif command = 'update volume v7' then
    perform update_volume_v7(job_id);
  elsif command = 'delete volume v5' then
    perform unmap_user_email_v2(job_id);
  end if;

  UPDATE job
  SET finished_at = now()
  where job.id = job_id;

  return;
end;$$;


ALTER FUNCTION "public"."execute_job_v6"() OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."extend_all_expired_by_email_or_cluster"("user_list" "text"[] DEFAULT NULL::"text"[], "cluster_id" bigint DEFAULT NULL::bigint, "day" integer DEFAULT 0) RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    sub_and_payment RECORD;
BEGIN
    FOR sub_and_payment IN SELECT * FROM na_preview_change_add_date(user_list,cluster_id) LOOP
        PERFORM add_day_by_sub_and_payment(sub_and_payment.subscription,sub_and_payment.payment_request,day);
    END LOOP;
END;
$$;


ALTER FUNCTION "public"."extend_all_expired_by_email_or_cluster"("user_list" "text"[], "cluster_id" bigint, "day" integer) OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."generate_account_v3"("email" "text", "domain" "text") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$

declare
    admintoken text;
    result text;
  begin
    select
      request.content::jsonb->>'token' as token
    into admintoken

    FROM clusters
    inner join extensions.http(('POST',concat(clusters.secret->>'url','/api/collections/_superusers/auth-with-password'), NULL,'application/json',
      jsonb_build_object('identity',clusters.secret->>'username','password',clusters.secret->>'password')
    )::extensions.http_request) as request on true
    and clusters.domain = generate_account_v3.domain;

    select
      item->>'id'
      into result
    FROM extensions.http(('GET',concat('https://',domain,'/api/collections/users/records?filter=(email="',generate_account_v3.email,'")'),
      ARRAY[extensions.http_header('Authorization',concat('Bearer ' ,admintoken))],
      'application/json', NULL
    )::extensions.http_request) as request
    inner join jsonb_array_elements(request.content::jsonb->'items') as item on true;

    if result is null then

       select
       content::jsonb->>'id' as user_id
        into result
      FROM extensions.http(('POST','https://'|| domain ||'/api/collections/users/records', NULL,'application/json',
        jsonb_build_object('username',REPLACE(email, '@', ''),'email',email, 'emailVisibility', true, 'password', '12131415', 'passwordConfirm', '12131415', 'name', email)
      )::extensions.http_request);


      if result is null then
        raise exception 'failed to find this user';
      end if;

    end if;

    return result;
  end;


$$;


ALTER FUNCTION "public"."generate_account_v3"("email" "text", "domain" "text") OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."get_active_addons"("subscription_id" bigint) RETURNS TABLE("type" "text", "created_at" timestamp with time zone, "last_payment" timestamp with time zone, "units" bigint, "unit_price" "jsonb")
    LANGUAGE "sql"
    AS $$
  select
    addons.name as type,
    addon_subscriptions.created_at,
    (select created_at from payment_request where payment_request.id = addon_subscriptions.last_payment) as last_payment,
    addon_subscriptions.unit_count as units,
    addons.unit_price as unit_price
  from addon_subscriptions
  inner join addons on addons.id = addon_subscriptions.addon
  where addon_subscriptions.subscription = get_active_addons.subscription_id
  and addon_subscriptions.cancelled_at is null
$$;


ALTER FUNCTION "public"."get_active_addons"("subscription_id" bigint) OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."get_active_addons"("email" "text") RETURNS TABLE("type" "text", "created_at" timestamp with time zone, "last_payment" timestamp with time zone, "units" bigint, "unit_price" "jsonb")
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
  declare
    subscription_id bigint;
  begin
    select id
    from subscriptions into subscription_id
    where allocated_at is not null
    and cleaned_at is null
    and subscriptions.user = get_active_addons.email;

  if (subscription_id is null) then
    raise exception 'email do not have any subscription';
  end if;

  return query select * from get_active_addons(subscription_id);
  end;
$$;


ALTER FUNCTION "public"."get_active_addons"("email" "text") OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."get_all_app_genres_v1"() RETURNS TABLE("name" "text", "total" bigint)
    LANGUAGE "sql" SECURITY DEFINER
    AS $$
select
  genre,
  count(*) as total
from stores
cross join UNNEST(stores.genres) as genre
group by genre
order by total desc
$$;


ALTER FUNCTION "public"."get_all_app_genres_v1"() OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."get_all_rank_rewards"() RETURNS TABLE("rank_tier" "text", "min_stars" integer, "rewards" "jsonb")
    LANGUAGE "sql" SECURITY DEFINER
    AS $$
  SELECT rr.rank_tier, rr.min_stars, rr.rewards
  FROM public.rank_rewards rr
  ORDER BY rr.min_stars ASC;
$$;


ALTER FUNCTION "public"."get_all_rank_rewards"() OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."get_app_access_usage"("cluster" bigint) RETURNS TABLE("usage" bigint, "email" "text")
    LANGUAGE "plpgsql"
    AS $$
declare
    admintoken text;
    url text;
    current_page int := 1;
    total_pages int := 1;
    resp_json jsonb;
begin
    select token, get_cluster_secrets.url into admintoken, url
    FROM get_cluster_secrets(get_app_access_usage.cluster);

    perform extensions.http_set_curlopt ('CURLOPT_TIMEOUT', '300');
    perform extensions.http_set_curlopt ('CURLOPT_CONNECTTIMEOUT', '300');

    LOOP
        select content::jsonb into resp_json
        from extensions.http(('GET',
            url || '/api/collections/app_access/records?fields=usage,expand.user.email&expand=user&perPage=500&filter=(usage>0)&page=' || current_page,
            ARRAY[extensions.http_header('Authorization', 'Bearer ' || admintoken)],
            NULL, NULL
        )::extensions.http_request);

        total_pages := coalesce((resp_json->>'totalPages')::int, 1);

        return query
        select
            (item->>'usage')::bigint,
            item->'expand'->'user'->>'email'
        from jsonb_array_elements(resp_json->'items') as item;

        EXIT WHEN current_page >= total_pages;
        current_page := current_page + 1;
    END LOOP;
end;
$$;


ALTER FUNCTION "public"."get_app_access_usage"("cluster" bigint) OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."get_buckets_size"("cluster" bigint) RETURNS TABLE("size_in_mb" bigint, "name" "text", "email" "text")
    LANGUAGE "plpgsql"
    AS $$
declare
    admintoken text;
    url text;
    current_page int := 1;
    total_pages int := 1;
    resp_json jsonb;
begin
    select token, get_cluster_secrets.url into admintoken, url
    FROM get_cluster_secrets(get_buckets_size.cluster);

    perform extensions.http_set_curlopt ('CURLOPT_TIMEOUT', '300');
    perform extensions.http_set_curlopt ('CURLOPT_CONNECTTIMEOUT', '300');

    LOOP
        select content::jsonb into resp_json
        from extensions.http(('GET',
            url || '/api/collections/buckets/records?fields=size,bucket_name,expand.user.email&expand=user&perPage=500&filter=(size>0)&page=' || current_page,
            ARRAY[extensions.http_header('Authorization', 'Bearer ' || admintoken)],
            NULL, NULL
        )::extensions.http_request);

        total_pages := (resp_json->>'totalPages')::int;

        return query
        select
            (item->>'size')::bigint / 1024 / 1024,
            item->>'bucket_name',
            item->'expand'->'user'->>'email'
        from jsonb_array_elements(resp_json->'items') as item;

        EXIT WHEN current_page >= total_pages;
        current_page := current_page + 1;
    END LOOP;
end;
$$;


ALTER FUNCTION "public"."get_buckets_size"("cluster" bigint) OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."get_cluster_personas_by_emails"("cluster_id" bigint, "emails" "text"[]) RETURNS TABLE("email" "text", "summary" "jsonb", "profile" "jsonb")
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    admintoken text;
    cluster_url text;
    batch_size int := 40;
    total_emails int;
    current_idx int := 1;
    email_batch text[];
    filter_str text;
    resp_json jsonb;
BEGIN
    total_emails := array_length(emails, 1);
    IF total_emails IS NULL OR total_emails = 0 THEN
        RETURN;
    END IF;

    SELECT token, get_cluster_secrets.url INTO admintoken, cluster_url
    FROM get_cluster_secrets(cluster_id);

    PERFORM extensions.http_set_curlopt('CURLOPT_TIMEOUT', '60');

    WHILE current_idx <= total_emails LOOP
        email_batch := emails[current_idx : current_idx + batch_size - 1];
        current_idx := current_idx + batch_size;

        SELECT string_agg('user.email=''' || e || '''', '||')
        INTO filter_str
        FROM unnest(email_batch) AS e;

        filter_str := '(' || filter_str || ')';

        SELECT content::jsonb INTO resp_json
        FROM extensions.http(('GET',
            cluster_url || '/api/collections/persona/records?expand=user&perPage=500&filter=' || urlencode(filter_str),
            ARRAY[extensions.http_header('Authorization', 'Bearer ' || admintoken)],
            NULL, NULL
        )::extensions.http_request);

        RETURN QUERY
        SELECT
            item->'expand'->'user'->>'email',
            item->'summary',
            item->'profile'
        FROM jsonb_array_elements(COALESCE(resp_json->'items', '[]'::jsonb)) AS item
        WHERE item->'expand'->'user'->>'email' IS NOT NULL;
    END LOOP;
END;
$$;


ALTER FUNCTION "public"."get_cluster_personas_by_emails"("cluster_id" bigint, "emails" "text"[]) OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."get_cluster_secrets"("cluster_id" bigint) RETURNS TABLE("token" "text", "url" "text", "domain" "text")
    LANGUAGE "sql"
    AS $$
  select
    request.content::jsonb->>'token' as token,
    clusters.secret->>'url' as url,
    clusters.domain as domain
  FROM clusters
  inner join extensions.http(('POST',
    clusters.secret->>'url' || '/api/collections/_superusers/auth-with-password',
    NULL,'application/json',
    jsonb_build_object(
      'identity',clusters.secret->>'username',
      'password',clusters.secret->>'password'
    )
  )::extensions.http_request) as request on true
  and clusters.id = get_cluster_secrets.cluster_id;
$$;


ALTER FUNCTION "public"."get_cluster_secrets"("cluster_id" bigint) OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."get_cohort_personas"("p_start_time" timestamp with time zone, "p_end_time" timestamp with time zone, "p_plan_name" "text") RETURNS TABLE("email" "text", "subscribed_at" timestamp with time zone, "summary" "jsonb", "profile" "jsonb")
    LANGUAGE "sql" SECURITY DEFINER
    AS $$
    WITH UserPayments AS (
        SELECT
            s."user" AS email,
            s.cluster AS cluster_id,
            pr.verified_at,
            p.name AS plan_name,
            ROW_NUMBER() OVER(PARTITION BY s."user" ORDER BY pr.verified_at ASC) as rn
        FROM public.subscriptions s
        JOIN public.payment_request pr ON pr.subscription = s.id
        JOIN public.plans p ON p.id = pr.plan
        WHERE pr.verified_at IS NOT NULL
    ),
    Cohort AS (
        SELECT
            email,
            cluster_id,
            verified_at AS subscribed_at
        FROM UserPayments
        WHERE rn = 1
          AND verified_at >= p_start_time
          AND verified_at <= p_end_time
          AND plan_name = p_plan_name
    ),
    ClusterCohorts AS (
        SELECT
            cluster_id,
            array_agg(email) AS emails
        FROM Cohort
        GROUP BY cluster_id
    ),
    AllPersonas AS (
        SELECT cp.email, cp.summary, cp.profile
        FROM ClusterCohorts cc
        CROSS JOIN LATERAL get_cluster_personas_by_emails(cc.cluster_id, cc.emails) cp
    )
    SELECT
        c.email,
        c.subscribed_at,
        p.summary,
        p.profile
    FROM Cohort c
    LEFT JOIN AllPersonas p ON c.email = p.email
    ORDER BY c.subscribed_at ASC;
$$;


ALTER FUNCTION "public"."get_cohort_personas"("p_start_time" timestamp with time zone, "p_end_time" timestamp with time zone, "p_plan_name" "text") OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."get_data_usage"("email" "text") RETURNS TABLE("name" "uuid", "created_at" timestamp with time zone, "size_in_gb" bigint)
    LANGUAGE "sql"
    AS $$
select
  name,
  created_at,
  size_in_gb
from
  volume_snapshoot
where
  email = get_data_usage.email
order by
  id desc
limit 24 * 7
$$;


ALTER FUNCTION "public"."get_data_usage"("email" "text") OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."get_deposit_history"("email" "text") RETURNS TABLE("id" bigint, "created_at" timestamp without time zone, "amount" integer)
    LANGUAGE "sql" SECURITY DEFINER
    AS $$

  select
    pocket_deposits.id,
    pocket_deposits.created_at,
    pocket_deposits.amount
  from pockets

  inner join pocket_deposits on pocket_deposits.pocket = pockets.id
  and pocket_deposits.verified_at is not null

  where pockets.user = get_deposit_history.email
  order by pocket_deposits.created_at desc
$$;


ALTER FUNCTION "public"."get_deposit_history"("email" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_depotkey"("app_id" bigint) RETURNS "jsonb"
    LANGUAGE "sql" SECURITY DEFINER
    AS $$
  select stores.depotkey
  from stores
  where get_depotkey.app_id = stores.id
$$;


ALTER FUNCTION "public"."get_depotkey"("app_id" bigint) OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."get_domains_availability_v5"() RETURNS TABLE("domain" "text", "routing_only" boolean)
    LANGUAGE "sql" SECURITY DEFINER
    AS $$
select domain, secret->>'url' is null as routing_only from clusters
where clusters.active;
$$;


ALTER FUNCTION "public"."get_domains_availability_v5"() OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."get_job_history"("email" "text", "only_pending" boolean) RETURNS TABLE("id" bigint, "command" "text", "created_at" timestamp with time zone, "finished" boolean, "success" boolean)
    LANGUAGE "sql" SECURITY DEFINER
    AS $$
select
  id,
  command,
  created_at,
  running_at is null as finished,
  success
from
  job
where
  arguments ->> 'email' = get_job_history.email
  and (
    case
    when get_job_history.only_pending
    then job.running_at is null
    and job.running_at > now() - '7 days'::interval
    else job.running_at > now() - '7 days'::interval end
  )
order by
  created_at desc
limit
  10
$$;


ALTER FUNCTION "public"."get_job_history"("email" "text", "only_pending" boolean) OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."get_llm_usage"("cluster" bigint) RETURNS TABLE("usage" bigint, "email" "text")
    LANGUAGE "plpgsql"
    AS $$
declare
    admintoken text;
    url text;
    current_page int := 1;
    total_pages int := 1;
    resp_json jsonb;
begin
    select token, get_cluster_secrets.url into admintoken, url
    FROM get_cluster_secrets(get_llm_usage.cluster);

    perform extensions.http_set_curlopt ('CURLOPT_TIMEOUT', '300');

    LOOP
        select content::jsonb into resp_json
        from extensions.http(('GET',
            url || '/api/collections/llmModels/records?fields=usage,expand.user.email&expand=user&perPage=500&filter=(usage>0)&page=' || current_page,
            ARRAY[extensions.http_header('Authorization', 'Bearer ' || admintoken)],
            NULL, NULL
        )::extensions.http_request);

        total_pages := coalesce((resp_json->>'totalPages')::int, 1);

        return query
        select
            (item->>'usage')::bigint,
            item->'expand'->'user'->>'email'
        from jsonb_array_elements(resp_json->'items') as item;

        EXIT WHEN current_page >= total_pages;
        current_page := current_page + 1;
    END LOOP;
end;
$$;


ALTER FUNCTION "public"."get_llm_usage"("cluster" bigint) OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."get_payermax_data_v2"("ordercode" bigint, "email" "text", "amount" double precision, "currency" "text", "metadata" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$DECLARE
  app_id text;
  merchant_no text;
  base_url text;

  http_status bigint;
  req_time text;
  req_body jsonb;
  req_data jsonb;
  signature text;

  api_result record;
  result jsonb;
BEGIN
  if get_payermax_data_v2.currency != 'USD' and
     get_payermax_data_v2.currency != 'IDR' then
    RAISE EXCEPTION 'only USD or IDR are accepted';
  end if;

  SELECT
    value->>'app_id',
    value->>'merchant_no',
    value->>'base_url'
  INTO app_id, merchant_no, base_url
  FROM constant
  WHERE name = 'payermax';

  IF app_id IS NULL OR merchant_no IS NULL OR base_url IS NULL THEN
    RAISE EXCEPTION 'PayerMax config (app_id/merchant_no/base_url) not available';
  END IF;


  req_time := to_char(now(), 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"');
  req_data := jsonb_build_object(
    'userId', 'U10001',
    'integrate', 'Hosted_Checkout',
    'outTradeNo', 'P' || get_payermax_data_v2.ordercode::text,
    'totalAmount', get_payermax_data_v2.amount::bigint,
    'currency', get_payermax_data_v2.currency,
    'country', 'ID',
    'subject', 'Thinkmay Service',
    'body', 'Order # ' || get_payermax_data_v2.ordercode::text,
    'frontCallbackUrl', 'https://thinkmay.net/id/payment/success?' || jsonb_to_query(get_payermax_data_v2.metadata)
  );

  req_body := jsonb_build_object(
    'version', '1.4',
    'keyVersion', '1',
    'requestTime', req_time,
    'appId', app_id,
    'merchantNo', merchant_no,
    'data', req_data
  );

  signature := sign_payermax_rsa_sha256(req_body::text);
  SELECT
    content::jsonb,
    status
  INTO result, http_status
  FROM extensions.http((
    'POST',
    base_url || '/orderAndPay',
    ARRAY[
      extensions.http_header('Content-Type', 'application/json'),
      extensions.http_header('Accept', 'application/json'),
      extensions.http_header('sign', signature)
    ],
    'application/json',
    req_body
  )::extensions.http_request);

  IF http_status != 200 OR result->>'code' != 'APPLY_SUCCESS' THEN
    RAISE EXCEPTION 'Failed to create PayerMax Cashier order: %', result;
  END IF;

  RETURN result;
END;$$;


ALTER FUNCTION "public"."get_payermax_data_v2"("ordercode" bigint, "email" "text", "amount" double precision, "currency" "text", "metadata" "jsonb") OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."get_payment_history"("email" "text") RETURNS TABLE("id" bigint, "created_at" timestamp without time zone, "plan_name" "text", "amount" integer)
    LANGUAGE "sql" SECURITY DEFINER
    AS $$select
    payment_request.id,
    payment_request.created_at,
    plans.name as plan_name,
    plans.credit as amount

  from subscriptions
  inner join payment_request
    on payment_request.subscription = subscriptions.id
    and payment_request.verified_at is not null
  inner join plans on payment_request.plan = plans.id


  where subscriptions.user = get_payment_history.email
  order by payment_request.created_at desc$$;


ALTER FUNCTION "public"."get_payment_history"("email" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_payment_history_by_userid"("userid" "text") RETURNS TABLE("id" bigint, "created_at" timestamp without time zone, "plan_name" "text", "amount" integer)
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
  user_email text;
  admintoken text;
  pb_url text;
  cluster_id bigint;
begin


  select token, url into admintoken, pb_url
  from get_cluster_secrets(3);

  -- Query PocketBase lấy email từ user_id
  select item->>'email' into user_email
  FROM extensions.http(('GET',concat(pb_url, '/api/collections/users/records?filter=(id="',userid,'")'),
      ARRAY[extensions.http_header('Authorization',concat('Bearer ' ,admintoken))],
      'application/json', NULL
  )::extensions.http_request) as request
  inner join jsonb_array_elements(request.content::jsonb->'items') as item on true;

  if user_email is null then
    raise exception 'User not found: %', userid;
  end if;

  return query select * from get_payment_history(user_email);
end;
$$;


ALTER FUNCTION "public"."get_payment_history_by_userid"("userid" "text") OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."get_payment_pocket"("email" "text") RETURNS TABLE("id" bigint, "plan_name" "text", "amount" bigint, "pay_at" timestamp with time zone)
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
  return query
  select
    payment_request.id as id,
    plans.name as plan_name,
    plans.credit as amount,
    payment_request.created_at as pay_at
  from payment_request
  inner join plans on plans.id = payment_request.plan
  inner join subscriptions on subscriptions.user = get_payment_pocket.email
  and subscriptions.id = payment_request.subscription
  where payment_request.verified_at is null
  and payment_request.pocket is not null
  order by payment_request.created_at desc;

end;
$$;


ALTER FUNCTION "public"."get_payment_pocket"("email" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_payos_data"("ordercode" bigint, "email" "text", "amount" double precision) RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$declare
    client_id text;
    client_secret text;
    checksum_key text;

    amount bigint;
    description text;
    prehash text;
    signature text;

    result jsonb;
    code bigint;
  begin
    select
      value->>'client_id' as client_id,
      value->>'checksum_key' as checksum_key,
      value->>'client_secret' as client_secret
    into client_id,checksum_key,client_secret
    from constant  where name = 'payos';

    if (client_id is null or
        client_secret is null or
        checksum_key is null) then
      raise exception 'payos secret not available';
    end if;

    amount := get_payos_data.amount::bigint;
    description := LEFT(SPLIT_PART(get_payos_data.email,'@'::text,1),15) || amount::text;
    prehash := 'amount='                       ||  amount::text ||
            '&cancelUrl=https://thinkmay.net'  ||
            '&description='                    || description ||
            '&orderCode='                      ||  get_payos_data.orderCode::text ||
            '&returnUrl=https://thinkmay.net';

    signature := encode(extensions.hmac(prehash,checksum_key,'sha256'), 'hex');

    select
      content::jsonb as result,
      ((content::jsonb)->>'code')::bigint as code
    into result,code
    from extensions.http(('POST','https://api-merchant.payos.vn/v2/payment-requests',
      ARRAY[
        extensions.http_header('x-client-id',client_id),
        extensions.http_header('x-api-key',client_secret)
      ],
      'application/json',
      jsonb_build_object(
        'cancelUrl','https://thinkmay.net',
        'returnUrl','https://thinkmay.net',

        'orderCode',get_payos_data.orderCode,
        'buyerEmail',get_payos_data.email,
        'amount',amount,
        'items',array_to_json(array[jsonb_build_object(
          'name', 'custom',
          'price', amount,
          'quantity', 1
        )]::jsonb[]),
        'signature',signature,
        'description', description,
        'expiredAt',(SELECT EXTRACT (EPOCH FROM (now() + '15 minutes'::interval)))::bigint
      )::text
    )::extensions.http_request);

    if (code != 0) then
      raise exception 'failed to request payment link %', result;
    end if;

    return result;
  end;$$;


ALTER FUNCTION "public"."get_payos_data"("ordercode" bigint, "email" "text", "amount" double precision) OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."get_payssion_data"("ordercode" bigint, "email" "text", "amount" bigint, "currency" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$
  declare
    api_key text;
    pm_id text;
    secret_key text;
    link_payssion text;

    api_sig text;

    result jsonb;
    code bigint;
  begin

    select
      value->>'api_key' as api_key,
      value->>'pm_id' as pm_id,
      value->>'secret_key' as secret_key,
      value->>'link' as link_payssion
    into api_key,pm_id,secret_key,link_payssion
    from constant
    where name = 'payssion';

    if (api_key is null or
        pm_id is null or
        link_payssion is null or
        secret_key is null) then
      raise exception 'payssion secret not available';
    end if;

    api_sig := md5(api_key || '|'
            || pm_id || '|'
            || get_payssion_data.amount::text || '|'
            || get_payssion_data.currency || '|'
            || get_payssion_data.orderCode::text || '|'
            || secret_key);

    select
      content::jsonb as result,
      ((content::jsonb)->>'result_code')::bigint as code
    into result, code
    from extensions.http((
      'POST',
      link_payssion || 'payment/create',
      ARRAY[
        extensions.http_header('Content-Type','application/x-www-form-urlencoded')
      ],
      'application/x-www-form-urlencoded',
      (
        'api_key=' || api_key ||
        '&api_sig=' || api_sig ||
        '&pm_id=' || pm_id ||
        '&amount=' || get_payssion_data.amount::text ||
        '&currency=' || get_payssion_data.currency ||
        '&order_id=' || get_payssion_data.orderCode::text ||
        '&description=' || LEFT(SPLIT_PART(get_payssion_data.email,'@'::text,1),15)
      )
      )::extensions.http_request);

    if (code != 200) then
      raise exception 'failed to request payment link % %', result,code;
    end if;

    return result;
  end;
$$;


ALTER FUNCTION "public"."get_payssion_data"("ordercode" bigint, "email" "text", "amount" bigint, "currency" "text") OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."get_pocket_balance"("email" "text") RETURNS TABLE("id" bigint, "user_email" "text", "created_at" timestamp with time zone, "amount" bigint)
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$declare
  pocket_id integer;
  lowercase_email text;
begin

  lowercase_email := lower(email);

  -- Get the pocket_id if it exists
  select pockets.id
  into pocket_id
  from pockets
  where pockets.user = lowercase_email;

  -- Create new pocket if it doesn't exist
  if (pocket_id is null) then
    insert into public.pockets(id, "user", amount)
    values (coalesce((select max(pockets.id) + 1 from pockets),1), lowercase_email, 0)
    returning pockets.id into pocket_id;
  end if;

  -- Return the pocket information
  return query
    select
    p.id          as id,
    p.user        as user_email,
    p.created_at  as created_at,
    p.amount      as amount
    from pockets p
    where p.user = lowercase_email;

end;$$;


ALTER FUNCTION "public"."get_pocket_balance"("email" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_rank_allowance"("p_email" "text", "p_addon_name" "text") RETURNS bigint
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
  SELECT COALESCE(
    (get_rank_rewards(p_email) ->> p_addon_name)::bigint,
    0
  );
$$;


ALTER FUNCTION "public"."get_rank_allowance"("p_email" "text", "p_addon_name" "text") OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."get_rank_bonus_hours"("p_email" "text") RETURNS bigint
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
  SELECT COALESCE(
    (public.get_rank_rewards(p_email) ->> 'bonus_hours')::bigint,
    0
  );
$$;


ALTER FUNCTION "public"."get_rank_bonus_hours"("p_email" "text") OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."get_rank_rewards"("p_email" "text") RETURNS "jsonb"
    LANGUAGE "sql" SECURITY DEFINER
    AS $$
  SELECT COALESCE(rr.rewards, '{}'::jsonb)
  FROM public.rank_rewards rr
  WHERE rr.min_stars <= (
    SELECT COALESCE(SUM(amount), 0)
    FROM public.star_ledger
    WHERE email = p_email
  )
  ORDER BY rr.min_stars DESC
  LIMIT 1;
$$;


ALTER FUNCTION "public"."get_rank_rewards"("p_email" "text") OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."get_star_balance"("p_email" "text") RETURNS integer
    LANGUAGE "sql" SECURITY DEFINER
    AS $$
  SELECT COALESCE(SUM(amount), 0)::integer
  FROM public.star_ledger
  WHERE email = p_email AND amount > 0;
$$;


ALTER FUNCTION "public"."get_star_balance"("p_email" "text") OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."get_star_leaderboard"("limit_count" integer DEFAULT 20) RETURNS TABLE("rank" bigint, "name" "text", "avatar" "text", "total_stars" bigint, "email" "text")
    LANGUAGE "sql" SECURITY DEFINER
    AS $$WITH star_totals AS (
    SELECT sl.email, SUM(sl.amount) AS total_stars
    FROM public.star_ledger sl
    WHERE sl.amount > 0
    GROUP BY sl.email
  )
  SELECT
    ROW_NUMBER() OVER(ORDER BY st.total_stars DESC)::bigint AS rank,
    COALESCE(u.metadata->>'name', SPLIT_PART(u.email, '@', 1)) AS name,
    COALESCE(u.metadata->>'avatar', 'https://api.dicebear.com/9.x/thumbs/svg?seed=' || u.email) AS avatar,
    st.total_stars::bigint,
    u.email
  FROM star_totals st
  INNER JOIN public.users u ON u.email = st.email
  WHERE st.total_stars > 0
    AND u.email NOT IN (
      SELECT jsonb_array_elements_text(value::jsonb)
      FROM public.constant
      WHERE name = 'admin'
    )
  ORDER BY st.total_stars DESC
  LIMIT limit_count;$$;


ALTER FUNCTION "public"."get_star_leaderboard"("limit_count" integer) OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."get_stripe_data_v2"("email" "text", "amount" double precision, "currency" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$declare
    secret_key text;
    result jsonb;
    code bigint;
  begin
    if get_stripe_data_v2.currency != 'USD' then
      raise exception 'only USD is supported in stripe payment method';
    end if;

    SELECT value->>'secret_key'
    INTO secret_key
    FROM constant
    WHERE name = 'stripe';
    IF secret_key IS NULL THEN
      RAISE EXCEPTION 'stripe secret not available';
    END IF;
    SELECT
      content::jsonb
    INTO result
    FROM extensions.http((
      'POST',
      'https://api.stripe.com/v1/checkout/sessions',
      ARRAY[
        extensions.http_header('Authorization','Bearer ' || secret_key),
        extensions.http_header('Content-Type','application/x-www-form-urlencoded')
      ],
      'application/x-www-form-urlencoded',
      (
        SELECT string_agg(v, '&') FROM (
          VALUES
            ('mode=payment'),
            ('ui_mode=embedded'),
            ('customer_email=' || get_stripe_data_v2.email),
            ('redirect_on_completion=never'),
            ('payment_method_types[0]=card'),
            ('line_items[0][price_data][product_data][name]=thinkmay'),
            ('line_items[0][price_data][unit_amount]=' || (get_stripe_data_v2.amount * 100)::text),
            ('line_items[0][price_data][currency]='    ||  lower(get_stripe_data_v2.currency)),
            ('line_items[0][quantity]=1')
        ) AS t(v)
      )
    )::extensions.http_request);
    return result;
  end;$$;


ALTER FUNCTION "public"."get_stripe_data_v2"("email" "text", "amount" double precision, "currency" "text") OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."get_subscription_v3"("email" "text") RETURNS TABLE("cluster" "text", "created_at" timestamp with time zone, "ended_at" timestamp with time zone, "total_usage" bigint, "usage_limit" bigint, "total_data_credit" bigint, "plan_name" "text", "next_plan" "text", "auto_extend" boolean, "expiration" "text")
    LANGUAGE "sql" SECURITY DEFINER
    AS $$
select
  clusters.domain,
  subscriptions.created_at,
  subscriptions.ended_at,
  subscriptions.total_usage,
  (select coalesce(subscriptions.usage_limit, plans.total_hours) + coalesce(public.get_rank_bonus_hours(email), 0)
    from payment_request
    inner join plans
    on plans.id = payment_request.plan
    where payment_request.verified_at is not null
    and payment_request.subscription = subscriptions.id
    order by payment_request.created_at desc
    limit 1
  ) as usage_limit,
  subscriptions.total_data_credit,
  (select plans.name
    from payment_request
    inner join plans
    on plans.id = payment_request.plan
    where payment_request.verified_at is not null
    and payment_request.subscription = subscriptions.id
    order by payment_request.created_at desc
    limit 1
  ) as plan_name,
  (select plans.name
    from payment_request
    inner join plans
    on plans.id = payment_request.plan
    where payment_request.verified_at is null
    and payment_request.subscription = subscriptions.id
    order by payment_request.created_at desc
    limit 1
  ) as next_plan,
  (select plans.credit <= pockets.amount
    from payment_request
    inner join plans
    on plans.id = payment_request.plan
    where payment_request.verified_at is null
    and payment_request.subscription = subscriptions.id
    order by payment_request.created_at desc
    limit 1
  ) as auto_extend,
  (select
    (case
      when subscriptions.total_usage > (coalesce(subscriptions.usage_limit, plans.total_hours) + coalesce(public.get_rank_bonus_hours(email), 0)) * 60 then 'out_of_time'
      when subscriptions.ended_at is not null and subscriptions.ended_at < now() then 'out_of_day'
      when subscriptions.total_usage - (coalesce(subscriptions.usage_limit, plans.total_hours) + coalesce(public.get_rank_bonus_hours(email), 0)) * 60 > 3 * 60 then 'near_out_of_time'
      when subscriptions.ended_at is not null and subscriptions.ended_at - '7 days'::interval < now() then 'near_out_of_day'
      else null end
    ) as expiration
    from payment_request
    inner join plans
    on plans.id = payment_request.plan
    where payment_request.verified_at is not null
    and payment_request.subscription = subscriptions.id
    order by payment_request.created_at desc
    limit 1
  ) as expiration

 from subscriptions
 inner join clusters
 on clusters.id = subscriptions.cluster
 inner join pockets
 on pockets."user" = subscriptions."user"
 where subscriptions."user" = get_subscription_v3.email
 and subscriptions.cancelled_at is null
 and subscriptions.cleaned_at is null
 and subscriptions.allocated_at is not null
 limit 1;
$$;


ALTER FUNCTION "public"."get_subscription_v3"("email" "text") OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."get_transaction_status"("id" bigint) RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
  return (select status
          from transactions
          where transactions.id = get_transaction_status.id
          limit 1);
end;
$$;


ALTER FUNCTION "public"."get_transaction_status"("id" bigint) OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."get_unpaid_addon_subscriptions"("email" "text") RETURNS TABLE("id" bigint, "name" "text", "created_at" timestamp with time zone, "cancelled_at" timestamp with time zone, "unit_price" "jsonb", "unit_count" bigint)
    LANGUAGE "sql"
    AS $$select
  addon_subscriptions.id,
  addons.name,
  addon_subscriptions.created_at,
  addon_subscriptions.cancelled_at,
  addons.unit_price,
  addon_subscriptions.unit_count

from addon_subscriptions
inner join addons
on addons.id = addon_subscriptions.addon

inner join subscriptions
on addon_subscriptions.subscription = subscriptions.id
and subscriptions.cleaned_at is null
and subscriptions.allocated_at is not null
and subscriptions.user = get_unpaid_addon_subscriptions.email

where addon_subscriptions.unit_count > 0$$;


ALTER FUNCTION "public"."get_unpaid_addon_subscriptions"("email" "text") OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."get_user_heatmap"("target_email" "text") RETURNS TABLE("usage_date" "date", "total_hours" numeric)
    LANGUAGE "sql" SECURITY DEFINER
    AS $$
  SELECT
    DATE(created_at) AS usage_date,
    (COUNT(*) * 5.0 / 60.0) AS total_hours
  FROM public.vm_snapshoot_v4
  WHERE email = target_email
    AND created_at >= NOW() - INTERVAL '365 days'
  GROUP BY DATE(created_at)
  ORDER BY usage_date ASC;
$$;


ALTER FUNCTION "public"."get_user_heatmap"("target_email" "text") OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."get_user_missions_v2"("p_email" "text") RETURNS TABLE("id" integer, "code" "text", "category" "text", "type" "text", "target_value" integer, "reward_stars" integer, "title_key" "text", "description_key" "text", "icon" "text", "is_repeatable" boolean, "progress" integer, "status" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_referral_signups int;
    v_referral_payments int;
    v_feedback_count int;
    v_discord_help_total int;
    v_sessions_today int;
    v_play_streak int;
    v_benchmark_approved int;
    v_discord_reviews_week int;
    v_discord_features_week int;
    v_month1_payments int;
    v_performance_payments int;
    v_admin_emails text[];
BEGIN
    -- Fetch admin emails once
    SELECT ARRAY(
        SELECT jsonb_array_elements_text(value::jsonb)
        FROM public.constant
        WHERE name = 'admin'
    ) INTO v_admin_emails;
    -- Referral signups (deduplicated, excludes self-referral)
    SELECT COUNT(DISTINCT "to") INTO v_referral_signups
    FROM public.referral WHERE "from" = p_email AND "to" != p_email;

    -- Referral payments (excludes self-referral)
    SELECT COUNT(DISTINCT r."to") INTO v_referral_payments
    FROM public.referral r
    JOIN public.subscriptions s ON s."user" = r."to"
    JOIN public.payment_request pr ON pr.subscription = s.id
    WHERE r."from" = p_email AND r."to" != p_email AND pr.verified_at IS NOT NULL;

    -- Self payments for monthly plans (month1 + month2 both count)
    SELECT COUNT(*) INTO v_month1_payments
    FROM public.payment_request pr
    JOIN public.subscriptions s ON s.id = pr.subscription
    JOIN public.plans p ON p.id = pr.plan
    WHERE s."user" = p_email AND pr.verified_at IS NOT NULL AND p.name IN ('month1', 'month2');

    -- Self payments for month2 plan only (kept for PLAN_RENEWAL_PERF missions if any)
    SELECT COUNT(*) INTO v_performance_payments
    FROM public.payment_request pr
    JOIN public.subscriptions s ON s.id = pr.subscription
    JOIN public.plans p ON p.id = pr.plan
    WHERE s."user" = p_email AND pr.verified_at IS NOT NULL AND p.name = 'month2';

    -- Feedback (total + today)
    SELECT COUNT(*) INTO v_feedback_count
    FROM public.feedbacks WHERE email = p_email;

    -- Sessions today
    SELECT COUNT(*) INTO v_sessions_today
    FROM public.vm_snapshoot_v4
    WHERE email = p_email AND DATE(created_at) = CURRENT_DATE;

    -- Play streak (consecutive days backwards from today)
    WITH daily AS (
        SELECT DISTINCT DATE(created_at) AS d
        FROM public.vm_snapshoot_v4
        WHERE email = p_email AND created_at >= NOW() - INTERVAL '60 days'
    ),
    numbered AS (
        -- FIX: Added + instead of - to correctly group descending dates
        SELECT d, d + (ROW_NUMBER() OVER (ORDER BY d DESC))::int AS grp
        FROM daily
    )
    SELECT COALESCE(COUNT(*), 0) INTO v_play_streak
    FROM numbered
    WHERE grp = (SELECT grp FROM numbered WHERE d = CURRENT_DATE LIMIT 1);

    -- Discord help (total + today) based on non-self reaction on messages with recipients
    SELECT COUNT(DISTINCT de.message_id) INTO v_discord_help_total
    FROM public.discord_events de
    WHERE de.name = 'message_create'
      AND de.email = p_email
      AND de.recipients IS NOT NULL
      AND array_length(de.recipients, 1) > 0
      AND EXISTS (
        SELECT 1 FROM public.discord_events r
        WHERE r.name = 'reaction_add'
          AND r.message_id = de.message_id
          AND r.email != p_email
      );


    -- Discord bug reports (admin-approved bug_report_create)
    SELECT COUNT(DISTINCT de.message_id) INTO v_discord_reviews_week
    FROM public.discord_events de
    WHERE de.name = 'bug_report_create'
      AND de.email = p_email
      AND EXISTS (
        SELECT 1 FROM public.discord_events r
        WHERE r.name = 'reaction_add'
          AND r.message_id = de.message_id
          AND r.email IN (SELECT jsonb_array_elements_text(value::jsonb) FROM public.constant WHERE name = 'admin')
      );

    -- Discord feature requests (admin-approved feature_request_create)
    SELECT COUNT(DISTINCT de.message_id) INTO v_discord_features_week
    FROM public.discord_events de
    WHERE de.name = 'feature_request_create'
      AND de.email = p_email
      AND EXISTS (
        SELECT 1 FROM public.discord_events r
        WHERE r.name = 'reaction_add'
          AND r.message_id = de.message_id
          AND r.email IN (SELECT jsonb_array_elements_text(value::jsonb) FROM public.constant WHERE name = 'admin')
      );

    v_benchmark_approved := 0;

    -- Evaluate each mission
    RETURN QUERY
    SELECT
        m.id, m.code, m.category, m.type, m.target_value, m.reward_stars,
        m.title_key, m.description_key, m.icon, m.is_repeatable,

        -- Resolve progress
        (CASE
            WHEN m.type = 'DAILY_SESSION'       THEN v_sessions_today
            WHEN m.type = 'PLAY_STREAK'         THEN v_play_streak
            WHEN m.type = 'REFERRAL_SIGNUP'     THEN v_referral_signups
            WHEN m.type = 'REFERRAL_PAYMENT'    THEN v_referral_payments
            WHEN m.type = 'PLAN_RENEWAL_MONTH1' THEN v_month1_payments
            WHEN m.type = 'PLAN_RENEWAL_PERF'   THEN v_performance_payments
            WHEN m.type = 'FEEDBACK_MILESTONE'  THEN v_feedback_count
            WHEN m.type = 'DISCORD_EVENT'       THEN
                CASE m.code
                    WHEN 'DISCORD_REVIEW'      THEN v_discord_reviews_week
                    WHEN 'DISCORD_FEATURE_REQ' THEN v_discord_features_week
                    ELSE 0
                END
            WHEN m.type = 'DISCORD_MILESTONE'   THEN v_discord_help_total
            WHEN m.type = 'BENCHMARK_EVENT'     THEN v_benchmark_approved
            ELSE 0
        END)::int AS progress,

        -- Resolve status
        (CASE
            -- Check if claimed (for non-repeatable, any claim; for repeatable, check cooldown)
            WHEN NOT m.is_repeatable AND EXISTS (
                SELECT 1 FROM public.user_mission_claims umc
                WHERE umc.mission_id = m.id AND umc.email = p_email
            ) THEN 'claimed'
            WHEN m.is_repeatable AND m.cooldown_days IS NOT NULL AND EXISTS (
                SELECT 1 FROM public.user_mission_claims umc
                WHERE umc.mission_id = m.id AND umc.email = p_email
                AND umc.claimed_at > NOW() - (m.cooldown_days || ' day')::interval
            ) THEN 'claimed'
            -- Check if completed (progress >= target)
            WHEN (CASE
                    WHEN m.type = 'DAILY_SESSION'       THEN v_sessions_today
                    WHEN m.type = 'PLAY_STREAK'         THEN v_play_streak
                    WHEN m.type = 'REFERRAL_SIGNUP'     THEN v_referral_signups
                    WHEN m.type = 'REFERRAL_PAYMENT'    THEN v_referral_payments
                    WHEN m.type = 'PLAN_RENEWAL_MONTH1' THEN v_month1_payments
                    WHEN m.type = 'PLAN_RENEWAL_PERF'   THEN v_performance_payments
                    WHEN m.type = 'FEEDBACK_COUNT'      THEN v_feedback_today
                    WHEN m.type = 'FEEDBACK_MILESTONE'  THEN v_feedback_count
                    WHEN m.type = 'DISCORD_EVENT'       THEN
                        CASE m.code
                            WHEN 'DISCORD_REVIEW'      THEN v_discord_reviews_week
                            WHEN 'DISCORD_FEATURE_REQ' THEN v_discord_features_week
                            ELSE 0
                        END
                    WHEN m.type = 'DISCORD_MILESTONE'   THEN v_discord_help_total
                    WHEN m.type = 'BENCHMARK_EVENT'     THEN v_benchmark_approved
                    ELSE 0
                  END) >= m.target_value THEN 'completed'
            ELSE 'in_progress'
        END)::text AS status

    FROM public.missions m
    WHERE m.is_active = true
    ORDER BY m.sort_order ASC, m.id ASC;
END;
$$;


ALTER FUNCTION "public"."get_user_missions_v2"("p_email" "text") OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."grant_app_access_v1"("email" "text", "app_id" "text", "cluster" bigint) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$declare
   user_id text;
   admintoken text;
   domain text;
   url text;
begin
    select token,get_cluster_secrets.url,get_cluster_secrets.domain
    into admintoken, url,domain
    FROM get_cluster_secrets(grant_app_access_v1.cluster);

    select generate_account_v3 into user_id
    from generate_account_v3(grant_app_access_v1.email, domain);

    if has_app_access(user_id, grant_app_access_v1.cluster) then
      return;
    end if;


    perform extensions.http_set_curlopt ('CURLOPT_TIMEOUT', '120');
    perform extensions.http_set_curlopt ('CURLOPT_CONNECTTIMEOUT', '120');

    perform extensions.http((
      'POST',
      url || '/api/collections/app_access/records',
      ARRAY[extensions.http_header('Authorization','Bearer ' || admintoken)],
      'application/json',
      jsonb_build_object(
        'user',user_id,
        'app_id', grant_app_access_v1.app_id
      )
    )::extensions.http_request) as request;
end;$$;


ALTER FUNCTION "public"."grant_app_access_v1"("email" "text", "app_id" "text", "cluster" bigint) OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."grant_bucket_access_v1"("email" "text", "cluster" bigint) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$declare
   user_id text;
   admintoken text;
   domain text;
   url text;

   bucket_name_uuid uuid;
begin
    select token,get_cluster_secrets.url,get_cluster_secrets.domain
    into admintoken, url,domain
    FROM get_cluster_secrets(grant_bucket_access_v1.cluster);

    select generate_account_v3 into user_id
    from generate_account_v3(grant_bucket_access_v1.email, domain);

    select gen_random_uuid() into bucket_name_uuid;

    if has_bucket_access(user_id, grant_bucket_access_v1.cluster) then
      return;
    end if;

    perform extensions.http_set_curlopt ('CURLOPT_TIMEOUT', '120');
    perform extensions.http_set_curlopt ('CURLOPT_CONNECTTIMEOUT', '120');
    perform extensions.http((
      'POST',
      url || '/api/collections/buckets/records',
      ARRAY[extensions.http_header('Authorization','Bearer ' ||admintoken)],
      'application/json',
      jsonb_build_object(
        'user',user_id,
        'bucket_name', bucket_name_uuid::text
      )
    )::extensions.http_request) as request;
end;$$;


ALTER FUNCTION "public"."grant_bucket_access_v1"("email" "text", "cluster" bigint) OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."grant_llm_access_v1"("email" "text", "cluster" bigint) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
   user_id text;
   admintoken text;
   domain text;
   url text;
   existing_check text;
begin
    select token, get_cluster_secrets.url, get_cluster_secrets.domain
    into admintoken, url, domain
    FROM get_cluster_secrets(grant_llm_access_v1.cluster);

    select generate_account_v3 into user_id
    from generate_account_v3(grant_llm_access_v1.email, domain);

    select item->>'id' into existing_check
    FROM try_get(
      url || '/api/collections/llmModels/records?filter=(user="' || user_id || '")',
      ARRAY[extensions.http_header('Authorization', 'Bearer ' || admintoken)]
    ) as request
    cross join jsonb_array_elements((request.content::jsonb)->'items') as item
    LIMIT 1;

    if existing_check is not null then
      return;
    end if;

    perform extensions.http_set_curlopt ('CURLOPT_TIMEOUT', '120');
    perform extensions.http((
      'POST',
      url || '/api/collections/llmModels/records',
      ARRAY[extensions.http_header('Authorization','Bearer ' || admintoken)],
      'application/json',
      jsonb_build_object(
        'user', user_id,
        'model', 'gemini-3-flash-preview',
        'usage', 0
      )
    )::extensions.http_request);
end;$$;


ALTER FUNCTION "public"."grant_llm_access_v1"("email" "text", "cluster" bigint) OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."has_app_access"("user_id" "text", "cluster" bigint) RETURNS boolean
    LANGUAGE "plpgsql"
    AS $$
declare
    admintoken text;
    url text;
    result bool;
  begin
    perform extensions.http_set_curlopt ('CURLOPT_TIMEOUT', '120');
    perform extensions.http_set_curlopt ('CURLOPT_CONNECTTIMEOUT', '120');

    select token,get_cluster_secrets.url
    into admintoken, url
    FROM get_cluster_secrets(has_app_access.cluster);

    with access_list as (
      select
        item->>'id' as id
      FROM extensions.http(('GET',
        url || '/api/collections/app_access/records?filter=(user="' || has_app_access.user_id || '")',
        ARRAY[extensions.http_header('Authorization',concat('Bearer ' ,admintoken))],
        NULL, NULL
      )::extensions.http_request) as request
      inner join jsonb_array_elements((request.content::jsonb)->'items') as item on true
    )

    select count(*) > 0 into result from access_list;

    return result;
  end;
$$;


ALTER FUNCTION "public"."has_app_access"("user_id" "text", "cluster" bigint) OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."has_bucket_access"("user_id" "text", "cluster" bigint) RETURNS boolean
    LANGUAGE "plpgsql"
    AS $$
  declare
    admintoken text;
    url text;
    user_id text;
    result bool;
  begin
    select token,get_cluster_secrets.url
    into admintoken, url
    FROM get_cluster_secrets(has_bucket_access.cluster);


    perform extensions.http_set_curlopt ('CURLOPT_TIMEOUT', '120');
    perform extensions.http_set_curlopt ('CURLOPT_CONNECTTIMEOUT', '120');

    with access_list as (
      select
        item->>'id' as id
      FROM extensions.http(('GET',
        url || '/api/collections/buckets/records?filter=(user="' || has_bucket_access.user_id || '")',
        ARRAY[extensions.http_header('Authorization',concat('Bearer ' ,admintoken))],
        NULL, NULL
      )::extensions.http_request) as request
      inner join jsonb_array_elements((request.content::jsonb)->'items') as item on true
    )
    select count(*) > 0
    into result
    from access_list;

    return result;
  end;
$$;


ALTER FUNCTION "public"."has_bucket_access"("user_id" "text", "cluster" bigint) OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."identify_user_subscription"("email" "text") RETURNS TABLE("week_payment" bigint, "month_payment" bigint)
    LANGUAGE "sql" SECURITY DEFINER
    AS $$
  select
    count(*) filter (where position('week' in plan_name) > 0) as week_payment,
    count(*) filter (where position('month' in plan_name) > 0) as month_payment
  from get_payment_history(identify_user_subscription.email)
$$;


ALTER FUNCTION "public"."identify_user_subscription"("email" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."insert_transaction_with_next_id"() RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    next_id INTEGER;
BEGIN
    -- Calculate the next ID as max(id) + 1
    SELECT COALESCE(MAX(id), 0) + 1 INTO next_id FROM transactions;

    DELETE FROM transactions WHERE email = 'this_email_for_fix_duplication_transaction_payos@gmail.com';

    -- Insert the new transaction with the calculated next_id
    INSERT INTO transactions(id, amount, email) VALUES(next_id, 1, 'this_email_for_fix_duplication_transaction_payos@gmail.com');

    -- Return the ID that was used
    RETURN next_id;
END;
$$;


ALTER FUNCTION "public"."insert_transaction_with_next_id"() OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."is_json"("_txt" "text") RETURNS boolean
    LANGUAGE "plpgsql" IMMUTABLE STRICT
    AS $$
BEGIN
   RETURN _txt::json IS NOT NULL;
EXCEPTION
   WHEN SQLSTATE '22P02' THEN  -- invalid_text_representation
      RETURN false;
END
$$;


ALTER FUNCTION "public"."is_json"("_txt" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."jsonb_to_query"("params" "jsonb") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE
    AS $$
SELECT string_agg(urlencode(key) || '=' || urlencode(value), '&')
FROM jsonb_each_text(params);
$$;


ALTER FUNCTION "public"."jsonb_to_query"("params" "jsonb") OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."list_addon_charges_v2"("input_email" "text") RETURNS TABLE("addon_name" "text", "usage_units" bigint, "billable_units" bigint, "price_per_unit" double precision, "total_amount" bigint)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
  WITH active_context AS (
    SELECT
      s.id AS subscription_id,
      s.total_data_credit,
      p.price->'allowances' AS plan_allowances,
      (p.price -> 'storage' -> 'unit_price' ->> 'amount')::float8 AS storage_price,
      (p.price -> 'storage' -> 'unit_price' ->> 'per_quantity')::float8 AS storage_per_quantity
    FROM subscriptions s
    JOIN payment_request pr ON pr.subscription = s.id
    JOIN plans p ON pr.plan = p.id
    WHERE s."user" = list_addon_charges_v2.input_email
      AND s.allocated_at IS NOT NULL
      AND s.cleaned_at IS NULL
      AND pr.verified_at IS NOT NULL
    ORDER BY pr.created_at DESC
    LIMIT 1
  )

  SELECT
      a.name::text AS addon_name,
      asu.unit_count AS usage_units,

      -- Deduct BOTH plan allowance AND rank reward allowance
      GREATEST(
        asu.unit_count
          - COALESCE((ctx.plan_allowances->>a.name)::bigint, 0)
          - get_rank_allowance(list_addon_charges_v2.input_email, a.name),
        0
      ) AS billable_units,

      (a.unit_price->>'amount')::float8 AS price_per_unit,

      (
        floor(
          GREATEST(
            asu.unit_count
              - COALESCE((ctx.plan_allowances->>a.name)::bigint, 0)
              - get_rank_allowance(list_addon_charges_v2.input_email, a.name),
            0
          ) / NULLIF((a.unit_price->>'per_quantity')::float8, 0)
        ) * (a.unit_price->>'amount')::float8
      )::bigint AS total_amount
  FROM active_context ctx
  JOIN addon_subscriptions asu ON asu.subscription = ctx.subscription_id
  JOIN addons a ON asu.addon = a.id
  WHERE asu.cancelled_at IS NULL
    AND asu.unit_count > 0

  UNION ALL

  SELECT
      'data_overage'::text,
      ctx.total_data_credit,
      (ctx.total_data_credit - COALESCE((ctx.plan_allowances->>'disk')::bigint, 0)),
      ctx.storage_price,
      ((ctx.total_data_credit - COALESCE((ctx.plan_allowances->>'disk')::bigint, 0))::float8 * ctx.storage_price / ctx.storage_per_quantity)::bigint
  FROM active_context ctx
  WHERE (ctx.total_data_credit - COALESCE((ctx.plan_allowances->>'disk')::bigint, 0)) > 0
    AND ctx.storage_price IS NOT NULL
  limit 10
$$;


ALTER FUNCTION "public"."list_addon_charges_v2"("input_email" "text") OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."local_version_control_v1"() RETURNS TABLE("proxymd5" "text", "daemonmd5" "text", "pbmd5" "text", "appmd5" "text", "proxyurl" "text", "daemonurl" "text", "pburl" "text", "appurl" "text")
    LANGUAGE "sql"
    AS $$select
      '3dc778e96ba2f4d56ecf9dda1a0e5afb' as proxymd5,
      'c279ad08d0d138998b29027595a1f903' as daemonmd5,
      'e30944e1c60952729a72e347b2d72f5f' as pbmd5,
      '' as appmd5,

      'https://link.storjshare.io/raw/ju4w2hnua5inz54vi7igflt4zogq/root/pbc_1754676875%2Fisxxrfnhj3mj2er/proxy_9fuci591bd' as proxyurl,
      'https://link.storjshare.io/raw/jxnnb4coiaq3t7gq3rbyumbgpqeq/root/pbc_1754676875%2Fa7h1yl9a2hxmmdg/daemon_icx33qsqq3' as daemonurl,
      'https://link.storjshare.io/raw/juhg5xj36xf76nhcdynx3tkihsna/root/pbc_1754676875%2Fb0oovn3bs3hfucc/pbmqt4brealk_de8x071glo' as pburl,
      '' as appurl$$;


ALTER FUNCTION "public"."local_version_control_v1"() OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."modify_payment_pocket"("id" bigint, "plan_name" "text", "renew" boolean) RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
    plan_id bigint;
    extendable boolean;
begin
    -- Find the plan ID
    select plans.id, plans.extendable into plan_id,extendable
    from plans
    where plans.name = modify_payment_pocket.plan_name;

    if plan_id is null then
        return false; -- Plan doesn't exist
    end if;

    if not extendable then
      raise exception 'this plan is not extendable';
    end if;

    -- Update the payment request
    if renew = true then
        update payment_request
        set plan = plan_id,
            created_at = now()
        where payment_request.id = modify_payment_pocket.id
        and payment_request.verified_at is null;
    else
        update payment_request
        set plan = plan_id
        where payment_request.id = modify_payment_pocket.id
        and payment_request.verified_at is null;
    end if;

    return true;
end;
$$;


ALTER FUNCTION "public"."modify_payment_pocket"("id" bigint, "plan_name" "text", "renew" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."new_pocket_deposits_v2"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$declare
    email text;
    signature text;
    prehash text;

    result jsonb;
    code bigint;

    transaction int8;
    multiply_rate float8;

    random_id int8;
  begin
    if (NEW.verified_at is not null) THEN
      RETURN NEW;
    elsif (NEW.discount is not null) then
      select coalesce(discounts.multiply_rate,1) into multiply_rate
      from discounts
      where discounts.id = NEW.discount;
    end if;

    select
      pockets.user as email
    into email
    from pockets
    where pockets.id = NEW.pocket;

    loop
      random_id := floor(random() * POWER(2::bigint, 32))::int8;
      exit when not exists(select 1 from transactions where id = random_id);
    end loop;

    insert into transactions(id,email,amount,metadata)
    values (
      random_id,
      email,
      round(NEW.amount / coalesce(multiply_rate,1)),
      NEW.metadata
    )
    returning id
    into transaction;


    NEW.transaction = transaction;
    return NEW;
  end;$$;


ALTER FUNCTION "public"."new_pocket_deposits_v2"() OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."new_store_added"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$DECLARE
    result jsonb;
    http_content text;
    steam_api_url text;
BEGIN
    IF (NEW.type != 'STEAM') THEN
        RETURN NEW;
    END IF;

    steam_api_url := 'https://store.steampowered.com/api/appdetails?appids=' || NEW.id || '&cc=us';

    -- Cách 1: Dùng SELECT INTO
    SELECT http_result.content::text INTO http_content
    FROM extensions.http_get(steam_api_url) AS http_result;

    -- Cách 2: Hoặc dùng assignment
    -- http_content := extensions.http_get(steam_api_url);

    BEGIN
        result := ((http_content::jsonb)->(NEW.id::text)->'data')::jsonb;
    EXCEPTION WHEN OTHERS THEN
        result := null;
    END;

    NEW.name = result->>'name';
    NEW.metadata := result;

    RETURN NEW;
END;$$;


ALTER FUNCTION "public"."new_store_added"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."notify_active_plan_v2"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$declare
  all_plan_active record;
begin
  if NEW.metadata = OLD.metadata then
    return NEW;
  end if;

  if NEW.metadata->>'disable' is not null then

    perform extensions.http(('POST', 'https://discord.com/api/webhooks/1371714781093953566/F7FT_lTLlnYNH3j0OlWFGoSHGutWrMxtsh8WhNbUKxWggiAXlCR_jV04G19te2Y-_Hie', NULL, 'application/json',
    jsonb_build_object('content', concat('**[', 'Plan Update' ,']** <@602030164880130062>, <@741841777367056436>, <@1056908237397565450>',' | ',
    'Đã đóng gói: ', OLD.name
    )))::extensions.http_request) as request;
  else
    perform extensions.http(('POST', 'https://discord.com/api/webhooks/1371714781093953566/F7FT_lTLlnYNH3j0OlWFGoSHGutWrMxtsh8WhNbUKxWggiAXlCR_jV04G19te2Y-_Hie', NULL, 'application/json',
    jsonb_build_object('content', concat('**[', 'Plan Update' ,']** <@602030164880130062>, <@741841777367056436>, <@1056908237397565450>',' | ',
    'Đã mở gói: ', OLD.name
    )))::extensions.http_request) as request;
  end if;


  return new;
end;$$;


ALTER FUNCTION "public"."notify_active_plan_v2"() OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."notify_failure_job"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$declare
begin

  if NEW.success = false and OLD.command != 'delete volume v5' then
    perform extensions.http(('POST', 'https://discordapp.com/api/webhooks/1276390101143785563/jE1hgDyN0_ip-1BCrqDk3rOFCT9FA2ERoxdIElO_BIXxY40EwF7WG_1DQnaJh3GMf0mx', NULL, 'application/json',
    jsonb_build_object('content', concat('**[**', OLD.command ,'** FAILED]**', ' id ', OLD.id, ' email ', OLD.arguments->>'email', '<@439682980638883840> <@1374201478960648364>', '\n' , 'Result: ', OLD.result)))::extensions.http_request) as request;
  end if;

  return new;
end;$$;


ALTER FUNCTION "public"."notify_failure_job"() OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."on_app_access_reset"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$declare
  v_email text;
  v_cluster_id bigint;
  v_addon_name text;
begin
  if (NEW.unit_count = 0 and OLD.unit_count != 0) then
    select name into v_addon_name
    from addons
    where id = NEW.addon;

    select "user", "cluster"
    into v_email, v_cluster_id
    from subscriptions
    where id = NEW.subscription;

    if (v_email is not null and v_cluster_id is not null) then
      if (v_addon_name = 'app_access') then
        perform reset_app_access_usage(v_cluster_id, v_email);
      elsif (v_addon_name = 'llm') then
        perform reset_llm_usage(v_cluster_id, v_email);
      end if;
    end if;
  end if;
  return NEW;
end;$$;


ALTER FUNCTION "public"."on_app_access_reset"() OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."on_transaction_driver_v2"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$declare
    result jsonb;
    exchange_rate float8;
  begin
    SELECT rate_to_system_credit
    INTO exchange_rate
    FROM currency_rates
    WHERE currency_rates.currency = NEW.currency;

    IF exchange_rate IS NULL THEN
        RAISE EXCEPTION 'Currency % not supported', NEW.currency;
    END IF;

    IF (OLD.provider is null and NEW.provider = 'PAYOS' and
        OLD.currency is null and NEW.currency = 'VND') then
        select get_payos_data into result
        from get_payos_data(NEW.id,NEW.email,NEW.amount / exchange_rate);
    ELSIF (OLD.provider is null and NEW.provider = 'PAYSSION') then
        select get_payssion_data into result
        from get_payssion_data(NEW.id,NEW.email,NEW.amount / exchange_rate,NEW.currency);
    ELSIF (OLD.provider is null and NEW.provider = 'STRIPE') then
        select get_stripe_data_v2 into result
        from get_stripe_data_v2(NEW.email,NEW.amount / exchange_rate,NEW.currency);
    ELSIF (OLD.provider is null and NEW.provider = 'PAYERMAX') then
        select get_payermax_data_v2 into result
        from get_payermax_data_v2(NEW.id,NEW.email, NEW.amount / exchange_rate, NEW.currency,NEW.metadata);
    END IF;
    IF (result is not null) then
      NEW.data = result;
    END IF;
    return NEW;
  end;$$;


ALTER FUNCTION "public"."on_transaction_driver_v2"() OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."pay_all_addon_charges"("email" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$DECLARE
    v_sub_id bigint;
    v_total_to_pay bigint;
BEGIN
    CREATE TEMP TABLE IF NOT EXISTS temp_addon_charges ON COMMIT DROP AS
    SELECT * FROM list_addon_charges_v2(email);

    SELECT COALESCE(SUM(temp_addon_charges.total_amount), 0)
    INTO v_total_to_pay
    FROM temp_addon_charges;

    IF v_total_to_pay <= 0 THEN RETURN; END IF;

    SELECT id INTO v_sub_id FROM subscriptions
    WHERE "user" = email AND allocated_at IS NOT NULL AND cleaned_at IS NULL LIMIT 1;

    IF v_sub_id IS NULL THEN RETURN; END IF;

    UPDATE pockets SET amount = amount - v_total_to_pay
    WHERE "user" = email AND amount >= v_total_to_pay;

    IF NOT FOUND THEN RAISE EXCEPTION 'Insufficient funds or pocket not found'; END IF;

    UPDATE addon_subscriptions
    SET unit_count = 0
    FROM addons, temp_addon_charges
    WHERE addons.id = addon_subscriptions.addon
      AND addons.name = temp_addon_charges.addon_name
      AND addon_subscriptions.subscription = v_sub_id
      AND temp_addon_charges.addon_name != 'data_overage';

    UPDATE subscriptions SET total_data_credit = 0
    WHERE id = v_sub_id AND EXISTS (SELECT 1 FROM temp_addon_charges WHERE addon_name = 'data_overage');
END;$$;


ALTER FUNCTION "public"."pay_all_addon_charges"("email" "text") OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."preorder_template"("app_id" bigint) RETURNS "void"
    LANGUAGE "sql" SECURITY DEFINER
    AS $$
UPDATE stores
SET queue = queue + 1
WHERE id = preorder_template.app_id
$$;


ALTER FUNCTION "public"."preorder_template"("app_id" bigint) OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."query_payermax_status"("transaction_id" bigint) RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  app_id text;
  merchant_no text;
  base_url text;

  outTradeNo text;
  req_body jsonb;
  signature text;

  api_result record;
  resp_json jsonb;
  pm_status text;
BEGIN
  SELECT value->>'app_id', value->>'merchant_no', value->>'base_url'
  INTO app_id, merchant_no, base_url
  FROM constant WHERE name = 'payermax';

  select data->'data'->>'outTradeNo' into outTradeNo
  from transactions
  where transactions.id = query_payermax_status.transaction_id
  and transactions.provider = 'PAYERMAX'
  limit 1;

  req_body := jsonb_build_object(
    'version', '1.4',
    'keyVersion', '1',
    'requestTime', to_char(now(), 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
    'appId', app_id,
    'merchantNo', merchant_no,
    'data', jsonb_build_object('outTradeNo', outTradeNo)
  );

  SELECT * INTO api_result
  FROM try_post(
    base_url || '/orderQuery',
    ARRAY[
      extensions.http_header('Content-Type', 'application/json;charset=utf-8'),
      extensions.http_header('sign', sign_payermax_rsa_sha256(req_body::text))
    ],
    req_body
  );

  IF api_result.success IS FALSE THEN
    RETURN 'ERROR_NETWORK';
  END IF;

  BEGIN
    resp_json := api_result.content::jsonb;
  EXCEPTION WHEN OTHERS THEN
    RETURN 'ERROR_JSON';
  END;

  IF (resp_json->>'code') != 'APPLY_SUCCESS' THEN
    RETURN resp_json->>'code';
  END IF;

  RETURN COALESCE(resp_json->'data'->>'status', 'UNKNOWN');
END;
$$;


ALTER FUNCTION "public"."query_payermax_status"("transaction_id" bigint) OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."reset_app_access_usage"("cluster_id" bigint, "email" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
  admintoken text;
  url text;
  domain text;
  user_id text;
  _res text;
begin
  select token, get_cluster_secrets.url, get_cluster_secrets.domain
  into admintoken, url, domain
  FROM get_cluster_secrets(reset_app_access_usage.cluster_id);

  select generate_account_v3 into user_id
  from generate_account_v3(reset_app_access_usage.email, domain);

  with reset_list as (
    select
      item->>'id' as id
    from extensions.http((
      'GET',
      url || '/api/collections/app_access/records?filter=(user="' || user_id || '")&fields=id',
      ARRAY[extensions.http_header('Authorization','Bearer ' || admintoken)],
      NULL, NULL
    )::extensions.http_request) as request
    cross join jsonb_array_elements((request.content::jsonb)->'items') as item
  )
  select id into _res from reset_list,
  lateral extensions.http((
    'PATCH',
    url || '/api/collections/app_access/records/' || reset_list.id,
    ARRAY[extensions.http_header('Authorization', 'Bearer ' || admintoken)],
    'application/json',
    '{"usage": 0}'
  )::extensions.http_request);

  return;
end;
$$;


ALTER FUNCTION "public"."reset_app_access_usage"("cluster_id" bigint, "email" "text") OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."reset_llm_usage"("cluster_id" bigint, "email" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
  admintoken text;
  url text;
  domain text;
  user_id text;
  _res text;
begin
  select token, get_cluster_secrets.url, get_cluster_secrets.domain
  into admintoken, url, domain
  FROM get_cluster_secrets(reset_llm_usage.cluster_id);

  select generate_account_v3 into user_id
  from generate_account_v3(reset_llm_usage.email, domain);

  with reset_list as (
    select
      item->>'id' as id
    from extensions.http((
      'GET',
      url || '/api/collections/llmModels/records?filter=(user="' || user_id || '")&fields=id',
      ARRAY[extensions.http_header('Authorization','Bearer ' || admintoken)],
      NULL, NULL
    )::extensions.http_request) as request
    cross join jsonb_array_elements((request.content::jsonb)->'items') as item
  )
  select id into _res from reset_list,
  lateral extensions.http((
    'PATCH',
    url || '/api/collections/llmModels/records/' || reset_list.id,
    ARRAY[extensions.http_header('Authorization', 'Bearer ' || admintoken)],
    'application/json',
    '{"usage": 0}'
  )::extensions.http_request);

  return;
end;
$$;


ALTER FUNCTION "public"."reset_llm_usage"("cluster_id" bigint, "email" "text") OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."search_stores"("texts" "text"[]) RETURNS TABLE("id" bigint, "name" "text", "code_name" "text", "publishers" "jsonb", "support_info" "jsonb", "short_description" "text", "detailed_description" "text", "header_image" "text", "pc_requirements" "jsonb", "screenshots" "jsonb", "genres" "jsonb", "type" "text", "queue" bigint, "benchmarks" "jsonb", "metadata_locale" "jsonb", "rank" double precision)
    LANGUAGE "sql"
    AS $_$

WITH search_inputs AS (
    -- 1. Unnest array and prepare search inputs
    SELECT
        search_text,
        CASE
            WHEN search_text ~ '^[0-9]+$' THEN NULL
            ELSE to_tsquery('english', search_text)
        END AS query_ts,
        CASE
            WHEN search_text ~ '^[0-9]+$' THEN search_text::bigint
            ELSE NULL
        END AS id_input
    FROM unnest(texts) AS search_text
),
best_matches AS (
    -- 2. LATERAL JOIN: For EACH search term, find exactly 1 highest-ranking store
    SELECT
        m.id,
        m.rank
    FROM search_inputs i
    CROSS JOIN LATERAL (
        SELECT
            s.id,
            CASE
                WHEN i.id_input IS NOT NULL THEN 2.0
                ELSE ts_rank(s.metadata_tsv, i.query_ts)
            END as rank
        FROM stores s
        WHERE s.metadata->'header_image' IS NOT NULL
          AND (
            (i.id_input IS NOT NULL AND s.id = i.id_input)
            OR (i.id_input IS NULL AND s.metadata_tsv @@ i.query_ts)
          )
        ORDER BY rank DESC
        LIMIT 1
    ) m
),
unique_best_matches AS (
    -- 3. If two different search terms result in the same best-match store,
    -- we group by ID to prevent returning duplicate rows in the final result.
    SELECT
        id,
        MAX(rank) as rank
    FROM best_matches
    GROUP BY id
)
SELECT
    s.id,
    s.name,
    s.code_name,
    s.metadata->'publishers' as publishers,
    s.metadata->'support_info' as support_info,
    s.metadata->>'short_description' as short_description,
    s.metadata->>'detailed_description' as detailed_description,
    s.metadata->>'header_image' as header_image,
    s.metadata->'pc_requirements' as pc_requirements,
    s.metadata->'screenshots' as screenshots,
    to_jsonb(s.genres) as genres,
    s.type,
    s.queue,
    s.benchmarks,
    s.metadata_locale,
    m.rank
FROM unique_best_matches m
JOIN stores s ON s.id = m.id
ORDER BY m.rank DESC;

$_$;


ALTER FUNCTION "public"."search_stores"("texts" "text"[]) OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."search_stores"("text" "text") RETURNS TABLE("id" bigint, "name" "text", "code_name" "text", "publishers" "jsonb", "support_info" "jsonb", "short_description" "text", "detailed_description" "text", "header_image" "text", "pc_requirements" "jsonb", "screenshots" "jsonb", "genres" "jsonb", "type" "text", "queue" bigint, "benchmarks" "jsonb", "metadata_locale" "jsonb", "rank" double precision)
    LANGUAGE "sql"
    AS $_$

WITH search_inputs AS (
    SELECT
        CASE
            WHEN search_stores.text ~ '^[0-9]+$' THEN NULL
            ELSE to_tsquery('english', search_stores.text)
        END AS query_ts,
        CASE
            WHEN search_stores.text ~ '^[0-9]+$' THEN search_stores.text::bigint
            ELSE NULL
        END AS id_input
)
SELECT
    s.id,
    s.name,
    s.code_name,
    s.metadata->'publishers' as publishers,
    s.metadata->'support_info' as support_info,
    s.metadata->>'short_description' as short_description,
    s.metadata->>'detailed_description' as detailed_description,
    s.metadata->>'header_image' as header_image,
    s.metadata->'pc_requirements' as pc_requirements,
    s.metadata->'screenshots' as screenshots,
    to_jsonb(s.genres),
    s.type,
    s.queue,
    s.benchmarks,
    s.metadata_locale,
    CASE
        WHEN i.id_input IS NOT NULL THEN 2.0
        ELSE ts_rank(s.metadata_tsv, i.query_ts)
    END as rank
FROM stores s
CROSS JOIN search_inputs i
WHERE s.metadata->'header_image' is not null
  AND (
    (i.id_input IS NOT NULL AND s.id = i.id_input)
    OR (i.id_input IS NULL AND s.metadata_tsv @@ i.query_ts)
  )

ORDER BY rank DESC;
$_$;


ALTER FUNCTION "public"."search_stores"("text" "text") OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."sign_payermax_rsa_sha256"("content" "text") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$DECLARE
  req_body jsonb;
  api_result record;
  resp_json jsonb;
  signature text;
  private_key text;
  parsed_content jsonb;
BEGIN


  BEGIN
    parsed_content := content::jsonb;
  EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Invalid JSON content: %', SQLERRM;
  END;

  IF NOT (
    parsed_content ? 'version' AND
    parsed_content ? 'keyVersion' AND
    parsed_content ? 'requestTime' AND
    parsed_content ? 'appId' AND
    parsed_content ? 'merchantNo' AND
    parsed_content ? 'data'
  ) THEN
    RAISE EXCEPTION 'Content missing required PayerMax fields';
  END IF;

  IF jsonb_typeof(parsed_content->'data') != 'object' THEN
    RAISE EXCEPTION 'data field must be JSON object';
  END IF;

  IF (parsed_content->>'data')::text ~ '[<>]' OR
     (parsed_content->>'data')::text ~ 'script' OR
     (parsed_content->>'data')::text ~ 'javascript' THEN
    RAISE EXCEPTION 'Potentially malicious content detected';
  END IF;



  select value->>'private_key'
  into private_key
  from constant
  where constant.name = 'payermax';

  -- 2. Prepare JSON Payload
  req_body := jsonb_build_object(
    'content', content,
    'private_key', private_key
  );

  -- 3. Call the Go API using try_post
  -- try_post handles timeouts and returns (success boolean, content text)
  SELECT * INTO api_result
  FROM try_post(
    'http://rsa:8080/sign-rsa',
    ARRAY[extensions.http_header('Content-Type', 'application/json')],
    req_body
  );

  -- 4. Validate Request Success (Network level + HTTP Status 200/204)
  IF api_result.success IS FALSE THEN
    RAISE EXCEPTION 'RSA Signer service failed: %', api_result.content;
  END IF;

  -- 5. Parse Response
  BEGIN
    resp_json := api_result.content::jsonb;
  EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'RSA Signer returned invalid JSON: %', api_result.content;
  END;

  -- 6. Check for Application level errors ({"error": "..."})
  IF resp_json->>'error' IS NOT NULL THEN
    RAISE EXCEPTION 'RSA Signer API error: %', resp_json->>'error';
  END IF;

  -- 7. Extract Signature
  signature := resp_json->>'signature';

  IF signature IS NULL THEN
    RAISE EXCEPTION 'RSA Signer service response missing signature: %', api_result.content;
  END IF;

  RETURN signature;
END;$$;


ALTER FUNCTION "public"."sign_payermax_rsa_sha256"("content" "text") OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."snapshoot_app_access_v1"() RETURNS "void"
    LANGUAGE "sql"
    AS $$insert into app_access_snapshoot (usage,email)
  select
    usages.usage,
    usages.email
  from clusters
  inner join get_app_access_usage(clusters.id) as usages
  on usages.email is not null
  where clusters.active
  and not clusters.secret->>'url' is null
  and not clusters.id = 4$$;


ALTER FUNCTION "public"."snapshoot_app_access_v1"() OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."snapshoot_buckets_v1"() RETURNS "void"
    LANGUAGE "sql"
    AS $$insert into bucket_snapshoot (name,size_in_mb,email)
  select
    sizes.name::uuid,
    sizes.size_in_mb,
    sizes.email
  from clusters
  inner join get_buckets_size(clusters.id) as sizes
  on sizes.email is not null
  where clusters.active
  and not clusters.secret->>'url' is null
  and not clusters.id = 4$$;


ALTER FUNCTION "public"."snapshoot_buckets_v1"() OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."snapshoot_llm_usage_v1"() RETURNS "void"
    LANGUAGE "sql"
    AS $$insert into llm_usage_snapshoot (usage, email)
  select
    usages.usage,
    usages.email
  from clusters
  inner join get_llm_usage(clusters.id) as usages
  on usages.email is not null
  where clusters.active
  and not clusters.secret->>'url' is null
  and not clusters.id = 4$$;


ALTER FUNCTION "public"."snapshoot_llm_usage_v1"() OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."snapshoot_v6"() RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$begin
insert into
  vm_snapshoot_v4 (email, session_id, volume_id, node)
select
  user_v2.email as email,
  volume_data.session_id,
  volume_data.volume_id::uuid as volume_id,
  volume_data.node as node
from
  extensions.http (
    (
      'GET',
      'http://globalproxy:50050/all',
      null,
      null,
      null
    )::extensions.http_request
  ) as all_nodes
  cross join lateral jsonb_array_elements(all_nodes.content::jsonb) as node_elem
  inner join lateral extensions.http (
    (
      'GET',
      'http://globalproxy:50050/query',
      array[
        extensions.http_header ('type', 'info'),
        extensions.http_header ('node', node_elem ->> 0)
      ],
      null,
      null
    )
  ) as all_nodes_content on true
  inner join jsonb_array_elements(all_nodes_content.content::jsonb -> 'Sessions') as sessions on true
  cross join lateral (
    select
      (volume ->> 'name')::uuid as volume_id,
      (sessions ->> 'id')::uuid as session_id,
      sessions -> 'vm' -> 'GPUs' -> 0 ->> 'id' as gpuid,
      sessions -> 'vm' -> 'GPUs' -> 0 ->> 'node' as node
      -- sessions -> 'vm' -> 'Sessions' -> 0 -> 'thinkmay' -> 'listener' as listener
    from
      jsonb_array_elements(sessions -> 'vm' -> 'Volumes') as volume
    where
      volume ->> 'name' is not null
      and volume ->> 'name' != 'app'
    union all
    -- Fallback method: get volume ID from Ndisks structure
    select
      (
        sessions -> 'vm' -> 'Ndisks' -> 0 -> 'volume' ->> 'name'
      )::uuid as volume_id,
      (sessions ->> 'id')::uuid as session_id,
      sessions -> 'vm' -> 'GPUs' -> 0 ->> 'id' as gpuid,
      sessions -> 'vm' -> 'GPUs' -> 0 ->> 'node' as node
      -- sessions -> 'vm' -> 'Sessions' -> 0 -> 'thinkmay' -> 'listener' as listener
    where
      not exists (
        select
          1
        from
          jsonb_array_elements(sessions -> 'vm' -> 'Volumes') as volume
        where
          volume ->> 'name' is not null
          and volume ->> 'name' != 'app'
      )
      and sessions -> 'vm' -> 'Ndisks' -> 0 -> 'volume' ->> 'name' is not null
      and sessions -> 'vm' -> 'GPUs' -> 0 ->> 'node' is not null
  ) as volume_data
  inner join user_v2 on user_v2.volume_id = volume_data.volume_id
group by
  volume_data.session_id,
  user_v2.email,
  volume_data.volume_id,
  volume_data.node,
  volume_data.gpuid;

end;$$;


ALTER FUNCTION "public"."snapshoot_v6"() OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."snapshoot_volume_v1"() RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$begin
PERFORM pg_advisory_xact_lock(3677);
insert into volume_snapshoot(name,email,size_in_gb)
select
  (volumes->>'name')::uuid as name,
  user_v2.email,
  avg((volumes->>'size')::bigint / 1024 / 1024 / 1024)::bigint as size_in_gb
from
  extensions.http (
    (
      'GET',
      'http://globalproxy:50050/all',
      null,
      null,
      null
    )::extensions.http_request
  ) as all_nodes
  cross join lateral jsonb_array_elements(all_nodes.content::jsonb) as node_elem
  inner join lateral extensions.http (
    (
      'GET',
      'http://globalproxy:50050/query',
      array[
        extensions.http_header ('type', 'info'),
        extensions.http_header ('node', node_elem ->> 0)
      ],
      null,
      null
    )
  ) as all_nodes_content on true
  cross join jsonb_array_elements(all_nodes_content.content::jsonb -> 'Volumes') as volumes
  inner join user_v2 on user_v2.volume_id::text = volumes->>'name'
  group by name, email;
end;$$;


ALTER FUNCTION "public"."snapshoot_volume_v1"() OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."subscribe_addon"("subscription_id" bigint, "addon_id" bigint) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$declare
    exist bigint;
  begin
    select count(*) as total
    into exist
    from addon_subscriptions
    where addon_subscriptions.subscription = subscribe_addon.subscription_id
    and addon_subscriptions.cancelled_at is null
    and addon_subscriptions.addon = subscribe_addon.addon_id;

    if (exist > 0) then
      return;
    end if;

    insert into addon_subscriptions(subscription,addon)
    values (
      subscribe_addon.subscription_id,
      subscribe_addon.addon_id
    );
  end;$$;


ALTER FUNCTION "public"."subscribe_addon"("subscription_id" bigint, "addon_id" bigint) OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."subscribe_addon"("email" "text", "addon_id" bigint) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
  declare
    subscription_id bigint;
  begin
    select subscriptions.id
    from subscriptions into subscription_id
    where allocated_at is not null
    and cleaned_at is null
    and subscriptions.user = subscribe_addon.email;

  if (subscription_id is null) then
    raise exception 'email do not have any subscription';
  end if;

  perform subscribe_addon(subscription_id, addon_id);
  end;
$$;


ALTER FUNCTION "public"."subscribe_addon"("email" "text", "addon_id" bigint) OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."sync_volume_data_v1"("email" "text", "volume_id" "text", "cluster_domain" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
  v_cluster_id bigint;
  v_cluster_domain text;
  v_existing_user record;
begin


  select id into v_cluster_id
  from clusters
  where domain = sync_volume_data_v1.cluster_domain;

  if v_cluster_id is null then
    v_cluster_id := 6;
  end if;

  select * into v_existing_user
  from user_v2
  where user_v2.volume_id = sync_volume_data_v1.volume_id::uuid
  and user_v2.email = sync_volume_data_v1.email
  and user_v2.cluster_id = v_cluster_id
  limit 1;

  if found then

  else
    insert into user_v2 (email, volume_id, cluster_id)
    values (sync_volume_data_v1.email, sync_volume_data_v1.volume_id::uuid, v_cluster_id);
  end if;

end;
$$;


ALTER FUNCTION "public"."sync_volume_data_v1"("email" "text", "volume_id" "text", "cluster_domain" "text") OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."try_delete"("url" "text", "header" "extensions"."http_header"[]) RETURNS TABLE("success" boolean, "content" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
    perform extensions.http_set_curlopt ('CURLOPT_TIMEOUT', '600');
    perform extensions.http_set_curlopt ('CURLOPT_CONNECTTIMEOUT', '600');

    return query
    select
    request.status = any(array[200,204]) as success,
    request.content::text as content
    from
    extensions.http((
      'DELETE',
      url,
      header, NULL,NULL
    )::extensions.http_request) as request;

    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT
            FALSE AS success,
            'unable to call to destination'::text AS content;
end;
$$;


ALTER FUNCTION "public"."try_delete"("url" "text", "header" "extensions"."http_header"[]) OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."try_get"("url" "text") RETURNS TABLE("content" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
   IF current_setting('request.jwt.claims', true)::json->>'role' != 'service_role' THEN
    RAISE EXCEPTION 'Access denied';
  END IF;


  return query select result.content::text from extensions.http_get(url) as result;
  EXCEPTION
      WHEN OTHERS THEN
          RETURN QUERY SELECT NULL::text WHERE FALSE;
 end;$$;


ALTER FUNCTION "public"."try_get"("url" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."try_get"("url" "text", "header" "extensions"."http_header"[]) RETURNS TABLE("success" boolean, "content" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin

  IF current_setting('request.jwt.claims', true)::json->>'role' != 'service_role' THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

    perform extensions.http_set_curlopt ('CURLOPT_TIMEOUT', '600');
    perform extensions.http_set_curlopt ('CURLOPT_CONNECTTIMEOUT', '600');

    return query
    select
    request.status = any(array[200,204]) as success,
    request.content::text as content
    from
    extensions.http((
      'GET',
      url,
      header, NULL,NULL
    )::extensions.http_request) as request;

    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT
            FALSE AS success,
            'unable to call to destination'::text AS content;
end;$$;


ALTER FUNCTION "public"."try_get"("url" "text", "header" "extensions"."http_header"[]) OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."try_get"("url" "text", "basic_header" "text") RETURNS TABLE("content" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin

   IF current_setting('request.jwt.claims', true)::json->>'role' != 'service_role' THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  perform extensions.http_set_curlopt ('CURLOPT_TIMEOUT', '600');
  perform extensions.http_set_curlopt ('CURLOPT_CONNECTTIMEOUT', '600');

  return query
  select result.content::text
  from extensions.http (
    (
      'GET',
      try_get.url,
      ARRAY[
        extensions.http_header (
          'Authorization',
          'Basic ' || try_get.basic_header
        )
      ],
      NULL,
      NULL
    )::extensions.http_request
  ) as result;

  EXCEPTION
      WHEN OTHERS THEN
          RETURN QUERY SELECT NULL::text WHERE FALSE;
 end;$$;


ALTER FUNCTION "public"."try_get"("url" "text", "basic_header" "text") OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."try_patch"("url" "text", "header" "extensions"."http_header"[], "body" "jsonb") RETURNS TABLE("success" boolean, "content" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
      IF current_setting('request.jwt.claims', true)::json->>'role' != 'service_role' THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

    perform extensions.http_set_curlopt ('CURLOPT_TIMEOUT', '600');
    perform extensions.http_set_curlopt ('CURLOPT_CONNECTTIMEOUT', '600');

    RETURN QUERY
    SELECT
        request.status = ANY(ARRAY[200, 204]) AS success,
        request.content::text AS content
    FROM
        extensions.http((
            'PATCH',
            url,
            header,
            'application/json',
            body
        )::extensions.http_request) AS request;

    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT
            FALSE AS success,
            'unable to call to destination'::text AS content;
end;$$;


ALTER FUNCTION "public"."try_patch"("url" "text", "header" "extensions"."http_header"[], "body" "jsonb") OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."try_post"("url" "text", "header" "extensions"."http_header"[], "body" "jsonb") RETURNS TABLE("success" boolean, "content" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $_$DECLARE
    allowed_prefixes text[] := ARRAY[
        'http://rsa:8080/',
        'https://api-merchant.payos.vn/',
        'https://api.stripe.com/',
        'https://api.payermax.com/',
        'http://globalproxy:50050/',
        'https://saigon2.thinkmay.net/',
        'https://haiphong.thinkmay.net/',
        'https://pay-gate.payermax.com/aggregate-pay/api/gateway'
    ];
    is_allowed boolean := false;
    prefix text;
    url_lower text;
BEGIN

    -- Normalize URL
    url_lower := lower(trim(url));

    IF url_lower !~ '^https?://[a-z0-9][a-z0-9.-]*(:[0-9]+)?(/|$)' THEN
        RAISE EXCEPTION 'Invalid URL format';
    END IF;

    -- Block non-standard ports (excluded http://rsa:8080 and http://globalproxy:50050)
    IF url_lower ~ '^https?://[^/]+:[0-9]+' AND
       url_lower !~ '^http://(rsa:8080|globalproxy:50050)/' THEN
        RAISE EXCEPTION 'Non-standard ports not allowed';
    END IF;

    -- Check URL whitelist
    FOREACH prefix IN ARRAY allowed_prefixes LOOP
        IF url_lower LIKE lower(prefix) || '%' THEN
            is_allowed := true;
            EXIT;
        END IF;
    END LOOP;


    IF NOT is_allowed THEN
        RAISE EXCEPTION 'URL not allowed';
    END IF;

    -- Set timeouts (chỉ những option supported)
    perform extensions.http_set_curlopt ('CURLOPT_TIMEOUT', '30');
    perform extensions.http_set_curlopt ('CURLOPT_CONNECTTIMEOUT', '10');

    return query
    select
        request.status = any(array[200,204]) as success,
        request.content::text as content
    from extensions.http((
        'POST',
        url,
        header,
        'application/json',
        body
    )::extensions.http_request) as request;

    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT
            FALSE AS success,
            SQLERRM AS content;
END;$_$;


ALTER FUNCTION "public"."try_post"("url" "text", "header" "extensions"."http_header"[], "body" "jsonb") OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."try_post"("url" "text", "basic_header" "text", "body" "jsonb") RETURNS TABLE("success" boolean, "content" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
   IF current_setting('request.jwt.claims', true)::json->>'role' != 'service_role' THEN
    RAISE EXCEPTION 'Access denied';
  END IF;


  return query
  select result.content::text
  from extensions.http (
    (
      'POST',
      try_post.url,
      ARRAY[
        extensions.http_header (
          'Authorization',
          'Basic ' || try_post.basic_header
        )
      ],
      NULL,
      try_post.body
    )::extensions.http_request
  ) as result;

  EXCEPTION WHEN OTHERS THEN
      RETURN QUERY SELECT
          FALSE AS success,
          'unable to call to destination'::text AS content;
 end;$$;


ALTER FUNCTION "public"."try_post"("url" "text", "basic_header" "text", "body" "jsonb") OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."unmap_app_access"("email" "text", "cluster" bigint) RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$declare
    user_id text;
    admintoken text;
    domain text;
    url text;

    _id text;
  begin
    select token,get_cluster_secrets.url,get_cluster_secrets.domain
    into admintoken, url,domain
    FROM get_cluster_secrets(unmap_app_access.cluster);

    select generate_account_v3 into user_id
    from generate_account_v3(unmap_app_access.email, domain);


    with delete_list as (
      select
        item->>'id' as id
      FROM extensions.http(('GET',
        url || '/api/collections/app_access/records?filter=(user="' || user_id || '")',
        ARRAY[extensions.http_header('Authorization',concat('Bearer ' ,admintoken))],
        NULL, NULL
      )::extensions.http_request) as request
      inner join jsonb_array_elements((request.content::jsonb)->'items') as item on true
    )
    select id into _id from delete_list,
    LATERAL  extensions.http(('DELETE',
      url || '/api/collections/app_access/records/' || delete_list.id,
      ARRAY[extensions.http_header('Authorization',concat('Bearer ' ,admintoken))],
      NULL,  NULL
    )::extensions.http_request);
  end;$$;


ALTER FUNCTION "public"."unmap_app_access"("email" "text", "cluster" bigint) OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."unmap_bucket_access"("email" "text", "cluster" bigint) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$declare
   user_id text;
   admintoken text;
   domain text;
   url text;

   _id text;
begin
    select token,get_cluster_secrets.url,get_cluster_secrets.domain
    into admintoken, url,domain
    FROM get_cluster_secrets(unmap_bucket_access.cluster);

    select generate_account_v3 into user_id
    from generate_account_v3(unmap_bucket_access.email, domain);

    perform extensions.http_set_curlopt ('CURLOPT_TIMEOUT', '120');
    perform extensions.http_set_curlopt ('CURLOPT_CONNECTTIMEOUT', '120');

    if length(user_id) < 10 then
      raise exception 'invalid user id %s',user_id;
    end if;

    with delete_list as (
      select
        item->>'id' as id
      FROM extensions.http(('GET',
        url || '/api/collections/buckets/records?filter=(user~"' || user_id || '")',
        ARRAY[extensions.http_header('Authorization',concat('Bearer ' ,admintoken))],
        NULL, NULL
      )::extensions.http_request) as request
      inner join jsonb_array_elements((request.content::jsonb)->'items') as item on true
    )
    select id into _id from delete_list,
    LATERAL  extensions.http(('DELETE',
      url || '/api/collections/buckets/records/' || delete_list.id,
      ARRAY[extensions.http_header('Authorization',concat('Bearer ' ,admintoken))],
      NULL,  NULL
    )::extensions.http_request);
  end;$$;


ALTER FUNCTION "public"."unmap_bucket_access"("email" "text", "cluster" bigint) OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."unmap_llm_access"("email" "text", "cluster" bigint) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
    user_id text;
    admintoken text;
    domain text;
    url text;
    _id text;
begin
    select token, get_cluster_secrets.url, get_cluster_secrets.domain
    into admintoken, url, domain
    FROM get_cluster_secrets(unmap_llm_access.cluster);

    select generate_account_v3 into user_id
    from generate_account_v3(unmap_llm_access.email, domain);

    with delete_list as (
      select item->>'id' as id
      FROM extensions.http(('GET',
        url || '/api/collections/llmModels/records?filter=(user="' || user_id || '")',
        ARRAY[extensions.http_header('Authorization', 'Bearer ' || admintoken)],
        NULL, NULL
      )::extensions.http_request) as request
      inner join jsonb_array_elements((request.content::jsonb)->'items') as item on true
    )
    select id into _id from delete_list,
    LATERAL extensions.http(('DELETE',
      url || '/api/collections/llmModels/records/' || delete_list.id,
      ARRAY[extensions.http_header('Authorization', 'Bearer ' || admintoken)],
      NULL, NULL
    )::extensions.http_request);
end;$$;


ALTER FUNCTION "public"."unmap_llm_access"("email" "text", "cluster" bigint) OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."unmap_user_email_v2"("job_id" bigint) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$

  declare
    email text;
    cluster_id bigint;

    admintoken text;
    url text;
    domain text;
    user_id text;

    delete_id text;
  begin
    select
      job.arguments->>'email' as email,
      clusters.id as cluster_id
    into email, cluster_id
    from job
    inner join clusters on job.cluster = clusters.id
    where job.id = unmap_user_email_v2.job_id;


    select token,get_cluster_secrets.url,get_cluster_secrets.domain
    into admintoken, url, domain
    FROM get_cluster_secrets(cluster_id);

    select generate_account_v3 into user_id
    from generate_account_v3(email, domain);

    if length(user_id) < 10 then
      UPDATE job
      SET success = false,
          result = jsonb_build_object('error','invalid user id')
      WHERE job.id = unmap_user_email_v2.job_id;
      RETURN;
    end if;

    select
      item->>'id' as delete_id
    into delete_id
    FROM try_get(
      url || '/api/collections/volumes/records?filter=(user~"' || user_id || '")',
      ARRAY[extensions.http_header('Authorization',concat('Bearer ' ,admintoken))]
    ) as request
    cross join jsonb_array_elements((request.content::jsonb)->'items') as item;

    if (delete_id is null) then
      UPDATE job
      SET success = false,
          result = jsonb_build_object('error','Volume not found')
      WHERE job.id = unmap_user_email_v2.job_id;
      return;
    end if;

    update job
    set
      success = request.success,
      result = request.content::jsonb
    from try_delete(
      url || '/api/collections/volumes/records/' || delete_id,
      ARRAY[extensions.http_header('Authorization',concat('Bearer ' ,admintoken))]
    ) as request
    where job.id = unmap_user_email_v2.job_id;

    return;
    exception when others then
      UPDATE job
      SET success = false,
          result = jsonb_build_object('error', SQLERRM, 'state', SQLSTATE)
      WHERE job.id = unmap_user_email_v2.job_id;
      return;
  end;
$$;


ALTER FUNCTION "public"."unmap_user_email_v2"("job_id" bigint) OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."unsubscribe_addon"("subscription_id" bigint, "addon_id" bigint) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
  declare
    addon_subid bigint;
    inuse boolean;
  begin
    select addon_subscriptions.id,addon_subscriptions.unit_count > 0 as inuse
    into addon_subid, inuse
    from addon_subscriptions
    where addon_subscriptions.subscription = unsubscribe_addon.subscription_id
    and addon_subscriptions.cancelled_at is null
    and addon_subscriptions.addon = unsubscribe_addon.addon_id;

    if (addon_subid is null) then
      return;
    end if;

    if (inuse) then
      RAISE EXCEPTION 'addon subscription is unpaid';
    end if;

    update addon_subscriptions
    set cancelled_at = now()
    where addon_subscriptions.id = addon_subid;
  end;
$$;


ALTER FUNCTION "public"."unsubscribe_addon"("subscription_id" bigint, "addon_id" bigint) OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."unsubscribe_addon"("email" "text", "addon_id" bigint) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
  declare
    subscription_id bigint;
  begin
    select subscriptions.id
    from subscriptions into subscription_id
    where allocated_at is not null
    and cleaned_at is null
    and subscriptions.user = unsubscribe_addon.email;

  if (subscription_id is null) then
    raise exception 'email do not have any subscription';
  end if;

  perform unsubscribe_addon(subscription_id, addon_id);
  end;
$$;


ALTER FUNCTION "public"."unsubscribe_addon"("email" "text", "addon_id" bigint) OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."update_app_access_usage"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$begin
  update addon_subscriptions
  set unit_count = GREATEST(addon_subscriptions.unit_count,NEW.usage)
  from
  (
    select addon_subscriptions.id
    from subscriptions
    inner join addon_subscriptions
    on addon_subscriptions.subscription = subscriptions.id
    and addon_subscriptions.cancelled_at is null

    inner join addons
    on addons.id = addon_subscriptions.addon
    and addons.name = 'app_access'

    where subscriptions.user = NEW.email
    and subscriptions.cleaned_at is null
    and subscriptions.allocated_at is not null

    order by subscriptions.created_at desc
  ) as subquery
  where subquery.id = addon_subscriptions.id;

  return NEW;
end;$$;


ALTER FUNCTION "public"."update_app_access_usage"() OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."update_bucket_usage"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$begin
  update addon_subscriptions
  set unit_count = coalesce(addon_subscriptions.unit_count,0) + NEW.size_in_mb
  from
  (select addon_subscriptions.id
  from subscriptions
  inner join addon_subscriptions
  on addon_subscriptions.subscription = subscriptions.id
  and addon_subscriptions.cancelled_at is null
  inner join addons
  on addons.id = addon_subscriptions.addon
  and addons.name = 'buckets'
  where subscriptions.user = NEW.email
  and subscriptions.cleaned_at is null
  and subscriptions.allocated_at is not null
  order by subscriptions.created_at desc
  ) as subquery
  where subquery.id = addon_subscriptions.id;

  return NEW;
end;$$;


ALTER FUNCTION "public"."update_bucket_usage"() OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."update_llm_usage"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  update addon_subscriptions
  set unit_count = GREATEST(addon_subscriptions.unit_count, NEW.usage)
  from
  (
    select addon_subscriptions.id
    from subscriptions
    inner join addon_subscriptions
    on addon_subscriptions.subscription = subscriptions.id
    and addon_subscriptions.cancelled_at is null

    inner join addons
    on addons.id = addon_subscriptions.addon
    and addons.name = 'llm'

    where subscriptions.user = NEW.email
    and subscriptions.cleaned_at is null
    and subscriptions.allocated_at is not null

    order by subscriptions.created_at desc
  ) as subquery
  where subquery.id = addon_subscriptions.id;

  return NEW;
end;$$;


ALTER FUNCTION "public"."update_llm_usage"() OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."update_pocket_remainder"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$declare
    email text;
    signature text;
    prehash text;

    result jsonb;
    code bigint;

    transaction int8;
  begin

    if ((OLD.verified_at is null and NEW.verified_at is not null) and (OLD.amount = NEW.amount)) then
      update pockets
      set amount = subquery.amount
      from (
        select
          pockets.id as id,
          pockets.amount + pocket_deposits.amount as amount
        from pocket_deposits
        inner join pockets on pockets.id = pocket_deposits.pocket
        where pocket_deposits.id = NEW.id
      ) as subquery
      where subquery.id = pockets.id;
    end if;

    return NEW;
  end;$$;


ALTER FUNCTION "public"."update_pocket_remainder"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_request_payment"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$declare
    email text;
    subscription_id bigint;
    subscription_allocated timestamp with time zone;
    subscription_ended timestamp with time zone;
    total_days bigint;

    subscription_cluster bigint;
    desired_cluster bigint;

    plan_configuration jsonb;
    plan_id bigint;
    previous_plan_id bigint;
    previous_transient text;

    expense bigint;
    after_pay_amount bigint;
  begin
    select
      subscriptions.id as id,
      subscriptions.user as email,
      subscriptions.cluster as cluster,
      subscriptions.allocated_at as allocated_at,
      subscriptions.ended_at as ended_at,
      (select plans.id
       from payment_request
       inner join plans on plans.id = payment_request.plan
       where payment_request.verified_at is not null
       and payment_request.subscription = subscriptions.id
       order by payment_request.created_at desc
       limit 1) as previous_plan_id,
      (select plans.configuration->>'transient'
       from payment_request
       inner join plans on plans.id = payment_request.plan
       where payment_request.verified_at is not null
       and payment_request.subscription = subscriptions.id
       order by payment_request.created_at desc
       limit 1) as previous_transient
    into
      subscription_id,
      email,
      subscription_cluster,
      subscription_allocated,
      subscription_ended,
      previous_plan_id,
      previous_transient
    from subscriptions
    where subscriptions.id = NEW.subscription;

    select plans.id, plans.total_days, plans.only_cluster, plans.configuration
    into  plan_id, total_days, desired_cluster, plan_configuration
    from  plans
    where plans.id = NEW.plan;

    if (email is null) then
      return OLD;
    end if;

    if ((OLD.verified_at is null and NEW.verified_at is not null and OLD.pocket is not null)) then
      select plans.credit
      into expense
      from plans
      where plans.id = OLD.plan;

      select (cast(pockets.amount as bigint) - expense)
      into after_pay_amount
      from pockets
      where pockets.id = OLD.pocket;

      if after_pay_amount < 0 or after_pay_amount is null then
        return OLD;
      end if;

      update pockets
      set amount = after_pay_amount
      where pockets.id = OLD.pocket;
    end if;

    if (NEW.verified_at is not null and OLD.verified_at is null) then
      if (subscription_allocated is not null) then
       update subscriptions
       set ended_at =
          (case when total_days is not null
          then coalesce(subscription_ended,now()) + total_days * INTERVAL '1 day'
          else NULL
          end),
       total_usage = 0,
       total_data_credit = 0,
       cluster = coalesce(desired_cluster, subscription_cluster)
       where id = subscription_id;

       if (desired_cluster != subscription_cluster and desired_cluster is not null)
       or previous_transient = 'true'
       then
        insert into job(command, arguments, cluster)
        values('delete volume v5',
          jsonb_build_object('email', email),
          subscription_cluster);

        insert into job(command, arguments,cluster)
        values('create volume v7',
          jsonb_build_object(
            'id', gen_random_uuid()::text,
            'email', email,
            'template', 'win11.template'
          ) || COALESCE(plan_configuration, '{}'::jsonb)
          ,desired_cluster);
       elsif previous_plan_id != plan_id then
        insert into job(command, arguments,cluster)
        values('update volume v7',
          jsonb_build_object(
            'email', email
          ) || COALESCE(plan_configuration, '{}'::jsonb)
          , subscription_cluster);
       end if;

      else
        update subscriptions
        set allocated_at = now(),
        total_usage = 0,
        total_data_credit = 0
        where id = subscription_id;
      end if;
    end if;

    return NEW;
  end;$$;


ALTER FUNCTION "public"."update_request_payment"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_subscription_data_usage"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  UPDATE subscriptions
  SET
    total_data_credit = COALESCE(subscriptions.total_data_credit, 0) + NEW.size_in_gb
  WHERE
    id = (
      SELECT sub.id
      FROM subscriptions AS sub
      WHERE sub.user = NEW.email
        AND sub.cleaned_at IS NULL
        AND sub.allocated_at is not null
      ORDER BY
        sub.created_at DESC
      LIMIT 1
  );

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_subscription_data_usage"() OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."update_subscription_usage"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  UPDATE subscriptions
  SET total_usage = COALESCE(total_usage, 0) + 5
  WHERE id = (
    SELECT sub.id
    FROM subscriptions AS sub
    WHERE sub.user = NEW.email
      AND sub.cleaned_at IS NULL
      AND sub.allocated_at IS NOT NULL
    ORDER BY sub.created_at DESC
    LIMIT 1
  );

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_subscription_usage"() OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."update_volume_v7"("job_id" bigint) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$declare
    email       text;
    cluster_id  bigint;

    admintoken text;
    url text;
    domain text;
    user_id text;

    update_id         text;
    arg_configuration jsonb;
    old_configuration jsonb;
begin
    select
      job.arguments->>'email' as email,
      job.arguments::jsonb as arg,
      clusters.id
    into email, arg_configuration, cluster_id
    from job
    inner join clusters on clusters.id = job.cluster
    where job.id = update_volume_v7.job_id;

    select token,get_cluster_secrets.url,get_cluster_secrets.domain
    into admintoken, url, domain
    FROM get_cluster_secrets(cluster_id);

    select generate_account_v3 into user_id
    from generate_account_v3(email, domain);

    select
      item->>'id' as update_id,
      item->'configuration' as old_configuration
    into update_id, old_configuration
    FROM try_get(
      url || '/api/collections/volumes/records?filter=(user~"' || user_id || '")',
      ARRAY[extensions.http_header('Authorization',concat('Bearer ' ,admintoken))]
    ) as request
    cross join jsonb_array_elements((request.content::jsonb)->'items') as item;

    if (update_id is null) then
      UPDATE job
      SET success = false,
          result = jsonb_build_object('error','Volume not found')
      WHERE job.id = update_volume_v7.job_id;
      RETURN;
    end if;

    update job
    set
      success = request.success,
      result = request.content::jsonb
    from try_patch(
      url || '/api/collections/volumes/records/' || update_id,
      ARRAY[extensions.http_header('Authorization',concat('Bearer ' ,admintoken))],
      jsonb_build_object('configuration', arg_configuration || jsonb_build_object(
        'email', old_configuration->>'email',
        'template', old_configuration->>'template',
        'disk', old_configuration->'disk'
      ))
    ) as request
    where job.id = update_volume_v7.job_id;

    return;
    exception when others then
      UPDATE job
      SET success = false,
          result = jsonb_build_object('error', SQLERRM, 'state', SQLSTATE)
      WHERE job.id = update_volume_v7.job_id;
      RETURN;
    end;
  $$;


ALTER FUNCTION "public"."update_volume_v7"("job_id" bigint) OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."urlencode"("text_to_encode" "text") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE
    AS $$
SELECT string_agg(
    CASE
        WHEN char ~ '[a-zA-Z0-9_.~-]' THEN char -- Keep safe characters
        ELSE '%' || upper(encode(char::bytea, 'hex')) -- Encode others to %XX
    END,
    ''
)
FROM regexp_split_to_table(text_to_encode, '') AS char;
$$;


ALTER FUNCTION "public"."urlencode"("text_to_encode" "text") OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."validate_discount_code"("discount_code" "text", "apply_for_type" "text", "user_email" "text") RETURNS TABLE("discount_id" bigint, "multiply_rate" real, "code" "text", "apply_for" "text"[])
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
  d discounts%rowtype;
  used bigint;
begin
  select * into d from discounts

  where discounts.code = discount_code and start_at < now() and end_at > now()
    and apply_for_type = any(discounts.apply_for);

  if not found then return; end if;


  if d.discount_limit_per_user is not null then
    select count(*) into used from pocket_deposits pd
    join pockets p on p.id = pd.pocket
    where pd.discount = d.id and p.user = user_email;
    if used >= d.discount_limit_per_user then return; end if;
  end if;

  -- check total limit
  if d.discount_limit is not null then
    select count(*) into used from pocket_deposits where discount = d.id;
    if used >= d.discount_limit then return; end if;
  end if;

  return query select d.id, d.multiply_rate, d.code, d.apply_for;
end;
$$;


ALTER FUNCTION "public"."validate_discount_code"("discount_code" "text", "apply_for_type" "text", "user_email" "text") OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."validate_subscription_usage_v1"() RETURNS "void"
    LANGUAGE "sql"
    AS $$
update subscriptions
set
  ended_at = now()
from
  (
    select
      subscriptions.id,
      subscriptions.user,
      subscriptions.total_usage / 60 as usage,
      active_plan.total_hours
    from
      subscriptions
    inner join plans as active_plan on active_plan.active
    where
      subscriptions.allocated_at is not null
      and subscriptions.cleaned_at is null
      and (subscriptions.ended_at is null or subscriptions.ended_at > now())
      and (
        select
          plans.id
        from
          payment_request
          inner join plans on plans.id = payment_request.plan
        where
          payment_request.subscription = subscriptions.id
          and payment_request.verified_at is not null
        order by
          payment_request.created_at desc
        limit
          1
      ) = active_plan.id
      and subscriptions.total_usage > (
        coalesce(subscriptions.usage_limit, active_plan.total_hours) + coalesce(public.get_rank_bonus_hours(subscriptions.user), 0)
      ) * 60
    order by
      subscriptions.total_usage desc
  ) as subquery
where subscriptions.id = subquery.id
$$;


ALTER FUNCTION "public"."validate_subscription_usage_v1"() OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."verify_all_deposits"() RETURNS "void"
    LANGUAGE "sql" SECURITY DEFINER
    AS $$
    update pocket_deposits
    set verified_at = now()

    from (
      select
        pocket_deposits.id as id
      from pocket_deposits

      inner join transactions
      on pocket_deposits.transaction = transactions.id
      and transactions.status = 'PAID'

      where pocket_deposits.verified_at is null
    ) as transitions

    where pocket_deposits.id = transitions.id;
$$;


ALTER FUNCTION "public"."verify_all_deposits"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."verify_all_payment_v2"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
    with pending_batch as (
        select
            pr.id
        from payment_request pr
        inner join subscriptions sub on sub.id = pr.subscription
        inner join plans current_plan on current_plan.id = pr.plan
        inner join pockets poc on pr.pocket = poc.id
        where
            pr.verified_at is null
            and pr.pocket is not null
            and sub.cancelled_at is null
            and sub.cleaned_at is null
            and poc.amount >= current_plan.credit
            and (
                pr.created_at <= now()
                or
                (
                    coalesce(sub.usage_limit, current_plan.total_hours) is not null
                    and sub.total_usage > (coalesce(sub.usage_limit, current_plan.total_hours) + coalesce(public.get_rank_bonus_hours(sub.user), 0)) * 60
                )
            )
        limit 1
        for update skip locked
    ),

    update_result as (
        update payment_request pr
        set verified_at = now()
        from subscriptions sub, plans current_plan
        where pr.id in (select id from pending_batch)
          and pr.subscription = sub.id
          and pr.plan = current_plan.id
        returning
            pr.id as old_id,
            pr.verified_at,
            pr.subscription,
            pr.pocket,
            pr.plan,
            sub.ended_at as new_created_at,
            current_plan.extendable
    )

    insert into payment_request (id, created_at, subscription, pocket, plan)
    select
        (
          coalesce((select max(id) from payment_request), 0) +
          row_number() over (order by ur.old_id)
        ) as id,
        ur.new_created_at,
        ur.subscription,
        ur.pocket,
        case
            when ur.extendable then ur.plan
            else (
                select id
                from plans
                where extendable = true
                and active = true
                order by plans.credit asc
                limit 1
            )
        end
    from update_result ur
    where ur.verified_at is not null;

end;
$$;


ALTER FUNCTION "public"."verify_all_payment_v2"() OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."verify_all_transactions_v2"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
  payos_client_id text;
  payos_client_secret text;

  stripe_client_secret text;

  valid_payermax bigint;
begin
  select
    value->>'secret_key' as client_secret
  into stripe_client_secret
  from constant where name = 'stripe' limit 1;

  select
    value->>'client_id' as client_id,
    value->>'client_secret' as client_secret
  into payos_client_id, payos_client_secret
  from constant where name = 'payos' limit 1;

  SELECT count(*)
  into  valid_payermax
  FROM constant
  WHERE name = 'payermax'
  AND value->>'app_id' IS NOT NULL
  limit 1;

  if (payos_client_id is not null and payos_client_secret is not null) then
    update transactions
    set status = transitions.status
    from (
      select
        transactions.id as id,
        (request.content::jsonb)->'data'->>'status' as status
      from transactions
      inner join extensions.http(('GET',
        'https://api-merchant.payos.vn/v2/payment-requests/' ||
        (transactions.data->'data'->>'orderCode')::text,
        ARRAY[
          extensions.http_header('x-client-id',  payos_client_id),
          extensions.http_header('x-api-key',    payos_client_secret)
        ],
        NULL, NULL
      )::extensions.http_request) as request
      on request.status = 200 and is_json(request.content)

      where (transactions.status = '_PENDING' or transactions.status = 'PENDING')
      and transactions.expire_at + INTERVAL '10 minutes' > now()
      and transactions.data is not null
      and transactions.provider = 'PAYOS'
    ) as transitions
    where transactions.id = transitions.id;
  end if;

  if (stripe_client_secret is not null) then
    update transactions
    set status = case
      when transitions.status = 'paid' then 'PAID'
      else 'PENDING'
    end

    from (
      select
        transactions.id as id,
        (request.content::jsonb)->>'payment_status' as status
      from transactions
      inner join extensions.http(('GET',
        'https://api.stripe.com/v1/checkout/sessions/' ||
        (transactions.data->>'id')::text,
        ARRAY[
          extensions.http_header('Authorization','Bearer ' || stripe_client_secret)
        ], NULL, NULL
      )::extensions.http_request) as request
      on request.status = 200 and is_json(request.content)

      where transactions.status = 'PENDING'
      and transactions.expire_at + INTERVAL '10 minutes' > now()
      and transactions.data is not null
      and transactions.provider = 'STRIPE'
    ) as transitions
    where transactions.id = transitions.id;
  end if;

  IF (valid_payermax > 0) THEN
      UPDATE transactions
      SET status = CASE
          WHEN pm_check.status = 'SUCCESS' THEN 'PAID'
          ELSE 'CANCEL'
      END
      FROM (
          SELECT
              transactions.id,
              query_payermax_status(transactions.id) as status
          FROM transactions
          WHERE transactions.provider = 'PAYERMAX'
          AND transactions.status = 'PENDING'
          and transactions.expire_at + INTERVAL '10 minutes' > now()
      ) AS pm_check
      WHERE transactions.id = pm_check.id
      AND pm_check.status IN ('SUCCESS', 'FAILED', 'CLOSED');
  END IF;

  return;
end;
$$;


ALTER FUNCTION "public"."verify_all_transactions_v2"() OWNER TO "supabase_admin";


CREATE FOREIGN DATA WRAPPER "stripe_wrapper" HANDLER "extensions"."stripe_fdw_handler" VALIDATOR "extensions"."stripe_fdw_validator";



SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."addon_subscriptions" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "subscription" bigint NOT NULL,
    "addon" bigint NOT NULL,
    "unit_count" bigint DEFAULT '0'::bigint NOT NULL,
    "cancelled_at" timestamp with time zone,
    "last_payment" bigint,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL
);


ALTER TABLE "public"."addon_subscriptions" OWNER TO "supabase_admin";


ALTER TABLE "public"."addon_subscriptions" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."addon_subscriptions_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."addons" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "name" "text" NOT NULL,
    "active" boolean DEFAULT false NOT NULL,
    "unit_type" "text" DEFAULT 'NULL'::"text" NOT NULL,
    "unit_price" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL
);


ALTER TABLE "public"."addons" OWNER TO "supabase_admin";


COMMENT ON TABLE "public"."addons" IS 'This is a duplicate of resources';



ALTER TABLE "public"."addons" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."addons_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."app_access_snapshoot" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "usage" bigint NOT NULL,
    "email" "text" NOT NULL
);


ALTER TABLE "public"."app_access_snapshoot" OWNER TO "supabase_admin";


ALTER TABLE "public"."app_access_snapshoot" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."app_access_snapshoot_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."banner" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "priority" integer DEFAULT 0 NOT NULL,
    "url" "text" DEFAULT ''::"text" NOT NULL,
    "alt" "text",
    "active" boolean DEFAULT true NOT NULL
);


ALTER TABLE "public"."banner" OWNER TO "supabase_admin";


ALTER TABLE "public"."banner" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."banner_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."blog" (
    "id" bigint NOT NULL,
    "title" "text" NOT NULL,
    "subtitle" "text" NOT NULL,
    "category" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "author" "text",
    "bgUrl" "text",
    "body" "text",
    "slug" "text"
);


ALTER TABLE "public"."blog" OWNER TO "supabase_admin";


ALTER TABLE "public"."blog" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."blog_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."bucket_snapshoot" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "name" "uuid" NOT NULL,
    "size_in_mb" bigint NOT NULL,
    "email" "text" NOT NULL
);


ALTER TABLE "public"."bucket_snapshoot" OWNER TO "supabase_admin";


ALTER TABLE "public"."bucket_snapshoot" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."bucket_snapshoot_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."clusters" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "domain" "text" NOT NULL,
    "secret" "jsonb" NOT NULL,
    "metadata" "jsonb" NOT NULL,
    "active" boolean,
    "version" "text" DEFAULT 'v1'::"text" NOT NULL,
    "free" integer
);


ALTER TABLE "public"."clusters" OWNER TO "postgres";


ALTER TABLE "public"."clusters" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."clusters_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."constant" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "name" "text" NOT NULL,
    "value" "jsonb" NOT NULL,
    "type" "text" NOT NULL
);


ALTER TABLE "public"."constant" OWNER TO "supabase_admin";


ALTER TABLE "public"."constant" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."constant_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."currency_rates" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "currency" "text" NOT NULL,
    "rate_to_system_credit" double precision NOT NULL,
    "is_base" boolean DEFAULT false NOT NULL
);


ALTER TABLE "public"."currency_rates" OWNER TO "supabase_admin";


ALTER TABLE "public"."currency_rates" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."currency_rates_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."discord_events" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "name" "text" NOT NULL,
    "email" "text" NOT NULL,
    "channel" "text" NOT NULL,
    "payload" "jsonb" DEFAULT '{}'::"jsonb",
    "recipients" "text"[] DEFAULT '{}'::"text"[],
    "message_id" "text"
);


ALTER TABLE "public"."discord_events" OWNER TO "supabase_admin";


ALTER TABLE "public"."discord_events" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."discord_events_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."discounts" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "code" "text",
    "start_at" timestamp with time zone NOT NULL,
    "end_at" timestamp with time zone NOT NULL,
    "policy" "jsonb",
    "metadata" "jsonb",
    "discount_rate" real,
    "multiply_rate" real,
    "discount_limit" bigint,
    "discount_limit_per_user" bigint,
    "apply_for" "text"[] NOT NULL
);


ALTER TABLE "public"."discounts" OWNER TO "supabase_admin";


ALTER TABLE "public"."discounts" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."discounts_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."feedbacks" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "email" "text" NOT NULL,
    "rating" "jsonb" NOT NULL,
    "feedback" "text"
);


ALTER TABLE "public"."feedbacks" OWNER TO "supabase_admin";


ALTER TABLE "public"."feedbacks" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."feedbacks_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."generic_events" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "timestamp" timestamp with time zone DEFAULT "now"() NOT NULL,
    "name" "text" NOT NULL,
    "type" "text" NOT NULL,
    "value" "jsonb" NOT NULL
);


ALTER TABLE "public"."generic_events" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."job" (
    "id" bigint NOT NULL,
    "command" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "running_at" timestamp with time zone,
    "result" "jsonb",
    "success" boolean,
    "arguments" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "cluster" bigint,
    "finished_at" timestamp with time zone
);


ALTER TABLE "public"."job" OWNER TO "postgres";


ALTER TABLE "public"."job" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."job_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."llm_usage_snapshoot" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "email" "text" NOT NULL,
    "usage" bigint NOT NULL
);


ALTER TABLE "public"."llm_usage_snapshoot" OWNER TO "supabase_admin";


ALTER TABLE "public"."llm_usage_snapshoot" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."llm_usage_snapshoot_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."missions" (
    "id" integer NOT NULL,
    "code" "text" NOT NULL,
    "category" "text" NOT NULL,
    "type" "text" NOT NULL,
    "target_value" integer NOT NULL,
    "reward_stars" integer NOT NULL,
    "title_key" "text" NOT NULL,
    "description_key" "text" NOT NULL,
    "icon" "text",
    "is_repeatable" boolean DEFAULT false,
    "cooldown_days" integer,
    "is_active" boolean DEFAULT true,
    "sort_order" integer DEFAULT 0
);


ALTER TABLE "public"."missions" OWNER TO "supabase_admin";


ALTER TABLE "public"."missions" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."missions_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."nodes" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "cluster_id" bigint,
    "name" "text",
    "active" boolean DEFAULT true,
    "ip_address" "text"
);


ALTER TABLE "public"."nodes" OWNER TO "supabase_admin";


ALTER TABLE "public"."nodes" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."nodes_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."payment_request" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "subscription" bigint NOT NULL,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "plan" bigint,
    "transaction" bigint,
    "pocket" bigint,
    "verified_at" timestamp with time zone,
    "discount" bigint,
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "total_usage" integer DEFAULT 0,
    "total_data_credit" integer DEFAULT 0
);


ALTER TABLE "public"."payment_request" OWNER TO "postgres";


ALTER TABLE "public"."payment_request" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."payment_request_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."plans" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "name" "text" NOT NULL,
    "policy" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "price" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "active" boolean DEFAULT false NOT NULL,
    "cluster_pool" bigint[] DEFAULT '{}'::bigint[],
    "configuration" "jsonb",
    "extendable" boolean DEFAULT true NOT NULL,
    "total_days" integer,
    "total_hours" bigint,
    "only_cluster" bigint,
    "credit" bigint DEFAULT '29'::bigint NOT NULL
);


ALTER TABLE "public"."plans" OWNER TO "postgres";


ALTER TABLE "public"."plans" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."plans_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."pocket_deposits" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "pocket" bigint NOT NULL,
    "amount" bigint NOT NULL,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "transaction" bigint,
    "verified_at" timestamp with time zone,
    "discount" bigint
);


ALTER TABLE "public"."pocket_deposits" OWNER TO "postgres";


ALTER TABLE "public"."pocket_deposits" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."pocket_deposits_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."pockets" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "user" "text" NOT NULL,
    "amount" bigint NOT NULL,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL
);


ALTER TABLE "public"."pockets" OWNER TO "postgres";


ALTER TABLE "public"."pockets" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."pockets_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."rank_rewards" (
    "id" integer NOT NULL,
    "rank_tier" "text" NOT NULL,
    "min_stars" integer NOT NULL,
    "rewards" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL
);


ALTER TABLE "public"."rank_rewards" OWNER TO "supabase_admin";


ALTER TABLE "public"."rank_rewards" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."rank_rewards_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."referral" (
    "id" bigint NOT NULL,
    "from" "text" NOT NULL,
    "to" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."referral" OWNER TO "supabase_admin";


ALTER TABLE "public"."referral" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."referral_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."star_ledger" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "email" "text" NOT NULL,
    "amount" integer NOT NULL,
    "source_type" "text" NOT NULL,
    "source_ref" "text",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb"
);


ALTER TABLE "public"."star_ledger" OWNER TO "supabase_admin";


ALTER TABLE "public"."star_ledger" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."star_ledger_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."stores" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "name" "text",
    "metadata" "jsonb",
    "management" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "code_name" "text",
    "type" "text" DEFAULT 'STEAM'::"text" NOT NULL,
    "priority" bigint,
    "download" "jsonb",
    "genres" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    "depotkey" "jsonb",
    "metadata_tsv" "tsvector" GENERATED ALWAYS AS ("to_tsvector"('"english"'::"regconfig", "metadata")) STORED,
    "queue" bigint DEFAULT '0'::bigint NOT NULL,
    "benchmarks" "jsonb" DEFAULT '{}'::"jsonb",
    "metadata_locale" "jsonb" DEFAULT '{}'::"jsonb"
);


ALTER TABLE "public"."stores" OWNER TO "postgres";


ALTER TABLE "public"."stores" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."stores_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."subscriptions" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "user" "text" NOT NULL,
    "ended_at" timestamp with time zone,
    "cancelled_at" timestamp with time zone,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "cluster" bigint NOT NULL,
    "cleaned_at" timestamp with time zone,
    "allocated_at" timestamp with time zone,
    "total_usage" integer DEFAULT 0,
    "total_data_credit" integer DEFAULT 0,
    "usage_limit" bigint
);


ALTER TABLE "public"."subscriptions" OWNER TO "postgres";


ALTER TABLE "public"."subscriptions" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."subscriptions_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."transactions" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "expire_at" timestamp with time zone DEFAULT ("now"() + '00:15:00'::interval) NOT NULL,
    "status" "text" DEFAULT 'PENDING'::"text" NOT NULL,
    "data" "jsonb",
    "currency" "text",
    "provider" "text",
    "amount" double precision NOT NULL,
    "email" "text",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL
);


ALTER TABLE "public"."transactions" OWNER TO "postgres";


ALTER TABLE "public"."transactions" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."transactions_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."user_mission_claims" (
    "id" bigint NOT NULL,
    "email" "text" NOT NULL,
    "mission_id" integer,
    "claimed_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."user_mission_claims" OWNER TO "supabase_admin";


ALTER TABLE "public"."user_mission_claims" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."user_mission_claims_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."user_v2" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "email" "text" NOT NULL,
    "metadata" "jsonb",
    "volume_id" "uuid" DEFAULT "gen_random_uuid"(),
    "cluster_id" bigint
);


ALTER TABLE "public"."user_v2" OWNER TO "supabase_admin";


ALTER TABLE "public"."user_v2" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."user_v2_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."users" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "email" "text" NOT NULL,
    "metadata" "jsonb",
    "reference" "text",
    "demo" "text"
);


ALTER TABLE "public"."users" OWNER TO "supabase_admin";


ALTER TABLE "public"."users" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."users_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."vm_snapshoot_v3" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "session_id" "uuid" NOT NULL,
    "volume_id" "uuid" NOT NULL,
    "user" "text"[] NOT NULL,
    "gpuid" "text" NOT NULL,
    "log" "text"[],
    "processes" "text"[]
);


ALTER TABLE "public"."vm_snapshoot_v3" OWNER TO "postgres";


ALTER TABLE "public"."vm_snapshoot_v3" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."vm_snapshoot_v3_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."vm_snapshoot_v4" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "session_id" "uuid" NOT NULL,
    "volume_id" "uuid" NOT NULL,
    "node" "text" NOT NULL,
    "cluster_id" bigint,
    "email" "text" NOT NULL,
    "size" bigint DEFAULT '0'::bigint
);


ALTER TABLE "public"."vm_snapshoot_v4" OWNER TO "supabase_admin";


ALTER TABLE "public"."vm_snapshoot_v4" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."vm_snapshoot_v4_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."volume_snapshoot" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "name" "uuid" NOT NULL,
    "email" "text" NOT NULL,
    "size_in_gb" bigint NOT NULL
);


ALTER TABLE "public"."volume_snapshoot" OWNER TO "supabase_admin";


ALTER TABLE "public"."volume_snapshoot" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."volume_snapshoot_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



ALTER TABLE ONLY "public"."addon_subscriptions"
    ADD CONSTRAINT "addon_subscriptions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."addons"
    ADD CONSTRAINT "addons_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."app_access_snapshoot"
    ADD CONSTRAINT "app_access_snapshoot_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."banner"
    ADD CONSTRAINT "banner_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."blog"
    ADD CONSTRAINT "blog_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."blog"
    ADD CONSTRAINT "blog_slug_key" UNIQUE ("slug");



ALTER TABLE ONLY "public"."bucket_snapshoot"
    ADD CONSTRAINT "bucket_snapshoot_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."clusters"
    ADD CONSTRAINT "clusters_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."constant"
    ADD CONSTRAINT "constant_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."currency_rates"
    ADD CONSTRAINT "currency_rates_created_at_key" UNIQUE ("created_at");



ALTER TABLE ONLY "public"."currency_rates"
    ADD CONSTRAINT "currency_rates_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."discord_events"
    ADD CONSTRAINT "discord_events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."discounts"
    ADD CONSTRAINT "discounts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."feedbacks"
    ADD CONSTRAINT "feedbacks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."generic_events"
    ADD CONSTRAINT "generic_events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."job"
    ADD CONSTRAINT "job_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."llm_usage_snapshoot"
    ADD CONSTRAINT "llm_usage_snapshoot_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."missions"
    ADD CONSTRAINT "missions_code_key" UNIQUE ("code");



ALTER TABLE ONLY "public"."missions"
    ADD CONSTRAINT "missions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."nodes"
    ADD CONSTRAINT "nodes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."payment_request"
    ADD CONSTRAINT "payment_request_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."plans"
    ADD CONSTRAINT "plans_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pocket_deposits"
    ADD CONSTRAINT "pocket_deposits_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pockets"
    ADD CONSTRAINT "pockets_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."rank_rewards"
    ADD CONSTRAINT "rank_rewards_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."rank_rewards"
    ADD CONSTRAINT "rank_rewards_rank_tier_key" UNIQUE ("rank_tier");



ALTER TABLE ONLY "public"."referral"
    ADD CONSTRAINT "referral_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."star_ledger"
    ADD CONSTRAINT "star_ledger_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."stores"
    ADD CONSTRAINT "stores_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."stores"
    ADD CONSTRAINT "stores_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."transactions"
    ADD CONSTRAINT "transactions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_mission_claims"
    ADD CONSTRAINT "user_mission_claims_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_v2"
    ADD CONSTRAINT "user_v2_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."vm_snapshoot_v3"
    ADD CONSTRAINT "vm_snapshoot_v3_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."vm_snapshoot_v4"
    ADD CONSTRAINT "vm_snapshoot_v4_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."volume_snapshoot"
    ADD CONSTRAINT "volume_snapshoot_pkey" PRIMARY KEY ("id");



CREATE INDEX "idx_discord_events_email" ON "public"."discord_events" USING "btree" ("email");



CREATE INDEX "idx_discord_events_name" ON "public"."discord_events" USING "btree" ("name");



CREATE INDEX "idx_mission_claims_email" ON "public"."user_mission_claims" USING "btree" ("email");



CREATE INDEX "idx_star_ledger_email" ON "public"."star_ledger" USING "btree" ("email");



CREATE INDEX "idx_user_array_vm_snapshoot_v3" ON "public"."vm_snapshoot_v3" USING "gin" ("user");



CREATE INDEX "stores_metadata_tsv_idx" ON "public"."stores" USING "gin" ("metadata_tsv");



CREATE OR REPLACE TRIGGER "addon_alloc" BEFORE INSERT ON "public"."addon_subscriptions" FOR EACH ROW EXECUTE FUNCTION "public"."allocate_addon_resources"();



CREATE OR REPLACE TRIGGER "addon_dealloc" BEFORE UPDATE ON "public"."addon_subscriptions" FOR EACH ROW EXECUTE FUNCTION "public"."deallocate_addon_resources"();



CREATE OR REPLACE TRIGGER "allocate_subscription_resources_v8" AFTER UPDATE ON "public"."subscriptions" FOR EACH ROW EXECUTE FUNCTION "public"."allocate_subscription_resources_v8"();



CREATE OR REPLACE TRIGGER "clean_subscription" BEFORE UPDATE ON "public"."subscriptions" FOR EACH ROW EXECUTE FUNCTION "public"."clean_subscription"();



CREATE OR REPLACE TRIGGER "generate_payment_link" BEFORE UPDATE ON "public"."transactions" FOR EACH ROW EXECUTE FUNCTION "public"."on_transaction_driver_v2"();



CREATE OR REPLACE TRIGGER "link_deposit_transaction_v2" BEFORE INSERT ON "public"."pocket_deposits" FOR EACH ROW EXECUTE FUNCTION "public"."new_pocket_deposits_v2"();



CREATE OR REPLACE TRIGGER "notify_active_plan_v2" BEFORE UPDATE ON "public"."plans" FOR EACH ROW EXECUTE FUNCTION "public"."notify_active_plan_v2"();



CREATE OR REPLACE TRIGGER "notify_failure_job" AFTER UPDATE ON "public"."job" FOR EACH ROW EXECUTE FUNCTION "public"."notify_failure_job"();



CREATE OR REPLACE TRIGGER "on_deposit_verification" BEFORE UPDATE ON "public"."pocket_deposits" FOR EACH ROW EXECUTE FUNCTION "public"."update_pocket_remainder"();



CREATE OR REPLACE TRIGGER "on_payment_verification" BEFORE UPDATE ON "public"."payment_request" FOR EACH ROW EXECUTE FUNCTION "public"."update_request_payment"();



CREATE OR REPLACE TRIGGER "trigger_fetch_steamdata" BEFORE INSERT ON "public"."stores" FOR EACH ROW EXECUTE FUNCTION "public"."new_store_added"();



CREATE OR REPLACE TRIGGER "trigger_reset_app_access" AFTER UPDATE OF "unit_count" ON "public"."addon_subscriptions" FOR EACH ROW EXECUTE FUNCTION "public"."on_app_access_reset"();



CREATE OR REPLACE TRIGGER "update_app_access_usage" BEFORE INSERT ON "public"."app_access_snapshoot" FOR EACH ROW EXECUTE FUNCTION "public"."update_app_access_usage"();



CREATE OR REPLACE TRIGGER "update_bucket_usage" BEFORE INSERT ON "public"."bucket_snapshoot" FOR EACH ROW EXECUTE FUNCTION "public"."update_bucket_usage"();



CREATE OR REPLACE TRIGGER "update_llm_usage" BEFORE INSERT ON "public"."llm_usage_snapshoot" FOR EACH ROW EXECUTE FUNCTION "public"."update_llm_usage"();



CREATE OR REPLACE TRIGGER "update_subscription_data_usage" BEFORE INSERT ON "public"."volume_snapshoot" FOR EACH ROW EXECUTE FUNCTION "public"."update_subscription_data_usage"();



CREATE OR REPLACE TRIGGER "update_subscription_usage" AFTER INSERT ON "public"."vm_snapshoot_v4" FOR EACH ROW EXECUTE FUNCTION "public"."update_subscription_usage"();



ALTER TABLE ONLY "public"."addon_subscriptions"
    ADD CONSTRAINT "addon_subscriptions_addon_fkey" FOREIGN KEY ("addon") REFERENCES "public"."addons"("id");



ALTER TABLE ONLY "public"."addon_subscriptions"
    ADD CONSTRAINT "addon_subscriptions_last_payment_fkey" FOREIGN KEY ("last_payment") REFERENCES "public"."payment_request"("id");



ALTER TABLE ONLY "public"."addon_subscriptions"
    ADD CONSTRAINT "addon_subscriptions_subscription_fkey" FOREIGN KEY ("subscription") REFERENCES "public"."subscriptions"("id");



ALTER TABLE ONLY "public"."job"
    ADD CONSTRAINT "job_cluster_fkey" FOREIGN KEY ("cluster") REFERENCES "public"."clusters"("id");



ALTER TABLE ONLY "public"."nodes"
    ADD CONSTRAINT "nodes_cluster_id_fkey" FOREIGN KEY ("cluster_id") REFERENCES "public"."clusters"("id");



ALTER TABLE ONLY "public"."payment_request"
    ADD CONSTRAINT "payment_request_discount_fkey" FOREIGN KEY ("discount") REFERENCES "public"."discounts"("id");



ALTER TABLE ONLY "public"."payment_request"
    ADD CONSTRAINT "payment_request_plan_fkey" FOREIGN KEY ("plan") REFERENCES "public"."plans"("id");



ALTER TABLE ONLY "public"."payment_request"
    ADD CONSTRAINT "payment_request_pocket_fkey" FOREIGN KEY ("pocket") REFERENCES "public"."pockets"("id");



ALTER TABLE ONLY "public"."payment_request"
    ADD CONSTRAINT "payment_request_subscription_fkey" FOREIGN KEY ("subscription") REFERENCES "public"."subscriptions"("id");



ALTER TABLE ONLY "public"."payment_request"
    ADD CONSTRAINT "payment_request_transaction_fkey" FOREIGN KEY ("transaction") REFERENCES "public"."transactions"("id") ON UPDATE CASCADE ON DELETE SET NULL;



ALTER TABLE ONLY "public"."plans"
    ADD CONSTRAINT "plans_only_cluster_fkey" FOREIGN KEY ("only_cluster") REFERENCES "public"."clusters"("id");



ALTER TABLE ONLY "public"."pocket_deposits"
    ADD CONSTRAINT "pocket_deposits_discount_fkey" FOREIGN KEY ("discount") REFERENCES "public"."discounts"("id");



ALTER TABLE ONLY "public"."pocket_deposits"
    ADD CONSTRAINT "pocket_deposits_pocket_fkey" FOREIGN KEY ("pocket") REFERENCES "public"."pockets"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."pocket_deposits"
    ADD CONSTRAINT "pocket_deposits_transaction_fkey" FOREIGN KEY ("transaction") REFERENCES "public"."transactions"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_cluster_fkey" FOREIGN KEY ("cluster") REFERENCES "public"."clusters"("id");



ALTER TABLE ONLY "public"."user_mission_claims"
    ADD CONSTRAINT "user_mission_claims_mission_id_fkey" FOREIGN KEY ("mission_id") REFERENCES "public"."missions"("id");



ALTER TABLE ONLY "public"."user_v2"
    ADD CONSTRAINT "user_v2_cluster_id_fkey" FOREIGN KEY ("cluster_id") REFERENCES "public"."clusters"("id");



ALTER TABLE ONLY "public"."vm_snapshoot_v4"
    ADD CONSTRAINT "vm_snapshoot_v4_cluster_id_fkey" FOREIGN KEY ("cluster_id") REFERENCES "public"."clusters"("id");



CREATE POLICY "Enable read access for all users" ON "public"."plans" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "public"."stores" FOR SELECT USING (true);



ALTER TABLE "public"."addon_subscriptions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."addons" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "all access" ON "public"."referral" USING (true);



CREATE POLICY "allow blog read" ON "public"."blog" FOR SELECT USING (true);



CREATE POLICY "allow fetch all" ON "public"."addons" FOR SELECT USING (true);



CREATE POLICY "allow insert" ON "public"."discord_events" FOR INSERT WITH CHECK (true);



CREATE POLICY "allow insert" ON "public"."feedbacks" FOR INSERT WITH CHECK (true);



CREATE POLICY "allow insert" ON "public"."stores" FOR INSERT WITH CHECK (true);



CREATE POLICY "allow select all" ON "public"."currency_rates" FOR SELECT USING (true);



CREATE POLICY "allow slect" ON "public"."banner" FOR SELECT USING (true);



CREATE POLICY "allow update url" ON "public"."stores" FOR UPDATE USING (true);



ALTER TABLE "public"."app_access_snapshoot" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."banner" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."blog" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."bucket_snapshoot" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."clusters" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."constant" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."currency_rates" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."discord_events" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."discounts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."feedbacks" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."generic_events" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."job" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."llm_usage_snapshoot" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."missions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."nodes" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "only_active_discount" ON "public"."discounts" FOR SELECT USING ((("start_at" < "now"()) AND ("end_at" > "now"())));



ALTER TABLE "public"."payment_request" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."plans" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."pocket_deposits" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."pockets" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."rank_rewards" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."referral" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."star_ledger" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."stores" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."subscriptions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."transactions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_mission_claims" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_v2" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."users" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."vm_snapshoot_v3" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."vm_snapshoot_v4" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."volume_snapshoot" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";








GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_in"("cstring") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_in"("cstring") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_in"("cstring") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_in"("cstring") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_out"("public"."gtrgm") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_out"("public"."gtrgm") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_out"("public"."gtrgm") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_out"("public"."gtrgm") TO "service_role";











































































































































































































































































