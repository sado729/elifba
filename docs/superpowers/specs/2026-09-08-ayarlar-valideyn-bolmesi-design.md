# Ayarlar + Valideyn bölməsi — dizayn sənədi

**Tarix:** 2026-09-08
**Status:** Təsdiq gözləyir
**Əhatə:** Səs idarəetməsi (master + kanallar), valideyn qapısı, ayarlar səhifəsi,
titrəmə, animasiyanı azaltma, pazl çətinliyi, progresin sıfırlanması.

> **Sətir nömrələri qəsdən yazılmayıb.** Bu sənəd yazılarkən iş ağacında paralel
> olaraq başqa sessiyalar (hərf cızma kartı, ulduz progresi) işləyirdi və eyni
> fayllar dəyişirdi. Bütün istinadlar **simvol adı** ilə verilir — sətir nömrəsi
> saatlar içində köhnəlir, simvol adı isə yox. İşə başlamazdan əvvəl hər simvolun
> yerini `grep` ilə təsdiqləyin.

---

## 1. Məqsəd

Tətbiqdə hazırda heç bir istifadəçi ayarı yoxdur: səs həmişə açıqdır, titrəmə
söndürülə bilmir və valideyn üçün ayrıca sahə mövcud deyil. Bu iş üç problemi
həll edir:

1. **Səsi söndürmək mümkün deyil.** İctimai yerdə və ya yatmazdan əvvəl valideyn
   tətbiqi susdura bilmir — cihazın səsini tam bağlamaqdan başqa yol yoxdur.
2. **Uşağa aid olmayan seçimlər uşağın əlindədir.** Pazl çətinliyi oyun ekranının
   ortasındadır; progresin sıfırlanması isə hazırda əlifba səhifəsindəki ℹ️
   dialoqundadır — yəni qapısız, uşağın çata biləcəyi yerdə. (İki addımlı təsdiq
   var, amma bu qapı deyil.) Ulduz progresi işlənəndə müvəqqəti olaraq ora
   qoyulub; bu bölmə hazır olanda **ora köçürülməlidir**, çünki həmin ℹ️ dialoqu
   onsuz da bu sənədə görə silinir.
3. **Google Play Families siyasəti** uşaq tətbiqlərində valideynə yönəlik
   məzmunun uşaq üçün çətin keçiləcək bir "qapı" arxasında olmasını tələb edir.

### 1.1 Kod artıq bu bölməni gözləyir

`lib/core/progress.dart` iki yerdə valideyn ekranına birbaşa işarə edir —
funksionallıq mövcuddur, sadəcə onu çağıran UI yoxdur:

- `ProgressStore.reset()` — sənəd şərhi: *"Bütün progresi silir (valideyn üçün
  'sıfırla')"*.
- `ProgressStore.writtenLetterCount` — sənəd şərhi: *"Yazılmış hərflərin sayı
  (valideyn ekranı / statistika üçün)"*.

`reset()` bu işə daxil edilir. Statistika ekranı **daxil edilmir** (bax §10).

## 2. Qərarlar (istifadəçi ilə razılaşdırılıb)

| Sual | Qərar |
|---|---|
| Bölmənin əhatəsi | **Standart paket** — səs qrupları, titrəmə, animasiyanı azaltma, pazl çətinliyi, progresi sıfırla, səs mənbələri, tətbiq haqqında. Ekran vaxtı və irəliləyiş statistikası **daxil deyil**. |
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

Qapının arxasında **bir dağıdıcı əməliyyat var** — "Progresi sıfırla". Ona görə o,
qapıdan əlavə öz təsdiq dialoqu ilə də qorunur (§5, "Valideyn" bölməsi).

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

`lib/widgets/` qovluğu **artıq mövcuddur** (`star_row.dart`, `tracing_canvas.dart`).

### 3.2 AppSettings — `ProgressStore`-un eyni nümunəsi ilə

**`shared_preferences` artıq layihədədir** (`^2.3.0`) və `lib/core/progress.dart`
onunla işləyən, sınaqdan çıxmış bir nümunə qurub. `AppSettings` **yeni üslub
uydurmur** — `ProgressStore`-un formasını hərfi-hərfinə təkrarlayır:

