---
name: Tokengochi
description: A dead-eyed 90s LCD handheld that judges your Claude usage from the menu bar
colors:
  dot-matrix-green: "#9CBD0F"
  screen-off-green: "#0F380F"
  faded-phosphor: "#CFE04F"
  overfed-amber: "#FFCC3D"
  queasy-orange: "#FF8A5C"
  low-battery-green: "#668A12"
  scanline: "#0000002E"
typography:
  title:
    fontFamily: "-apple-system, 'SF Pro Text', system-ui, sans-serif"
    fontSize: "13px"
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: "normal"
  body:
    fontFamily: "ui-monospace, 'SF Mono', Menlo, monospace"
    fontSize: "11px"
    fontWeight: 500
    lineHeight: 1.3
    letterSpacing: "normal"
  label:
    fontFamily: "ui-monospace, 'SF Mono', Menlo, monospace"
    fontSize: "10px"
    fontWeight: 700
    lineHeight: 1.3
    letterSpacing: "0.02em"
rounded:
  screen: "10px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "10px"
  lg: "12px"
  content: "14px"
components:
  lcd-screen:
    backgroundColor: "{colors.screen-off-green}"
    rounded: "{rounded.screen}"
    padding: "{spacing.md}"
  lcd-readout:
    textColor: "{colors.dot-matrix-green}"
    typography: "{typography.label}"
---

# Design System: Tokengochi

## 1. Overview

**Creative North Star: "The Pocket Conscience"**

Tokengochi is a 1990s monochrome LCD handheld that someone left running in your menu bar. It has exactly one screen, a fixed phosphor-green palette, and an unbothered opinion about how much Claude you're using. The aesthetic is not "retro-inspired" or "pixel-flavored", it is a literal dead-matrix LCD: dot-matrix green glowing on a dark powered-on backdrop, raked by faint scanlines, bezeled by a thick dark border. The creature inside it is the entire interface; the numbers are its vital signs, not a readout panel.

The system runs on a hard split. Inside the LCD "screen" everything obeys the phosphor palette and a strict monospace grid, because that surface is a fictional device. Everything around it, the popover frame, the title, the bars, the buttons, is honest native macOS chrome that doesn't pretend to be anything. The retro never leaks out of the screen, and the OS never leaks in. This is what keeps it from reading as a costume.

It explicitly rejects the generic SaaS analytics dashboard: no hero-metric template (big number, small label, supporting stats, gradient sheen), no identical card grids, no gradient accents standing in for hierarchy, no "Insights" chrome. Usage is the creature's lived state first and a plain bar second; it is never staged as a metrics showcase. The tone is deadpan, the motion is near-zero, and the personality is carried by restraint, not animation.

**Key Characteristics:**
- One fictional LCD screen, sealed off from native macOS chrome around it.
- A fixed five-state phosphor palette; mood is a color, an expression, and a word, never color alone.
- Monospace for every number; system sans only for the one chrome title.
- Flat by doctrine: depth comes from the dark bezel and scanlines, never shadows.
- Deadpan and still at rest; the screen earns attention by what it says, not by moving.

## 2. Colors

A sealed phosphor palette borrowed from a dead handheld: one live green, one near-black backdrop, and three warning tints the creature shifts into as its state degrades.

### Primary
- **Dot-Matrix Green** (`#9CBD0F`): The live phosphor. The creature's healthy body, every lit pixel of the readouts (HUN / HAP meters, the mood word), and the only "on" color. This is the screen at rest.

### Secondary
- **Faded Phosphor** (`#CFE04F`): The "OKAY" middle state. A paler, washed-out green-yellow for a creature that's fine but unremarkable. Deliberately less saturated than Dot-Matrix Green so "okay" reads as lower-energy than "thriving".
- **Overfed Amber** (`#FFCC3D`): The "STUFFED" state, when a limit is maxed (~95%+) and the creature is napping it off. Warm, sated, not alarmed; maxing out is earned, not punished.
- **Queasy Orange** (`#FF8A5C`): The "SICK" state, when uncleaned mess has drained Health below 40%. The only genuinely alarming color in the system. Its rarity is the warning.

