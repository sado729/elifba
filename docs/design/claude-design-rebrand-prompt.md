# Əlifba — rebrand and full redesign brief

## 1. The product

**Əlifba** is an offline Android app, built in Flutter, that teaches the 32-letter
Azerbaijani Latin alphabet to children aged about 4–7. It is live on Google Play
(v1.4.0). It is free, with no ads, no internet access, no accounts and no data collection.

I want a **full rebrand and visual redesign**. The new look should be softer, warmer and
more playful, and more inviting for small children. **Every existing feature must stay and
work exactly as it does today.** This is a redesign, not a feature change. Section 7 lists
every screen, feature and state, and each one needs a place in the new design.

**The core loop:**
1. The child opens an alphabet "book" and picks a letter.
2. They see the animals whose names start with that letter, and open one.
3. On the animal's page they read or listen about it, feed it, solve a word puzzle and
   solve an image puzzle.
4. They trace the letter with a finger.

Every finished activity earns stars.

## 2. Who it is for

- **The child (4–7)** is the main user. Many are pre-readers or early readers. They find
  their way by picture, colour, sound and position, not by reading labels. Their fingers
  are small and imprecise, they don't like waiting, and they love feedback and
  celebration.
- **The parent** installs the app. Behind a parental gate they control sound and settings
  and can reset progress. The parent area can be calmer and more grown-up, but it must
  feel like the same brand.

## 3. What is wrong with the current look

- **It feels like night-time.** Almost every screen is dark navy or indigo: gradients
  from `#2E2B5F` to `#1B1A3A`, and Material `deepPurple 700`, with bright `yellowAccent`
  highlights. It feels heavy and low-energy, not like a children's app.
- **It looks like a utility app.** Most parts are stock Material 3 widgets: default
  AlertDialogs, Chips, SwitchListTiles and ElevatedButtons.
- **It is inconsistent:**
  - The word puzzle uses light-blue tiles.
  - The image puzzle uses an amber hint button and deep-purple level buttons.
  - The celebrations come in three different styles: a custom overlay, a plain
    AlertDialog, and an AlertDialog with stars.
- **Some touch targets are too small.** Top-bar arrows and icons are 22–24 dp. For long
  animal names, the word-puzzle letter tiles shrink to 18 dp.
- **Right and wrong are shown by colour alone,** a green or red border, which is not safe
  for colour-blind children.
- **The home book is a stock photo** of a blank brown book.
- **The current brand art does not match the app.** The attached icon and feature graphic
  show a bright blue sunburst, glossy 3D multicolour letters, an open book and the line
  "Azərbaycan əlifbasını öyrən!". The app itself is dark purple.

## 4. Brand direction

- **Mood:** soft, warm, friendly and safe, like a picture book. Not a slot-machine game.
- **Backgrounds:** light and warm (cream, paper, pastel sky) instead of dark purple.
  Avoid a full screen of pure `#FFFFFF`, neon colours and black.
- **Accents:** candy pastels, saturated enough to feel joyful. Letters and cards can
  rotate through a set of friendly colours, so the alphabet feels like a box of crayons.
- **Shapes:** round everything. Use big corner radii, pill buttons, soft organic
  background shapes and soft shadows. Tactile "squishy" buttons are welcome: a solid,
  darker bottom edge that presses down on tap.
- **Typography:**
  - Letters and headings: a rounded, chunky, friendly display face. Baloo 2, which the
    app already bundles, is one option.
  - Body text: a very legible face for early readers. Andika (SIL), designed for
    beginning readers, is a candidate worth checking.
  - Both faces must pass the glyph rules in §5.
- **Name:** keep "Əlifba". A new wordmark and logo are part of this work.
- **Colour:** you may keep a softened purple or lavender as a bridge to the old brand,
  but you don't have to.
