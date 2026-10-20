# Play Console — 1.5.0 (versionCode 11)

Əvvəlki buraxılış: **1.4.0 (10)** — Dəqiq adlar, 68 səs, yeni izahlar.
Bu buraxılış: Tam rebrend və yeni vizual dizayn ("Lavanda buludu"): yeni loqo və ikon,
açıq və mehriban ekranlar, günəş maskotu, uşaqlar üçün yeni şriftlər, ✓/✕ ilə rəy və
vahid təbrik kartları. Funksiyalar və ulduz qaydaları dəyişməyib.

---

## Release name (Play Console daxili ad, maks. 50 simvol)

```
1.5.0 (11) — Yeni dizayn: Lavanda buludu
```

40 simvol. Bu ad yalnız Play Console-da görünür, istifadəçiyə çıxmır.

---

## Release notes / "What's new" — az-AZ (maks. 500 simvol)

```
Yeniliklər:

• Tamamilə yeni dizayn — lavanda səması, günəş maskotu və yumşaq, işıqlı rənglər.
• Yeni loqo və tətbiq ikonu.
• Böyük, rahat düymələr və uşaqlar üçün asan oxunan şriftlər.
• Doğru və səhv cavablar indi ✓ və ✕ işarələri ilə göstərilir.
• Kitabda səhifə nömrəsi, hər hərf üçün öz rəngi.
• Söz tapmacada uzun adlar iki sətrə düzülür, pazlda yeni «İpucu».
• Bütün təbriklər yeni, şən kartlarda.
```

Simvol sayı: **404** (500 limitinə uyğun).

### Daha qısa variant (~200 simvol)

```
• Tamamilə yeni, işıqlı dizayn və günəş maskotu.
• Yeni loqo və ikon.
• Böyük düymələr və asan oxunan şriftlər.
• Doğru və səhv cavablar ✓ və ✕ ilə göstərilir.
• Yeni təbrik kartları və pazlda «İpucu».
```

Simvol sayı: **201**.

---

## Release notes / "What's new" — en-US (maks. 500 simvol)

```
What's new:

• A brand-new look — a lavender sky, a sunny mascot and soft, bright colours.
• New logo and app icon.
• Bigger, friendlier buttons and easy-to-read fonts for young readers.
• Right and wrong answers are now shown with ✓ and ✕ marks.
• Page numbers in the alphabet book and a colour for every letter.
• Long names wrap onto two lines in the word puzzle; new "Hint" in the picture puzzle.
• All celebrations in new, cheerful cards.
```

Simvol sayı: **443**.

---

## Mağaza səhifəsi (Store listing) — bu buraxılışla birlikdə yenilənməlidir

İkon dəyişdiyi üçün mağaza qrafikası da yeni brendə keçməlidir (Main store listing →
Graphics):

- **App icon:** `docs/store/ic_play_512.png` (512×512, 32-bit PNG, künc və kölgəni Play
  özü əlavə edir).
- **Feature graphic:** `docs/store/feature_graphic_1024x500.png` (1024×500, 24-bit PNG,
  alfa yoxdur).
- Ekran görüntüləri köhnə tünd-bənövşəyi dizayndadırsa, onları da yenisi ilə əvəz edin.

---

## Buraxılışa daxil olan dəyişikliklər (1.4.0+10 → 1.5.0+11)

İstifadəçiyə görünən:

| Commit | Dəyişiklik |
|---|---|
| `bdef910` | Yeni brend: adaptiv ikon (themed icon daxil), wordmark, açılış ekranı #E4DEFF, tətbiq adı «Əlifba» |
| `89333a1` | Dizayn sistemi: rənglər, Comfortaa + Andika şriftləri, squishy düymələr, ulduzlar, günəş maskotu, təbrik ailəsi |
| `89d5d75`, `a7f4cbf` | Əlifba kitabı: rəngli hərf kartları, tamamlanmış hərfdə günəş şüaları və ✓, «N / 16» səhifə nişanı, ilk/son səhifədə söndürülmüş oxlar |
| `44c4215`, `93c6071` | Valideyn qapısı: sakit dialoq, dolan halqa, tam saxlayanda yaşıl ✓ |
| `a01cf45`, `f409ae4` | Ayarlar: düz valideyn fonu, cümlə registrində başlıqlar, yeni açarlar və dialoqlar, «Tətbiq haqqında»-da loqo |
| `f0e95db`, `bd9da2e` | Hərf səhifəsi: bütöv sürüşən səhifə, kartın içində səs düyməsi, yeni yazı və heyvan kartları, «tamam» təbrikində konfeti |
| `4047009`, `a9beae1` | Heyvan səhifəsi: heyvan «səhnəsi», yapışqan pill tablar, qida uçuşu, ✓/✕ ilə söz tapmaca, «İpucu» ilə pazl |
| `5e0dcc0`, `d41d3b5` | Yazı oyunu: açıq rəngli lövhə, rejim düymələri, səhv toxunuşda silkələnmə və ✕ |
| `4ee170e`, `6d778e6` | Klaviatura/ekran oxuyucu dəstəyi, seçilmiş tab həmişə görünür, dialoq düymələri ekrandan çıxmır |

Görünməyən (texniki / sənədləşmə):

| Commit | Dəyişiklik |
|---|---|
| `3136578` | NotoSans, Baloo2, kitab fotosu və istifadə olunmayan şəkillər silindi (~2,8 MB) |
| `a7edf72` | CLAUDE.md: dizayn sistemi, yeni test qarmaqları, yenilənmiş gotcha-lar |
| `38833d1` | 1.5.0+11 versiya artımı |

Davranışda bilərəkdən dəyişənlər: heyvan tabları radio qrupudur (seçilmiş taba toxunmaq
heç nə etmir); ipucu zamanı «İpucu» və lövhə 2 s bağlıdır; qapı tam saxlayanda 200 ms
sonra açılır; «Kömək» → «İpucu», «Puzzle» → «Pazl».

---

## Yükləmə qeydləri

- Artefakt: `build/app/outputs/bundle/release/app-release.aab` (81.7 MB / 85 687 744 bayt)
- `versionCode` 11, `versionName` 1.5.0, `targetSdk` 36, `minSdk` 21
- İmza: `vebstudio` alias, `key/elifba.jks` (CN=mrsadiq, SHA-256
  `CB:01:BA:8A:…:4E:C6:43:D5`)
- Manifest icazələri: `ACCESS_NETWORK_STATE` (media3 daxili) və AndroidX-in daxili
  `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` — tətbiqin özündə xüsusi icazə yoxdur,
  şəbəkəyə müraciət etmir.
- Data safety formasında dəyişiklik yoxdur: məlumat toplanmır, bütün fəaliyyət cihazda qalır.
- Şriftlər (Andika, Comfortaa) SIL OFL 1.1 ilə paketə daxildir; lisenziyalar
  `assets/fonts/OFL-*.txt`.
- `flutter analyze`: təmiz. `flutter test`: 339 test uğurla keçdi. Android 16 emulyatorunda
  (412 dp) bütün ekranlar əl ilə yoxlanıldı.
