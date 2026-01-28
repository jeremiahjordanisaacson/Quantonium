# Quantonium Brand Guidelines

## Brand Identity

### Name
**Quantonium** - A fusion of "Quantum" (representing cutting-edge technology, infinite possibilities) and the suffix "-ium" (suggesting an element, a fundamental building block).

### Tagline
*"The Future of Desktop Linux"*

Alternative taglines:
- "Where Power Meets Elegance"
- "Computing, Evolved"
- "Your Universe, Your Rules"

### Brand Personality
- **Innovative** - Always pushing boundaries
- **Elegant** - Refined, sophisticated, beautiful
- **Powerful** - Capable, professional-grade
- **Accessible** - Welcoming to all skill levels
- **Trustworthy** - Stable, secure, reliable

---

## Color System

### Primary Palette

#### Quantum Purple (Primary Brand Color)
```
HEX: #6B4C9A
RGB: 107, 76, 154
HSL: 264°, 34%, 45%
```
Used for: Logo, primary buttons, active states, brand elements

#### Deep Space (Dark Background)
```
HEX: #1A1A2E
RGB: 26, 26, 46
HSL: 240°, 28%, 14%
```
Used for: Dark mode backgrounds, sidebars, headers

#### Void Black (Deepest Dark)
```
HEX: #0D0D14
RGB: 13, 13, 20
HSL: 240°, 21%, 6%
```
Used for: OLED dark mode, terminal backgrounds, deepest UI layers

### Accent Colors

#### Nebula Cyan (Primary Accent)
```
HEX: #00D9FF
RGB: 0, 217, 255
HSL: 189°, 100%, 50%
```
Used for: Links, highlights, focus indicators, notifications

#### Cosmic Pink (Secondary Accent)
```
HEX: #FF6B9D
RGB: 255, 107, 157
HSL: 340°, 100%, 71%
```
Used for: Alerts, special features, warmth accents

#### Aurora Green (Success)
```
HEX: #00E676
RGB: 0, 230, 118
HSL: 151°, 100%, 45%
```
Used for: Success states, confirmations, positive actions

#### Solar Orange (Warning)
```
HEX: #FF9100
RGB: 255, 145, 0
HSL: 34°, 100%, 50%
```
Used for: Warnings, caution states

#### Nova Red (Error/Danger)
```
HEX: #FF4757
RGB: 255, 71, 87
HSL: 355°, 100%, 64%
```
Used for: Errors, destructive actions, critical alerts

### Neutral Colors

#### Starlight (Light Mode Background)
```
HEX: #E8E8F0
RGB: 232, 232, 240
HSL: 240°, 20%, 93%
```

#### Moonlight (Light Mode Surface)
```
HEX: #F5F5FA
RGB: 245, 245, 250
HSL: 240°, 33%, 97%
```

#### Cosmic Gray 100-900 Scale
```
100: #F8F8FC (Lightest)
200: #E8E8F0
300: #D0D0DC
400: #A0A0B8
500: #707088
600: #505068
700: #383850
800: #252538
900: #16161F (Darkest)
```

---

## Typography

### Primary Font: Inter
A modern, highly legible sans-serif optimized for screens.

```
Headings: Inter Bold (700)
Subheadings: Inter SemiBold (600)
Body: Inter Regular (400)
UI Labels: Inter Medium (500)
```

### Monospace Font: JetBrains Mono
For code, terminal, and technical content.

```
Code: JetBrains Mono Regular (400)
Terminal: JetBrains Mono Medium (500)
```

### Font Sizes (rem scale)
```
Display Large: 3.5rem (56px)
Display: 2.5rem (40px)
Heading 1: 2rem (32px)
Heading 2: 1.5rem (24px)
Heading 3: 1.25rem (20px)
Heading 4: 1.125rem (18px)
Body Large: 1.125rem (18px)
Body: 1rem (16px)
Body Small: 0.875rem (14px)
Caption: 0.75rem (12px)
Overline: 0.625rem (10px)
```

---

## Logo

### Primary Logo
The Quantonium logo consists of:
1. **Logomark** - A stylized "Q" formed by an orbital ring around a nucleus
2. **Wordmark** - "Quantonium" in custom-spaced Inter Bold

### Logo Variations
- **Full Logo** - Logomark + Wordmark (horizontal)
- **Stacked Logo** - Logomark above Wordmark
- **Logomark Only** - For small spaces, favicons
- **Wordmark Only** - For text-heavy contexts

