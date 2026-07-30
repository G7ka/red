# Penguin App - Wireframe Description for Google Sites

## App Overview
**Penguin** is an anonymous chat app where users start as anonymous penguins and can become friends after chatting. The app features voice calls (15 min/day limit), voice messages, photos, and video posts.

---

## Screen Flow & Navigation

### 1. **Welcome Screen** (Entry Point)
**Layout:**
- Full-screen gradient background (dark blue to darker blue)
- Centered logo: Large circular icon with gradient (purple to pink) containing heart icon
- App name: "Penguin" (large, white, bold)
- Tagline: "Anonymous penguin chats that become real only when you both choose."
- Bottom section with 3 buttons:
  - **"Continue with Google"** (primary purple button with login icon)
  - **"Sign up with Email"** (primary purple button with mail icon)
  - **"Already have an account? Log in"** (text link below)

**User Actions:**
- Tap Google sign-in → Auto-login → Navigate to HomeScreen
- Tap Sign up → Navigate to SignupScreen
- Tap Log in → Navigate to LoginScreen

---

### 2. **Signup Screen**
**Layout:**
- AppBar: "Sign up" title
- Scrollable form with fields:
  - First name (text input, required)
  - Last name (text input, optional)
  - Gender dropdown (Male/Female, required)
  - Date of birth (tap to open date picker, must be 18+, required)
  - Interests (comma-separated text input)
  - Email (text input, required)
  - Password (text input, min 6 chars, required)
  - **"Create account"** button (purple, full-width)
- Error message appears at top if signup fails

**User Actions:**
- Fill form → Tap "Create account" → Navigate to HomeScreen

---

### 3. **Login Screen**
**Layout:**
- AppBar: "Log in" title
- Form with:
  - Email field (text input)
  - Password field (text input, obscured)
  - **"Continue"** button (purple, full-width)
  - **"No account? Sign up"** text link below
- Error message appears if login fails

**User Actions:**
- Enter credentials → Tap "Continue" → Navigate to HomeScreen
- Tap "Sign up" → Navigate to SignupScreen

---

### 4. **Home Screen** (Main App Container)
**Layout:**
- Bottom Navigation Bar (4 tabs):
  1. **Anonymous** (bolt icon)
  2. **Chats** (chat bubble icon)
  3. **Feed** (video library icon)
  4. **Profile** (person icon)
