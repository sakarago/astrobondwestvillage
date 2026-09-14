# AstroBond West Village — V1 Product Brief

**Status:** agreed direction (2026-09-14)  
**Goal:** Ship a **new UI codebase** that implements the product, talking to the **existing Supabase backend**. Early prototype UI is reference-only — not copied.

**Team narrative (internal):** Design intent from E (paper). Backend/product engineering from Salih. Production UI rebuilt by the continuing team with a new visual system. Feature ideas are common in-category + our own rules.

---

## Principles

1. **New UI project** — do not port old SwiftUI views/components.
2. **Keep Supabase** — auth, profiles, birth_data, charts, reveals, messaging RPCs/RLS.
3. **Obvious redesign** — new layout, materials (crystal glass / depth), navigation polish.
4. **Slim V1** — TestFlight-ready loop first; niceties later.
5. **Build from this brief + E’s paper**, not from the old repo’s view tree.

---

## V1 user loop (must work)

1. Splash → Welcome → Auth (email; Apple later if needed)
2. Onboarding: birth data → profile basics (name, gender, prefs, cartoon or photo) → chart ready
3. Main tabs: **Discover (light)** · **Match** · **Messages** · **Profile**
4. Match: spin/reveal → bond story → accept/reject → accepted opens messaging path
5. Messages: inbox → chat (text)
6. Profile: big-three + natal wheel + settings/sign out

---

## Screens (V1)

| Area | Screens | Notes |
|------|---------|--------|
| Entry | Splash, Welcome, Login, Register | New composition; brand-first welcome |
| Onboarding | Birth date/time/place, Gender + prefs, Avatar/photo, Calculating, Done | Same data fields as backend expects |
| Discover | Simple home / insight teaser | Can be thin in V1 |
| Match | Wheel/reveal, Match detail (bond + synastry summary), Prefs sheet | Core product |
| Messages | Conversation list, Chat | Text only |
| Profile | Astral profile, Chart (wheel + table), Settings | Chart from stored JSON / on-device calc |

**Out of V1 (explicit):** moderation polish, rich admin, multi-photo gallery, astrologer chat (mark as V1.1+), heavy Discover marketing pages.

---

## Product rules (keep / encode)

| Rule | V1 behavior |
|------|-------------|
| Daily reveals | ~3 / day (server `reveal_match`) |
| Never repeat | Once revealed, not a *new* candidate again |
| Connected users | Exclude people you already message / mutual reveal path |
| Gender prefs | Collected in onboarding; filter candidates |
| Messaging | Text, max length ~500; daily send cap ~10 |
| Photo unlock | **Real profile photo visible only after N messages** (default **10** in a conversation) — new UX rule; cartoon/initials before that |
| Cartoon avatars | Optional preset faces for compact UI before unlock |
| Birth privacy | Exact birth data owner-only; public profile is safe fields + chart as today |
| Bonds | Named bond tiers (romantic etc.) — copy can evolve; don’t lead with raw % |

---

## Visual direction (new)

- Crystal glass: more transparent plates, light 3D (bevel + soft depth)
- Cosmic photography backgrounds; lavender as accent only
- Avoid cloning old screen layouts; E’s paper + this brief drive structure
- 2–3 intentional motions (press, reveal, sheet) — not constant shimmer

---

## Technical approach

| Layer | Plan |
|-------|------|
| Repo | `sakarago/astrobondWest Village` — replace with **new Xcode project** (clean tree) |
| UI | New SwiftUI app + small design system (Background, Plate, CTA, Field, Chip, TabBar, Type) |
| Domain | Re-specify matching/messaging rules in new modules; astrology calculator can be **reimplemented from spec** or extracted later as pure Swift if needed — **no UI copy** |
| Backend | Existing Supabase project + migrations; add photo-unlock rule in app (and later SQL if needed) |
| Old project | Archive / reference only; do not merge view code |

---

## V1.1+ (after TestFlight)

- Talk to an astrologist
- 2 compressed profile photos
- Stronger Discover
- Apple/Google sign-in polish
- Push notifications
- Photo-unlock enforced server-side if required

---

## Build order

1. Empty app shell + design tokens + tab bar  
2. Auth + session  
3. Onboarding → profile/birth/chart persist  
4. Match reveal loop  
5. Messages  
6. Profile chart  
7. Photo-after-N-messages + polish  
8. TestFlight  

---

## Definition of done (V1 TestFlight)

- Friend can register, get a chart, reveal matches, accept, chat, see gated photos after 10 messages, sign out  
- UI is clearly the new system (not a restyle of the prototype)  
- No dependency on old SwiftUI sources in the shipping target  
