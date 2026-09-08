# Ayarlar + Valideyn bölməsi — dizayn sənədi

**Tarix:** 2026-09-08
**Status:** Təsdiq gözləyir
**Əhatə:** Səs idarəetməsi (master + kanallar), valideyn qapısı, ayarlar səhifəsi,
animasiyanı azaltma, pazl çətinliyinin yadda saxlanması.

---

## 1. Məqsəd

Tətbiqdə hazırda heç bir ayar yoxdur: səs həmişə açıqdır, heç nə yadda saxlanmır
və valideyn üçün ayrıca sahə mövcud deyil. Bu iş üç problemi həll edir:

1. **Səsi söndürmək mümkün deyil.** İctimai yerdə və ya yatmazdan əvvəl valideyn
   tətbiqi susdura bilmir — cihazın səsini tam bağlamaqdan başqa yol yoxdur.
2. **Uşağa aid olmayan seçimlər uşağın əlindədir.** Pazl çətinliyi kimi
   parametrlər oyun ekranının ortasındadır.
3. **Google Play Families siyasəti** uşaq tətbiqlərində valideynə yönəlik
   məzmunun uşaq üçün çətin keçiləcək bir "qapı" arxasında olmasını tələb edir.

## 2. Qərarlar (istifadəçi ilə razılaşdırılıb)

| Sual | Qərar |
|---|---|
| Bölmənin əhatəsi | **Standart paket** — səs qrupları, animasiyanı azaltma, pazl çətinliyi, səs mənbələri, tətbiq haqqında. Ekran vaxtı və irəliləyiş statistikası **daxil deyil**. |
| Qapı mexanizmi | **Uzun basıb saxlama** (3 saniyə). |
| Səs düyməsinin yeri | **Hər ikisi** — əsas ekranda sürətli master düyməsi + valideyn bölməsində kanal-kanal ayarlar. |
| Xarici keçidlər | **Yoxdur.** Məxfilik/haqqında mətni tətbiqin içindədir; `url_launcher` əlavə olunmur. |

### 2.1 Qəbul edilmiş risk: qapının gücü

Uzun basıb saxlama ən zəif valideyn qapısı variantıdır — 4-5 yaşlı uşaq
təsadüfən və ya təkrar cəhdlə keçə bilər. İstifadəçi bunu bilərək seçib.
Yumşaltma tədbirləri:

- Müddət **3 saniyə** (2 saniyə çox qısadır).
- Toxunma sahəsi kiçikdir (~72 px) və dialoqun mərkəzindədir — ovucla təsadüfən
  basılması çətinləşir.
- Barmaq qaldırılan kimi tam sıfırlanır (yığılan tərəqqi saxlanmır).
- **Səs və titrəmə geri-bildirişi yoxdur** — uzun basmaq uşaq üçün maraqlı bir
  "oyuncaq" olmamalıdır.

Qapının arxasında dağıdıcı heç nə yoxdur (satınalma, xarici link, silinmə), ona
görə bu risk qəbul ediləndir.

---

## 3. Arxitektura

### 3.1 Yeni fayllar

```
lib/core/settings.dart          AppSettings — ChangeNotifier singleton + saxlama
lib/core/sound.dart             SoundChannel + GatedPlayer (səs keçid qatı)
lib/widgets/parental_gate.dart  showParentalGate() — basıb-saxla dialoqu
lib/widgets/mute_button.dart    Sürətli master mute düyməsi
lib/pages/settings_page.dart    Valideyn bölməsinin UI-ı
```

`lib/widgets/` qovluğu hazırda mövcud deyil (köhnə YouTube widget-i ilə birlikdə
silinib) — yenidən yaradılır.

### 3.2 AppSettings

```dart
enum SoundChannel { narration, animal, effect }

class AppSettings extends ChangeNotifier {
  static final AppSettings instance = AppSettings._();

  bool masterSound    = true;   // ümumi açar
  bool narrationSound = true;   // hərf/heyvan izahı (…_info_sound.mp3)
  bool animalSound    = true;   // heyvan səsi (…_sound.mp3)
  bool effectSound    = true;   // click, win, page_flip
  bool reduceMotion   = false;  // konfeti söndürülür
  int  puzzleGridSize = 3;      // 3 və ya 4

  bool isOn(SoundChannel c);    // masterSound && <kanalın öz açarı>

  Future<void> load();          // main()-də runApp-dan ƏVVƏL
  // hər setter dəyəri yazır, sonra notifyListeners()
}
```

- **Saxlama:** `shared_preferences` (yeni asılılıq, `^2.3.0`). Açarlar
  `settings.masterSound` və s. prefiksi ilə.