### Neutral
- **Screen-Off Green** (`#0F380F`): The powered-on-but-dark LCD backdrop, the bezel border, and the "holes" punched for eyes and mouth. Everything dark in the screen is this, never black.
- **Low-Battery Green** (`#57750D`): The "NO DATA" creature, a dimmed, half-lit green for when no Claude session has reported in yet. Reads as "asleep / not reporting", distinct from any active mood.
- **Scanline** (`#0000002E`): 18% black, drawn as 2px horizontal lines on a 4px pitch across the whole screen. Atmosphere only; never a content color.
- **Native macOS chrome**: The popover background, the title, the stat labels, the freshness line, and the buttons all inherit the system's dynamic label / secondary-label / control colors. These are intentionally NOT tokenized; they must track light/dark mode and accent settings.

### Named Rules
**The Single-Screen Rule.** The phosphor palette lives only inside the LCD screen. The popover frame, bars, and buttons stay native macOS chrome. Never tint OS-level UI green, and never render the screen in system colors. The boundary between the fictional device and the real OS is load-bearing.

**The Five-State Rule.** The creature is only ever Dot-Matrix Green, Faded Phosphor, Overfed Amber, Queasy Orange, or Low-Battery Green. No sixth body color exists. A new mood reuses an existing phosphor state; it does not introduce a hue.

## 3. Typography

**Display Font:** none. The system has no display tier; the largest text is the popover title.
**Body / Data Font:** SF Mono (`ui-monospace`, fallback Menlo, monospace)
**Title Font:** SF Pro Text (`-apple-system`, system-ui, sans-serif)

**Character:** Monospace does the work because every glyph that matters is a number or a fixed-width readout, and the block-character meters (`HUN ████░░░░`) only align in a mono grid. The lone system-sans title is a deliberate piece of native chrome, a reminder that this is a Mac app, not the device talking.

### Hierarchy
- **Title** (SF Pro, 600, 13px, 1.2): The single chrome heading "Tokengochi" at the top of the popover. The only sans-serif in the product.
- **Body** (SF Mono, 500, 11px, 1.3): Stat-row labels and values (Session / Weekly / Context, the percentages), the Health and mess line. The data layer.
- **Label** (SF Mono, 700, 10px, +0.02em): The in-screen LCD readouts, the HUN / HAP block meters and the all-caps mood word. Bold and slightly tracked so it reads as etched into the phosphor.

### Named Rules
**The Monospace-Is-Data Rule.** Every number, percentage, and machine-readable readout is set in SF Mono. System sans is permitted for exactly one thing: the chrome title. If a new number appears in sans, it is wrong.

**The All-Caps Readout Rule.** In-screen status words (HUN, HAP, OKAY, SICK, STUFFED) are uppercase monospace. This is device language, not prose; never sentence-case the screen.

**The Fixed-Screen-Type trade-off.** In-screen LCD text uses fixed point sizes (10/14pt) and does not scale with Dynamic Type, because the block-character meters only align on a fixed mono grid and the screen is a fixed-size fictional device. This is deliberate. Accessibility is preserved off-screen: the native chrome (Title, Body) uses scalable text styles, the session percentage is mirrored in the menu-bar label, and the full creature state is exposed in the screen's VoiceOver label.

## 4. Elevation

Flat by doctrine. The system uses zero `box-shadow`. Depth inside the screen is an illusion built from two cheap tricks a real LCD would use: a thick (4px) Screen-Off Green bezel around the rounded screen, and the scanline overlay that makes the surface feel like glass with something glowing behind it. The pixel creature reads as "inset" because its eyes and mouth are holes punched to the backdrop color, not shaded.

The one real shadow in the experience is the macOS popover's own system drop shadow, which is the OS's, not ours. We don't add to it.

### Named Rules
**The Flat-Screen Rule.** No shadows, ever, inside the app's own surfaces. If something needs to feel recessed or raised, do it with the bezel, the scanlines, or punched-hole contrast, never with a blur. A drop shadow on the LCD would break the illusion that it is a screen.

## 5. Components

### LCD Screen (signature component)
- **Character:** The fictional device. A self-contained rounded rectangle that holds the entire creature experience; everything retro happens here and nowhere else.
- **Shape:** 10px radius (`{rounded.screen}`), wrapped in a 4px Screen-Off Green bezel (`strokeBorder`), fixed 220×152.
- **Background:** Screen-Off Green (`#0F380F`) with the Scanline overlay drawn on top.
- **Internal layout:** HUN / HAP meters pinned top-left and top-right, creature centered in a fixed 84px band, mood word centered at the bottom. Internal padding 10px (`{spacing.md}`).
- **Shadow Strategy:** none. See The Flat-Screen Rule.

