# Android handoff

Goal: native Android port (Kotlin, Jetpack Compose, Material3 customised to the "crystal" look) of the iOS app. Same Supabase backend, same behaviour, same Turkish UI.

## Rules
- Work only in `android/`. Use a dedicated branch (`android`) and merge to `main` via small PRs.
- iOS source is the spec. Read it, do not edit it.
- App UI is fully Turkish. Bond names stay English: RomanticBond, SexBond, BusinessBond, FriendBond. Zodiac names are Turkish.
- Package/applicationId: `com.astrobond.app` (same as iOS bundle id).
- Do not commit secrets or keystores. The Supabase anon key is public by design (RLS protects data); read it the same way iOS does, see below.

## Backend
- Supabase project URL and anon key: `AstroBondWestVillage/Infrastructure/Supabase/SupabaseCredentials.swift`. Client setup: `SupabaseClientProvider.swift`.
- Use `supabase-kt` (auth, postgrest, realtime, storage).
- Table/RPC usage is in the iOS services: `Infrastructure/Auth`, `Profile`, `Match`, `Messaging`, `Settings`. Mirror their queries exactly.

## Where the logic lives (iOS -> port)
| Area | iOS path |
|---|---|
| Domain models | `Domain/*.swift` |
| Ephemeris (Swiss Ephemeris) | `Packages/SwissEphemeris` (use the C library via NDK/JNI, or a Java/Kotlin binding; keep results identical) |
| Natal chart + compatibility | `Infrastructure/Astrology/ChartService.swift`, `CalculateCompatibilityUseCase.swift`, `SimplifiedAstronomyCalculator.swift` |
| Daily notes / Discover content | `DailyNoteEngine.swift`, `DiscoverContent.swift` (pure template engine with seeded RNG: port 1:1 so output matches) |
| Discover AI enrichment | `DiscoverAI.swift` (iOS uses Apple on-device FoundationModels; on Android skip or use Gemini Nano / AICore if available, always fall back to templates) |
| Screens | `Features/Welcome, Onboarding, Match, Messages, Discover, Profile, Settings, Shared` |
| Theme / crystal design | `DesignSystem/`, `Features/Discover/DiscoverTheme.swift` |

## Suggested order
1. Gradle project, theme, navigation shell with 4 tabs (Keşfet, Eşleşme, Mesajlar, Profil), Turkish strings.
2. Supabase auth + onboarding (birth data, Turkey locations from `Domain/TurkeyLocations.swift`).
3. Chart calculation (ephemeris) and compatibility report.
4. Match wheel / reveal flow.
5. Messages + chat (+ question discovery).
6. Discover tab (daily card flow, events, signs, love, guide).
7. Profile, settings, notifications (daily 09:00 local notification for the daily card).

## Known caveats
- `DailyRevealQuotaStore.isUnlimited = true` (`Infrastructure/Match/MatchDecisionsStore.swift`) is an iOS TEST MODE flag. Do not port it as unlimited; the real limit is enforced per day.
- Event dates in `DiscoverContent.rawEvents` (Merkür retrosu, new/full moons, eclipses) are a hand-written list; verify before release.
- Daily card pick is stored per user per day on device; one card per day.
