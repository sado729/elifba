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
  main.dart                  # MaterialApp, ElifbaTheme.light(), dark system bars, 1.3x text clamp, home = AlphabetPage
  core/
    config.dart              # ALL content + the data model. ~760 lines of const maps.
    utils.dart               # normalizeFileName / getFirstLetter helpers (delegate to config.dart)
    progress.dart            # ProgressStore: which sections are done, star maths, persistence
    settings.dart            # AppSettings: sound channels, haptics, motion, puzzle size + persistence
    sound.dart               # SoundChannel + GatedPlayer — the ONLY way to play audio
    letter_strokes.dart      # per-letter stroke geometry for the tracing game
    stroke_tracker.dart      # scores a traced stroke against its target path
  theme/                     # the design system: import 'theme/theme.dart' (barrel)
    elifba_palette.dart      # every hex as a const (ElifbaPalette), letter colour sets, confetti colours
    elifba_colors.dart       # ElifbaColors ThemeExtension (+ of(context) with a fallback)
    elifba_typography.dart   # Comfortaa/Andika TextTheme + ElifbaTextStyles (named off-scale styles)
    elifba_tokens.dart       # ElifbaSpace / Radius / Edge / Ring / Size / Layout
    elifba_motion.dart       # ElifbaMotion: every duration/curve + the reduced-motion switch
    elifba_component_themes.dart, elifba_theme.dart  # ThemeData, switch/segmented/dialog themes
  pages/
    alphabet_page.dart       # the book: 2 letter cards per spread (PageView), arrows, page chip
    animal_list_page.dart    # letter page: one CustomScrollView (info card, progress, SliverGrid)
    animal_detail_page.dart  # animal page: stage, sticky pill tabs, 4 sections, inline AnimalWordPuzzle
    puzzle_page.dart         # sliding image-tile puzzle (CustomPainter slices the image)
    letter_writing_page.dart # letter tracing game
    settings_page.dart       # parent area: sound/haptics/motion/puzzle size, reset, credits, about
  widgets/
    squishy.dart             # the press primitive behind every child tappable (see Design system)
    pill_button.dart, icon_buttons.dart, audio_button.dart, pill_tab.dart, food_chip.dart
    elifba_card.dart         # ElifbaCard, AnimalStage, ImagePlaceholder, DashedRRectPainter
    star_row.dart            # StarGlyph (the design's stroked star) + StarRow
    progress_bar.dart, badges.dart (CheckBadge/CrossBadge), game_feedback.dart (tiles, slots, puzzle cells, pop/shake)
    sun_mascot.dart, sunburst.dart, sky_background.dart, elifba_confetti.dart
    celebration.dart         # the one celebration family: small + big win, overlay or route
    parent_ui.dart           # parent-area dialogs, groups, section headers, snackbar
    tracing_canvas.dart      # the tracing game's draw surface
    parental_gate.dart       # showParentalGate(): 3-second press-and-hold before the parent area
    mute_button.dart         # the quick master-mute button in the book header
    elifba_wordmark.dart     # the outlined "Əlifba" logo (CustomPainter), 4 colour variants
test/
  widget_test.dart               # smoke tests for the alphabet book
  content_integrity_test.dart    # config maps vs. the files actually on disk
  normalize_file_name_test.dart  # normalizeFileName / getFirstLetter behaviour
  progress_test.dart             # star maths, task plan, persistence round-trip
  star_ui_test.dart              # stars on screen: book, letter progress, cards, reset
  settings_test.dart             # AppSettings: isOn() logic, JSON round-trip, corrupt input
  settings_page_test.dart        # parent area UI + the quick mute button
  parental_gate_test.dart        # the hold gate: full hold, early release, no accumulation
  wordmark_test.dart             # the Dart logo path/colours vs. branding/wordmark/*.svg
  foundation_widgets_test.dart   # every shared widget in every state at 360/412, test-hook rules
  foundation_followups_test.dart # keyboard Squishy, dialog semantics/clipping, celebration centring
  home_page_test.dart, letter_page_test.dart, animal_detail_page_test.dart,
  letter_writing_page_test.dart, settings_page_design_test.dart  # per-screen layout + behaviour
  letter_strokes_test.dart, stroke_tracker_test.dart, tracing_canvas_test.dart  # tracing logic
