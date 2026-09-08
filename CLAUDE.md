# CLAUDE.md

This file guides Claude Code (and other AI agents) when working in this repository.

## Project overview

**elifba** is a Flutter app that teaches the **Azerbaijani alphabet** to children. The
flow is: a book-style alphabet page → list of animals whose name starts with a chosen
letter → an animal detail page with description, audio narration, foods animation, a
sliding-tile image puzzle and a drag-and-drop word puzzle.

- All UI text and content is in **Azerbaijani**. The 32-letter alphabet includes the
  special letters `Ç Ə Ğ I İ Ö Ş Ü X Q`.
- Target platform is **Android** (mobile). Web is not properly supported yet (see Gotchas).
- Package id / namespace: `com.vebstudio.elifba`.

## Commands

```bash
flutter pub get          # install dependencies
flutter run              # run on a connected device/emulator
flutter analyze          # static analysis (currently: No issues found)
flutter test             # smoke + content-integrity tests (currently: all green)
flutter build apk --release   # release build (needs signing env vars, see below)
```

Release signing reads `STORE_PASSWORD` and `KEY_PASSWORD` from the environment and the
keystore from `key/elifba.jks` (the `.jks` is git-ignored and must be supplied locally —
see `key/README.md`). **Do not hardcode these secrets** (see Security below).

Release builds run R8: `isMinifyEnabled` and `isShrinkResources` are on, with an
intentionally empty `android/app/proguard-rules.pro` (Flutter, just_audio and media3 ship
their own consumer keep rules).

## Architecture

```
lib/
  main.dart                  # MaterialApp, theme (deepPurple, Material3, NotoSans), home = AlphabetPage
  core/
    config.dart              # ALL content + the data model. ~760 lines of const maps.
    utils.dart               # normalizeFileName / getFirstLetter helpers (delegate to config.dart)
  pages/
    alphabet_page.dart       # book of letters, 2 letters per page (PageView)
    animal_list_page.dart    # grid of animals for a letter, prev/next letter nav
    animal_detail_page.dart  # detail screen + inline AnimalWordPuzzle
    puzzle_page.dart         # sliding image-tile puzzle (CustomPainter slices the image)
test/
  widget_test.dart               # smoke tests for the alphabet book
  content_integrity_test.dart    # config maps vs. the files actually on disk
  normalize_file_name_test.dart  # normalizeFileName / getFirstLetter behaviour
```

Dependencies are deliberately minimal: **`just_audio` and `confetti` only** (plus
`flutter_lints`). `flutter_tts`, `turn_page_transition`, `collection`, `cupertino_icons`
and `webview_flutter` were all declared but never used, and have been removed — do not
re-add a package without a call site. Keep `uses-material-design: true`; the Material icon
font is the one the app actually uses.

### Content & data model (important)

There is **no database and no JSON** — all content lives as `const` maps in
`lib/core/config.dart`, keyed by **letter** or by **animal name string**:

- `AppConfig.alphabet` — ordered list of 32 letters.
- `letterDescriptions[LETTER]` — per-letter teaching text.
- `animalsByLetter[LETTER]` — list of animal names for each letter.
- `animalInfo[NAME]`, `animalFoods[NAME]`, `animalHasSound[NAME]`, `animalHasPuzzle[NAME]`
  — per-animal data, all joined by the **animal name string**.
- `lettersWithAudio` — the letters that actually have a pronunciation recording (`A`, `B`,
  `C` today). `hasLetterAudio()` gates the speaker button in `animal_list_page.dart`, and
  `content_integrity_test.dart` asserts the set still matches the files on disk.

The animal name string is the join key across ~5 separate maps, so a typo in any one map
silently falls back to a default (empty description, no puzzle, etc.). When adding an
animal, update **every** map consistently — the integrity test will tell you if you did not.

`AppConfig.findLetter()` / `findAnimal()` build `LetterConfig` / `AnimalInfo` objects on
the fly from these maps **on every call** (no caching).

### Asset naming convention

Images/audio live under `assets/images/<letter>/` and `assets/audios/<letter>/`.
File names are produced by `AppConfig.normalizeFileName()`, which lowercases and strips
Azerbaijani diacritics: `ə→e, ı→i, ö→o, ğ→g, ü→u, ş→s, ç→c`, spaces→`_`.

Examples: `Əqrəb` → `assets/images/ə/eqreb.webp`; info audio is
`<name>_info_sound.mp3`, animal sound is `<name>_sound.mp3`, puzzle image is the animal
image with `.webp` replaced by `_puzzle.jpg`.

**All bitmap art is WebP; only the puzzle crops stay JPEG.** Re-encoding a 600×600
photographic JPEG as WebP measurably *grows* it (122 % of source at q88), so `*_puzzle.jpg`
is deliberately left as JPEG. Everything that used to be PNG is now `.webp`.

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

1. **Diacritic letters break asset lookup in the detail page.** `AnimalDetailPage` does
   not receive the letter; it recomputes it with `getFirstLetter(name)` which normalizes
   diacritics (`Əqrəb`→`e`), so it looks in the normalized folder (`e/`) instead of the
   real one (`ə/`). This is currently worked around by **mirroring both images and audio**
   into the normalized folders (e.g. `assets/audios/e/eqreb_info_sound.mp3`). ⚠️ When you
   add an animal whose name starts with `Ç/Ə/Ğ/Ö/Ş/Ü/I/İ`, you must copy its assets into
   **both** the real and the normalized letter folder, or the detail page will show the
   fallback icon / play nothing. `content_integrity_test.dart` fails if you forget. The
   clean fix is to pass the real letter down instead of re-deriving it.
