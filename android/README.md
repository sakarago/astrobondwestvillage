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
- [ ] Step 2: Supabase auth + onboarding
- [ ] Step 3: Ephemeris + compatibility
- [ ] Step 4–7: Match, Messages, Discover, Profile/Settings/notifications

Notes: `DailyRevealQuotaStore.isUnlimited` (iOS test flag) must NOT be ported as unlimited.
Crystal glass is approximated with translucent fills (no backdrop blur); body font is SansSerif until a rounded font is bundled.
