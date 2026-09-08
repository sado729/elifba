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
    progress.dart            # ProgressStore: which sections are done, star maths, persistence
    letter_strokes.dart      # per-letter stroke geometry for the tracing game
    stroke_tracker.dart      # scores a traced stroke against its target path
  pages/
    alphabet_page.dart       # book of letters, 2 letters per page (PageView) + per-letter stars
    animal_list_page.dart    # grid of animals for a letter, prev/next letter nav, letter progress
    animal_detail_page.dart  # detail screen + inline AnimalWordPuzzle
    puzzle_page.dart         # sliding image-tile puzzle (CustomPainter slices the image)
    letter_writing_page.dart # letter tracing game
  widgets/
    star_row.dart            # the shared filled/empty star row (one look everywhere)
    tracing_canvas.dart      # the tracing game's draw surface
test/
  widget_test.dart               # smoke tests for the alphabet book
  content_integrity_test.dart    # config maps vs. the files actually on disk
  normalize_file_name_test.dart  # normalizeFileName / getFirstLetter behaviour
  progress_test.dart             # star maths, task plan, persistence round-trip
  star_ui_test.dart              # stars on screen: book, letter progress, cards, reset
```

Dependencies are deliberately minimal, one per capability: **`just_audio`** (audio),
**`confetti`** (celebration), **`shared_preferences`** (star progress) and
**`path_drawing`** (letter tracing), plus `flutter_lints`. `flutter_tts`, `turn_page_transition`, `collection`, `cupertino_icons`
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

### Star progress (`core/progress.dart`)

`ProgressStore` is a `ChangeNotifier` singleton (`ProgressStore.instance`), loaded in
`main()` **before** `runApp` so the first frame already has the right stars. It persists to
`shared_preferences` under one JSON key (`progress_v1`), debounced 400 ms.

A letter's stars come from the sections completed under it:

- Per animal, up to 4 tasks in `Activity`: `info` (the Məlumat section — completed by
  *opening* the animal, since it is the default section), `foods` (**all** of its foods fed
  one by one), `wordPuzzle`, `tilePuzzle` (only when `animalHasPuzzle`).
- Per letter, +1 for tracing the letter (`markWritten`), which is why every one of the 32
  letters has content and `maxTotalStars` is 96 — `Ğ`, `I` and `Ü` have no animals but can
  still be written.
- `starsFor(done, total)`: 0 done → 0 stars, any progress → 1, `≥ 2/3` → 2, **all** → 3.
  Monotone by design, and the third star is the only strict one, so "did everything about
  this letter" is exactly 3 stars. Pinned by `progress_test.dart`.

**Audio is deliberately not a task.** Only 60 of 91 animals have narration and only 3 of 32
letters have a pronunciation recording, so counting listening would put a full star out of
reach for a third of the app. Nothing requires the child to listen.

`markDone` ignores an activity that is not in the animal's task plan and `markFoodFed`
ignores a food the animal does not eat, so `animalDone` can never exceed `animalTotal`.
Restoring unknown animals, activities or foods from stored JSON is silently skipped —
old saves never break a new build. `_scheduleSave()` no-ops while `_prefs` is null, so a
widget test that records progress does not leave a pending debounce timer behind.

Pages do not thread the store through constructors: `alphabet_page.dart` and
`animal_list_page.dart` hold one `addListener`/`removeListener` pair each and rebuild their
whole subtree, while `animal_detail_page.dart` just calls `setState` after its own marks.
`AnimalDetailPage` and `LetterWritingPage` accept an optional `store` so a widget test can
pass `ProgressStore.forTesting()`. **Never mark progress during a build** — the detail page
records `Activity.info` from a post-frame callback precisely because `notifyListeners()`
would otherwise call `setState` on the listening list page mid-build.

`ProgressStore.reset()` is wired to "Progresi sıfırla" in the alphabet page's ℹ️ dialog,
behind a second explicit confirmation so a child cannot wipe the stars with one tap. That
dialog is slated to move into the parent-gated settings page (see the spec under
`docs/superpowers/specs/`); the reset moves with it.

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
    delivers `MissingPluginException` and fails the test). And the animal grid is built
    lazily: on the default 800x600 test surface the GridView is 768x357 and lays out
    only its first **two** cells, so a finder reaching the third animal matches nothing
    and `ensureVisible` throws `Bad state: No element` — use `tester.scrollUntilVisible`.
    Adding a cell at the head of the grid shifts which animals those two slots hold, so
    a test that names an animal by position breaks without the grid itself being wrong.

12. **An empty asset folder is invisible to git and breaks a clean clone.** `pubspec.yaml`
    declares `assets/audios/<letter>/` for all 32 letters, but git does not track empty
    directories, so a folder holding no recordings simply does not exist after `git clone`
    — and Flutter turns that into a hard build failure, not a warning:
    `Error: unable to find directory entry in pubspec.yaml: ...assets\audios\ğ\`.
    It went unnoticed for the project's whole history because the folders existed locally
    on the machine where they were created by hand. `ğ`, `ı`, `ş` and `ü` therefore each
    carry a `.gitkeep`. **Declaring a new asset folder means either putting a real file in
    it or adding a `.gitkeep`** — verify with a throwaway worktree
    (`git worktree add --detach <tmp> HEAD && cd <tmp> && flutter pub get && flutter build bundle`),
    since `flutter analyze` in the main tree cannot see the problem. Deleting the pubspec
    line instead would be worse: a recording dropped in later would silently never bundle.

13. **The star UI must not add a fixed-height row to a page's `Column`.**
    `animal_detail_page.dart` and `animal_list_page.dart` both end in
    `Expanded(<scrollable>)`, and on a short screen the fixed children already use up the
    height — the detail page overflowed by 8 px even before stars existed. A star row added
    as one more `Column` child took that to 44 px, and on the list page it squeezed
    `Expanded` to nearly zero so the **lazy** grid built no cells at all and every
    `find.text(<animal>)` failed. Both are now placed at zero height cost: the animal's
    stars are a `Positioned` overlay inside the hero `Stack` (whose size the `AspectRatio`
    child fixes), and the letter's progress replaced the decorative divider **inside** the
    existing "Heyvanlar" heading `Row` (its tallest element, an 18 px star, is shorter than
    the 24 px heading text). Verify a new badge with
    `tester.getSize(find.byType(GridView))` — it must not shrink.

14. **A puzzle star must not be awarded during a hint.** `_showHint()` in
    `puzzle_page.dart` puts the solved arrangement into `slots` for 2 seconds, which makes
    `_isCompleted()` return `true`. Both completion checks are therefore guarded with
    `!showHint` before calling `widget.onCompleted` — without it a child could tap the hint
    and collect the star. No test catches this; it is a logic invariant.

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
