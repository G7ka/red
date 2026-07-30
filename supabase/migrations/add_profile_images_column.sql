-- Migration: Add profile_images column to users table
-- This column stores an array of image URLs for user profile pictures

-- Add the profile_images column
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS profile_images TEXT[];

-- Add a comment to document the column
COMMENT ON COLUMN users.profile_images IS 'Array of profile image URLs (up to 4 images)';

-- Optional: Set a default empty array for existing users
UPDATE users 
SET profile_images = ARRAY[]::TEXT[] 
WHERE profile_images IS NULL;
