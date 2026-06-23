# CLAUDE.md

This file guides Claude Code (and other AI agents) when working in this repository.

## Project overview

**elifba** is a Flutter app that teaches the **Azerbaijani alphabet** to children. The
flow is: a book-style alphabet page → list of animals whose name starts with a chosen
letter → an animal detail page with description, audio narration, foods animation, a
sliding-tile image puzzle, a drag-and-drop word puzzle, and an (optional) YouTube video.

- All UI text and content is in **Azerbaijani**. The 32-letter alphabet includes the
  special letters `Ç Ə Ğ I İ Ö Ş Ü X Q`.
- Target platform is **Android** (mobile). Web is not properly supported yet (see Gotchas).
- Package id / namespace: `com.vebstudio.elifba`.

## Commands

```bash
flutter pub get          # install dependencies
flutter run              # run on a connected device/emulator
flutter analyze          # static analysis (currently: No issues found)
flutter test             # run tests
flutter build apk --release   # release build (needs signing env vars, see below)
```

Release signing reads `STORE_PASSWORD` and `KEY_PASSWORD` from the environment and the
keystore from `key/elifba.jks` (the `.jks` is git-ignored and must be supplied locally —
see `key/README.md`). **Do not hardcode these secrets** (see Security below).

## Architecture

```
lib/
  main.dart                  # MaterialApp, theme (deepPurple, Material3, NotoSans), home = AlphabetPage
  core/
    config.dart              # ALL content + the data model. ~800 lines of const maps.
    utils.dart               # normalizeFileName / getFirstLetter helpers (delegate to config.dart)
  pages/
    alphabet_page.dart       # book of letters, 2 letters per page (PageView)
    animal_list_page.dart    # grid of animals for a letter, prev/next letter nav
    animal_detail_page.dart  # detail screen + inline AnimalWordPuzzle
    puzzle_page.dart         # sliding image-tile puzzle (CustomPainter slices the image)
  widgets/
    youtube_video_widget.dart  # platform-split YouTube widget (mobile=webview, web=fallback msg)
```

### Content & data model (important)

There is **no database and no JSON** — all content lives as `const` maps in
`lib/core/config.dart`, keyed by **letter** or by **animal name string**:

- `AppConfig.alphabet` — ordered list of 32 letters.
- `letterDescriptions[LETTER]` — per-letter teaching text.
- `animalsByLetter[LETTER]` — list of animal names for each letter.
- `animalInfo[NAME]`, `animalFoods[NAME]`, `animalHasSound[NAME]`, `animalHasPuzzle[NAME]`,
  `animalYoutubeEmbeds[NAME]` — per-animal data, all joined by the **animal name string**.

The animal name string is the join key across ~6 separate maps, so a typo in any one map
silently falls back to a default (empty description, no puzzle, etc.). When adding an
animal, update **every** map consistently.

`AppConfig.findLetter()` / `findAnimal()` build `LetterConfig` / `AnimalInfo` objects on
the fly from these maps **on every call** (no caching).

### Asset naming convention

Images/audio live under `assets/images/<letter>/` and `assets/audios/<letter>/`.
File names are produced by `AppConfig.normalizeFileName()`, which lowercases and strips
Azerbaijani diacritics: `ə→e, ı→i, ö→o, ğ→g, ü→u, ş→s, ç→c`, spaces→`_`.

Examples: `Əqrəb` → `assets/images/ə/eqreb.png`; info audio is
`<name>_info_sound.mp3`, animal sound is `<name>_sound.mp3`, puzzle image is the animal
image with `.png` replaced by `_puzzle.jpg`.

⚠️ **Folder vs. file mismatch:** the *folder* is the real letter (e.g. `ə/`) but the
*file name* is normalized (`eqreb`). `animal_detail_page.dart` re-derives the letter from
the **normalized** name via `getFirstLetter()`, which yields the wrong folder for
diacritic letters. See Gotchas.

## Conventions

- State management is plain `StatefulWidget` + `setState`. No Provider/Bloc/Riverpod.
- Audio uses `just_audio`; confetti uses `confetti`; the word/image puzzles use Flutter's
  built-in `Draggable`/`DragTarget`.
- Colors use `Color.withAlpha((opacity * 255).toInt())` (post-`withOpacity` migration).
- Fonts declared in `pubspec.yaml`: `NotoSans` (default) and `Baloo2`.
- Lints: default `flutter_lints` via `analysis_options.yaml`.

## Gotchas / known issues

See the analysis notes the team produced, but the key traps for an agent are:

1. **Diacritic letters break asset lookup in the detail page.** `AnimalDetailPage` does
   not receive the letter; it recomputes it with `getFirstLetter(name)` which normalizes
   diacritics (`Əqrəb`→`e`), so it looks in the normalized folder (`e/`) instead of the
   real one (`ə/`). This is currently worked around by **mirroring both images and audio**
   into the normalized folders (e.g. `assets/audios/e/eqreb_info_sound.mp3`). ⚠️ When you
   add an animal whose name starts with `Ç/Ə/Ğ/Ö/Ş/Ü/I/İ`, you must copy its assets into
   **both** the real and the normalized letter folder, or the detail page will show the
   fallback icon / play nothing. The clean fix is to pass the real letter down instead of
   re-deriving it.
2. **Dotted/dotless I.** `String.toLowerCase()` is locale-independent, so `I`/`İ` do not
   map cleanly to the `i/` and `ı/` folders. Treat any I-letter asset path with suspicion.
3. **Where the widgets live.** `AnimalWordPuzzle` is defined **inline** in
   `animal_detail_page.dart` (the old unused duplicate `pages/animal_word_puzzle.dart` was
   deleted). `YoutubeVideoWidget` is the platform-split widget in
   `widgets/youtube_video_widget.dart`, imported by the detail page (its inline duplicate
   was removed). Edit these, don't reintroduce copies.
4. **Web/desktop.** YouTube uses `webview_flutter` (mobile only) via the platform-split
   `widgets/youtube_video_widget.dart`; on web it shows a "mobile only" fallback message.
   The app is targeted at Android.
5. **AudioPlayer init.** AudioPlayer fields are now constructed synchronously at the field
   declaration (`final ... = AudioPlayer()`), and `_initAudio()` only `setAsset`s them
   inside a try/catch. Keep this pattern — do not move construction back into the async
   `_initAudio()` (that reintroduces a `LateInitializationError` race on early interaction
   or `dispose()`). Note: `pages/animal_word_puzzle.dart` is the unused duplicate and still
   has the old `late` pattern.
6. **Asset bloat.** `assets/images/` ships non-image files (`tom-select.complete.js`,
   `loading*.gif`, `feature.png`) because the whole folder is declared as an asset.

## Security

`android/app/build.gradle.kts` currently contains **hardcoded keystore passwords** as
env-var fallbacks (and they are in git history). Never commit signing passwords — rely on
`STORE_PASSWORD`/`KEY_PASSWORD` env vars only, and rotate the leaked credentials.
