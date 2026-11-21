-- Tavelya database. Run this whole file once in Supabase: SQL Editor > New query > paste > Run.

create table if not exists public.profiles(
  id uuid primary key references auth.users on delete cascade,
  name text, email text,
  type text not null default 'customer' check (type in ('customer','affiliate','admin')),
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  code text unique, rate numeric default 0, pay text, details text,
  created_at timestamptz default now());

create table if not exists public.site_data(
  key text primary key, value jsonb not null, updated_at timestamptz default now());

create table if not exists public.reviews(
  id uuid primary key default gen_random_uuid(),
  product_id text not null, product text,
  rating int check (rating between 1 and 5), body text,
  user_id uuid references auth.users on delete set null,
  status text not null default 'published' check (status in ('published','hidden')),
  created_at timestamptz default now());

create table if not exists public.messages(
  id uuid primary key default gen_random_uuid(),
  to_user uuid references auth.users on delete cascade,
  body text not null, created_at timestamptz default now());

create or replace function public.is_admin() returns boolean language sql security definer stable set search_path=public as
$$ select exists(select 1 from public.profiles where id=auth.uid() and type='admin' and status='approved') $$;

create or replace function public.is_affiliate() returns boolean language sql security definer stable set search_path=public as
$$ select exists(select 1 from public.profiles where id=auth.uid() and type='affiliate' and status='approved') $$;

-- A new signup becomes a customer (approved) or an affiliate (pending). Nobody can sign up as admin.
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
declare t text := case when new.raw_user_meta_data->>'type'='affiliate' then 'affiliate' else 'customer' end;
begin
  insert into public.profiles(id,name,email,type,status,code)
  values(new.id, coalesce(new.raw_user_meta_data->>'name',''), new.email, t,
         case when t='affiliate' then 'pending' else 'approved' end,
         case when t='affiliate' then 'AFF-'||upper(substr(md5(random()::text||new.id::text),1,6)) end);
  return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();

-- Members edit only their own name and payout details, through this function (they cannot change status or type).
create or replace function public.save_profile(p_name text,p_pay text,p_details text) returns void language sql security definer set search_path=public as
$$ update public.profiles set name=p_name, pay=p_pay, details=p_details where id=auth.uid() $$;

alter table public.profiles  enable row level security;
alter table public.site_data enable row level security;
alter table public.reviews   enable row level security;
alter table public.messages  enable row level security;

drop policy if exists profiles_read on public.profiles;
create policy profiles_read on public.profiles for select using (id=auth.uid() or public.is_admin());
drop policy if exists profiles_admin_update on public.profiles;
create policy profiles_admin_update on public.profiles for update using (public.is_admin()) with check (public.is_admin());

drop policy if exists site_read on public.site_data;
create policy site_read on public.site_data for select using (true);
drop policy if exists site_admin_write on public.site_data;
create policy site_admin_write on public.site_data for all using (public.is_admin()) with check (public.is_admin());

drop policy if exists reviews_read on public.reviews;
create policy reviews_read on public.reviews for select using (status='published' or public.is_admin() or user_id=auth.uid());
drop policy if exists reviews_insert on public.reviews;
create policy reviews_insert on public.reviews for insert to authenticated with check (user_id=auth.uid() and status='published');
drop policy if exists reviews_admin on public.reviews;
create policy reviews_admin on public.reviews for update using (public.is_admin()) with check (public.is_admin());
drop policy if exists reviews_admin_delete on public.reviews;
create policy reviews_admin_delete on public.reviews for delete using (public.is_admin());

drop policy if exists msg_read on public.messages;
create policy msg_read on public.messages for select using (public.is_admin() or (public.is_affiliate() and (to_user is null or to_user=auth.uid())));
drop policy if exists msg_admin on public.messages;
create policy msg_admin on public.messages for all using (public.is_admin()) with check (public.is_admin());


-- Explicit permissions (Row Level Security above still decides who sees or changes which rows).
grant usage on schema public to anon, authenticated;
grant select on public.site_data, public.reviews to anon, authenticated;
grant insert, update, delete on public.site_data to authenticated;
grant insert, update, delete on public.reviews to authenticated;
grant select, update on public.profiles to authenticated;
grant select, insert, update, delete on public.messages to authenticated;
grant execute on function public.is_admin(), public.is_affiliate() to anon, authenticated;
grant execute on function public.save_profile(text,text,text) to authenticated;

-- STEP 2 (after you create your own account on the site): make yourself the admin.
-- Replace the text in quotes with the email you signed up with, then run this line alone.
-- update public.profiles set type='admin', status='approved' where email='YOUR_EMAIL_HERE';