tool/                            # NOT run by `flutter test`: font-accurate PNG capture harnesses
  foundation_gallery_test.dart   # all shared widgets      (GALLERY_OUT, default build/…)
  <screen>_screens_test.dart     # every designed state of home/gate/letter/animal/trace/settings
                                 # at 360x640 + 412x915 (HOME_/GATE_/TRACE_SCREENS_OUT or SCREENS_OUT)
```

Dependencies are deliberately minimal, one per capability: **`just_audio`** (audio),
**`confetti`** (celebration), **`shared_preferences`** (star progress) and
**`path_drawing`** (letter tracing, and the wordmark's outline), plus `flutter_lints`. `shared_preferences` now
backs two stores — star progress and user settings. `flutter_tts`, `turn_page_transition`, `collection`, `cupertino_icons`
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
- `lettersWithAudio` — the letters that actually have a narration recording (all 32
  today). `hasLetterAudio()` gates the speaker button in `animal_list_page.dart`, and
  `content_integrity_test.dart` asserts the set still matches the files on disk.

**Narration provenance.** On 2026-09-29 every narration (32 letters, today 88 animals) was
synthesised, or re-synthesised, from its own `letterDescriptions` / `animalInfo` text, so
the whole app speaks in **one voice** and each recording matches the text on screen. The
older recordings for 3 letters and 61 animals were replaced; many covered only about half
of today's text. The voice is **Inflect-Micro-v2 Azerbaijani** (Apache-2.0,
<https://huggingface.co/spaces/ilqarrrr/Inflect_Micro_v2_Azerbaijan>). That space is static:
the model runs as ONNX, so it was run locally with the space's own `js/tts.js` under Node
(`onnxruntime-node` + `@diffusionstudio/piper-wasm`), defaults speed 1.0 / variation 0.667 /
seed 7 / 15-word chunks. The MP3s were encoded to match the existing ones: MPEG-2, 24 kHz,
mono, 48 kbps. Only the TTS input was prepared, never the app text: lines were joined and a
spaced dash (` – `) became a comma so the pause survives. If you edit a description, the
matching narration goes stale; regenerate it the same way.

**Animal sounds (`<name>_sound.mp3`, 34 files) are levelled.** On 2026-09-29 each one was
processed the same way:
- **Channels and edges:** downmixed to mono, and edge silence trimmed. The threshold is 35 dB
  under the loudest 20 ms window, or 6 dB over the noise floor when a field recording has one.
- **Length:** internal pauses over 1.2 s shortened to 0.6 s, then capped at about 10 s. The cut
  lands at the quietest point between 8 and 10 s, with a 0.4 s fade.
- **Loudness:** normalised to **−18 LUFS** integrated, then peak-limited to −1.5 dBFS.
  `Siçan` sits at about −20 on purpose: pushing its squeaks to −18 would have flattened them.
- **Encoding:** re-encoded as 64 kbps mono MP3 at the source rate (44.1 or 48 kHz).

Before this the loudness spread was 29 LU (from `Şir` at −9 to `Qurd` at −39), and several
files clipped. `Qırqovul` was 67 s long and 89 % silence. A new animal sound should be
brought to the same level, or it will stick out.

**34 more animal sounds were added on 2026-09-29 (68 in total).** They came from freesound,
xeno-canto, Wikimedia Commons, figshare (the supplements of research papers) and NPS.
Only CC0, Public Domain and CC BY sources were used; NonCommercial, NoDerivatives and
"personal use" sources were rejected. They went through the same levelling, plus four
additions for raw field recordings:
- **High-pass per animal** against wind and traffic rumble: 35–100 Hz for large mammals,
  300–600 Hz, 4th order, for birds.
- **Best 10 s, not the first 10 s:** a long recording keeps the 10 s window with the most
  sound within 15 dB of its loudest moment, measured in the animal's own band.
- **Hand-picked segments** for two sources. `Hepard` uses the chirp series at 14.0–17.8 s of a
  seven-call research file. `Turac` uses one song bout at 213.8–217.2 s of a 6.5-minute
  café recording.
- **Two exceptions to the level:**
  - `Dağsiçanı` is a single very short squeak. It sits about 12 LU under target, and extra
    limiting does not raise it.
  - `Yaquar` was allowed 6 dB of limiting instead of 3.

Every **CC BY sound needs its author** in the "Səs mənbələri" dialog
(`settings_page.dart`, `_showSoundCredits`). Add the author there whenever you add one.
Several animals still have no sound, for three reasons:
- **Effectively silent species:** no sound needed.
- **Only non-vocal recordings exist:** Maralöküz, Qunduz, Porsuq, Lama.
- **Only NC or personal-use recordings exist:** Bəbir, Gəlincik, Dovdaq.

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
  letters has content and `maxTotalStars` is 96 — `Ğ`, `I`, `Ü`, `J` and `R` have no animals but can
  still be written.
- `starsFor(done, total)`: 0 done → 0 stars, any progress → 1, `≥ 2/3` → 2, **all** → 3.
  Monotone by design, and the third star is the only strict one, so "did everything about
  this letter" is exactly 3 stars. Pinned by `progress_test.dart`.

**Audio is deliberately not a task.** When stars were designed only 60 of 91 animals had
narration and only 3 of 32 letters had a recording, so counting listening would have put a
full star out of reach for a third of the app. Nothing requires the child to listen. Almost
everything is narrated now (2 animals still are not), but this remains a product decision,
not an accident.

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

`ProgressStore.reset()` is wired to "Progresi sıfırla" in the parent-gated settings page,
behind a second explicit confirmation ("Bütün ulduzlar silinsin?") so a child cannot wipe
the stars with one tap.

### Settings & the audio gate (`core/settings.dart`, `core/sound.dart`)

`AppSettings` is a `ChangeNotifier` singleton that deliberately **mirrors `ProgressStore`
exactly**: same singleton + `forTesting()` factory, same versioned JSON key
(`settings_v1`), same 400 ms debounce, same `try/catch` in `load()`. `main()` awaits both
`load()` calls before `runApp`. Do not invent a second persistence style.

It holds: `masterSound`, `narrationSound`, `animalSound`, `effectSound`, `haptics`,
`reduceMotion`, `puzzleGridSize`. Master overrides the three channels but **never erases
their values** — turning master back on restores what the parent had chosen.

**`GatedPlayer` (`core/sound.dart`) is the only sanctioned way to play audio.** It wraps
`AudioPlayer`, checks `AppSettings.isOn(channel)` before playing, and stops itself the
moment its channel is switched off. Channels: `narration` (`…_info_sound.mp3`), `animal`
(`…_sound.mp3`), `effect` (`click`/`win`/`page_flip`). The gate lives *inside* the player
on purpose — the previous code had 9 separate `AudioPlayer` fields across 5 widgets, and
any new one would have silently bypassed a per-call-site check.

UI binds to settings with `AnimatedBuilder` (the same choice `ProgressStore` made); audio
code does **not** listen, it reads `isOn()` at play time.

The parent area sits behind `showParentalGate()` — a 3-second press-and-hold. It is
knowingly the weakest gate option (see the design doc), which is why the one destructive
action behind it, `ProgressStore.reset()`, keeps its own separate confirm dialog.

`kAppVersion` in `config.dart` must be kept in sync with `pubspec.yaml` by hand.

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

### Brand assets (2026-10-20 rebrand)

The brand comes from a Claude Design project ("Mobile app brand directions"), file
**"Əlifba Brand Assets"**, built from the brief in `docs/design/claude-design-rebrand-prompt.md`.
Direction "Lavanda buludu": an orange sun in a lavender sky. The brand assets, the design
system and every screen of that project are implemented (see Design system below).

- **Launcher icon = three VectorDrawables**:
  `res/drawable/ic_launcher_{background,foreground,monochrome}.xml`, wired up by
  `res/mipmap-anydpi-v26/ic_launcher{,_round}.xml`. They are **generated** by
  `python branding/build_icon_vectors.py` (needs `pip install skia-pathops fonttools`).
  That script holds the design's geometry and colours as constants. **Edit the constants,
  never the XML**, then run it and `render_icons.py`. The pipeline is: design geometry →
  VectorDrawables → bitmaps.
  - **Background:** `#8F78E6` sky, a `#7C63D9` hill and three clouds at 16–18 %.
  - **Foreground:** the outlined Comfortaa Bold "Ə" (`#FFFDFB`) with a `#5C45B5` shadow
    offset 3 units, and the sun (`#FFC547`, rays `#FFA62B`). The sun's ring is *painted*
    in the background colour `#8F78E6`, as in the design.
  - **Monochrome** (Android 13+ themed icons): one path, `((Ə ∪ rays) − disk r8.8) ∪ disk
    r6.4` around the sun at (68, 40). The generator derives it from the same constants
    with skia-pathops, so it follows any change to the letter or the sun. No renderer
    has to support clip-path holes.
