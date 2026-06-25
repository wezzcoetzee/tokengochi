# Product

## Register

product

## Users

A single power user of Claude (developer / heavy Claude Code user) who wants an at-a-glance read of their own Anthropic subscription limits without leaving their workflow. They live in the menu bar all day, context-switch constantly, and check usage in passing, not in a dedicated session. Built clean enough to share with other Claude power users later. The job to be done: "tell me where I stand on session, weekly, and context limits, and make me feel something about it."

## Product Purpose

Tokengochi turns Claude usage limits into a virtual pet that lives in the menu bar (and, later, the notch). The 5-hour session window drives hunger, the weekly cap drives happiness, and accumulated usage shows as the creature's size. Neglect (wasting a session window under 20%) leaves a mess that can only be cleaned by coming back and using Claude. Success is a tool the user actually keeps in their menu bar: honest numbers, a glanceable read, and a creature whose state they check on reflexively because it has opinions about how they're doing.

## Brand Personality

Dry and deadpan. The creature is a companion with a flat affect and quiet sarcasm, not a needy, exclamation-mark mascot. It judges your usage more than it celebrates it. Voice: terse, understated, occasionally cutting, never bubbly. Three words: deadpan, observant, unbothered. Emotional goal: a wry smirk, not a dopamine hit. Copy is sparse and earns its keep; the humor lands because it's underplayed.

## Anti-references

- **Generic SaaS analytics dashboard**: the primary thing to avoid. No hero-metric template (big number + small label + supporting stats + gradient accent), no identical card grids, no gradient accents standing in for hierarchy, no "Insights" chrome. Usage is shown as the creature's lived state first, plain bars second, never as a metrics showcase.
- Corollary: resist the reflex to make a "usage tracker" look like every other usage tracker.

## Design Principles

- **The pet is the data.** Every visible trait of the creature maps to a real, current number. No decorative state, no theater. If it looks fed, it is fed. Honesty over flattery.
- **Dry, not cute.** Wit beats whimsy. The creature reacts with deadpan economy; it never begs, bounces, or over-emotes. Restraint is the personality.
- **Glanceable first, depth on click.** The menu-bar read must resolve in a fraction of a second. Detail and game mechanics live one click deeper, never crowding the glance.
- **Earned consequences.** Game state follows real behavior: using more is rewarded, neglect is the only failure, and recovery requires genuine usage. Never gamify dishonestly or nag for engagement the data doesn't justify.
- **Calm by default, loud on purpose.** Motion is rare punctuation reserved for genuine milestones, not ambient decoration. Stillness is the resting state.

## Accessibility & Inclusion

Target WCAG 2.2 AA for the popover and any text surfaces. Honor the system Reduce Motion setting: milestone and notch animations degrade to a quiet, instant state change when it's on, and ambient motion is suppressed. Never rely on color alone to convey state: mood is always carried by an explicit text label and the creature's facial expression, and health / mess by numerals and icons, so the green-to-orange shift is reinforcement, not the only signal. Maintain legible contrast for the LCD palette's text on its dark background.
