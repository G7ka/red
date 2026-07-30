-- Create matching_queue table
create table if not exists public.matching_queue (
  user_id uuid references public.users(id) on delete cascade not null primary key,
  created_at timestamp with time zone default now()
);

-- Enable RLS
alter table public.matching_queue enable row level security;

-- Policies
create policy "Users can insert themselves into queue"
  on public.matching_queue for insert
  with check ( auth.uid() = user_id );

create policy "Users can delete themselves from queue"
  on public.matching_queue for delete
  using ( auth.uid() = user_id );
  
create policy "Users can read queue"
  on public.matching_queue for select
  using ( true );

-- Function to find a match atomically
create or replace function public.find_match(my_user_id uuid)
returns table (matched_user_id uuid) 
security definer
as $$
declare
  found_id uuid;
  my_gender text;
  target_gender text;
begin
  -- Get my gender
  select gender into my_gender from public.users where id = my_user_id;

  -- Determine target gender (Strict Hetero)
  if my_gender = 'male' then
    target_gender := 'female';
  elsif my_gender = 'female' then
    target_gender := 'male';
  else
    -- If unknown gender, do not match (or handle gracefully)
    return;
  end if;

  -- Try to find a user in the queue who is target_gender
  delete from public.matching_queue
  where user_id = (
    select q.user_id
    from public.matching_queue q
    join public.users u on u.id = q.user_id
    where q.user_id != my_user_id
    and u.gender = target_gender
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
