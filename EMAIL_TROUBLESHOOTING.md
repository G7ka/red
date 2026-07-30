# Email Verification Troubleshooting

## Issue: Not Receiving Verification Emails

If you're not receiving the verification code email, here are the most common causes and solutions:

### 1. **Supabase Email Configuration Not Complete**

**Most Likely Cause**: Supabase requires SMTP configuration for production use.

#### Check Your Supabase Email Settings:

1. Go to **Supabase Dashboard** → Your Project
2. Click **Authentication** → **Settings**
3. Scroll to **SMTP Settings**

#### Default Behavior (Development):
- Supabase uses a **development email service** by default
- Emails may be **delayed** or **not sent at all**
- Check your **Supabase Dashboard** → **Authentication** → **Users** to see if the user was created

#### Solution: Configure Custom SMTP

You need to set up your own email service:

**Option A: Use Gmail SMTP (Free)**
```
SMTP Host: smtp.gmail.com
SMTP Port: 587
SMTP User: your-email@gmail.com
SMTP Password: [App Password - not your regular password]
Sender Email: your-email@gmail.com
Sender Name: Penguin App
```

**How to get Gmail App Password:**
1. Go to Google Account → Security
2. Enable 2-Step Verification
3. Go to App Passwords
4. Generate password for "Mail"
5. Use this password in Supabase SMTP settings

**Option B: Use SendGrid (Recommended for Production)**
- Free tier: 100 emails/day
- More reliable than Gmail
- Better deliverability

**Option C: Use Resend (Modern Alternative)**
- Free tier: 3,000 emails/month
- Very easy setup
- Great for developers

### 2. **Email Template Issue**

Make sure you updated the email template correctly:

1. Go to **Authentication** → **Email Templates**
2. Edit **"Confirm signup"** template
3. Verify it contains: `{{ .Token }}`
4. Save changes

### 3. **Email Confirmation Method**

1. Go to **Authentication** → **Settings**
2. Find **Email confirmation method**
3. Make sure it's set to **"OTP"** (not "Magic Link")

### 4. **Check Spam/Junk Folder**

Even with proper SMTP, emails can land in spam:
- Check your spam/junk folder
- Mark as "Not Spam" if found there

### 5. **Verify Email in Supabase Dashboard**

**Quick Test** (Development Only):
1. Go to **Authentication** → **Users**
2. Find your newly created user
3. Click the user
4. Manually set **Email Confirmed At** to current timestamp
5. User can now log in without email verification

**⚠️ Warning**: Only use this for testing. Always require email verification in production.

### 6. **Alternative: Disable Email Confirmation (Development Only)**

For development/testing purposes:
1. Go to **Authentication** → **Settings**
2. Toggle OFF **"Enable email confirmations"**
3. Users can sign up and log in immediately

**⚠️ Critical**: Re-enable this before going to production!

## Recommended Setup for Production

1. **Set up custom SMTP** (SendGrid or Resend recommended)
2. **Configure email templates** with your branding
3. **Test with real email addresses**
4. **Monitor email delivery** in your SMTP provider dashboard
5. **Keep email confirmation enabled**

## Quick Debug Steps

1. **Check if user was created**: Supabase Dashboard → Authentication → Users
2. **Check SMTP logs**: Your SMTP provider dashboard (if configured)
3. **Test with different email**: Try Gmail, Outlook, Yahoo
4. **Check Supabase logs**: Dashboard → Logs → Auth logs

## Current Status

Your app is configured to use Supabase's default email service, which may not send emails reliably. **You must configure custom SMTP for production use.**
