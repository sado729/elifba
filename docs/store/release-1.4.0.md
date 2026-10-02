# Play Console — 1.4.0 (versionCode 10)

Əvvəlki buraxılış: **1.3.0 (9)** — Yazı oyunu, ulduz progresi və valideyn bölməsi.
Bu buraxılış: Orfoqrafik ad dəqiqləşdirmələri, 34 yeni real heyvan səsi (cəmi 68 səs),
təsvirlərin zənginləşdirilməsi və tək səslə yenidən səsləndirilməsi, yeni pazl fotoları.

---

## Release name (Play Console daxili ad, maks. 50 simvol)

```
1.4.0 (10) — Dəqiq adlar, 68 səs, yeni izahlar
```

46 simvol. Bu ad yalnız Play Console-da görünür, istifadəçiyə çıxmır.

---

## Release notes / "What's new" — az-AZ (maks. 500 simvol)

```
Yeniliklər:

• Dəqiq orfoqrafiya — heyvan adları rəsmi orfoqrafiya lüğətinə uyğunlaşdırıldı (Leylək, Yaquar, Yenot, Yexidna, Hepard, Maralöküz, Dağsiçanı, Qızılqaz, Zebr).
• 34 yeni real heyvan səsi — tətbiqdə artıq 68 heyvanın təbii səsi var (kəklik, turac, dələ, vaşaq, ceyran və s.).
• Yenilənmiş səsli izahlar — heyvanlar haqqında mətnlər daha zəngin və dəqiq şəkildə yenidən səsləndirildi.
• Yeni pazl şəkilləri və anatomik dəqiqlik təkmilləşdirmələri.
```

Simvol sayı: **462** (500 limitinə uyğun).

### Daha qısa variant (~280 simvol)

```
• Dəqiq orfoqrafiya — heyvan adları rəsmi lüğətə uyğunlaşdırıldı.
• 34 yeni real heyvan səsi — artıq 68 heyvanın təbii səsi var.
• Yenilənmiş səsli izahlar — mətnlər daha zəngin və aydın səsləndirildi.
• Təzələnmiş pazl fotoları və vizual dəqiqlik.
```

Simvol sayı: **242**.

---

## Release notes / "What's new" — en-US (maks. 500 simvol)

```
What's new:

• Standardized names — animal names aligned with the official Azerbaijani orthography dictionary.
• 34 new real animal sounds — now featuring 68 authentic, leveled animal sounds (partridge, lynx, francolin, gazelle, etc.).
• Updated voice narrations — descriptions rewritten and re-recorded for richer and clearer educational content.
• Improved puzzle photos and visual anatomy enhancements.
```

Simvol sayı: **420**.

---

## Buraxılışa daxil olan dəyişikliklər (1.3.0+9 → 1.4.0+10)

İstifadəçiyə görünən:

| Commit | Dəyişiklik |
|---|---|
| `1d2e4e0` | Rəsmi orfoqrafiya lüğətinə uyğunlaşdırma, vizual aktivlərin yenilənməsi və 34 yeni heyvan səsi |
| `1d2e4e0` | Təsvir mətnlərinin düzəldilməsi və Inflect-Micro-v2 ilə yenidən səsləndirilməsi |
| `1d2e4e0` | Bəbir / Leopard təkrarının birləşdirilməsi, yeni Baltadimdik, Sarıköynək, Ulaq və Ayı pazlları |
| `1d2e4e0` | Ayarlar bölməsində yeni CC BY 4.0 səs müəlliflərinin kredit siyahısı |

Görünməyən (texniki / sənədləşmə):

| Commit | Dəyişiklik |
|---|---|
| `d7ad5be` | Audio assetləri, tətbiq konfiqurasiyası və məzmun bütövlüyü testləri |
| `f0b568f` | Mövcud 34 heyvan səsinin −18 LUFS-ə bərabərləşdirilməsi və kəsilməsi |
| `31aa119` | Qeyri-dəqiq heyvan illüstrasiyaları üçün göstəriş sənədi (`docs/art/`) |
| `79d16cf` | CLAUDE.md sənədində orfoqrafiya, səs qaydaları və audit qeydləri |
| `c1fe72c` | 1.4.0+10 versiya artımı |

---

## Yükləmə qeydləri

- Artefakt: `build/app/outputs/bundle/release/app-release.aab` (81.8 MB / 85 739 741 bayt)
- `versionCode` 10, `versionName` 1.4.0, `targetSdk` 36, `minSdk` 21
- İmza: `vebstudio` alias, `key/elifba.jks`
- Manifest icazələri: yalnız `ACCESS_NETWORK_STATE` (media3 daxili) — tətbiqin özündə heç bir xüsusi icazə yoxdur, şəbəkəyə müraciət etmir.
- Data safety formasında dəyişiklik yoxdur: məlumat toplanmır, bütün fəaliyyət cihazda qalır.
- `flutter analyze`: təmiz. `flutter test`: 179 test uğurla keçdi.
