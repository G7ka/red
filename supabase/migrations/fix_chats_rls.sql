-- Enable RLS
alter table public.chats enable row level security;

-- Drop existing policies to avoid conflicts
drop policy if exists "Users can view own chats" on public.chats;
drop policy if exists "Users can insert chats" on public.chats;
drop policy if exists "Users can update own chats" on public.chats;

-- Create Policies
create policy "Users can view own chats" on public.chats
for select using (
  auth.uid() = any(participants)
);

create policy "Users can insert chats" on public.chats
for insert with check (
  auth.uid() = any(participants)
);

create policy "Users can update own chats" on public.chats
for update using (
  auth.uid() = any(participants)
);

-- Ensure columns exist and have defaults
alter table public.chats add column if not exists is_anonymous_active boolean default true;
alter table public.chats alter column is_anonymous_active set default true;

-- Update nulls
update public.chats set is_anonymous_active = true where is_anonymous_active is null;