- **Mascot (optional):** if you propose one, keep it simple and flat, so it can be
  exported as a few poses (idle, cheering, pointing, sleepy for empty states).
  - It appears only in a few places: the home header, empty states, celebrations and
    image placeholders. It never appears in the parent area.
  - One idea: a character built from the letter **Ə**, which only Azerbaijani has.
  - If it is a real animal, draw it accurately. In this app, an animal's picture must
    match its real species.
- **The design must sit well next to the content art,** which is not changing (see §6).

## 5. Hard constraints

### Platform and implementation

- **Devices:** Android phones in portrait. Design at **360×640 dp** (small: everything
  must fit) and **412×915 dp** (typical). Rotation is not locked, so layouts must not break
  in landscape, but they don't need their own designs. Tablet layouts are a nice extra.
- **Build:** everything must be buildable in Flutter, with Material 3 underneath and
  custom widgets on top: Flutter's own widgets, `CustomPainter` and built-in animations.
  Give every size in dp and every colour in hex.
- **No new runtime dependencies** unless you name them and give the reason. For example,
  Lottie or Rive animations need a package, and so does rendering SVG (`flutter_svg`).
- **Icons:** use Flutter's built-in Material Icons (Rounded variants are available), or
  supply custom bitmap art.
- **Bitmap art** is exported as WebP, with transparency where needed.
- **Fonts** must have an open licence (SIL OFL or similar), because they are bundled.
  The app never goes online.
- **Performance:** the app must run on low-end Android phones. Avoid full-screen backdrop
  blur, large animated gradients behind scrolling grids, and heavy layered shadows on
  every grid cell.
- **Edge-to-edge:** Android 16 draws the app behind the status bar and the navigation
  bar, so backgrounds must run full-bleed and content must keep clear of the bars. For each
  screen, say whether the status-bar and nav-bar icons are light or dark. Today they are
  always light, because every screen is dark.
- **Short screens:** the animal page and the letter page already overflow on short
  phones.
  - Do not add fixed-height rows above the scrolling areas.
  - Badges and progress indicators should overlay the content or live inside rows that
    already exist.

### Language and letters

- **All UI text is Azerbaijani.** Use the exact strings from §7. If you think a piece of
  copy should change, mark it as a suggestion, in Azerbaijani only, and I will review it.
- **The display and body fonts must render all of these:**
  `A B C Ç D E Ə F G Ğ H X I İ J K Q L M N O Ö P R S Ş T U Ü V Y Z` and
  `a b c ç d e ə f g ğ h x ı i j k q l m n o ö p r s ş t u ü v y z`.
  - Show a specimen of all 32 letters in both cases.
  - **I/İ and ı/i must be impossible to confuse.** The dot is the whole difference.
  - **Ə/ə must look like a real Ə,** not a rotated "e" from a fallback font.
  - For a learning app, prefer school-style letterforms: a single-storey **a** and **g**.
- **Capitals:** in Azerbaijani the capital of **i** is **İ**, so "Valideyn" in capitals is
  **VALİDEYN**, never "VALIDEYN". Prefer sentence case for labels. If you use capitals,
  write them out correctly.

### Child safety

Do not add any of these: ads, external links, purchases, accounts, streaks or daily
pressure, timers, notifications, leaderboards.

### Accessibility

- Touch targets are at least **48 dp** everywhere, and at least **64 dp** for the child's
  main actions.
- Text contrast meets WCAG AA: 4.5:1 for body text, 3:1 for large text.
- **Never show right and wrong by colour alone.** Add an icon, a shape or motion.
- Every celebration needs a **reduced-motion version**, because the parent can switch
  confetti off.
- Each action a child takes must be clear from its icon or picture alone. Text labels
  support the picture; they don't carry the meaning.

## 6. Content that is not changing: design around it

- **Animal illustrations.** There are 90 semi-realistic digital paintings in a
  children's-encyclopedia style. Each is one animal cut out on a transparent background,
  400×400 WebP. Their shapes vary widely: a tall giraffe, a long snake, a wide crocodile, a
  tiny insect.
- **Food pictures.** There are 100 cut-out images, 256 px, shown small (32–64 dp) next to
  a name.
