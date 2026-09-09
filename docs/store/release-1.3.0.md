# Play Console — 1.3.0 (versionCode 9)

Əvvəlki buraxılış: **1.1.1 (7)** — Android 16 edge-to-edge dəstəyi.
Bu buraxılış 1.1.1-dən sonrakı bütün dəyişiklikləri daşıyır.
(1.2.0 / versionCode 8 heç vaxt yüklənməmişdi, ona görə birbaşa 1.3.0-a keçildi.)

---

## Release name (Play Console daxili ad, maks. 50 simvol)

```
1.3.0 (9) — Yazı, ulduzlar, valideyn bölməsi
```

44 simvol. Bu ad yalnız Play Console-da görünür, istifadəçiyə çıxmır.

---

## Release notes / "What's new" — az-AZ (maks. 500 simvol)

```
Yeniliklər:

• Hərf yazma oyunu — uşaq barmağı ilə hər 32 hərfi cızaraq yazmağı öyrənir.
• Ulduz progresi — hər hərf üçün 3 ulduz: heyvanı tanı, yemləndir, pazlları yığ, hərfi yaz.
• Valideyn bölməsi — 3 saniyəlik basıb-saxlama qapısının arxasında: səsləri ayrı-ayrı söndür (izah, heyvan səsi, effektlər), titrəməni və animasiyanı azalt, pazl çətinliyini seç (3×3 / 4×4), progresi sıfırla.
• Tətbiq daha yüngül və sürətli açılır.
```

Simvol sayı: **429** (500 limitinə uyğun).

### Daha qısa variant (~280 simvol)

```
• Hərf yazma oyunu — barmaqla 32 hərfi cızaraq yazmağı öyrən.
• Ulduz progresi — hər hərf üçün 3 ulduza qədər ulduz qazan.
• Valideyn bölməsi — səsləri ayrı-ayrı söndür, titrəmə və animasiyanı azalt, pazl çətinliyini seç, progresi sıfırla.
• Tətbiq daha yüngül və sürətli açılır.
```

Simvol sayı: **279**.

---

## Release notes / "What's new" — en-US (maks. 500 simvol)

```
What's new:

• Letter tracing game — children learn to write all 32 letters by tracing them with a finger.
• Star progress — up to 3 stars per letter: meet the animal, feed it, solve the puzzles, write the letter.
• Parent area — behind a 3-second press-and-hold: mute narration, animal sounds and effects separately, reduce haptics and motion, pick puzzle difficulty (3x3 / 4x4), reset progress.
• Smaller app, faster launch.
```

Simvol sayı: **426**.

---

## Buraxılışa daxil olan dəyişikliklər (tam siyahı, 1.1.1+7 → 1.3.0+9)

İstifadəçiyə görünən:

| Commit | Dəyişiklik |
|---|---|
| `de397ec` | Hərf cızma (tracing) oyunu + ulduz progresinin bünövrəsi |
| `a95a795` | Hərf məlumat kartı yığılan oldu, yazı oyunu oradan açılır |
| `f9abb3d` | Hər hərf üçün bölmələri tamamlayaraq ulduz qazanma (96 ulduz) |
| `15ffca1` | Valideyn bölməsi: kanal-kanal səs, titrəmə, animasiya, pazl ölçüsü, sıfırlama, kreditlər |
| `337974c` | Bütün bitmap sənətkarlığı WebP-yə keçdi (tətbiq kiçildi) |
| `3708377` | Release build-də R8 kod kiçildilməsi və resurs təmizləməsi |

Görünməyən (texniki):

| Commit | Dəyişiklik |
|---|---|
| `77dcdf4` | pubspec-dəki placeholder təsvir əvəzlənib |
| `d1396d0` | Dörd boş audio qovluğu `.gitkeep` ilə izlənir — təmiz clone build olunur |
| `d194bdc`, `f62a634`, `67c1b68` | CLAUDE.md və dizayn sənədi yeniləmələri |
| `f6fdb44` | 1.3.0+9-a versiya artımı |

---

## Yükləmə qeydləri

- Artefakt: `build/app/outputs/bundle/release/app-release.aab` (68.2 MB / 71 541 932 bayt)
- `versionCode` 9, `versionName` 1.3.0, `targetSdk` 36, `minSdk` 21
- İmza: `vebstudio` alias, `key/elifba.jks`
- Manifest icazələri: `ACCESS_NETWORK_STATE` (media3/ExoPlayer-dən avtomatik gəlir —
  tətbiqin öz manifestində heç bir icazə yoxdur, şəbəkə istifadəsi yoxdur)
- Data safety formasında dəyişiklik yoxdur: məlumat toplanmır, hər şey cihazda qalır
  (`shared_preferences` — ulduzlar və ayarlar).
- `flutter analyze`: təmiz. `flutter test`: 178 test keçdi.
