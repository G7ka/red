# How to Fix Notification Deletion & Read Status (RLS Setup)

## Problem
When you swipe to delete or mark notifications as read, they might return when you reopen the screen. This happens because the database's Row Level Security (RLS) restricts clients from updating or deleting rows by default.

## Solution

You need to add UPDATE and DELETE RLS policies to the `notifications` table on your Supabase dashboard.

### Step 1: Go to Supabase Dashboard
1. Open [supabase.com](https://supabase.com)
2. Select your project
3. Click **SQL Editor** in the left sidebar

### Step 2: Run the SQL Script
1. Click **New Query**
2. Copy and paste this SQL code:

```sql
-- 1. Allow users to update their own notifications (e.g. marking as read)
DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
CREATE POLICY "Users can update own notifications"
ON public.notifications FOR UPDATE
TO authenticated
USING (auth.uid() = to_uid)
WITH CHECK (auth.uid() = to_uid);

-- 2. Allow users to delete their own notifications (e.g. swipe-to-delete)
DROP POLICY IF EXISTS "Users can delete own notifications" ON public.notifications;
CREATE POLICY "Users can delete own notifications"
ON public.notifications FOR DELETE
TO authenticated
USING (auth.uid() = to_uid);
```

3. Click **Run** (or press `Ctrl+Enter`)
4. You should see "Success. No rows returned"

---

## Alternative: Use Supabase CLI
If you deploy your database updates using the CLI:
```bash
supabase db push
```
This will automatically push the newly created migration file in `supabase/migrations/notifications_rls.sql`.
