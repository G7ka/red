-- Enable UPDATE and DELETE policies for the notifications table so users can read and delete their own notifications

-- Enable RLS on notifications (already enabled, but let's be sure)
ALTER TABLE IF EXISTS public.notifications ENABLE ROW LEVEL SECURITY;

-- 1. UPDATE policy: Allow users to update their own notifications (e.g. marking as read)
DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
CREATE POLICY "Users can update own notifications"
ON public.notifications FOR UPDATE
TO authenticated
USING (auth.uid() = to_uid)
WITH CHECK (auth.uid() = to_uid);

-- 2. DELETE policy: Allow users to delete their own notifications (e.g. swipe-to-delete)
DROP POLICY IF EXISTS "Users can delete own notifications" ON public.notifications;
CREATE POLICY "Users can delete own notifications"
ON public.notifications FOR DELETE
TO authenticated
USING (auth.uid() = to_uid);
