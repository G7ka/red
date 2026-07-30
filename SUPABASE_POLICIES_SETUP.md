# Supabase Storage Policies - Step-by-Step Setup Guide

## Overview
You need to create policies for 4 storage buckets:
1. `profile-images`
2. `posts`
3. `chat-images`
4. `chat-audio`

Each bucket needs policies for: **Upload (INSERT)**, **Read (SELECT)**, and **Delete**.

---

## Method 1: Quick Setup (Recommended) - Using SQL Editor

This is the **fastest way** - just copy and paste one SQL script!

### ⚠️ IMPORTANT: Before You Run This
If you already created policies (from previous attempts), you should **delete them first** to avoid errors. 
Run this command to clear old policies:
```sql
DROP POLICY IF EXISTS "Allow authenticated uploads" ON storage.objects;
DROP POLICY IF EXISTS "Allow public read" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to delete own files" ON storage.objects;
```

### Step 1: Open SQL Editor
1. Go to your Supabase dashboard
2. Click **SQL Editor** in the left sidebar
3. Click **New query**

### Step 2: Copy and Paste This Entire Script

```sql
-- ============================================
-- SUPABASE STORAGE POLICIES FOR PENGUIN APP
-- ============================================

-- First, enable RLS on storage.objects
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;

-- ============================================
-- SUPABASE STORAGE POLICIES FOR PENGUIN APP
-- ============================================

-- First, enable RLS on storage.objects
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;

-- ============================================
-- BUCKET: profile-images
-- Policies: INSERT and DELETE check if path starts with user_id
-- Path structure: bucket_id/user_id/filename.ext
-- ============================================

-- Allow authenticated users to upload ONLY to their own folder
CREATE POLICY "Allow authenticated uploads to profile-images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'profile-images' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow public read access (Profile pics are public)
CREATE POLICY "Allow public read from profile-images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'profile-images');

-- Allow users to delete ONLY their own files
CREATE POLICY "Allow authenticated delete from profile-images"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'profile-images' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- ============================================
-- BUCKET: posts
-- Path structure: bucket_id/user_id/filename.ext
-- ============================================

CREATE POLICY "Allow authenticated uploads to posts"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'posts' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY "Allow public read from posts"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'posts');

CREATE POLICY "Allow authenticated delete from posts"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'posts' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- ============================================
-- BUCKET: chat-images
-- Path structure: bucket_id/user_id/filename.ext
-- ============================================

CREATE POLICY "Allow authenticated uploads to chat-images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'chat-images' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY "Allow public read from chat-images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'chat-images');

CREATE POLICY "Allow authenticated delete from chat-images"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'chat-images' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- ============================================
-- BUCKET: chat-audio
-- Path structure: bucket_id/user_id/filename.ext
-- ============================================

CREATE POLICY "Allow authenticated uploads to chat-audio"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'chat-audio' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY "Allow public read from chat-audio"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'chat-audio');

CREATE POLICY "Allow authenticated delete from chat-audio"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'chat-audio' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- ============================================
-- ALLOW LISTING BUCKETS
-- Essential for some clients to see available buckets
-- ============================================

CREATE POLICY "Allow public list buckets"
ON storage.buckets FOR SELECT
TO public
USING (true);
```

### Step 3: Run the Script
1. Click **Run** (or press Ctrl+Enter)
2. You should see "Success. No rows returned"
3. Done! ✅

---

## Method 2: Manual Setup (Using UI)

If you prefer to create policies one by one through the UI:

### For EACH bucket (profile-images, posts, chat-images, chat-audio):

#### Step 1: Navigate to Bucket Policies
1. Click **Storage** in left sidebar
2. Click on the bucket name (e.g., `profile-images`)
3. Click **Policies** tab
4. Click **New Policy**

---

### Policy 1: Allow Authenticated Uploads

