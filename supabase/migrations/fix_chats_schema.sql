-- Add missing columns to chats table to fix Matching Error
alter table public.chats 
  add column if not exists is_anonymous boolean default false,
  add column if not exists is_anonymous_active boolean default true;