- **Bitmaps are rendered from those vectors** by `python branding/render_icons.py`
  (Pillow plus headless Chrome or Edge). It writes:
  - the legacy `mipmap-*/ic_launcher.png` (rounded square) and `ic_launcher_round.png`
    (circle); minSdk is 21, so API 21–25 uses them;
  - every iOS `AppIcon` PNG (opaque);
  - the web icons, favicon included.

  Its VectorDrawable→SVG converter knows only literal `#hex` colours and plain
  path/group attributes, and **exits on anything else** rather than render it wrong. Its
  square render matches the design's own `ic_play_512.png` export to within
  anti-aliasing.
  `flutter_launcher_icons` was removed from `pubspec.yaml` on purpose: it would replace the
  vector icon with one built from a single PNG.
- **Store art** (`docs/store/`) is the design's own export, not rendered here:
  - `ic_play_512.png`: 512×512, no mask or shadow; Play adds them.
  - `feature_graphic_1024x500.png`: flattened to RGB, because Play rejects alpha.

  `branding/logo.png` is a copy of the Play icon (the old LinkedIn templates use it).
- **Wordmark:** `branding/wordmark/elifba_wordmark_{light,lavender,mono,dark}.svg`, one per
  background. The dot of the dotless **ı** is the sun. In the app it is
  `ElifbaWordmark` (`widgets/elifba_wordmark.dart`): the same path drawn with
  `path_drawing`, never a `Text`. The brand forbids another font, a plain dot, coloured
  letters and stretching, so the painter scales uniformly. `wordmark_test.dart` fails if
  the Dart path, viewBox, sun position/radii or colours drift from the SVGs. The book header
  uses the `light` variant (height 37); the About dialog shows it too.