| `ProgressStore`-dan götürülən | Səbəb |
|---|---|
| `ChangeNotifier` + `static final instance` | Paket asılılığı olmadan; layihənin "sadə setState" konvensiyasını pozmur. |
| `@visibleForTesting factory .forTesting()` | Diskə yazmayan təmiz nüsxə — testlər üçün. |
| `static const _prefsKey` (`'settings_v1'`) | Versiyalı açar; gələcək miqrasiya üçün yer saxlayır. |
| `_scheduleSave()` + `_saveDebounce` | Açarın sürətli çevrilməsi hər dəfə diskə yazmasın. |
| `load()` içində `try/catch` | Prefs oxunmasa tətbiq **default dəyərlərlə işləməyə davam edir**, çökmür. |

```dart
enum SoundChannel { narration, animal, effect }

class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  @visibleForTesting
  factory AppSettings.forTesting() => AppSettings._();

  static const String _prefsKey = 'settings_v1';
  static const Duration _saveDebounce = Duration(milliseconds: 400);

  bool masterSound    = true;   // ümumi açar
  bool narrationSound = true;   // hərf/heyvan izahı (…_info_sound.mp3)
  bool animalSound    = true;   // heyvan səsi (…_sound.mp3)
  bool effectSound    = true;   // click, win, page_flip
  bool haptics        = true;   // tracing_canvas-dakı titrəmə
  bool reduceMotion   = false;  // konfeti söndürülür
  int  puzzleGridSize = 3;      // 3 və ya 4

  bool isOn(SoundChannel c);    // masterSound && <kanalın öz açarı>

  Future<void> load();          // main()-də runApp-dan ƏVVƏL
}
```

**Saxlama formatı:** `ProgressStore` kimi tək bir JSON sətri (`_prefsKey`
altında), ayrı-ayrı `setBool` açarları yox — eyni nümunə, eyni miqrasiya yolu.

**Yükləmə anı:** `main()` içində, mövcud `await ProgressStore.instance.load()`
sətrinin **yanında**:

```dart
await ProgressStore.instance.load();
await AppSettings.instance.load();
runApp(const MyApp());
```

`main.dart`-dakı mövcud şərh bunun səbəbini artıq izah edir (ilk kadrda default
dəyər görünüb sonra "tullanmasın"). Ayarlar üçün əlavə səbəb: ayarlar gəlməmiş
səs çalınmamalıdır. İki `load()` ardıcıl işləyir; hər ikisi eyni
`SharedPreferences.getInstance()` nüsxəsini alır, ona görə ikinci çağırış praktiki
olaraq pulsuzdur.

### 3.3 Dəyərin səhifələrə çatdırılması

Provider/Bloc əlavə olunmur. İki mexanizm, hər biri öz yerində:

**(a) Çalınma anında oxumaq** — səs kodu üçün. `GatedPlayer` sinxron olaraq
`AppSettings.instance.isOn(channel)` oxuyur. `InheritedWidget` plumbing-i 9
pleyerə çəkmək lazım gəlmir.

**(b) `AnimatedBuilder` ilə dinləmək** — yalnız yenidən çəkilməli UI üçün.
`ProgressStore` üçün seçilmiş bağlama üsulu budur (bax onun sinif şərhi), ona görə
`AppSettings` də `ListenableBuilder` yox, **`AnimatedBuilder`** işlədir — tətbiqdə
tək bir üsul qalsın. İstifadə yerləri: mute düyməsi, ayarlar səhifəsi, səs
düymələrinin sönük görünüşü.

### 3.4 GatedPlayer — səs keçid qatı

**Niyə lazımdır:** 9 çalınma nöqtəsinə `if (səs açıqdır)` şərti səpələmək
kövrəkdir — biri unudula bilər və gələcəkdə əlavə olunan yeni `AudioPlayer`
səssizcə mute-u keçər. Bu, nəzəri risk deyil: bu sənəd yazılarkən `letter_writing_page.dart`
əlavə olundu və özü ilə **iki yeni `AudioPlayer`** gətirdi. Keçid pleyerin öz
içində olmalıdır.

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

