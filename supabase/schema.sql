-- Schema Setup (Run in Supabase SQL Editor)

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- USERS TABLE (Extends auth.users)
create table public.users (
  id uuid references auth.users not null primary key,
  email text,
  first_name text,
  last_name text,
  display_name text,
  gender text,
  dob timestamp with time zone,
  image_url text, -- profileImageUrl in app
  bio text,
  interests text[],
  profile_images text[],
  friends uuid[],
  anonymous_penguin_type text,
  fcm_token text,
  fcm_token_updated_at timestamp with time zone,
  is_online boolean default false,
  last_seen timestamp with time zone,
  created_at timestamp with time zone default now()
);

-- POSTS TABLE
create table public.posts (
  id uuid default uuid_generate_v4() primary key,
  owner_uid uuid references public.users(id) not null,
  text text,
  video_url text,
  image_url text,
  media_type text,
  likes_count int default 0,
  comments_count int default 0,
  created_at timestamp with time zone default now()
);

-- POST LIKES TABLE
create table public.post_likes (
  post_id uuid references public.posts(id) on delete cascade not null,
  user_id uuid references public.users(id) not null,
  created_at timestamp with time zone default now(),
  primary key (post_id, user_id)
);

-- POST COMMENTS TABLE
create table public.post_comments (
  id uuid default uuid_generate_v4() primary key,
  post_id uuid references public.posts(id) on delete cascade not null,
  uid uuid references public.users(id) not null,
  text text not null,
  created_at timestamp with time zone default now()
);

-- CHATS TABLE
create table public.chats (
  id uuid default uuid_generate_v4() primary key,
  type text default 'private', -- 'private', 'group', 'anonymous'
  participants uuid[] not null,
  last_message text,
  last_message_time timestamp with time zone,
  is_anonymous_active boolean default true,
  created_at timestamp with time zone default now()
);

-- MESSAGES TABLE
create table public.messages (
  id uuid default uuid_generate_v4() primary key,
  chat_id uuid references public.chats(id) on delete cascade not null,
  sender_id uuid references public.users(id) not null,
  text text,
  type text default 'text', -- 'text', 'image', 'video', 'audio'
  media_url text,
  read_by uuid[],
  created_at timestamp with time zone default now()
);

-- NOTIFICATIONS TABLE
create table public.notifications (
  id uuid default uuid_generate_v4() primary key,
  to_uid uuid references public.users(id) not null,
  type text not null, -- 'like', 'comment', 'welcome', 'request'
  data jsonb,
  is_read boolean default false,
  created_at timestamp with time zone default now()
);

-- SECURITY POLICIES (Row Level Security)

-- Enable RLS on all tables
alter table public.users enable row level security;
alter table public.posts enable row level security;
alter table public.post_likes enable row level security;
alter table public.post_comments enable row level security;
alter table public.chats enable row level security;
alter table public.messages enable row level security;
alter table public.notifications enable row level security;

-- USERS POLICIES
create policy "Public profiles are viewable by everyone"
  on public.users for select
  using ( true );

create policy "Users can insert their own profile"
  on public.users for insert
  with check ( auth.uid() = id );

create policy "Users can update own profile"
  on public.users for update
  using ( auth.uid() = id );

-- POSTS POLICIES
create policy "Posts are viewable by everyone"
  on public.posts for select
  using ( true );

create policy "Users can insert their own posts"
  on public.posts for insert
  with check ( auth.uid() = owner_uid );

create policy "Users can update own posts"
  on public.posts for update
  using ( auth.uid() = owner_uid );

create policy "Users can delete own posts"
  on public.posts for delete
  using ( auth.uid() = owner_uid );

-- LIKES POLICIES
create policy "Likes are viewable by everyone"
  on public.post_likes for select
  using ( true );

create policy "Users can toggle likes"
  on public.post_likes for all
  using ( auth.uid() = user_id );

-- COMMENTS POLICIES
create policy "Comments are viewable by everyone"
  on public.post_comments for select
  using ( true );

create policy "Users can insert comments"
  on public.post_comments for insert
  with check ( auth.uid() = uid );

-- CHATS POLICIES
create policy "Users can view chats they are part of"
  on public.chats for select
  using ( auth.uid() = any(participants) );

create policy "Users can insert chats"
  on public.chats for insert
  with check ( auth.uid() = any(participants) );

create policy "Users can update chats they are part of"
  on public.chats for update
  using ( auth.uid() = any(participants) );

-- MESSAGES POLICIES
create policy "Users can view messages in their chats"
  on public.messages for select
  using (
    exists (
      select 1 from public.chats
      where id = messages.chat_id
      and auth.uid() = any(participants)
    )
  );

create policy "Users can insert messages in their chats"
  on public.messages for insert
  with check (
    exists (
      select 1 from public.chats
      where id = chat_id
      and auth.uid() = any(participants)
    )
  );

-- NOTIFICATIONS POLICIES
create policy "Users can view own notifications"
  on public.notifications for select
  using ( auth.uid() = to_uid );

create policy "Server/Edge Functions can insert notifications"
  on public.notifications for insert
  with check ( true ); -- Ideally restrict this further or use service key

-- FUNCTION TO HANDLE NEW USER SIGNUP (Auto-create profile)
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.users (id, email, display_name)
  values (new.id, new.email, new.raw_user_meta_data->>'full_name');
  return new;
end;
$$ language plpgsql security definer;

-- TRIGGER FOR NEW USER

-- ENABLE REALTIME
alter publication supabase_realtime add table public.users, public.posts, public.post_likes, public.post_comments, public.chats, public.messages, public.notifications;