- Content area shows selected tab (tabs persist state, don't rebuild)

**Navigation:**
- Tap tab → Switch to that tab's content
- All tabs share same bottom nav bar

---

### 5. **Anonymous Tab** (Tab 1)
**Layout:**
- AppBar: "Anonymous" title
- AppBar right: Notification bell icon (with red badge if unread count > 0)
- Center content:
  - Instruction text: "Tap start to search for an opposite-gender penguin who is also searching now."
  - Error message (if search fails, red text)
  - **"Start"** button (purple, or loading spinner if searching)

**User Actions:**
- Tap "Start" → Searches for match → If found, navigate to AnonymousChatScreen
- Tap notification icon → Navigate to NotificationsScreen

---

### 6. **Chats Tab** (Tab 2)
**Layout:**
- AppBar: "Chats" title
- ListView of chat items:
  - Each item shows:
    - Left: Circle avatar (purple background, penguin icon for anonymous, person icon for friends)
    - Title: "Anonymous penguin" or friend's display name
    - Subtitle: Last message preview (or "No messages")
  - Empty state: "No chats yet. Start an anonymous search!"

**User Actions:**
- Tap chat item → Navigate to AnonymousChatScreen (if anonymous) or FriendsChatScreen (if friend)

---

### 7. **Feed Tab** (Tab 3)
**Layout:**
- AppBar: "Feed" title
- AppBar right: "+" icon button (add post)
- ListView of video posts:
  - Each post card shows:
    - Top: User avatar + name
    - Video player (with play/pause overlay)
    - Post text below video
    - Bottom: Like icon + count, Comment icon + count
  - Empty state: "Add friends to see their posts!" or "No posts yet. Be the first to post!"

**User Actions:**
- Tap "+" → Navigate to CreatePostScreen
- Tap like → Toggle like
- Tap video → Play/pause

---

### 8. **Profile Tab** (Tab 4)
**Layout:**
- AppBar: "My profile" title
- AppBar right: Edit icon, Logout icon
- Scrollable content:
  - Center: Large profile picture (circle, purple background, camera icon overlay at bottom-right)
  - Display name (large, white, bold)
  - Age (if available)
  - "Interests:" section with chips (purple-tinted)
  - Divider
  - "My Posts" section
  - Grid of user's posts (3 columns, video/image icons)

**User Actions:**
- Tap edit icon → Open edit dialog (name change, once only)
- Tap camera icon → Pick profile picture
- Tap logout → Sign out → Navigate to WelcomeScreen

---

### 9. **Anonymous Chat Screen**
**Layout:**
- AppBar: "Anonymous penguin" title
- AppBar right: "Add friend" button (appears after 6+ messages), Exit icon
- Chat area:
  - ListView of messages:
    - Right-aligned (your messages): Dark bubble with white text
    - Left-aligned (their messages): Purple bubble with white text
    - Each shows text + seen indicator (small circle, purple if seen, white if not)
  - Empty state: "Start the conversation!"
- Bottom input bar:
  - Text field (rounded, dark)
  - Send button (purple icon)

**User Actions:**
- Type message → Tap send → Message appears
- After 6 messages → "Add friend" appears → Tap to send friend request
- Tap exit → Leave chat

---

### 10. **Friends Chat Screen**
**Layout:**
- AppBar: Friend's name as title
- AppBar right: Call icon (phone), Profile icon
- Chat area:
  - ListView of messages:
    - Text messages (right/left aligned bubbles)
    - Image messages (shows image thumbnail, 200x200)
    - Voice messages (play button + "Voice message (max 30s)" text)
    - Call log entries (WhatsApp-style):
      - Icon (call_made/call_received/call_missed)
      - Text: "Outgoing call • 03:15 • 2:05 PM" or "Outgoing call (not picked up)" or "Missed call"
      - Color: Red if missed, green/white if answered
  - Empty state: "No messages yet. Start chatting!"
- Bottom input bar:
  - Photo icon button (left)
  - Text field (expanded)
  - Mic icon button (red, shows "Xs" counter when recording, max 30s)
  - Send button (purple icon)

**User Actions:**
- Tap call icon → Check daily limit → Show usage dialog → Navigate to VoiceCallScreen
- Tap photo icon → Pick image → Send
- Tap mic → Start recording (shows timer) → Tap again to stop → Auto-send (max 30s)
- Type message → Tap send
- Tap voice message → Play audio
- Tap image → View full image

---

### 11. **Voice Call Screen**
**Layout:**
- Full-screen dark background
- Center content:
  - Large circle avatar (purple background, friend's first letter)
  - Friend's name (large, white)
  - Status: "Connected" or "Calling..." (white)
  - Big timer: "MM:SS" (white, large font)
  - Usage text: "Today: MM:SS / 15:00 used" (smaller, white)
- Bottom controls:
  - Mute button (grey circle, mic icon)
  - Red X button (red circle, close icon) - Cancel/End call

**User Actions:**
- Tap mute → Toggle mic on/off
- Tap red X → End call → Navigate back to FriendsChatScreen
- Call auto-ends if daily limit reached (shows dialog)

**Call Logging:**
- Creates call entry in chat when call starts
- Updates with status (answered/missed) and duration when call ends
- Shows in chat history as WhatsApp-style call log

---

### 12. **Create Post Screen**
**Layout:**
- AppBar: "Create Post" title
- Content:
  - Video preview area (if video selected):
    - Video player with controls
    - Duration indicator
  - Text field: "Write a caption..." (multi-line)
  - **"Choose Video (max 30s)"** button (if no video)
  - **"Post"** button (purple, full-width, bottom)

**User Actions:**
- Tap "Choose Video" → Pick video from gallery → Preview appears
- If video > 30s → Error message, must pick another
- Type caption → Tap "Post" → Post created → Navigate back to FeedTab

---

### 13. **Notifications Screen**
**Layout:**
- AppBar: "Notifications" title
- ListView of notifications:
  - Each item shows:
    - Icon (varies by type: friend_request, like, comment)
    - Title + body text
    - Timestamp
    - Unread indicator (if not read)
  - Empty state: "No notifications"

**User Actions:**
- Tap notification → Navigate to relevant screen (chat, post, etc.)

---

## Key Features & Behaviors

### Voice Calls
- **Daily Limit:** 15 minutes per day (resets every 24 hours)
- **Friends Only:** Only available in Friends Chat Screen
- **Usage Tracking:** Shows minutes used today before starting call
- **Call Logging:** Each call creates a chat message entry with:
  - Status: answered/missed/not picked up
  - Duration (if answered)
  - Timestamp
  - WhatsApp-style display in chat

### Voice Messages
- **Max Duration:** 30 seconds
- **Auto-stop:** Recording stops at 30s automatically
- **Visual Indicator:** Shows timer while recording
- **Playback:** Tap to play in chat

### Media Sharing
- **Photos:** Can send images in friends chat
- **Videos:** Can create 30-second video posts in feed

### Friend System
- **Anonymous → Friend:** After 6+ messages, can send friend request
- **Friend Requests:** Shown in notifications
- **Friends Chat:** Unlocks voice calls, photos, voice messages

---

## Color Scheme
- **Primary Purple:** #7C3AED
- **Background Dark:** #020617 (almost black)
- **Text White:** #FFFFFF
- **Text Grey:** #FFFFFF70 (70% opacity)
- **Error Red:** #FF5252
- **Call Red:** #F44336

---

## Navigation Flow Diagram

```
Welcome Screen
    ↓
[Google Sign-in] → HomeScreen
[Sign up] → SignupScreen → HomeScreen
[Log in] → LoginScreen → HomeScreen

HomeScreen (Bottom Nav)
    ├─ Anonymous Tab → [Start] → AnonymousChatScreen
    ├─ Chats Tab → [Tap Chat] → AnonymousChatScreen / FriendsChatScreen
    ├─ Feed Tab → [+] → CreatePostScreen
    └─ Profile Tab → [Edit] → Edit Dialog

FriendsChatScreen → [Call Icon] → VoiceCallScreen
FriendsChatScreen → [Photo/Mic] → Send Media
```

---

## Wireframe Notes for Google Sites

1. **Use rectangles/boxes** to represent screens
2. **Label each screen** with its name
3. **Show navigation arrows** between screens
4. **Include key UI elements** as labeled boxes:
   - AppBar (top bar)
   - Bottom Navigation (4 tabs)
   - Buttons (labeled)
   - Input fields (labeled)
   - Lists (show as repeating items)
5. **Color code:**
   - Purple for primary buttons
   - Dark background for screens
   - White for text areas
6. **Show user flow** with numbered steps or arrows
7. **Include call-to-action buttons** clearly labeled
8. **Show empty states** where applicable
9. **Indicate modals/dialogs** as overlays on screens

---

This description should give you everything needed to create detailed wireframes in Google Sites or any wireframing tool!