- **Puzzle photos.** Square real photographs, 600×600, used by the image puzzle.
- **Audio.** Narration for every letter and almost every animal, 68 animal sounds, and
  three effects: click, win and page flip.

Frame this art; don't restyle it. A flat cartoon UI next to semi-realistic paintings can
clash, so solve that. For example, a soft coloured "stage" shape could sit behind each
animal.

**Real data to use in mockups:**
- **Letters:** 32 letters, shown 2 per spread, so the book has 16 spreads.
- **Animals:**
  - There are 90 animals, from 0 to 11 per letter. Q has 11; Ğ, I, Ü, J and R have none.
  - The longest name is **Qarışqayeyən** (12 letters). Other names: Ayı, Fil, Pinqvin,
    Zürafə, Ağacdələn, Sarıköynək.
  - Each animal has 1–6 foods, and some food names are two words ("Quru yem"). For
    example, Ayı eats: Bal, Balıq, Giləmeyvə.
- **Animal descriptions** are 4–5 short paragraphs, about 600–900 characters. Sample
  (Ayı):
  > Ayılar çox güclü və ağıllı heyvanlardır. Onların burnu çox iti olur, hətta
  > kilometrlərlə uzaqdan yeməyin qoxusunu ala bilirlər! Ayılar çox vaxt tək yaşayır və
  > meşələrdə, dağlarda və bəzən buzlu yerlərdə görülür.
  > Ən məşhur ayı növlərindən biri qütb ayısıdır – o, tamamilə ağ rəngdə olur və buzlu
  > dənizlərdə yaşayır. …
- **Letter descriptions** are 5 short lines. Sample (B):
  > B hərfi balaca baloncuklar kimi görünür – böyük B-də iki dairə var!
  > "B" ilə başlayan sözlərə bax: balıq, barmaq, balon!
  > Bu hərf həm yazıda, həm də danışıqda çox işlənir.
  > B hərfini yazmaq bir az oyuncağa bənzəyir – əvvəl bir xətt, sonra iki yumru!
  > Uşaqlar bu hərfi öyrəndikcə bir çox maraqlı şeylərin adını deyə bilirlər!
- **Stars:** at most 96 in total (32 letters × 3).

## 7. Every screen, feature and state

### 7.1 Systems used across the whole app

**Stars and progress**
- **Animal tasks.** Each animal has 3 or 4 tasks:
  - **Məlumat** (reading). It counts as done as soon as the animal is opened.
  - **Qidalar.** Feed **all** of the animal's foods.
  - **Söz tapmaca** (the word puzzle).
  - **Pazl** (the image puzzle). Only some animals have it.
- **Letter task.** Each letter has one more task: tracing the letter.
- **Star rule.** Stars go from 0 to 3 by the share of tasks done: nothing → 0, anything
  → 1, at least two-thirds → 2, everything → 3. Animals and letters use the same 3-star
  row. Today the stars are gold, `#FFD54F`.
- **Where stars appear:**
  - under each letter in the book;
  - in the "Heyvanlar" heading row of the letter page, with a thin progress bar and
    "9/30", or "Tamam!" when the letter is complete;
  - under each animal's name on its card;
  - on the animal page's picture, with "2/4";
  - in celebrations;
  - as a single star on the trace card and on the tracing screen;
  - as the home screen's total, "41/96".
- **A complete letter** (3 stars) must look special in the book. Today it gets a gold
  border and a glow.

**Sound**
- **Channels.** There are three: narration, animal sounds and effects. The parent can mute
  each one, and the master switch overrides all three.
- **Every audio button has 3 states:**
  - **ready:** a play icon;
  - **playing:** a stop icon;
  - **muted:** greyed out, disabled, with a mute icon.

  Design all three. A muted button must never look tappable.

**Celebrations**
- **Today there are 5 kinds,** and all but the last one have confetti:
  - the word puzzle is solved;
  - the image puzzle is solved;
  - a letter is traced;
  - every task of an animal is done ("Tam ulduz!");
  - every task of a letter is done (a "… hərfi tamam!" dialog).
