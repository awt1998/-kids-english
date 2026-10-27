# CLAUDE.md

**Labeeb (لبيب)**: a mobile app (Flutter, Android + iOS, phones + tablets) that
teaches English to Arab children aged 3–10 through picture + sound games.
Arabic RTL interface, English learning content. Mascot: Labeeb, a baby falcon
(`assets/images/mascot/labeeb_*.svg`). App id: `com.labeeb.english`.

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
flutter test screenshots --update-goldens  # renders every screen to docs/previews/latest/
python3 tool/gen_sfx.py                    # regenerate sound effects
/opt/tts/venv/bin/python tool/gen_voice_en.py  # English word audio for new words (Kokoro)
```

## Layout

- `lib/core/theme/` — design tokens (colours, text, spacing). Read `DESIGN.md` first.
- `lib/core/widgets/` — shared components (`KidButton`, `Mascot`).
- `lib/features/<feature>/` — one folder per feature/screen.
- `lib/content/` — content models + loader. `lib/progress/` — child profiles, stars, unlock rules.
- `lib/audio/` — `AudioService` (word audio, Arabic prompts, effects). Tests use `SilentAudioService`.
- `assets/content/index.json` lists units (order = map order); `assets/content/units/<id>.json`
  holds the words. A unit without a file shows as "coming soon".
- Per word: `assets/images/words/<id>.svg` and `assets/audio/en/words/<id>.mp3`
  (`test/content/content_test.dart` fails if either is missing).
- `screenshots/` — renders screens to PNG for review; not part of `flutter test`.

## Decisions already made (do not re-open without the owner)

- Flutter. Data on device only: no backend, no accounts, no third-party analytics,
  no Firebase. Crash data comes from the Play Console / App Store Connect only.
- Three age levels: 3–5 (no reading, audio + pictures), 6–8, 9–10.
- Art: own SVGs + Microsoft Fluent Emoji (MIT). No copyrighted characters.
- Audio is pre-generated and bundled (works offline). English: Kokoro-82M
  (Apache-2.0) voice `af_heart` at speed 0.8, generated locally by
  `tool/gen_voice_en.py`. Arabic instructions: Gulf dialect if natural, else simple MSA,
  most human-sounding voice available (compare Azure vs ElevenLabs samples).
  Azure, ElevenLabs and HuggingFace are blocked from the cloud container; GitHub
  raw/releases, pypi and Google's Android/Maven hosts work.
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
