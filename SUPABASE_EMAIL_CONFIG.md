# Supabase Email Configuration for OTP

## Problem
Supabase is sending magic links instead of 6-digit OTP codes for email verification.

## Solution
You need to configure Supabase to use OTP instead of magic links.

### Steps:

1. **Go to Supabase Dashboard**
   - Navigate to your project at [supabase.com](https://supabase.com)

2. **Open Authentication Settings**
   - Click **Authentication** in the left sidebar
   - Click **Email Templates**

3. **Configure Email Templates**
   - Find **"Confirm signup"** template
   - Click **Edit**

4. **Change Template to Use OTP**
   
   Replace the template content with:

   ```html
   <h2>Confirm your signup</h2>
   <p>Follow this link to confirm your email:</p>
   <p><a href="{{ .ConfirmationURL }}">Confirm your email</a></p>
   <p>Or enter this code in the app:</p>
   <h1>{{ .Token }}</h1>
   <p>This code expires in 24 hours.</p>
   ```

5. **Enable OTP in Auth Settings**
   - Go to **Authentication** → **Settings**
   - Scroll to **Email Auth**
   - Make sure **Enable email confirmations** is ON
   - Set **Email confirmation method** to **OTP** (not Magic Link)

6. **Save Changes**

### Alternative: Disable Email Confirmation (Development Only)

If you want to skip email verification during development:

1. Go to **Authentication** → **Settings**
2. Scroll to **Email Auth**
3. Toggle OFF **Enable email confirmations**
4. Users will be able to sign in immediately without verification

**⚠️ Warning**: Only use this for development. Always enable email confirmation in production.

### Testing

After configuration:
1. Sign up with a new email
2. You should receive an email with a 6-digit code
3. Enter the code in the app's verification screen