- **Make them one family,** with a small-win and a big-win level.
- **Each one needs a reduced-motion version:** no confetti, a calm static reward instead.

**Navigation and motion**
- **Letter page:** it slides in from the right. Moving to the previous or next letter
  slides from the left or right.
- **Book:** its pages turn with a flip sound, 500 ms, ease-in-out cubic.
- **Please give a motion spec** for transitions, button presses, right and wrong feedback,
  and celebrations.

**Loading and fallbacks**
- Images fade in over 400 ms.
- A missing image shows a placeholder. Today this is a paw icon or a broken-image icon.
  Design a friendly one.

### 7.2 Home: the alphabet book (the first screen)

**Header row**
- **Total stars badge:** a star and "41/96". Its spoken label is
  "96 ulduzdan 41 ulduz yığılıb".
- **Title:** "Əlifba".
- **Quick mute button.** It is deliberately **not** behind the parental gate: a parent on
  a bus needs it in one tap. It turns all sound on or off. Its tooltip reads
  "Səsi söndür" or "Səsi aç". Design it on and off.
- **Settings button** (a gear; tooltip "Ayarlar"). It opens the parental gate, then the
  settings. It should look like a parent's control, not something attractive to a child.

**The book**
- It swipes sideways through 16 spreads, with 2 letters per spread. Arrow buttons also turn
  the page, with a page-flip sound.
- Each letter shows a large glyph (today Baloo 2, 72 sp) with a 3-star row under it.
  States: 0, 1, 2 and 3 stars; 3 stars is the "complete" highlight.
- Tapping a letter opens its letter page.

**Bottom bar**
- Previous and next arrows, with a book icon between them.
- There is no disabled state at the first or last spread today; design one.
- There is no page indicator today. You may add one (16 pages) if it fits.

**States to show:**
- the first spread (A, B) right after install, with 0 stars;
- a middle spread with mixed progress, including one complete letter;
- the last spread (Y, Z);
- the mute button switched off.

### 7.3 The parental gate (a dialog)

- **Content:** a lock icon, the title "Valideynlər üçün", and the text
  "Davam etmək üçün düyməni 3 saniyə basıb saxlayın."
- **Hold button:** one 72 dp button in the centre. A ring around it fills over 3
  seconds.
  - Letting go early resets the ring to zero; progress never accumulates.
  - When the ring is full, the settings open.
- **Cancel:** a "Ləğv et" button.
- **Mood:** deliberately uninviting to a child: calm and neutral.
- **States:** idle, holding (ring half full), done.

### 7.4 The letter page (for example "B hərfi")

**Top bar**
- Back; the title "B hərfi".
- Previous and next letter arrows, with the tooltips "Əvvəlki hərf" and "Növbəti hərf".
  They are disabled at A and at Z.

**Letter info card** (collapsible)
- **Collapsed** is the default: it shows "B hərfi haqqında oxu" with an expand chevron.
- **Expanded:** it shows "B hərfi haqqında" and the 5-line letter description.
- **Narration button for the letter.** It has the 3 audio states, with the tooltips
  "Səsləndir", "Dayandır" and "Səs söndürülüb". Today it is a round yellow button that
  overlaps the card's top-left corner. It appears only when a recording exists, which is
  all 32 letters today.

**The "Heyvanlar" heading**
- The letter's progress shares the heading's row: a thin progress bar, 3 stars, and the
  text "9/30", or "Tamam!" when the letter is complete.
- This must not make the page any taller.

**The grid** (2 columns, scrolling)
- **First cell: the "write the letter" card,** which opens the tracing game.
  - It shows the letter as a path that has not been traced yet: a thick faint "road", a
    dashed centre line, and a coloured dot where the first stroke starts.
  - It also shows a single star (filled once the letter has been traced) and a small quill
    icon.
  - It must read clearly as an activity, not as another animal.
  - Its spoken label is "B hərfini yaz".
