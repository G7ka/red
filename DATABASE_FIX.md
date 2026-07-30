# How to Fix the Database Schema Error

## Problem
You're getting a PostgreSQL error: `could not find profile_images column`

This means your Supabase database doesn't have the `profile_images` column yet.

## Solution

### Step 1: Go to Supabase Dashboard
1. Open [supabase.com](https://supabase.com)
2. Select your project
3. Click **SQL Editor** in the left sidebar

### Step 2: Run the Migration
1. Click **New Query**
2. Copy and paste this SQL code:

```sql
-- Add profile_images column to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS profile_images TEXT[];

-- Add a comment to document the column
COMMENT ON COLUMN users.profile_images IS 'Array of profile image URLs (up to 4 images)';

-- Set default empty array for existing users
UPDATE users 
SET profile_images = ARRAY[]::TEXT[] 
WHERE profile_images IS NULL;
```

3. Click **Run** (or press `Ctrl+Enter`)
4. You should see "Success. No rows returned"

### Step 3: Verify
1. Go to **Table Editor** in the left sidebar
2. Click on the `users` table
3. You should now see a `profile_images` column

### Step 4: Test in Your App
1. Hot reload your app (`r` in terminal)
2. Try uploading profile pictures again
3. It should work now!

## Alternative: Use Supabase CLI (Advanced)

If you have Supabase CLI installed:

```bash
cd e:\flutter_projects\penguin_app
supabase db push
```

This will automatically apply the migration file I created in `supabase/migrations/`.

## What This Column Does

- **Type**: Array of text (TEXT[])
- **Purpose**: Stores up to 4 profile image URLs
- **Example**: `["https://..../image0.jpg", "https://..../image1.jpg", "https://..../image2.jpg"]`

After running this migration, you'll be able to upload and display multiple profile pictures!