Mövcud `final ... = AudioPlayer()` sahə-səviyyəli qurma nümunəsi **saxlanılır**
(CLAUDE.md gotcha #5) — `GatedPlayer` də sahədə sinxron qurulur, `setAsset`
`_initAudio()` içində try/catch ilə qalır.

### 3.5 Mövcud 9 pleyerin kanallara bölünməsi

| Fayl | Simvol | Nə çalır | Kanal |
|---|---|---|---|
| `alphabet_page.dart` | `_AlphabetPageState._audioPlayer` | `page_flip.mp3` | `effect` |
| `animal_list_page.dart` | `_SoundButtonState._audioPlayer` | hərf izahı | `narration` |
| `animal_detail_page.dart` | `_AnimalDetailPageState.audioPlayer` | **iki iş** | bax aşağı |
| `animal_detail_page.dart` | `_AnimalWordPuzzleState._clickPlayer` | `click.mp3` | `effect` |
| `animal_detail_page.dart` | `_AnimalWordPuzzleState._winPlayer` | `win.mp3` | `effect` |
| `puzzle_page.dart` | `_PuzzlePageState._audioPlayer` | `click.mp3` | `effect` |
| `puzzle_page.dart` | `_PuzzlePageState._winPlayer` | `win.mp3` | `effect` |
| `letter_writing_page.dart` | `_clickPlayer` | `click.mp3` | `effect` |
| `letter_writing_page.dart` | `_winPlayer` | `win.mp3` | `effect` |

**`_AnimalDetailPageState.audioPlayer` bölünməlidir.** Bu tək pleyer həm
`_toggleAnimalInfo()` (izah — `narration`), həm də AppBar-dakı heyvan səsi
düyməsinin `_playSound(animalSoundAsset)` çağırışı (`animal`) tərəfindən istifadə
olunur. İki ayrı `GatedPlayer`-ə bölünür: `_infoPlayer` və `_animalPlayer`.
**Yan fayda:** heyvan səsi artıq izahı yarıda kəsməyəcək.

`letter_writing_page.dart`-da artıq `_play(AudioPlayer player)` adlı tək bir
köməkçi var — o səhifədə migrasiya yalnız həmin bir funksiyaya toxunur.

### 3.6 "Susdurulub" vəziyyətinin UI-da göstərilməsi

**Problem:** `_AnimalDetailPageState` və `_SoundButtonState`
`playerStateStream`-i dinləyib `isPlaying` / `isPlayingInfo` bayrağını
`ProcessingState.completed` hadisəsində sıfırlayır. Səs susdurulubsa heç nə
çalınmır, `completed` gəlmir və düymə **əbədi "Dayandır" vəziyyətində ilişir**.

**Həll (iki qat):**

1. **UI qatı:** kanal söndürülübsə səs düymələri sönük (`onPressed: null`) və
   susdurulmuş ikonu ilə göstərilir. Uşaq üçün işləməyən düymədən yaxşıdır — nə
   üçün səs gəlmədiyi görünür. `AnimatedBuilder` ilə bağlanır. Yerlər: detal
   səhifəsinin "Dinlə" düyməsi, AppBar-dakı heyvan səsi düyməsi, siyahı
   səhifəsinin `_SoundButton`-u.
2. **Təhlükəsizlik qatı:** `play()` `false` qaytarır və çağırış yerləri bayrağı
   `true` etmir.

CLAUDE.md gotcha #6 ("səssiz səs düyməsi mövcud olmamalıdır") eyni qaydanın
mövcud ifadəsidir — bu, onun mute-a genişləndirilməsidir.

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

> **Edge-to-edge** (CLAUDE.md gotcha #10): yeni səhifə mütləq öz insetini tətbiq
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

- `Titrəmə` — `TracingCanvas._emit()` içindəki `HapticFeedback.selectionClick()`
  çağırışını şərtə salır (hərfi cızarkən yoxlama nöqtəsi keçiləndə işləyir).
- `Animasiyanı azalt` — konfeti effektini söndürür. Həssas uşaqlar və zəif
  cihazlar üçün.
- `Pazl çətinliyi` — `SegmentedButton`: 3×3 / 4×4.

**3. Valideyn**

- `Progresi sıfırla` — mövcud `ProgressStore.reset()`-i çağırır. **İkiqat
  qorunur:** valideyn qapısından keçmiş olsa da, ayrıca `AlertDialog` təsdiqi
  istəyir ("Bütün ulduzlar silinəcək. Davam edilsin?"), çünki əməliyyat geri
  qaytarıla bilmir. Təsdiqdən sonra `SnackBar` ilə bildiriş.

**4. Məlumat**

- `Səs mənbələri` — mövcud dialoq (`_AlphabetPageState._showSoundCredits`) buraya
  köçür.
- `Tətbiq haqqında` — ad, versiya, paket id (`com.vebstudio.elifba`), qısa
  məxfilik mətni: "Bu tətbiq heç bir şəxsi məlumat toplamır, internetə qoşulmur
  və reklam göstərmir."

Versiya sətri `lib/core/config.dart`-da `const kAppVersion = '1.1.1'` kimi
saxlanılır; `package_info_plus` asılılığı əlavə edilmir. **Bu sabit
`pubspec.yaml`-dakı `version:` ilə əl ilə sinxronlaşdırılmalıdır.**

---

## 6. Əsas ekrandakı giriş nöqtələri

`_AlphabetPageState.build()` içindəki başlıq sırası (`Əlifba` mətni + mövcud
`Icons.info_outline` düyməsi) dəyişir:

```
[ 🔊 ]        Əlifba        [ ⚙ ]
  ↑                           ↑
master susdur            3 san. basıb saxla → Ayarlar
(dərhal, qapısız)
```

- **Sol — `MuteButton`:** `masterSound`-u dərhal çevirir, qapı yoxdur.
  `AnimatedBuilder` ilə açıq/bağlı ikonlar arasında keçir.
- **Sağ — ⚙:** `if (await showParentalGate(context))` → `SettingsPage`.
- Mövcud ℹ️ (səs mənbələri) düyməsi **silinir** — məzmunu ayarlar səhifəsinə köçür.

---

## 7. Qalan bağlantılar

### 7.1 reduceMotion — 5 konfeti nöqtəsi

Konfeti indi **beş** yerdə oynadılır (əvvəlki üç deyil):

| Fayl | Simvol / kontekst |
|---|---|
| `animal_detail_page.dart` | tam-ulduz təbriki (`_fullStarShown` yoxlanılan metod) |
| `animal_detail_page.dart` | qida/bölmə tamamlanma nöqtəsi |
| `animal_detail_page.dart` | `_AnimalWordPuzzleState._checkWin()` |
| `puzzle_page.dart` | iki tamamlanma nöqtəsi |
| `letter_writing_page.dart` | `_confetti.play()` — hərf cızma qalibiyyəti |

Hər birində:

```dart
if (!AppSettings.instance.reduceMotion) _confettiController.play();
```

`ConfettiWidget` ağacda qalır (oynadılmayanda heç nə çəkmir) — şərti widget
ağacına salmaq lazım deyil.

### 7.2 puzzleGridSize

`_PuzzlePageState.gridSize` sahəsi `initState`-də
`AppSettings.instance.puzzleGridSize`-dan alınır. Səhifə daxilindəki ölçü seçicisi
seçimi **geri yazır** — beləliklə oyun içindəki seçim və ayar tək bir dəyərdir,
iki fərqli həqiqət mənbəyi yaranmır.

### 7.3 haptics

`TracingCanvas._emit()` içindəki tək `HapticFeedback.selectionClick()` çağırışı
şərtə salınır. Tətbiqdə başqa haptik çağırış yoxdur.

---

## 8. Testlər

| Fayl | Nə yoxlanılır |
|---|---|
| `test/settings_test.dart` | `AppSettings.forTesting()` ilə `isOn()` məntiqi (master söndürülübsə bütün kanallar bağlıdır, alt-açarların dəyəri itmir); `SharedPreferences.setMockInitialValues({})` ilə yükləmə/yazma dövrü və zədələnmiş JSON-un default dəyərlərə düşməsi. |
| `test/parental_gate_test.dart` | 2.9 san. → dialoq açıq qalır; 3.1 san. → `true`; barmaq erkən qaldırılanda tərəqqi sıfırlanır; "Ləğv et" → `false`. |
| `test/settings_page_test.dart` | Master söndürüləndə alt-açarlar `disabled` olur; "Progresi sıfırla" təsdiq dialoqu olmadan `ProgressStore`-a toxunmur. |

**`GatedPlayer` üçün ayrıca test yazılmır** — `AudioPlayer()` qurulması test
mühitində platforma kanalı tələb edir (CLAUDE.md gotcha #11: just_audio
çağırışını `await` etməyin, `tester.runAsync` işlətməyin). Bunun əvəzinə keçid
məntiqi `AppSettings.isOn()` saf funksiyasında cəmlənir və orada test olunur.

**Mövcud test dəsti:** `test/widget_test.dart` artıq 250 sətirlik həqiqi smoke
test dəstidir (fayl başında just_audio qaydaları sənədləşdirilib) — bu iş ona
yalnız yeni mute düyməsi/⚙ düyməsi üçün lazım gələn düzəlişi əlavə edir.

> **Diqqət:** bu sənəd yazılarkən `flutter test` 136 keçid / 4 uğursuzluq verirdi.
> Dördü də `_WriteLetterCard` ilə bağlıdır və **başqa sessiyanın yarımçıq işidir**
> — bu plana aid deyil. İşə başlamazdan əvvəl `flutter test`-in təmiz olduğuna
> əmin olun, əks halda öz dəyişikliyinizin nəyi sındırdığını ayırd edə
> bilməyəcəksiniz.

---

## 9. Risklər və tələlər

1. **İş ağacı paralel redaktə altındadır.** Bu sənəd yazılarkən ən azı iki başqa
   sessiya eyni fayllarda işləyirdi; `pubspec.yaml` və `lib/widgets/` bir neçə
   dəqiqə ərzində dəyişdi. **Başlamazdan əvvəl `git status` və `flutter test`
   yoxlanılmalı**, digər sessiyaların bitdiyi təsdiqlənməlidir.
2. **Edge-to-edge** — §5-dəki xəbərdarlığa bax.
3. **İlişən `isPlaying`** — §3.6-da həll olunub; migrasiyada unudulmamalıdır.
4. **Detal səhifəsinin tək pleyeri iki kanala xidmət edir** — bölünməlidir (§3.5).
5. **Qapının zəifliyi** — bilərəkdən qəbul edilib (§2.1); `reset()` üçün ikinci
   təsdiq qatı ona görə əlavə olunub.
6. **Versiya sabitinin sinxronu** — `pubspec.yaml` ilə əl ilə (§5).
7. **CRLF churn** — layihədə `autocrlf=true` və köhnə CRLF blob-ları var; mövcud
   fayllardakı kiçik redaktələr diff-də bütöv fayl yenidən yazılması kimi görünə
   bilər. Commit-dən əvvəl `git diff --stat` yoxlanılmalıdır.

## 10. Əhatədən kənar (YAGNI)

- **Statistika ekranı.** `ProgressStore` `totalStars`, `maxTotalStars`,
  `writtenLetterCount` hazır verir və valideyn bölməsinə təbii oturardı, amma
  istifadəçi "Standart paket"i seçdi. Sonradan asanlıqla əlavə edilə bilər —
  yeni data qatı tələb etmir.
- Ekran vaxtı limiti / fasilə xatırlatması.
- PIN kodu, məxfilik siyasəti URL-i, "Bizi qiymətləndirin", e-poçt keçidi.
- Dil seçimi (tətbiq yalnız Azərbaycan dilindədir).
- Fon musiqisi (hazırda yoxdur).

---

## 11. Toxunulan fayllar

**Yeni (5):** `lib/core/settings.dart`, `lib/core/sound.dart`,
`lib/widgets/parental_gate.dart`, `lib/widgets/mute_button.dart`,
`lib/pages/settings_page.dart`

**Dəyişən (8):** `lib/main.dart`, `lib/core/config.dart`,
`lib/pages/alphabet_page.dart`, `lib/pages/animal_list_page.dart`,
`lib/pages/animal_detail_page.dart`, `lib/pages/puzzle_page.dart`,
`lib/pages/letter_writing_page.dart`, `lib/widgets/tracing_canvas.dart`

**`pubspec.yaml` dəyişmir** — `shared_preferences` artıq mövcuddur.

**Sənədləşmə:** `CLAUDE.md` — ayarlar qatı və yeni qayda: *"hər səs
`GatedPlayer`-dən keçməlidir, birbaşa `AudioPlayer` qurulmamalıdır"*.

---

## 12. İcra ardıcıllığı

Hər mərhələ öz-özlüyündə yoxlanıla bilən vəziyyətdə bitir:

1. **`AppSettings` + testlər.** UI yoxdur; `ProgressStore` nümunəsi təkrarlanır.
2. **`GatedPlayer` + 9 pleyerin migrasiyası.** Bütün defaultlar açıq olduğu üçün
   istifadəçi davranışı **dəyişmir** — təmiz refaktor, ayrıca yoxlanıla bilər.
3. **`showParentalGate()` + testi.** Təcrid olunmuş widget.
4. **`SettingsPage` + `MuteButton` + əsas ekran giriş nöqtələri.** Səs mənbələri
   dialoqu köçürülür, `reset()` bağlanır. Bu mərhələnin sonunda funksiya işlək olur.
5. **`haptics`, `reduceMotion`, `puzzleGridSize` bağlantıları.**
6. **`CLAUDE.md` yenilənir.**