- **Then the animal cards:** each has the illustration, the name and a 3-star row.
- **Empty letters** (Ğ, I, Ü, J, R) show only the write card, with the message
  "Bu hərflə başlayan heyvan yoxdur, amma hərfi yaza bilərsən!"
- **Fallback,** never reached today (no animals and no tracing):
  "Bu hərflə başlayan heyvan yoxdur."

**Letter-complete celebration**
- It shows once, when the child comes back to this page after finishing the last task.
- **Content:** 3 big stars; the title "B hərfi tamam!"; the text "Bu hərflə bağlı hər şeyi
  etdin — heyvanları, tapmacaları və hərfi yazmağı. 3 ulduz sənindir!"; a "Yaşa!" button.

**States to show:**
- a letter with many animals (Q has 11), scrolled;
- a letter with one animal (E);
- an empty letter (Ğ);
- the info card expanded;
- a complete letter;
- narration playing;
- narration muted.

### 7.5 The animal page (for example "Ayı")

**Top bar**
- **Back.**
- **The animal's name,** with an animal-sound button next to it.
  - The button appears only for animals that have a sound (68 of 90).
  - It has two states: ready (tooltip "Heyvanın səsi") and muted (tooltip
    "Heyvan səsləri söndürülüb").
  - The sound plays on its own channel, so it never interrupts narration.
- **Previous and next animal** within the same letter. They are disabled at either end.

**Picture area**
- The illustration is large. Today it sits in a 16:9 area on a purple panel with rounded
  bottom corners.
- A corner overlay shows the animal's 3 stars and "2/4". It must not take any vertical
  space.

**Section switcher**
- Up to 4 pill tabs, each with an icon and a label: "Məlumat", "Qidalar",
  "Söz tapmaca", "Pazl". The Pazl tab appears only for some animals.
- Each tab has a selected state, and a finished section shows a check mark.
- "Məlumat" is open by default.

**Section A: Məlumat**
- A card titled "Məlumat:", with a listen button that has the 3 audio states: "Dinlə",
  "Dayandır", "Səs söndürülüb".
- Below it, the description (4–5 paragraphs). It must stay comfortable to read: a good
  line length and at least 16 sp.

**Section B: Qidalar (feeding)**
- A card titled "Qidaları:". Each food is a chip with its picture and name.
- Tapping a chip sends the food picture flying from the chip to the animal along an arc of
  about 0.9 s. It pops on the animal with a soft yellow glow.
- Fed foods show a check mark. The section is complete only when **all** foods have been
  fed. Feeding again is allowed.
- **States:** a chip at rest, a fed chip, the flight, and the arrival effect.

**Section C: Söz tapmaca (the word puzzle)**
- **Layout:** the heading "Heyvanın adını düzgün doldur", a row of empty slots (one per
  letter of the name), and the scrambled letter tiles below.
- **Playing:**
  - The child drags a tile into a slot. The slot then shows correct (green today) or
    wrong (red today).
  - Tapping a filled slot sends its letter back.
  - Repeated letters are interchangeable.
- **Sound:** a click when a tile is picked up or dropped. When the word is solved: confetti,
  the win sound and a celebration.
- **"Yenidən başla"** shuffles the tiles again.
- **Size:** it must work for both "Ayı" (3 letters) and "Qarışqayeyən" (12 letters) at
  360 dp width. Tiles must not get much smaller than 40 dp; two rows are fine.
- **States:** empty, partly filled with one wrong letter, solved.

**Section D: Pazl (the image puzzle; only some animals)**
- **Controls:**
  - A 60 dp thumbnail of the photo. Pressing and holding it shows the photo large in an
    overlay; letting go hides it.
  - "Yenidən başla" shuffles again.
  - "Kömək" (a hint) shows the solved picture, faded, inside the board for 2 seconds. It
    never awards a star.
  - Difficulty buttons: "Asan" (3×3), "Orta" (4×4), "Çətin" (5×5).
