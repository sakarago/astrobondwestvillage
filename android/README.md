# AstroBond West Village — Android

Native Android port (Kotlin + Jetpack Compose) of the iOS app in this repo.
Keep all Android files inside `android/`. Do not move or edit the iOS folders.

See `Notes/AndroidHandoff.md` before starting.

## Build

Needs Android Studio (Koala+) or the Android SDK (platform 35, build-tools 35) and JDK 17+.
Set `sdk.dir` in `android/local.properties` (not committed) or `ANDROID_HOME`, then:

```
cd android && ./gradlew :app:assembleDebug
```

## Status

- [x] Step 1: Gradle project, crystal theme (`ui/theme`), 4-tab shell (`ui/nav`), Turkish strings
- [x] Step 2: Supabase auth (`data/Repositories.kt`, `session/`), welcome/sign-in/sign-up, onboarding (name, avatar, birth data, Turkey locations from `assets/locations.json`, preferences)
- [x] Step 3 (engine): Swiss Ephemeris via NDK/JNI (`cpp/`, `astro/SwissEph.kt`), natal chart (`astro/ChartEngine.kt`), compatibility (`domain/Compatibility.kt`), chart JSON compatible with iOS rows (`domain/Chart.kt`).
  Verified on emulator: J2000 Sun 280.3689°, Moon 223.3238°.
- [ ] Step 3 (UI): chart wheel / profile chart, report screens
- [x] Step 4: Match tab (wheel, 6s spin, reveal card, accept/new, today strip, Sinastri detail, bond tiers, 3/day quota). Not yet ported: iOS wheel atmosphere effects, dual synastry wheel, match prefs sheet (age/location), chat hand-off (step 5)
- [x] Step 5: Messages inbox, chat (history, send, realtime inserts, mark-read, photo gate after 10 messages, Astro Uyum score, shared Sinastri), question discovery (hand-written bank, 23/day; no on-device AI), Match → chat hand-off. Not yet verified against a live account.
- [ ] Step 6: Discover (DailyNoteEngine / DiscoverContent 1:1 port)
- [ ] Step 7: Profile, settings, 09:00 daily notification

Notes: Crystal glass is approximated with translucent fills (no backdrop blur); body font is SansSerif until a rounded font is bundled; cartoon avatars are a simplified flat drawing using the iOS colour table; Google/Apple/phone sign-in are stubs as on iOS.
Supabase URL/anon key are read at build time from the iOS `SupabaseCredentials.swift` (or `local.properties` `supabase.url` / `supabase.anonKey`).
Email sign-up needs email confirmation OFF on the Supabase project (same limitation as iOS).
