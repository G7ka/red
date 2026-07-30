-- 1. SETUP MATCHING QUEUE
create table if not exists public.matching_queue (
  user_id uuid references public.users(id) on delete cascade not null primary key,
  created_at timestamp with time zone default now()
);

alter table public.matching_queue enable row level security;

-- Safely create policies
do $$ begin
  create policy "Users can insert themselves into queue"
    on public.matching_queue for insert with check ( auth.uid() = user_id );
exception when duplicate_object then null; end $$;

do $$ begin
  create policy "Users can delete themselves from queue"
    on public.matching_queue for delete using ( auth.uid() = user_id );
exception when duplicate_object then null; end $$;
  
do $$ begin
  create policy "Users can read queue"
    on public.matching_queue for select using ( true );
exception when duplicate_object then null; end $$;

-- 2. MATCHING FUNCTION (Case-Insensitive Strict Gender)
create or replace function public.find_match(my_user_id uuid)
returns table (matched_user_id uuid) 
security definer
as $$
declare
  found_id uuid;
  my_gender text;
  target_gender text;
begin
  -- Get my gender (handle mixed case)
  select lower(gender) into my_gender from public.users where id = my_user_id;

  -- Determine target gender (Strict Hetero)
  if my_gender = 'male' then
    target_gender := 'female';
  elsif my_gender = 'female' then
    target_gender := 'male';
  else
    return; -- No match for unknown gender
  end if;

  -- Try to find a user in the queue who is target_gender
  delete from public.matching_queue
  where user_id = (
    select q.user_id
    from public.matching_queue q
    join public.users u on u.id = q.user_id
    where q.user_id != my_user_id
    and lower(u.gender) = target_gender
    order by q.created_at asc
    limit 1
    for update skip locked
  )
  returning user_id into found_id;

  if found_id is not null then
    return query select found_id;
  end if;
end;
$$ language plpgsql;

-- 3. DELETE ACCOUNT FUNCTION
create or replace function public.delete_my_account()
returns void
security definer
as $$
begin
  -- Delete public profile data
  delete from public.users where id = auth.uid();
  -- Note: Does not delete from auth.users, but removes all app data 
  -- because of cascade constraints.
end;
$$ language plpgsql;

-- 4. ENABLE REALTIME FOR NOTIFICATIONS (Crucial for badge count)
alter publication supabase_realtime add table public.notifications;
alter publication supabase_realtime add table public.matching_queue;