- **Board:**
  - A square grid of empty slots, with a tray of shuffled pieces below it.
  - The child drags a piece from the tray into a slot, or from one slot to another.
    Tapping a placed piece sends it back to the tray.
  - A correct placement plays a click and shows a green border today; a wrong one shows a
    red border.
- **Finished:** confetti, the win sound and a star. After 1.5 s a dialog appears:
  "Təbriklər!", "Pazl tamamlandı!", with the button "Yenidən".
- **States:** 3×3, 4×4 and 5×5 at 360 dp width; the tray full of pieces; the hint; the
  finished board.

**Celebrations on this page**
- **Word puzzle solved:** a dimmed backdrop and a card with a trophy and "Təbriklər!".
  Tapping anywhere closes it. Confetti.
- **Every task of this animal done** (shown once): 3 big stars, "Tam ulduz!", and
  "Ayı haqqında hər şeyi öyrəndin!".

### 7.6 The letter tracing game ("B hərfini yaz")

It is a full-screen page.

**Header**
- Back (tooltip "Geri").
- Previous and next letter arrows. They wrap around: after Z comes A.
- The title "B hərfini yaz".
- One star, filled once this letter has been traced.

**The canvas** is the heart of the game. It is all drawn in code (`CustomPainter`), so
give colours, line widths and shapes for each part:
- **Ruled lines:** four "notebook" lines (cap line, mid line, base line, descender line).
- **Road:** the letter drawn as a thick, translucent road. Its width is the tracing
  tolerance.
- **Centre line:** a dashed line along the middle of each stroke.
- **Ink** fills the ideal path as the finger moves forward. The child's raw finger line is
  never drawn, so the result always looks neat.
- **Current-stroke guides,** for the current stroke only: a pulsing start dot (green
  today) with the stroke's number, and a direction arrow just ahead of the finger.
- **Dots,** such as the dot of İ, are separate targets.
- **Feedback:**
  - A touch in the wrong place makes the canvas do a short sideways "no" shake (280 ms).
  - An optional haptic tick at checkpoints and at stroke ends (a parent setting).
  - A click sound when a stroke is finished.
- **Letter finished:** the win sound, confetti (yellow, green, blue and pink today), and
  the star fills.
- **Today's colours** are ink `#FFD54F`, finished ink `#FFECB3`, road white at 20 %,
  guides white at 13 %, start dot `#66BB6A`, all on dark navy. A light theme needs a new
  scheme.

**Mode pills**
- "Bax" (watch): an automatic demo draws the letter, then switches to İzlə on its own.
- "İzlə" (guided, the default): the road, the stroke numbers and the arrow.
- "Təkrarla" (faded): only the dotted outline remains; the child works from memory.

**Footer:** "12 / 32 hərf yazıldı" and a "Yenidən" restart button.

**Fallback** (should never happen): an edit-off icon and the text
"\"B\" hərfi üçün yazı datası hələ hazır deyil."

**States to show:** guided at the start, the middle of a stroke, the wrong-touch shake,
the watch demo, faded, finished.

### 7.7 Settings: the parent area ("Ayarlar")

A grouped list. The section headers are below; mind the İ rule in §5.

**Səs**
- "Bütün səslər": "Tətbiqdəki bütün səsləri susdurur" (the master switch).
- "İzah və nəqletmə": "Hərf və heyvan haqqında danışıq".
- "Heyvan səsləri".
- "Effektlər": "Klik, qalibiyyət, səhifə çevirmə".

When the master switch is off, the three channel switches are disabled but keep their
positions. Turning the master back on restores them. Design this disabled state.

**Oyun**
- "Titrəmə": "Hərfi cızarkən qısa titrəyiş".
- "Animasiyanı azalt": "Konfeti və təbrik effektlərini söndürür".
- "Pazl çətinliyi": "Şəkil pazlındaki parça sayı", with a segmented control:
  "3 × 3" / "4 × 4" / "5 × 5".

