---
name: penguin-ui
description: Enforces the Penguin app's clean purple design system for Flutter widgets. Use when building or modifying any UI screen in the Penguin app.
---

# Penguin UI Design System

## When to Use
Use this skill when creating or modifying any Flutter screen/widget in the Penguin app.

## Color Palette
- **Background (screens):** `Color(0xFF0A0A0F)` — near-black
- **Background (nav/system):** `Color(0xFF020617)` — dark blue-black
- **Cards/surfaces:** `Color(0xFF1A1A2E)` — dark navy
- **Drawer:** `Color(0xFF1E0B36)` — dark purple
- **Primary accent:** `Color(0xFF7C3AED)` — purple
- **Secondary accent:** `Color(0xFF6D28D9)` — deeper purple (for gradients)
- **Text primary:** `Colors.white`
- **Text secondary:** `Colors.white.withOpacity(0.6)`
- **Text tertiary:** `Colors.white.withOpacity(0.4)`
- **Borders/dividers:** `Colors.white.withOpacity(0.06)`

## Forbidden Patterns
- **NO neon glows** — Never use `spreadRadius > 0` on boxShadow
- **NO pink gradients** — Do NOT use `Color(0xFFDB2777)` in gradients. Use purple-to-deeper-purple: `[Color(0xFF7C3AED), Color(0xFF6D28D9)]`
- **NO particle systems** — No `CustomPainter` for floating particles
- **NO sweep gradients** — No rotating rainbow/sweep gradient animations
- **NO heart icons** for search — Use penguin-themed icons (`Icons.pets`)
- **Button shadows max:** `blurRadius: 8`, `opacity: 0.15`, `spreadRadius: 0`

## Allowed Patterns
- Subtle depth shadows: `BoxShadow(color: Color.withOpacity(0.1), blurRadius: 8, offset: Offset(0, 4))`
- Solid purple buttons with `Color(0xFF7C3AED)` background
- Purple-to-deep-purple gradients: `[Color(0xFF7C3AED), Color(0xFF6D28D9)]`
- Concentric circle pulse animations (for search states)
- Clean card layouts with `Color(0xFF1A1A2E)` background
- Staggered fade/slide entrance animations

## Typography
- Titles: `fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.3`
- Subtitles: `fontSize: 15, color: Colors.white.withOpacity(0.6)`
- Body: `fontSize: 14, color: Colors.white.withOpacity(0.7)`
- Labels: `fontSize: 12, fontWeight: FontWeight.w600`

## Spacing (8pt grid)
- Screen padding: `EdgeInsets.symmetric(horizontal: 24)`
- Card padding: `EdgeInsets.all(20)`
- Section gaps: `SizedBox(height: 24)`
- Element gaps: `SizedBox(height: 8)` or `SizedBox(height: 16)`

## Border Radius
- Cards: `BorderRadius.circular(16)`
- Buttons: `BorderRadius.circular(12)` (standard) or `BorderRadius.circular(28)` (pill)
- Chips/badges: `BorderRadius.circular(8)`
