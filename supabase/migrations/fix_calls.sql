-- Create call_rooms table for signaling
create table if not exists public.call_rooms (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  caller_id uuid references auth.users not null,
  receiver_id uuid references auth.users not null,
  status text check (status in ('offering', 'ringing', 'accepted', 'rejected', 'ended', 'missed')) default 'offering',
  caller_name text,
  caller_avatar text
);

-- RLS
alter table public.call_rooms enable row level security;

create policy "Users can insert calls" on public.call_rooms for insert with check (auth.uid() = caller_id);
create policy "Users can update their calls" on public.call_rooms for update using (auth.uid() in (caller_id, receiver_id));
create policy "Users can view their calls" on public.call_rooms for select using (auth.uid() in (caller_id, receiver_id));

-- Realtime
alter publication supabase_realtime add table public.call_rooms;
