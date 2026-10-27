# CLAUDE.md

Mobile app (Flutter, Android + iOS, phones + tablets) that teaches English to
Arab children aged 3–10 through picture + sound games. Arabic RTL interface,
English learning content.

**Always talk to the owner in Arabic.** They are not a professional developer:
explain steps they must do themselves in plain language. Work in phases and
show results (screenshots / APK) before moving on; ask before design decisions.

## Commands

```bash
export PATH=/opt/flutter/bin:$PATH        # cloud container install location
flutter pub get
flutter analyze                           # must be clean
flutter test                              # must pass before every commit
dart format lib test
flutter build web --release --no-web-resources-cdn   # preview build (CDN is blocked in the container)
```

## Layout

- `lib/core/theme/` — design tokens (colours, text, spacing). Read `DESIGN.md` first.
- `lib/core/widgets/` — shared components (`KidButton`, `Mascot`).
- `lib/features/<feature>/` — one folder per feature/screen.
- `assets/` — fonts, images, (later) audio and content JSON.

## Decisions already made (do not re-open without the owner)

- Flutter. Data on device only: no backend, no accounts, no third-party analytics,
  no Firebase. Crash data comes from the Play Console / App Store Connect only.
- Three age levels: 3–5 (no reading, audio + pictures), 6–8, 9–10.
- Art: own SVGs + Microsoft Fluent Emoji (MIT). No copyrighted characters.
- Audio is pre-generated and bundled (works offline). English: Azure neural TTS,
  slightly slow. Arabic instructions: Gulf dialect if natural, else simple MSA,
  most human-sounding voice available (compare Azure vs ElevenLabs samples).
- Monetisation:
  - **Android:** free + AdMob + one-time "remove ads" IAP.
  - **iOS:** Kids Category, **no ads**, free first units + one-time "unlock all" IAP.
- "Repeat after me" (microphone) is postponed to v1.1. If built: on-device only,
  nothing stored, parent opt-in, and on iOS reset the AVAudioSession to playback /
  speaker afterwards (audio otherwise drops to the quiet earpiece).

## Child-safety rules (store policy, never break)

- AdMob only (no mediation): `tagForChildDirectedTreatment = true`,
  `maxAdContentRating = G`, non-personalised. Remove the `AD_ID` permission
  from the Android manifest.
- Ads only at natural breaks (after an activity's celebration), never during
  play, never on first day of use or at app launch, max one per ~4 minutes,
  no banners in kid screens, no rewarded ads.
- Purchases, settings, links and contact are only behind the parental gate.
- No external links, sharing or chat in the child area.
- No wrong-answer punishment: hint + retry. Never red for "wrong".
- Content must be culturally appropriate (see the exclusion list in `DESIGN.md`).

## Conventions

- No hard-coded colours, sizes or fonts in screens: use the tokens.
- Wrap English text in `Directionality(textDirection: TextDirection.ltr)`.
- Every tappable thing ≥ 64 logical px.
- Add a test with each piece of logic (spaced repetition, ad rules, gate, content validation).