### Pixel Creature
- **Character:** The product. A chunky dot-matrix blob with feet, rendered as literal square cells on a 16-column grid.
- **Body:** Filled in the current mood phosphor (Dot-Matrix Green / Faded Phosphor / Overfed Amber / Queasy Orange / Low-Battery Green). Size scales with accumulated usage (cell size grows with weight); a fatter creature means more tokens spent.
- **Face:** Eyes and mouth are cells punched to Screen-Off Green. Expression is state-driven, not decorative: smile (thriving / okay), frown (lonely / starving), queasy open mouth (sick), closed eyes (stuffed / napping).
- **Mess:** 💩 glyphs appear bottom-left, one per wasted session window, capped at four shown.
- **Motion:** dormant and still by default. Subtle life (breathing, blinking, sway, bounce, sparkle) is *earned*: each tier unlocks at a weekly-usage peak threshold, so motion is a readout of real usage, not decoration. A light week leaves the creature still; a heavy week earns it a heartbeat. All ambient motion is suppressed when Reduce Motion is on, collapsing to a static frame. Milestone punctuation (the "bonk") still lives in the notch overlay, not here.

### Stat Rows
- **Character:** The honest data layer beneath the device. Plain, native, unstyled-on-purpose.
- **Style:** A monospace label + right-aligned percentage (Body type), above a native `ProgressView` bar in the system accent color. Three rows: Session, Weekly, Context.
- **Crucial restraint:** these are deliberately NOT cards and NOT a metric dashboard. No backgrounds, no borders, no gradient fills. A label, a number, a bar.

### Buttons
- **Style:** Native macOS push buttons (Refresh, Quit). No custom styling. They are chrome and should look like the OS.

### Menu Bar Item
- **Style:** A single line, mood emoji + session percentage (e.g. `🙂 32%`), or `🥚 —` when no data. System font, system menu-bar treatment. The glanceable read; everything else is one click deeper.

## 6. Do's and Don'ts

### Do:
- **Do** keep the phosphor palette sealed inside the LCD screen (The Single-Screen Rule); let the popover, bars, and buttons stay native macOS chrome. Chrome emphasis (the help toggle, active help rows, the "● now" marker) uses the **system accent color**, never a phosphor green, so it adapts to light/dark and meets contrast.
- **Do** set every number and readout in SF Mono (The Monospace-Is-Data Rule).
- **Do** convey mood with three reinforcing signals at once: body color, facial expression, and the uppercase mood word, so the state survives color blindness and never depends on the green-to-orange shift alone.
- **Do** keep the resting state still. Motion is rare punctuation reserved for genuine milestones, and degrades to an instant state change when Reduce Motion is on.
- **Do** show usage as the creature's lived state first and a plain bar second.
- **Do** tint every dark pixel toward Screen-Off Green (`#0F380F`); never use pure `#000`.
- **Do** convey alarm in native chrome (the Health line below 40%) with the **system semantic red**, reinforced by the heart icon and numeral. Queasy Orange is a phosphor state and stays inside the screen.
- **Do** honor Reduce Motion: ambient creature tiers collapse to a static frame, and the popover backs off its 5s refresh poll to 30s while closed.

### Don't:
- **Don't** build the generic SaaS analytics dashboard: no hero-metric template (big number + small label + supporting stats + gradient accent), no identical card grids, no "Insights" chrome. This is the primary anti-reference.
- **Don't** wrap the stat rows in cards or give them borders or background fills. A label, a number, a bar.
- **Don't** add a sixth creature color or a gradient body; reuse one of the five phosphor states (The Five-State Rule).
- **Don't** put a `box-shadow` on any in-app surface (The Flat-Screen Rule); fake depth with the bezel and scanlines.
- **Don't** use `border-left` / `border-right` greater than 1px as a colored accent stripe on any element.
- **Don't** let the creature emote like a needy mascot: no unearned cheer, no exclamation-mark theatrics, no motion that doesn't map to a real usage threshold. The earned animation tiers are deadpan and slow; the resting state is genuinely still.
- **Don't** render in-screen status words in sentence case or in a proportional font.