**Valideyn**
- "Progresi sıfırla": "Bütün ulduzları və bölmələri silir". This is the destructive
  action, and it has its own confirm dialog:
  - a warning icon;
  - the title "Bütün ulduzlar silinsin?";
  - the text "Yığılmış 41 ulduz və tamamlanmış bütün bölmələr silinəcək. Bu addımı geri
    qaytarmaq mümkün deyil.";
  - the buttons "Ləğv et" and "Bəli, sil".

  After it, a snackbar says "Progres sıfırlandı."

**Məlumat**
- "Səs mənbələri" opens a long, scrolling credits dialog (title "Səs mənbələri", button
  "Bağla"). It holds sources, licences and about 10 lines of author credits, and it must
  stay readable.
- "Tətbiq haqqında" ("Versiya 1.4.0") opens a dialog with:
  - "Əlifba", "Versiya 1.4.0", "com.vebstudio.elifba";
  - a "Məxfilik" heading and the text "Bu tətbiq heç bir şəxsi məlumat toplamır, internetə
    qoşulmur və reklam göstərmir. Bütün şəkillər və səslər tətbiqin içindədir; yığılmış
    ulduzlar yalnız bu cihazda saxlanılır.";
  - a "Bağla" button.

## 8. Things you may fix or decide: flag each one

1. **Puzzle difficulty lives in two places,** settings and the game, with the same three
   choices (3×3, 4×4, 5×5), and both change the same setting. Design both, and tell me
   whether you would keep just one.
2. **Make the three celebration styles one family.**
3. **Never show right or wrong by colour alone.**
4. **The book needs a disabled state** at the first and last spread, and possibly a page
   indicator.
5. **The word-puzzle tiles get too small** for long names.

## 9. Out of scope

- New features, new content, redrawn animals, and changes to the learning flow or the star
  rules.
- Dark mode is not needed.
- **Prefer restyling the current structure.** If you think a bigger structural change is
  worth it (for example, replacing the book with another home metaphor), show it as an
  extra option and give the reason. It should not be the default.

## 10. Attached references

- **Current brand:** the app icon and the Play Store feature graphic.
- **Animal illustrations,** for style and for the range of shapes: bison, sparrow, sheep,
  stork, giraffe, python, crocodile.
- **Food pictures:** honey and apple.
- **One puzzle photo:** a bear.
- **Screenshots of the current app,** if attached.

## 11. Process and deliverables

**Step 1: three directions. Stop after this step and wait for my choice.** Show three
clearly different brand directions side by side. Each one needs:
- a one-line mood;
- a palette in hex;
- a type pairing, with the Azerbaijani specimen from §5;
- a shape language;
- a mockup of the home book;
- one animal card using an attached illustration;
- a mascot sketch, if you propose a mascot.

**Step 2: the design system** for the chosen direction:
- **Colour tokens,** mapped to Flutter `ColorScheme` roles plus custom roles: the star,
  correct, wrong, muted, and the letter colour set.
- **A type scale,** mapped to `TextTheme` roles, with font files and licences.
- **Spacing, radii and elevation.**
- **Components, with every state:**
  - primary, secondary and icon buttons, and the 3-state audio button;
  - pill tabs, chips, cards, the star row and the progress bar;
  - switches, the segmented control, dialogs and the snackbar;
  - the celebration family.

**Step 3: every screen in §7, in every listed state,** at 360×640 and 412×915 dp.

**Step 4: brand assets:**
- the "Əlifba" wordmark;
- an Android adaptive icon: separate foreground and background layers on a 108×108 dp
  canvas, with the key artwork inside the central 66 dp safe circle, plus a monochrome
  layer for themed icons;
- a Play Store icon, 512×512;
- a Play feature graphic, 1024×500;
- the background colour of the launch screen. Android 12+ shows the icon on a flat colour.

**Step 5: handoff notes for a Flutter developer:**
- a token table (hex, dp, sp);
- component specs;
- a motion table (durations and curves, with the reduced-motion version of each);
- the per-screen status-bar and nav-bar icon colour;
- a list of every new bitmap asset to export, with file name, size and format.
