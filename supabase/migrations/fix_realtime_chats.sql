-- Enable Realtime for chats table to fix Matching Synchronization
-- This ensures the second user (waiting in queue) gets notified immediately when a match is found.
alter publication supabase_realtime add table public.chats;