- **Yükləmə anı:** `main()` içində `await AppSettings.instance.load()`,
  `runApp()`-dan əvvəl. Səbəb: ilk kadrda default dəyərlərin görünüb sonra
  dəyişməsinin qarşısını alır və ayarlar gəlməmiş səs çalınmasına imkan vermir.
  Qiymət: ~5 ms açılış gecikməsi.
- **Yazma:** `notifyListeners()` sinxron, disk yazısı `unawaited` — açar dərhal
  reaksiya verir, disk arxa planda yazır.

### 3.3 Dəyərin səhifələrə çatdırılması

Provider/Bloc əlavə olunmur (mövcud konvensiya: `StatefulWidget` + `setState`).
İki mexanizm, hər biri öz yerində:

**(a) Çalınma anında oxumaq** — səs kodu üçün. `GatedPlayer` sinxron olaraq
`AppSettings.instance.isOn(channel)` oxuyur. `InheritedWidget` plumbing-i 7
pleyerə çəkmək lazım gəlmir.

**(b) Dinləmək** — yalnız yenidən çəkilməli UI üçün:
`ListenableBuilder(listenable: AppSettings.instance, …)`. İstifadə yerləri: mute
düyməsi, ayarlar səhifəsi, səs düymələrinin sönük görünüşü.

### 3.4 GatedPlayer — səs keçid qatı

**Niyə lazımdır:** 7 çalınma nöqtəsinə `if (settings.effectsOn)` səpələmək
kövrəkdir — biri unudula bilər və gələcəkdə əlavə olunan yeni `AudioPlayer`
səssizcə mute-u keçər. Keçid pleyerin öz içində olmalıdır.

```dart
class GatedPlayer {
  GatedPlayer(this.channel);
  final SoundChannel channel;
  final AudioPlayer _inner = AudioPlayer();

  Future<void> setAsset(String asset);
  Future<bool> play();      // false = susdurulub, heç nə çalınmadı
  Future<bool> replay();    // seek(0) + play, təkrarlanan effektlər üçün
  Future<void> stop();
  Stream<PlayerState> get playerStateStream;
  void dispose();
}
```

Konstruktorda `AppSettings.instance`-ə abunə olur: öz kanalı **söndürüləndə**
dərhal `_inner.stop()` çağırır. Bu, "susdur" düyməsinə basanda oxunmaqda olan
izahın ortada kəsilməsini təmin edir. `dispose()` abunəni ləğv edir.