- **Launch screen:** `@color/splash_background` = `#E4DEFF` (the design's `skyTop`), in
  light and dark mode alike, because the app has no dark theme. The design names no
  splash colour, so this is a choice. On Android 12+ the colour is set explicitly through
  `windowSplashScreenBackground` in `values-v31` and `values-night-v31`. Without it, the
  system would estimate the colour from the layer-list's bottom layer, which happens to
  be the same. Those folders **redefine the whole `LaunchTheme`**, so all four copies
  (`values`, `values-night`, `-v31`, `-night-v31`) must change together.
- **App name** under the icon is **"Əlifba"** (Android label, iOS display name, web
  manifest). It used to be lowercase "əlifba".

### Design system (redesign, 2026-10-20)

Every screen follows the same Claude Design project's "Əlifba Design System" and "Əlifba
Screens" files: light lavender sky backgrounds, candy-pastel cards, squishy buttons, an
orange sun mascot. The parent area (settings, gate, dialogs) is calmer: flat `#F8F5FF`, no
squish, no mascot.

- **Never hard-code a hex that has a name.** Colours come from `ElifbaPalette` (consts, for
  painters and tests) or `ElifbaColors.of(context)` (theme extension); sizes from
  `ElifbaSpace/Radius/Edge/Ring/Size`; text from `ElifbaTypography` / `ElifbaTextStyles`;
  timing from `ElifbaMotion`. Letters get a colour set by `AppConfig.alphabet` index % 6
  (`ElifbaPalette.letterSetFor`); a complete letter/animal uses the gold `complete` look.
- **Fonts:** Comfortaa Bold (letters, titles, buttons) and Andika 400/700 (body, chips,
  parent area). Both are SIL OFL with a Reserved Font Name, so the `.ttf` files are kept
  **unmodified** (no subsetting); licences are `assets/fonts/OFL-*.txt`. Both contain all 64
  Azerbaijani letters with single-storey a/g. Lower-case display letters come from
  `AppConfig.lowerOf()` (explicit table), never `toLowerCase()`.
- **Icons:** Material `Icons.*_rounded`, except two deliberate `_outlined` glyphs that are
  also test hooks: the settings gear (`Icons.settings_outlined`, `QuietIconButton`) and the
  gate's hold button (`Icons.touch_app_outlined`). Every back button has tooltip **'Geri'**.
- **`Squishy`** is the press primitive behind every child tappable: solid darker bottom
  edge, press = translate by the edge in 90 ms easeOut, release 140 ms easeOutBack, no blur.
  It builds **exactly one `AnimatedContainer`** (its frame); `widget_test`'s `_cardOf` /
  `_writeCardOf` rely on that, so nothing inside a card may be another
  `AnimatedContainer`. Edges and rings paint outside the layout box, so a clipping scroll
  view needs at least `edge` dp of padding under its last squishy child. It is focusable
  (keyboard, D-pad, switch access) with a 2 dp secondary focus ring.
- **Stars** are `StarGlyph` (the design's stroked star path), not icons. Tests count them
  with `find.byWidgetPredicate((w) => w is StarGlyph && w.filled)`.
- **Right / wrong is never colour alone:** a check `CheckBadge` / cross `CrossBadge`, a
  solid ring vs a dashed outline, a pop vs a 280 ms shake, a -5 degree tilt on wrong tiles.
- **Celebrations are one family** (`widgets/celebration.dart`): `CelebrationCard.small`
  (word puzzle, image puzzle) and `.big` ("Tam ulduz!", "... hərfi tamam!"). The animal page
  shows its two as in-page `CelebrationOverlay`s (present after one `pump()`); the image
  puzzle's (1.5 s after solving) and the letter-complete card are routes
  (`showCelebration`). Each has a reduced-motion version.
- **Reduced motion** means `AppSettings.instance.reduceMotion` only (`ElifbaMotion.reduced`;
  `MediaQuery.disableAnimations` is deliberately ignored). It removes confetti, the
  celebration entrances and ray rotation, the food flight (fade instead), right/wrong pop
  and shake, the audio "playing" pulse and the tracing shake/pulse; shapes and icons stay.
  Squish presses and the 500 ms page turn are not gated.
- **Infinite animations** (audio playing pulse, big-win ray rotation, tracing start-dot
  pulse) run only while their state is active. Never `pumpAndSettle` while one runs, or
  while confetti plays (the package uses the real clock).
- **Text scale** is clamped to 1.3x in `MaterialApp.builder`, so 48-64 dp pills never overflow.
- **Visual checks:** `flutter test tool/<screen>_screens_test.dart` renders every designed
  state with the real fonts into PNGs (a fake just_audio platform lives inside the
  harness). Compare them with the design renders after any UI change.

Behaviour that changed with the redesign (everything else is identical):
- the animal page's tabs are a radio group (tapping the selected tab does nothing; before,
  it could hide every section);
- the image-puzzle hint disables "İpucu" and locks the board for its 2 s (see gotcha 14);
- the gate turns green and closes 200 ms after a full 3 s hold;
- the letter-complete celebration has confetti;
- labels "Kömək" -> "İpucu", "Puzzle" -> "Pazl"; settings headers in sentence case.

## Conventions

- State management is plain `StatefulWidget` + `setState`. No Provider/Bloc/Riverpod.
- Audio goes through `GatedPlayer` (`core/sound.dart`), never a bare `just_audio`
  `AudioPlayer`; confetti uses `confetti`; the word/image puzzles use Flutter's built-in
  `Draggable`/`DragTarget`.
- **Do not run `dart format` over `lib/` or `test/`.** The committed code is in the old
  (short) formatter style, and Dart 3.8's formatter rewrites it to the tall style — a
  one-line edit turns into a 500-line diff in files you never touched, which is unreviewable
  and collides with anyone else working in the tree. Format only files you actually wrote,
  or match the surrounding style by hand. `flutter analyze` does not check formatting, so
  nothing forces the issue.
- Colors use `Color.withAlpha((opacity * 255).toInt())` (post-`withOpacity` migration).
- Fonts declared in `pubspec.yaml`: `Andika` (default, via the theme) and `Comfortaa`.
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
   **Letter audio is already fixed:** `AppConfig.letterAudioPath()` maps `I` to `ı/`
   explicitly, so `I` plays `assets/audios/ı/ı_info_sound.mp3` and `İ` plays `i/`. Images
   and the rest still go through `toLowerCase()`.
   The trap also works the other way: `toUpperCase()` turns `i` into `I`, never `İ`.
   The redesign avoids all-caps text altogether (settings headers are sentence case; the
   old `_SectionHeader` that showed "VALIDEYN" is gone). If capitals are ever needed, map
   `i → İ` first. `ProgressStore` keys letters through its own explicit lower→upper table,
   and `AppConfig.lowerOf()` goes the other way, for the same reason.
3. **Where the widgets live.** `AnimalWordPuzzle` is defined **inline** in
   `animal_detail_page.dart`; the old duplicate `pages/animal_word_puzzle.dart`
   and the YouTube widget were deleted. Do not reintroduce copies of either.
4. **No network, no webview.** The YouTube / `webview_flutter` feature is gone: no map, no
   field, no widget. `android/app/src/main/AndroidManifest.xml` declares **no permissions
   at all** (INTERNET exists only in the stock debug/profile variant manifests, for the
   Dart VM service). Everything the app plays or shows is a bundled asset — keep it that
   way, a children app with no network permission is far easier to ship.
5. **AudioPlayer init.** `GatedPlayer` fields are constructed synchronously at the field
   declaration (`final ... = AudioPlayer()`), and `setAsset` calls live inside a
   try/catch. Keep this pattern — moving construction into an async `_initAudio()`
   reintroduces a `LateInitializationError` race on early interaction or `dispose()`.
6. **A silent audio button must not exist.** All 32 letters and 88 of 90 animals have
   narration today, but that coverage is not guaranteed. The letter speaker button is rendered only when
   `AppConfig.hasLetterAudio(letter)` is true, and every `setAsset` is wrapped in
   try/catch — without both, a missing file leaves the button stuck in its stop state and
   swallows the first tap. Apply the same rule to any new audio affordance.
   The same rule now covers **muting**: when a channel is off, its button renders
   greyed out with a `volume_off_rounded` icon and `onPressed: null` (`AudioButton` /
   `AudioPillButton` in the `muted` state do both). Without that, the
   button's `isPlaying` flag would latch forever — nothing plays, so the
   `ProcessingState.completed` event that clears the flag never arrives.
7. **Asset bloat.** The whole `assets/` tree is declared in `pubspec.yaml`, so anything
   dropped in there ships to every user. Store/branding art lives **outside** `assets/`
   on purpose: `docs/store/` (Play icon, feature graphic) and `branding/` (icon renderer,
   wordmark SVGs, `logo.png`; see Brand assets). Two cleanups so far: 2026-07-30 removed 66
   duplicate `*.mp3` (10.8 MB) and web junk; 2026-09-08 converted all PNG art to WebP and
   re-encoded the oversized sound effects.
   ⚠️ The per-letter card images (`assets/images/<letter>/<letter>*.webp`) are **never
   rendered** — `alphabet_page.dart` draws each letter as two Comfortaa `Text`s (upper and
   lower case; tests tap `find.text(letter)`). They are kept only as small 512 px WebP files
   in case a letter card is added later; do not let them grow back. The stock book photo
   (`book_cover.webp`) and the unused `ball`/`basket` images were removed in the redesign,
   and so were the NotoSans and Baloo2 fonts.
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
    turns on `SystemUiMode.edgeToEdge` for every Android version and sets
    `kElifbaSystemUiStyle`: **dark** icons on transparent bars, because every page now sits
    on a light background. The AppBar-less pages repeat it with an `AnnotatedRegion`. Each
    page insets its own content: `alphabet_page`, `letter_writing_page` and the puzzle use
    `SafeArea`; `animal_list_page`, `animal_detail_page` and `settings_page` add
    `MediaQuery.viewPaddingOf(context)` to their scroll padding. Keep the full-bleed
    `SkyBackground` *outside* the inset so it still paints behind the bars. **A new page must do one of these or its bottom content hides under the nav
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
    lazily: it is a `SliverGrid` inside the letter page's single `CustomScrollView`
    (`ValueKey('letterPageScroll')`), so on the 800x600 test surface only the first rows
    exist; a finder reaching a later animal matches nothing — use
    `tester.scrollUntilVisible` (with an explicit `scrollable:` on pages that have more
    than one Scrollable, like the animal page). Adding a cell at the head of the grid
    shifts which animals the first slots hold, so a test that names an animal by position
    breaks without the grid itself being wrong.

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

13. **Never add a fixed-height row above a page's scrolling area.** On short screens the
    old `Column` + `Expanded(<scrollable>)` layouts overflowed, and an extra row squeezed
    the lazy grid until it built no cells. The redesign removes the problem at the root:
    the letter page is one `CustomScrollView` (info card, "Heyvanlar" row, `SliverGrid`
    scroll together) and on the animal page everything below the 64 dp bar scrolls, with
    only the pill tabs sticky. Badges still cost zero height: the animal's stars are a
    pill overlaid on the stage, and the letter's progress lives **inside** the "Heyvanlar"
    row (which wraps to two lines on very narrow / large-text screens).

14. **A puzzle star must not be awarded during a hint.** `_showHint()` in
    `puzzle_page.dart` puts the solved arrangement into `slots` for 2 seconds, which makes
    `_isCompleted()` return `true`. The single `_checkCompleted()` is therefore guarded
    with `!showHint` before calling `widget.onCompleted`. On top of that, "İpucu" is
    disabled while the hint shows (a second tap used to save the solved board as the
    "original"), the board and tray ignore input (`IgnorePointer`), and drops return early;
    the screen shows the child's own board under a 40 % ghost photo.

15. **Never construct a bare `AudioPlayer`.** Every sound must go through
    `GatedPlayer(SoundChannel.x)` (`core/sound.dart`), which is what makes the parent's
    mute switches actually work. A raw `AudioPlayer` plays straight through a muted app,
    and nothing in the build catches it. This is not hypothetical: the tracing game was
    added while the settings feature was being designed and brought two more players with
    it, taking the count from 7 to 9. Pick the channel by the sound's **role**, not its
    file name — `click.mp3` is an `effect` in both the puzzle and the tracing game.

16. **`reduceMotion` gates confetti at the call site.** All six `ConfettiController.play()`
    calls (3 in `animal_detail_page.dart`, 1 each in `puzzle_page.dart`,
    `letter_writing_page.dart` and the `showCelebration` route in `celebration.dart`) are
    wrapped in `if (!AppSettings.instance.reduceMotion)`. The `ConfettiWidget` stays in the
    tree (it paints nothing when not playing) — do not make the widget itself conditional.
    Controllers come from `ConfettiPreset.small/.big.createController()` (design colours,
    at most 40 pieces).
17. **The gate's 3 s must not shrink.** `parental_gate.dart`'s controllers use
    `AnimationBehavior.preserve`: with the system "remove animations" setting a normal
    `AnimationController` runs 20x faster, which turned the 3 s hold into 150 ms. The 200 ms
    "done" beat is an `AnimationController` too — never a `Timer`.

## Known content gaps

Tracked as allowlists in `test/content_integrity_test.dart`, not as TODO comments:

- 2 of 90 animals have **no narration** (`<name>_info_sound.mp3`): `Qarışqayeyən` and
  `Qırqovul`, because they have no description text to narrate.
- `Ğ`, `I`, `Ü`, `J`, `R` have **no animals** — their list page opens empty. `J` and `R`
  emptied when their only animals got their standard names (Jaquar → Yaquar, Rakun → Yenot).
- `Ş` has no letter-card image; `Qarışqayeyən` and `Qırqovul` have no description text.
- 22 of 90 animals have **no animal sound** (`<name>_sound.mp3`); see the sound notes above.

**The name is the source of truth** for an animal. Its picture, text, foods and sounds must
match what the Azerbaijani name means, as az.wikipedia defines it.

A full audit of all 91 animals (name, illustration, puzzle photo, text, foods) ran on
2026-09-29/30. Every changed text had its narration regenerated.

Fixed:
- **Rewritten:** `Dovdaq`, `Turac`, `Baltadimdik`, `Dələ`, `Sarıköynək` and `Suiti` had
  texts, and some foods, describing another animal. Suiti's text described a small bird.
- **Corrected in about 50 more texts:**
  - **Grammar:** `ovlanmaq` means "to be hunted", not "to hunt". Also `sudan yaşamaq`,
    `qarını`, `boyunu`, `baraj`, `istifadə etmək` + ablative, and `iy bilmə` →
    `iybilmə`.
  - **Facts:** mammoth tusks are not horns, rhino horns sit on the nose, a snail shell is not
    bone, pandas live alone, and a cat does not catch with its tongue.
  - **Foods:** only from the existing food images. The `Qurd` food icon is an earthworm, so
    it is not used where a wolf could be read.
- **Standard Azerbaijani names** (orthography dictionary orfoqrafiya.azleks.az, or az.wikipedia
  where the dictionary has no entry). Every map key, text, credit and asset file was renamed with
  them, and some animals moved to another letter: `Leylek` → `Leylək`, `Jaquar` → `Yaquar` (Y),
  `Rakun` → `Yenot` (Y), `Echidna` → `Yexidna` (Y), `Çita` → `Hepard` (H; az.wikipedia title),
  `Eland` → `Maralöküz` (M), `Hamster` → `Dağsiçanı` (D), `Flamingo` → `Qızılqaz` (Q; the text
  still says it is also called flaminqo) and `Zebra` → `Zebr`, including Şir's food.
  Saved stars of a renamed animal do not carry over, because progress is keyed by the name.
- **Merged duplicate:** `Leopard` was the same species as `Bəbir`, so it was removed. Bəbir
  now uses Leopard's spotted illustration instead of the black panther. Its text, foods and
  puzzle photo stay.
- **Photos:** `Dələ` uses the marten illustration that had been filed under `Çalağan`.
  Four puzzle photos were replaced or recropped:
  - `Baltadimdik`: hawfinch, iNaturalist photo 122343794, CC0, Лариса Артемьева.
  - `Sarıköynək`: male golden oriole, Commons
    "Rigogolo-maschio-Lazio, isola di Ventotene (LT) 19.4.2024.jpg", CC0, Carlo Caimi.
  - `Ulaq`: donkey, replacing a mule; iNaturalist photo 529310977, CC0,
    Emily Langdon-Lassagne.
  - `Ayı`: recropped from 655×468 to a 600×600 square.

**Illustrations that are still wrong.** Ready prompts for all of them are in
`docs/art/illustration-prompts.md`:
- **A different animal:**
  - `Çalağan`: a marten.
  - `Dovdaq`: a pheasant.
  - `Turac`: a peacock.
  - `Camış`: an African buffalo.
  - `Baltadimdik`: a shoebill.
  - `Sarıköynək`: a wagtail.
  - `Qırqovul`: a bobwhite quail.
  - `Maral`: a white-tailed deer.
  - `Ceyran`: a Thomson's gazelle.
  - `Gürzə`: a common adder.
  - `Kəklik`: a red-legged partridge.
- **Wrong anatomy:**
  - `Ağcaqanad` has 8 legs.
  - `Dağsiçanı` (hamster) has a long rat tail.
  - `Çaqqal` has invented stripes.
  - `Maralöküz` (eland) has kudu-like horns and no dewlap.

`keklik.webp` was a style reference; do not use it as one any more.

**Open question:** the `Leylək` animal sound is an American wood stork (fws.gov), not a white stork.

## Security

`android/app/build.gradle.kts` currently contains **hardcoded keystore passwords** as
env-var fallbacks (and they are in git history). Never commit signing passwords — rely on
`STORE_PASSWORD`/`KEY_PASSWORD` env vars only, and rotate the leaked credentials.