### Logo Colors
- Primary: Quantum Purple (#6B4C9A)
- On Dark: White (#FFFFFF) or Nebula Cyan (#00D9FF)
- On Light: Deep Space (#1A1A2E) or Quantum Purple (#6B4C9A)
- Monochrome: White or Black depending on background

### Clear Space
Minimum clear space around logo = height of the "Q" in the wordmark

### Minimum Sizes
- Full logo: 120px wide minimum
- Logomark: 24px minimum
- Favicon: 16px, 32px, 48px

---

## Iconography

### Icon Style
- **Stroke-based** with 1.5px stroke weight at 24px
- **Rounded caps and joins** (4px radius at 24px)
- **Consistent optical sizing**
- **Filled variants** for active/selected states

### Icon Grid
- 24x24px base grid
- 2px padding from edge
- Keyline shapes: Circle (20px), Square (18px), Vertical Rectangle (18x20px), Horizontal Rectangle (20x18px)

### Icon Colors
- Default: Cosmic Gray 600 (#505068)
- Active: Quantum Purple (#6B4C9A)
- Disabled: Cosmic Gray 400 (#A0A0B8)
- On colored backgrounds: White (#FFFFFF)

---

## Gradients

### Primary Gradient (Quantum Glow)
```css
background: linear-gradient(135deg, #6B4C9A 0%, #00D9FF 100%);
```

### Secondary Gradient (Cosmic Dawn)
```css
background: linear-gradient(135deg, #6B4C9A 0%, #FF6B9D 100%);
```

### Dark Background Gradient (Deep Space)
```css
background: linear-gradient(180deg, #1A1A2E 0%, #0D0D14 100%);
```

### Accent Gradient (Nebula)
```css
background: linear-gradient(135deg, #00D9FF 0%, #FF6B9D 100%);
```

---

## Shadows & Elevation

### Elevation Scale (Dark Mode)
```css
/* Level 0 - Flat */
box-shadow: none;

/* Level 1 - Raised */
box-shadow: 0 1px 3px rgba(0, 0, 0, 0.4), 0 1px 2px rgba(0, 0, 0, 0.3);

/* Level 2 - Floating */
box-shadow: 0 4px 6px rgba(0, 0, 0, 0.4), 0 2px 4px rgba(0, 0, 0, 0.3);

/* Level 3 - Overlay */
box-shadow: 0 10px 20px rgba(0, 0, 0, 0.5), 0 6px 6px rgba(0, 0, 0, 0.4);

/* Level 4 - Modal */
box-shadow: 0 20px 40px rgba(0, 0, 0, 0.6), 0 15px 12px rgba(0, 0, 0, 0.4);
```

### Glow Effects
```css
/* Accent Glow */
box-shadow: 0 0 20px rgba(0, 217, 255, 0.3);

/* Primary Glow */
box-shadow: 0 0 20px rgba(107, 76, 154, 0.4);

/* Focus Glow */
box-shadow: 0 0 0 3px rgba(0, 217, 255, 0.4);
```

---

## Border Radius

### Radius Scale
```
None: 0
Small: 4px (buttons, inputs, small cards)
Medium: 8px (cards, dialogs)
Large: 12px (panels, large cards)
XLarge: 16px (modals, popovers)
Full: 9999px (pills, avatars)
```

---

## Motion & Animation

### Duration Scale
```
Instant: 0ms (state changes)
Fast: 100ms (micro-interactions)
Normal: 200ms (standard transitions)
Slow: 300ms (complex animations)
Slower: 500ms (page transitions)
```

### Easing Functions
```css
/* Standard - for most transitions */
ease-out: cubic-bezier(0.0, 0.0, 0.2, 1);

/* Decelerate - for entering elements */
ease-in: cubic-bezier(0.4, 0.0, 1, 1);

/* Accelerate - for exiting elements */
ease-in-out: cubic-bezier(0.4, 0.0, 0.2, 1);

/* Bounce - for playful interactions */
bounce: cubic-bezier(0.68, -0.55, 0.265, 1.55);
```

---

## Voice & Tone

### Writing Style
- **Clear** - Simple language, no jargon
- **Friendly** - Warm but professional
- **Confident** - Assured, not arrogant
- **Helpful** - Solution-oriented

### Examples

**Good:**
- "Your system is up to date."
- "Would you like to restart now?"
- "Something went wrong. Let's try that again."

**Avoid:**
- "Update process completed successfully with zero errors."
- "Initiate system restart sequence?"
- "Fatal error: Exception thrown in module."

---

## Application

### System Areas
- **Boot Screen** - Minimal, logo centered, progress indicator with Nebula Cyan
- **Login Screen** - Wallpaper blur, centered login form, subtle animations
- **Desktop** - Clean, organized, consistent spacing
- **Settings** - Sidebar navigation, clear hierarchy
- **File Manager** - Efficient layout, clear icons
- **Terminal** - Void Black background, syntax highlighting with palette

### Do's
- Maintain consistent spacing (8px grid)
- Use the color palette purposefully
- Ensure sufficient contrast (WCAG AA minimum)
- Test on both light and dark modes

### Don'ts
- Don't use colors outside the palette
- Don't mix rounded and sharp corners
- Don't use more than 3 levels of visual hierarchy
- Don't animate everything - be purposeful

---

*These guidelines ensure Quantonium presents a unified, professional, and beautiful experience across all touchpoints.*