Mövcud `final ... = AudioPlayer()` sahə-səviyyəli qurma nümunəsi saxlanılır
(CLAUDE.md gotcha #5) — `GatedPlayer` də sahədə sinxron qurulur.

### 3.5 Mövcud 7 pleyerin kanallara bölünməsi

| Fayl | Sətir | Pleyer | Kanal |
|---|---|---|---|
| `alphabet_page.dart` | 15 | səhifə çevirmə (`page_flip.mp3`) | `effect` |
| `animal_list_page.dart` | 384 | `_SoundButton` — hərf izahı | `narration` |
| `animal_detail_page.dart` | 38 | `audioPlayer` — **iki işdə** | bax aşağı |
| `animal_detail_page.dart` | 971 | `_clickPlayer` | `effect` |
| `animal_detail_page.dart` | 972 | `_winPlayer` | `effect` |
| `puzzle_page.dart` | 34 | `_audioPlayer` (klik) | `effect` |
| `puzzle_page.dart` | 35 | `_winPlayer` | `effect` |

**`animal_detail_page.dart:38` bölünməlidir.** Bu tək pleyer həm
`_toggleAnimalInfo()` (izah — `narration`), həm də AppBar-dakı heyvan səsi
düyməsi (sətir 350 — `animal`) tərəfindən istifadə olunur. İki ayrı
`GatedPlayer`-ə bölünür: `_infoPlayer` (narration) və `_animalPlayer` (animal).
Yan fayda: heyvan səsi artıq izahı yarıda kəsmir.

### 3.6 "Susdurulub" vəziyyətinin UI-da göstərilməsi

**Problem:** `animal_detail_page` (sətir 68-76) və `_SoundButton`
(`animal_list_page.dart:388`) `playerStateStream`-i dinləyib `isPlaying`
bayrağını `completed` hadisəsində sıfırlayır. Səs susdurulubsa heç nə çalınmır,
`completed` gəlmir və düymə **əbədi "Dayandır" vəziyyətində ilişir**.

**Həll (iki qat):**

1. **UI qatı:** kanal söndürülübsə səs düymələri sönük (`disabled`) və susdurulmuş
   ikonu ilə göstərilir. Uşaq üçün işləməyən düymədən yaxşıdır — nə üçün səs
   gəlmədiyi görünür. `ListenableBuilder` ilə bağlanır. Yerlər: detal səhifəsinin
   "Dinlə" düyməsi (sətir ~660), AppBar heyvan səsi (sətir 347), siyahı
   səhifəsinin `_SoundButton`-u.
2. **Təhlükəsizlik qatı:** `play()` `false` qaytarır və çağırış yerləri
   `isPlaying`-i `true` etmir.

---

## 4. Valideyn qapısı

`lib/widgets/parental_gate.dart`

```dart
Future<bool> showParentalGate(BuildContext context);
```

`true` = keçdi. Davranış:

- `AlertDialog`: başlıq **"Valideynlər üçün"**, mətn **"Davam etmək üçün düyməni
  3 saniyə basıb saxlayın"**.
- Mərkəzdə ~72 px dairəvi düymə, ətrafında dolan `CircularProgressIndicator`
  (`AnimationController(duration: 3s)` ilə idarə olunur).
- `onTapDown` → `forward()`; `onTapUp` / `onTapCancel` → `reset()`.
- `status == completed` → `Navigator.pop(true)`.
- **"Ləğv et"** düyməsi → `pop(false)`.
- Səs və `HapticFeedback` **yoxdur** (uşaq üçün mükafat siqnalı olmamalıdır).
- Cəhd limiti yoxdur — mexanizm onsuz da zaman əsaslıdır.

Funksiya ümumi təyinatlıdır: gələcəkdə xarici link və ya satınalma əlavə olunsa,
eyni çağırış istifadə olunacaq.

---

## 5. Ayarlar səhifəsi

`lib/pages/settings_page.dart` — adi `Scaffold` + `AppBar`, digər səhifələrlə eyni
tünd bənövşəyi fon.

> **Edge-to-edge** (CLAUDE.md gotcha #9): yeni səhifə mütləq öz insetini tətbiq
> etməlidir. `ListView`-in `padding.bottom`-una
> `MediaQuery.viewPaddingOf(context).bottom` əlavə olunur, tam-en gradient
> `Container` isə insetdən **kənarda** qalır.

### Bölmələr

**1. Səs**

- `Bütün səslər` — master açar.
- `İzah və nəqletmə` — hərf/heyvan izahı.
- `Heyvan səsləri`.
- `Effektlər (klik, qalibiyyət, səhifə)`.
- Master söndürüləndə üç alt-açar sönük və qeyri-aktiv olur (dəyərləri itmir —
  master geri açılanda əvvəlki vəziyyət bərpa olunur).

**2. Oyun**

- `Animasiyanı azalt` — konfeti effektini söndürür. Həssas uşaqlar və zəif
  cihazlar üçün.
- `Pazl çətinliyi` — `SegmentedButton`: 3×3 / 4×4.

**3. Məlumat**

- `Səs mənbələri` — mövcud dialoq buraya köçür (`alphabet_page.dart:47`).
- `Tətbiq haqqında` — ad, versiya, paket id (`com.vebstudio.elifba`), qısa
  məxfilik mətni: "Bu tətbiq heç bir şəxsi məlumat toplamır, internetə qoşulmur
  və reklam göstərmir."

Versiya sətri `lib/core/config.dart`-da `const kAppVersion = '1.1.1'` kimi
saxlanılır; `package_info_plus` asılılığı əlavə edilmir. **Bu sabit
`pubspec.yaml`-dakı `version:` ilə əl ilə sinxronlaşdırılmalıdır.**

---

## 6. Əsas ekrandakı giriş nöqtələri

`alphabet_page.dart:141-171` başlıq sırası dəyişir:

```
[ 🔊 ]        Əlifba        [ ⚙ ]
  ↑                           ↑
master susdur            3 san. basıb saxla → Ayarlar
(dərhal, qapısız)
```

- **Sol — `MuteButton`:** `masterSound`-u dərhal çevirir, qapı yoxdur.
  `ListenableBuilder` ilə açıq/bağlı ikonlar arasında keçir.
- **Sağ — ⚙:** `if (await showParentalGate(context))` → `SettingsPage`.
- Mövcud ℹ️ (səs mənbələri) düyməsi **silinir** — məzmunu ayarlar səhifəsinə köçür.

---

## 7. Qalan bağlantılar

### 7.1 reduceMotion

4 çağırış yeri şərtə salınır: `animal_detail_page.dart:799`,
`animal_detail_page.dart:1037`, `puzzle_page.dart:331`, `puzzle_page.dart:472`.

```dart
if (!AppSettings.instance.reduceMotion) _confettiController.play();
```

`ConfettiWidget` ağacda qalır (oynadılmayanda heç nə çəkmir) — şərti widget
ağacına salmaq lazım deyil.

### 7.2 puzzleGridSize

`puzzle_page.dart:24` (`int gridSize = 3;`) → `initState`-də
`AppSettings.instance.puzzleGridSize`-dan alınır. Səhifə daxilindəki ölçü seçicisi
(sətir 84 və 717) seçimi **geri yazır** — beləliklə oyun içindəki seçim və ayar
tək bir dəyərdir, iki fərqli həqiqət mənbəyi yaranmır.

---

## 8. Testlər

| Fayl | Nə yoxlanılır |
|---|---|
| `test/settings_test.dart` | `SharedPreferences.setMockInitialValues({})` ilə yükləmə/yazma dövrü; `isOn()` məntiqi (master söndürülübsə bütün kanallar bağlıdır, alt-açarların dəyəri itmir). |
| `test/parental_gate_test.dart` | 2.9 san. → dialoq açıq qalır; 3.1 san. → `true`; barmaq erkən qaldırılanda tərəqqi sıfırlanır; "Ləğv et" → `false`. |
| `test/settings_page_test.dart` | Master söndürüləndə alt-açarlar `disabled` olur; pazl seçimi yazılır. |

**Qeyd:** `GatedPlayer` üçün ayrıca test yazılmır — `AudioPlayer()` qurulması test
mühitində platforma kanalı tələb edir. Bunun əvəzinə keçid məntiqi
`AppSettings.isOn()` saf funksiyasında cəmlənir və orada test olunur.

**Ayrıca:** `test/widget_test.dart` hazırda default sayğac şablonudur və
**uğursuz olur** (tətbiqdə nə `Icons.add`, nə də "0" mətni var). Bu işin bir
hissəsi kimi düzəldilir və `AlphabetPage`-in açıldığını yoxlayan sadə smoke
testinə çevrilir.

---

## 9. Risklər və tələlər

1. **Yeni plugin.** `shared_preferences` Android build-inə toxunur;
   `flutter pub get` təkrar işlədilməlidir. Manifest dəyişikliyi tələb etmir.
2. **Edge-to-edge** — 5-ci bölmədəki xəbərdarlığa bax.
3. **İlişən `isPlaying`** — 3.6-cı bölmədə həll olunub; migrasiyada unudulmamalıdır.
4. **Detal səhifəsinin tək pleyeri iki kanala xidmət edir** — bölünməlidir (3.5).
5. **Qapının zəifliyi** — bilərəkdən qəbul edilib (2.1).
6. **Versiya sabitinin sinxronu** — `pubspec.yaml` ilə əl ilə (5-ci bölmə).
7. **CRLF churn** — layihədə `autocrlf=true` və köhnə CRLF blob-ları var; mövcud
   fayllardakı kiçik redaktələr diff-də bütöv fayl yenidən yazılması kimi görünə
   bilər. Commit-dən əvvəl `git diff --stat` yoxlanılmalıdır.

## 10. Əhatədən kənar (YAGNI)

- Ekran vaxtı limiti / fasilə xatırlatması.
- İrəliləyiş izləmə və statistika.
- PIN kodu, məxfilik siyasəti URL-i, "Bizi qiymətləndirin", e-poçt keçidi.
- Dil seçimi (tətbiq yalnız Azərbaycan dilindədir).
- Fon musiqisi (hazırda yoxdur).
- İstifadə olunmayan `flutter_tts` asılılığının silinməsi və ölü `showYoutube`
  bayrağının təmizlənməsi — ayrı, əlaqəsiz təmizlik işidir.

---

## 11. Toxunulan fayllar

**Yeni (5):** `lib/core/settings.dart`, `lib/core/sound.dart`,
`lib/widgets/parental_gate.dart`, `lib/widgets/mute_button.dart`,
`lib/pages/settings_page.dart`

**Dəyişən (7):** `pubspec.yaml`, `lib/main.dart`, `lib/core/config.dart`,
`lib/pages/alphabet_page.dart`, `lib/pages/animal_list_page.dart`,
`lib/pages/animal_detail_page.dart`, `lib/pages/puzzle_page.dart`

**Sənədləşmə:** `CLAUDE.md` — ayarlar qatı və yeni "səs `GatedPlayer`-dən
keçməlidir" qaydası əlavə olunur.

---

## 12. İcra ardıcıllığı

Hər mərhələ öz-özlüyündə yoxlanıla bilən vəziyyətdə bitir:

1. **`AppSettings` + `shared_preferences` + testlər.** UI yoxdur; testlərlə
   yoxlanılır.
2. **`GatedPlayer` + 7 pleyerin migrasiyası.** Bütün defaultlar açıq olduğu üçün
   istifadəçi davranışı **dəyişmir** — təmiz refaktor.
3. **`showParentalGate()` + testi.** Təcrid olunmuş widget.
4. **`SettingsPage` + `MuteButton` + əsas ekran giriş nöqtələri.** Səs mənbələri
   dialoqu köçürülür. Bu mərhələnin sonunda funksiya işlək olur.
5. **`reduceMotion` və `puzzleGridSize` bağlantıları.**
6. **Təmizlik:** `widget_test.dart` düzəldilir, `CLAUDE.md` yenilənir.