1. Click **New Policy** → **For full customization**
2. Fill in:
   - **Policy name**: `Allow authenticated uploads`
   - **Allowed operation**: Check ✅ **INSERT**
   - **Target roles**: `authenticated`
   - **USING expression**:
   ```sql
   auth.role() = 'authenticated'
   ```
   - **WITH CHECK expression**:
   ```sql
   auth.role() = 'authenticated'
   ```
3. Click **Review** → **Save policy**

---

### Policy 2: Allow Public Read

1. Click **New Policy** → **For full customization**
2. Fill in:
   - **Policy name**: `Allow public read`
   - **Allowed operation**: Check ✅ **SELECT**
   - **Target roles**: `public`, `authenticated`
   - **USING expression**:
   ```sql
   true
   ```
3. Click **Review** → **Save policy**

---

### Policy 3: Allow Users to Delete Own Files

1. Click **New Policy** → **For full customization**
2. Fill in:
   - **Policy name**: `Allow users to delete own files`
   - **Allowed operation**: Check ✅ **DELETE**
   - **Target roles**: `authenticated`
   - **USING expression**:
   ```sql
   auth.role() = 'authenticated'
   ```
3. Click **Review** → **Save policy**

---

### Repeat for All Buckets
You need to create these **3 policies** for **each of the 4 buckets**:
- ✅ `profile-images`
- ✅ `posts`
- ✅ `chat-images`
- ✅ `chat-audio`

**Total: 12 policies** (3 policies × 4 buckets)

---

## Method 3: Using Supabase CLI (Advanced)

If you have Supabase CLI installed:

```bash
# Create a file called policies.sql with the SQL from Method 1
supabase db push policies.sql
```

---

## Verify Your Policies

### Check if policies are working:

1. Go to **Storage** → Select any bucket
2. Click **Policies** tab
3. You should see 3 policies for each bucket:
   - ✅ `Allow authenticated uploads` (INSERT)
   - ✅ `Allow public read` (SELECT)
   - ✅ `Allow users to delete own files` (DELETE)

### Test Upload:
1. Try uploading a file through your Flutter app
2. If it works, policies are set correctly! ✅

---

## Troubleshooting

### Error: "new row violates row-level security policy"
- **Solution**: Make sure you're logged in (authenticated) when uploading
- Check that the policy definition is exactly as shown above

### Error: "permission denied for table storage.policies"
- **Solution**: You need to use the SQL Editor in Supabase dashboard (not a direct database connection)

### Files upload but can't be viewed
- **Solution**: Make sure the "Allow public read" policy is created with `SELECT` operation

### Can't delete files
- **Solution**: Verify the DELETE policy exists and user is authenticated

---

## What These Policies Do

| Policy | What it allows |
|--------|---------------|
| **Allow authenticated uploads** | Logged-in users can upload files to any bucket |
| **Allow public read** | Anyone (even not logged in) can view/download files |
| **Allow users to delete own files** | Logged-in users can delete files they uploaded |

---

## Security Notes

✅ **Safe**: Public read is OK because profile pictures and posts should be visible to everyone  
✅ **Safe**: Only authenticated users can upload (prevents spam)  
✅ **Safe**: Only authenticated users can delete (prevents vandalism)  

⚠️ **Note**: Currently, any authenticated user can delete any file. If you want users to only delete their own files, you'd need more complex policies checking file ownership.

---

## Next Steps

After setting up policies:
1. ✅ Test uploading a profile picture during signup
2. ✅ Test sending an image in chat
3. ✅ Test creating a post with image/video
4. ✅ Verify images display correctly in the app

---

## Need Help?

If you get stuck:
1. Check the Supabase logs: **Logs** → **Storage**
2. Verify buckets are created and set to **Public**
3. Make sure you're using the correct bucket names (no typos!)
4. Ensure your app has the correct Supabase URL and anon key

**Recommended**: Use **Method 1 (SQL Editor)** - it's the fastest and least error-prone! 🚀