2. **Dotted/dotless I.** Dart `toLowerCase()` maps **both** `I` and `İ` to a single `i`
   (verified: one code unit, 105), so the `I` page loads the assets of `İ` and
   `assets/images/ı/` is unreachable from code. The fix is an explicit letter→folder
   table, not `toLowerCase()`. `normalize_file_name_test.dart` pins this behaviour.
3. **Where the widgets live.** `AnimalWordPuzzle` is defined **inline** in
   `animal_detail_page.dart`; the old duplicate `pages/animal_word_puzzle.dart`
   and the YouTube widget were deleted. Do not reintroduce copies of either.
4. **No network, no webview.** The YouTube / `webview_flutter` feature is gone: no map, no
   field, no widget. `android/app/src/main/AndroidManifest.xml` declares **no permissions
   at all** (INTERNET exists only in the stock debug/profile variant manifests, for the
   Dart VM service). Everything the app plays or shows is a bundled asset — keep it that
   way, a children app with no network permission is far easier to ship.
5. **AudioPlayer init.** AudioPlayer fields are constructed synchronously at the field
   declaration (`final ... = AudioPlayer()`), and `setAsset` calls live inside a
   try/catch. Keep this pattern — moving construction into an async `_initAudio()`
   reintroduces a `LateInitializationError` race on early interaction or `dispose()`.
6. **A silent audio button must not exist.** Only 3 of 32 letters and 61 of 91 animals
   have narration. The letter speaker button is rendered only when
   `AppConfig.hasLetterAudio(letter)` is true, and every `setAsset` is wrapped in
   try/catch — without both, a missing file leaves the button stuck in its stop state and
   swallows the first tap. Apply the same rule to any new audio affordance.
7. **Asset bloat.** The whole `assets/` tree is declared in `pubspec.yaml`, so anything
   dropped in there ships to every user. Store/branding art lives **outside** `assets/`
   on purpose: `docs/store/feature.png`, `branding/logo.png` (the latter is
   `flutter_launcher_icons.image_path`). Two cleanups so far: 2026-07-30 removed 66
   duplicate `*.mp3` (10.8 MB) and web junk; 2026-09-08 converted all PNG art to WebP and
   re-encoded the oversized sound effects.
   ⚠️ The per-letter card images (`assets/images/<letter>/<letter>*.webp`) are **never
   rendered** — `alphabet_page.dart` draws each letter as `Text(fontSize: 72)`. They are
   kept only as small 512 px WebP files in case a letter card is added later; do not let
   them grow back.
8. **Image decode widths.** Every `Image.asset` of animal/food/puzzle art passes
   `cacheWidth` (`kAnimalThumbDecodeWidth` 400, `kAnimalHeroDecodeWidth` 400,
   `kFoodDecodeWidth` 256, `kPuzzleThumbDecodeWidth` 192, `kPuzzlePreviewDecodeWidth` 700).
   `precacheImage` must wrap the provider in `ResizeImage(..., width: <same constant>)` —
   a different width is a **different image-cache key**, so a mismatch silently doubles
   memory. That is exactly why the hero width is 400 and not 800: grid thumb and hero now
   share one cache entry. Source sizes today: animal art 400×400, foods 256 px, puzzle
   crops 600×600. Food art is decoded at one shared width even though it renders at
   32/40/64 px, on purpose: one cache entry per food.
9. **Puzzle image is decoded once.** `puzzle_page.dart` caches the `ui.Image` in
   `_puzzleImageFuture`/`_puzzleImage` via `_puzzleImageOf()` and disposes it in
   `dispose()`. Do not call `_loadImage()` from `build()` — that decoded the 600×600 image
   once **per tile** (9–16×) and re-decoded on every `setState`.
10. **Edge-to-edge is manual.** The app targets API 36, where Android 16 forces
    edge-to-edge with no opt-out, so system bars overlay the `Scaffold.body`. `main.dart`
    turns on `SystemUiMode.edgeToEdge` for every Android version and pins light system-bar
    icons (all pages sit on dark purple). Each page insets its own content:
    `alphabet_page` uses `SafeArea`, `animal_list_page` / `animal_detail_page` add
    `MediaQuery.viewPaddingOf(context)` to the padding of their bottom-most scrollable.
    Keep the full-bleed gradient `Container` *outside* the inset so it still paints behind
    the bars. **A new page must do one of these or its bottom content hides under the nav
    bar.**
11. **Tests are the content gate.** `content_integrity_test.dart` walks the config maps,
    builds paths with the **same functions the pages use**, and stats them with `dart:io`
    (relative paths resolve to the package root under `flutter test`). Missing content is
    tracked in explicit allowlists (`kAnimalsWithoutInfoAudio`, `kAnimalsWithoutInfoText`,
    `kLettersWithoutAnimals`, `kLettersWithoutLetterImage`) — when you add a file, delete
    the name from the allowlist or the test fails. In widget tests: **never `await` a
    just_audio call** (it hangs for the full 10-minute timeout) and **never use
    `tester.runAsync`** on a page that builds an `AudioPlayer` (the real event loop then
    delivers `MissingPluginException` and fails the test).

## Known content gaps

Tracked as allowlists in `test/content_integrity_test.dart`, not as TODO comments:

- 29 of 32 letters have **no pronunciation audio** (only `A`, `B`, `C` do).
- 30 of 91 animals have **no narration** (`<name>_info_sound.mp3`).
- `Ğ`, `I`, `Ü` have **no animals** — their list page opens empty.
- `Ş` has no letter-card image; `Qarışqayeyən` and `Qırqovul` have no description text.

## Security

`android/app/build.gradle.kts` currently contains **hardcoded keystore passwords** as
env-var fallbacks (and they are in git history). Never commit signing passwords — rely on
`STORE_PASSWORD`/`KEY_PASSWORD` env vars only, and rotate the leaked credentials.
