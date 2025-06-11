class LetterConfig {
  final String letter;
  final String description;
  final String imagePath;
  final String audioPath;
  final List<AnimalInfo> animals;

  const LetterConfig({
    required this.letter,
    required this.description,
    required this.imagePath,
    required this.audioPath,
    required this.animals,
  });
}

class AnimalInfo {
  final String name;
  final String description;
  final String imagePath;
  final String audioPath;
  final List<String> foods;
  final bool hasSound;
  final bool hasPuzzle;
  final String? youtubeEmbed;

  const AnimalInfo({
    required this.name,
    required this.description,
    required this.imagePath,
    required this.audioPath,
    required this.foods,
    this.hasSound = false,
    this.hasPuzzle = false,
    this.youtubeEmbed,
  });
}

class AppConfig {
  static const List<String> alphabet = [
    'A',
    'B',
    'C',
    'Ç',
    'D',
    'E',
    'Ə',
    'F',
    'G',
    'Ğ',
    'H',
    'X',
    'I',
    'İ',
    'J',
    'K',
    'Q',
    'L',
    'M',
    'N',
    'O',
    'Ö',
    'P',
    'R',
    'S',
    'Ş',
    'T',
    'U',
    'Ü',
    'V',
    'Y',
    'Z',
  ];

  static const Map<String, String> letterDescriptions = {
    'A':
        '"A" əlifbanın ilk hərfidir və çox vacib bir hərfdir.\nBu hərflə "alma", "ay", "at" kimi sözlər başlayır.\n"A" həm böyük, həm də kiçik yazılır: A və a.\nBu hərfi yazmaq asandır və bir çox dildə də eyni şəkildə istifadə olunur.\nUşaqların öyrəndiyi ilk hərflərdən biri də məhz "A" olur!',
    'B':
        'B hərfi balaca baloncuklar kimi görünür – böyük B-də iki dairə var!\n"B" ilə başlayan sözlərə bax: balıq, barmaq, balon!\nBu hərf həm yazıda, həm də danışıqda çox işlənir.\nB hərfini yazmaq bir az oyuncağa bənzəyir – əvvəl bir xətt, sonra iki yumru!\nUşaqlar bu hərfi öyrəndikcə bir çox maraqlı şeylərin adını deyə bilirlər!',
    'C':
        'C hərfi aypara kimi görünür – elə bil gülümsəyən bir üz!\n"C" ilə cəld, cəhrayı, cəngəllik kimi sözlər başlayır.\nBu hərf bir çox heyvanların adında da var: ceyran, cücə, cəngəllik pişiyi!\nC hərfini yazmaq asandır – sadəcə bir dairənin bir hissəsi kimi!\nUşaqlar bu hərfi tanıyanda həm təbiəti, həm rəngləri, həm də heyvanları öyrənmiş olurlar.',
    'Ç':
        '"Ç" hərfi şən səslənir – elə bil çılğın bir dost kimidir!\n"Ç" ilə çətir, çay, çarpayı, çanta kimi sözlər başlayır.\nBu hərf yağışlı havada çətir tutan uşaq kimi görünür!\n"Ç" səsi çıxanda dil bir az dişlərə yaxın olur – "ç-ç-ç"!\nUşaqlar bu hərfi öyrənəndə həm sözləri düzgün deyir, həm də əylənirlər!',
    'D':
        '"D" hərfi qalın və güclü səslənir – elə bil döyüntü səsi kimi: "dum-dum"!\nBu hərflə dəvə, daş, dəftər, dəbilqə kimi maraqlı sözlər başlayır.\nBöyük D hərfi elə bil bir dairə ilə bir xəttin dostluğudur!\n"D" deyəndə dil dişlərə yaxınlaşır və güclü bir səs yaranır.\nUşaqlar D hərfini tanıyanda bir çox əşyaların və heyvanların adını öyrənmiş olurlar!',
    'E':
        '"E" hərfi üç xəttli balaca pilləkənə bənzəyir!\nBu hərflə ev, elma, əllər, eşşək kimi sözlər başlayır.\n"E" səsi çox yumşaqdır – elə bil gülümsəyən bir səsdir: "e-e-e"!\nUşaqlar "E" hərfini öyrənəndə bir çox sevdikləri sözləri oxumağa başlayırlar.\nE hərfi həm yazmaqda, həm də oxumaqda çox tez-tez qarşımıza çıxır!',
    'Ə':
        '"Ə" hərfi yalnız Azərbaycan dilində olan özəl bir hərfdir!\nBu hərflə əllər, əjdaha, əkin, əmi kimi sözlər başlayır.\n"Ə" səsi elə bil təəccüblənəndə dediyimiz "əəə?" kimi çıxır – çox maraqlıdır!\nBöyük "Ə" hərfi çevrilmiş "e" kimidir, amma öz səsi tam fərqlidir.\nUşaqlar "Ə" hərfini öyrənəndə Azərbaycan dilinin gözəlliyini daha yaxşı anlayırlar!',
    'F':
        '"F" hərfi nazik və sakit bir səs çıxarır – elə bil fısıltı kimi: "f-f-f"!\nBu hərflə fil, fəhlə, fəvvarə, fənər kimi sözlər başlayır.\nF hərfi yazılanda bir dik xətt və iki balaca xəttdən ibarət olur – çox sadədir!\n"F" səsi çıxanda dodaqlar bir-birinə yaxın olur və yumşaq bir hava səsi yaranır.\nUşaqlar "F" hərfini öyrəndə ətraflarındakı bir çox maraqlı əşyaların adını tanıyırlar!',
    'G':
        '"G" hərfi dönən bir qapı kimi görünür, sanki içəri girmək istəyir!\nBu hərflə gül, gəmi, gözəl, gözlük kimi sözlər başlayır.\nG səsi bəzən yumşaq, bəzən isə güclü olur – "g-g-g" kimi!\n"G" hərfi yazılanda böyük dairə ilə kiçik bir quyruq əlavə edilir.\nUşaqlar "G" hərfini öyrənəndə həm təbiəti, həm də əşyaları daha yaxşı tanıyırlar!',
    'Ğ':
        '"Ğ" hərfi Azərbaycan əlifbasında xüsusi və nadir bir səsdir.\nBu hərf adətən sözlərin ortasında və ya sonunda çıxır, məsələn, dağ, ağ, bağ kimi sözlərdə.\n"Ğ" səsi danışıqda səsi yumşaldır və uzadır, elə bil sözlərə mehribanlıq qatır.\nBu hərfi öyrənəndə uşaqlar Azərbaycan dilinin zənginliyini daha yaxşı başa düşürlər.\n"Ğ" hərfi yazılarkən böyük "G" hərfinə bənzəyir, amma səsi fərqlidir və xüsusi bir havası var.',
    'H':
        '"H" hərfi sanki nəfəs alıb-verən bir səslə başlayır – "h-h-h"!\nBu hərflə hava, hamı, həyat, hərf kimi sözlər başlayır.\nH səsi çıxanda ağız açıq qalır və yumşaq bir nəfəs səsi yaranır.\n"H" hərfi çox əhəmiyyətlidir, çünki onunla danışıq daha aydın olur.\nUşaqlar "H" hərfini öyrənəndə yeni sözləri kəşf edir və danışıqda daha inamlı olurlar!',
    'X':
        '"X" hərfi sanki bir xəzinənin qapısını açan sirli bir işarə kimidir!\nBu hərflə xəyal, xalça, xarıbülbül, xələc kimi sözlər başlayır.\nX səsi çıxanda dil arxası damağa toxunur və maraqlı bir səs yaranır.\n"X" hərfi yazılanda iki xətt üst-üstə qoyulur, çox özəl və fərqlidir!\nUşaqlar "X" hərfini öyrənəndə həm səs oyunlarını, həm də yazını daha yaxşı başa düşürlər!',
    'I':
        '"I" hərfi Azərbaycan əlifbasında səssiz və çox xüsusi bir hərfdir.\nBu hərf adətən sözlərin içində, ortasında və ya sonunda olur, məsələn, qış, bıçaq, sıra kimi sözlərdə.\n"I" səsi danışıqda yumşaq və boğazdan gələn bir səslə çıxır.\nUşaqlar "I" hərfini öyrənəndə sözlərin necə fərqli səsləndiyini və zənginliyini başa düşürlər.\nBu hərfi yazanda nöqtəsi olmur, ona görə də digər "i" hərfi ilə fərqlənir.',
    'İ':
        '"İ" hərfi Azərbaycan dilində çox vacib bir səslə başlayır – parlaq və aydın!\nBu hərflə ilə, işıq, inə, istanbul kimi sözlər başlayır.\nİ səsi çıxanda dilin ucu dişlərin arxasına yaxın olur və aydın bir səslənmə yaranır.\n"İ" hərfi yazılanda başında kiçik nöqtə olur, bu onu digərlərindən fərqləndirir.\nUşaqlar "İ" hərfini öyrənəndə həm sözləri, həm də cümlələri daha yaxşı başa düşürlər!',
    'J':
        '"J" hərfi sanki yüngülcə cingildəyən bir səslə başlayır.\nBu hərflə jurnal, jelatin, jant kimi sözlər başlayır.\nJ səsi çıxanda dilin ortası damağa yaxın olur və yumşaq bir səslənmə yaranır.\n"J" hərfi Azərbaycan əlifbasında çox özəl bir səsdir, bəzi dillərdə isə daha çox istifadə olunur.\nUşaqlar "J" hərfini öyrəndikdə yeni sözləri kəşf edir və dil bacarıqlarını artırırlar!',
    'K':
        '"K" hərfi çox güclü və qətiyyətli bir səslə başlayır!\nBu hərflə kitab, kələm, kürək, kompüter kimi sözlər başlayır.\nK səsi çıxanda dil arxası damağa toxunur və açıq, sərt bir səslənmə yaranır.\n"K" hərfi uşaqlar üçün yeni sözlər öyrənməkdə və danışıqda çox önəmlidir.\nUşaqlar "K" hərfini öyrəndikdə sözlər daha aydın və güclü səslənir!',
    'Q':
        '"Q" hərfi Azərbaycan dilində çox xüsusi və güclü bir səslə başlayır!\nBu hərflə qapı, qartal, qızıl, qələm kimi sözlər başlayır.\nQ səsi çıxanda dilin kökü boğaza yaxın olur və dərin bir səslənmə yaranır.\n"Q" hərfi uşaqlar üçün dil oyunlarında və sözləri düzgün tələffüz etməkdə çox önəmlidir.\nUşaqlar "Q" hərfini öyrəndikdə yeni sözlərin və hekayələrin dünyasına addım atırlar!',
    'L':
        '"L" hərfi çox yumşaq və ləzzətli səslə başlayır!\nBu hərflə ləzzət, limon, lampa kimi sözlər başlayır.\nL səsi çıxanda dilin ucu dişlərin arxasına toxunur və səs çox gözəl səslənir.\n"L" hərfi uşaqlar üçün danışıqda çox faydalıdır, çünki sözləri daha aydın edir.\nUşaqlar "L" hərfini öyrəndikdə sözləri və hekayələri daha yaxşı başa düşürlər!',
    'M':
        '"M" hərfi sanki mırıldanan bir səslə başlayır.\nBu hərflə məktəb, məxmər, meyvə, masa kimi sözlər başlayır.\nM səsi çıxanda dodaqlar yumşaqca bir-birinə toxunur və səslənmə çox rahatdır.\n"M" hərfi uşaqlar üçün yeni sözləri öyrənməkdə və danışıqda çox faydalıdır.\nUşaqlar "M" hərfini öyrəndikdə dil bacarıqları daha da inkişaf edir!',
    'N':
        '"N" hərfi çox sadə və yumşaq səslə başlayır.\nBu hərflə nənə, nəğmə, nar, nota kimi sözlər başlayır.\nN səsi çıxanda dil ucu dişlərin arxasına yaxın olur və səs çox aydın eşidilir.\n"N" hərfi uşaqlar üçün sözləri düzgün tələffüz etməkdə və danışıqda çox vacibdir.\nUşaqlar "N" hərfini öyrəndikdə sözlər daha gözəl və dəqiq səslənir!',
    'O':
        '"O" hərfi böyük və açıq səslə başlayır!\nBu hərflə orman, ot, oyun, ovqat kimi sözlər başlayır.\nO səsi çıxanda ağız geniş açılır və səs çox aydın, dolğun olur.\n"O" hərfi uşaqlar üçün yeni sözlər öyrənməkdə və danışıqda çox faydalıdır.\nUşaqlar "O" hərfini öyrəndikdə sözləri daha gözəl və güclü tələffüz edə bilirlər!',
    'Ö':
        '"Ö" hərfi çox fərqli və xüsusi səslə başlayır!\nBu hərflə özəl, ömür, ördək, öyrənmək kimi sözlər başlayır.\nÖ səsi çıxanda dodaqlar bir az dairəvi olur və səs yumuşaq səslənir.\n"Ö" hərfi uşaqlar üçün danışıqda çox vacibdir, çünki bir çox xüsusi sözlər bu hərflə başlayır.\nUşaqlar "Ö" hərfini öyrəndikdə yeni sözləri asanlıqla yadda saxlayırlar!',
    'P':
        '"P" hərfi partlayan və enerjili bir səslə başlayır!\nBu hərflə papaq, paltar, palıd, pul kimi sözlər başlayır.\nP səsi çıxanda dodaqlar qısa müddət bir-birinə toxunur və səs kəsik olur.\n"P" hərfi uşaqlar üçün sözləri daha canlı və əyləncəli tələffüz etməkdə çox önəmlidir.\nUşaqlar "P" hərfini öyrəndikdə danışığı daha maraqlı və aydın olur!',
    'R':
        '"R" hərfi çox canlı və guruldayan səslə başlayır!\nBu hərflə rəng, rəqs, rəhim, rəf kimi sözlər başlayır.\nR səsi çıxanda dilin ucu bir az titrəyir və səs çox maraqlı olur.\n"R" hərfi uşaqlar üçün sözləri daha rəngarəng və ifadəli tələffüz etməkdə çox vacibdir.\nUşaqlar "R" hərfini öyrəndikdə danışıqda daha çox söz istifadə edə bilirlər!',
    'S':
        '"S" hərfi sanki şirin bir fısıltı kimi səslənir!\nBu hərflə salam, sarı, su, saat kimi sözlər başlayır.\nS səsi çıxanda dişlər bir az açılır və hava sürətlə keçərək yumşaq səs yaranır.\n"S" hərfi uşaqlar üçün sözləri daha aydın və şirin tələffüz etməkdə çox vacibdir.\nUşaqlar "S" hərfini öyrəndikdə danışıq daha səlis və gözəl olur!',
    'Ş':
        '"Ş" hərfi sanki yumşaq bir şırıltı kimidir!\nBu hərflə şəkər, şapka, şirin, şəlalə kimi sözlər başlayır.\nŞ səsi çıxanda dodaqlar bir az dairəvi olur və səs yumuşaq, şirin səslənir.\n"Ş" hərfi uşaqlar üçün sözləri daha gözəl və mehriban tələffüz etməkdə çox önəmlidir.\nUşaqlar "Ş" hərfini öyrəndikdə danışıqda daha çox sevgi və şirinlik olur!',
    'T':
        '"T" hərfi tək və kəskin bir səslə başlayır!\nBu hərflə top, tulpan, təşəkkür, tərəvəz kimi sözlər başlayır.\nT səsi çıxanda dil ucu dişlərin arxasına toxunur və səs kəsik olur.\n"T" hərfi uşaqlar üçün sözləri daha dəqiq və aydın tələffüz etməkdə çox vacibdir.\nUşaqlar "T" hərfini öyrəndikdə danışıq daha anlaşılan və maraqlı olur!',
    'U':
        '"U" hərfi yumşaq və geniş bir səslə başlayır!\nBu hərflə uçmaq, uzun, uğur, üçbucaq kimi sözlər başlayır.\nU səsi çıxanda ağız geniş açılır və səs dərin olur.\n"U" hərfi uşaqlar üçün sözləri daha dolğun və güclü tələffüz etməkdə çox faydalıdır.\nUşaqlar "U" hərfini öyrəndikdə danışıqda daha inamlı və özünə güvənən olurlar!',
    'Ü':
        '"Ü" hərfi çox xüsusi və yumşaq bir səslə başlayır!\nBu hərflə üzüm, üzgüçülük, ürək, üfüq kimi sözlər başlayır.\nÜ səsi çıxanda dodaqlar dairəvi olur və səs burundan bir az keçir.\n"Ü" hərfi uşaqlar üçün sözləri daha şirin və yumşaq tələffüz etməkdə çox önəmlidir.\nUşaqlar "Ü" hərfini öyrəndikdə danışıqda mehribanlıq və sevgi artır!',
    'V':
        '"V" hərfi sanki kiçik bir qanad vızıltısı kimidir!\nBu hərflə valideyn, vasitə, və və vəhşi kimi sözlər başlayır.\nV səsi çıxanda dodaqlar alt dişlərə toxunur və səs qısa, kəskin olur.\n"V" hərfi uşaqlar üçün sözləri daha canlı və maraqlı tələffüz etməkdə çox vacibdir.\nUşaqlar "V" hərfini öyrəndikdə danışıq daha ritmik və əyləncəli olur!',
    'Y':
        '"Y" hərfi sanki yüngül bir yay kimi səslənir!\nBu hərflə yaşıl, yelkən, yemək, yoldaş kimi sözlər başlayır.\nY səsi çıxanda dil ağızın yuxarı hissəsinə yaxınlaşır və səs yumşaq olur.\n"Y" hərfi uşaqlar üçün sözləri daha şirin və rahat tələffüz etməkdə çox önəmlidir.\nUşaqlar "Y" hərfini öyrəndikdə danışıqda mehribanlıq və sevgi artar!',
    'Z':
        '"Z" hərfi zümzümə edən bir səslə başlayır!\nBu hərflə zebra, zəfəran, zəng, zoologiya kimi sözlər başlayır.\nZ səsi çıxanda dodaqlar və dişlər bir az yaxınlaşır və səs vızıldayar.\n"Z" hərfi uşaqlar üçün sözləri daha canlı və maraqlı tələffüz etməkdə çox vacibdir.\nUşaqlar "Z" hərfini öyrəndikdə danışıqda daha ritmik və əyləncəli olur!',
  };

  static const Map<String, List<String>> animalsByLetter = {
    'A': ['At', 'Ayı', 'Ağcaqanad', 'Alpaka'],
    'B': ['Balıq', 'Bayquş', 'Buqələmun', 'Bizon', 'Begemot', 'Baltadimdik'],
    'C': ['Camış', 'Cücə', 'Ceyran'],
    'Ç': ['Çalağan', 'Çita'],
    'D': ['Dənizatı', 'Donuz', 'Dovşan'],
    'E': ['Eşşək', 'Eland', 'Echidna'],
    'Ə': ['Ərincək', 'Əqrəb'],
    'F': ['Folivora', 'Fil', 'Flamingo'],
    'G': ['Gürzə', 'Gəlincik'],
    'H': ['Hamster'],
    'X': ['Xərçəng'],
    'İ': ['İlan'],
    'J': ['Jaquar'],
    'K': ['Kəpənək', 'Kirpi', 'Kərtənkələ', 'Kəklik'],
    'Q': ['Qaranquş', 'Qartal', 'Qaz', 'Qoyun', 'Qurd'],
    'L': ['Lama', 'Leopard', 'Leylek'],
    'M': ['Mamont', 'Meymun'],
    'N': ['Nərə'],
    'O': ['Orka'],
    'Ö': ['Ördək'],
    'P': ['Pələng', 'Pinqvin'],
    'R': ['Rakun'],
    'S': ['Siçan', 'Sincab', 'Sərçə'],
    'Ş': ['Şahin', 'Şir'],
    'T': ['Tısbağa', 'Tülkü'],
    'U': ['Ulaq'],
    'V': ['Vaşaq'],
    'Y': ['Yarasa'],
    'Z': ['Zürafə', 'Zebra'],
  };

  static const Map<String, String> animalInfo = {
    'At':
        'Atlar çox sürətli və zəkalı heyvanlardır. Onlar min illərdir ki, insanlara kömək edirlər – həm yük daşıyıblar, həm də insanları bir yerdən başqa yerə aparıblar.\nAtlar çox yaxşı yaddaşa malikdir və sahibini illərlə unutmaya bilirlər. Onlar həm də bir-birini tanıya və dostluq edə bilirlər.\nAtların qulaqları daim hərəkət edir – onlar bununla həm səsləri eşidirlər, həm də əhval-ruhiyyələrini göstərirlər.\nAtlar ot yeyirlər və çox vaxt ayaq üstə yatırlar. Bəli, atlar uzanmadan da dincələ bilirlər!\nBalaca ata tay deyilir və o çox oynaq və sevimli olur. Taylar doğulduqdan bir neçə dəqiqə sonra ayağa qalxa bilirlər!',
    'Ayı':
        'Ayılar çox güclü və ağıllı heyvanlardır. Onların burnu çox iti olur, hətta kilometrlərlə uzaqdan yeməyin qoxusunu ala bilirlər! Ayılar çox vaxt tək yaşayır və meşələrdə, dağlarda və bəzən buzlu yerlərdə görülür.\nƏn məşhur ayı növlərindən biri qütb ayısıdır – o, tamamilə ağ rəngdə olur və buzlu dənizlərdə yaşayır.Amma qəhvəyi ayılar və qara ayılar da var. Onlar əsasən meşələrdə olur və bal, meyvə, balıq və hətta kiçik heyvanlarla qidalanırlar.\nAyılar qışda uzun bir yuxuya gedirlər. Bu yuxuya qış yuxusu deyilir. Onlar bir neçə ay heç oyanmadan yatırlar!\nAyılar çox sevimli görünür, amma əslində çox güclüdürlər. Körpə ayılar – yəni ayı balaları – çox şirin və oynaq olurlar, anaları onları qorumağa çox diqqət edir.',
    'Ağcaqanad':
        'Ağcaqanadlar çox kiçik, amma maraqlı canlılardır. Onlar uçarkən vızıltı kimi bir səs çıxarırlar – bu səs qanadlarını çox sürətli çaldıqları üçün yaranır.\nOnlar əsasən axşam və gecə saatlarında aktiv olurlar və isti havanı sevirlər.\nOnların bəziləri insanların qanını sorur, amma bunu yalnız dişi ağcaqanadlar edir! Çünki onlar yumurta qoymaq üçün xüsusi qidalara ehtiyac duyurlar.\nAğcaqanadların qoxuya qarşı çox həssas burunları var. Onlar insanın tər qoxusunu hiss edib yaxınlaşırlar.',
    'Alpaka':
        'Alpakalar yumşaq və qalın tükləri ilə tanınan mehriban heyvanlardır. Onlar əsasən Cənubi Amerikanın dağlıq bölgələrində, xüsusilə And dağlarında yaşayırlar.\nAlpakaların tükləri çox dəyərlidir, çünki həm isti saxlayır, həm də allergiya yaratmır. Bu səbəbdən onların yunu ilə xüsusi geyimlər hazırlanır.\nAlpakalar çox sakit və dostcanlıdırlar. Onlar sürülərlə yaşayır və bir-biriləri ilə yumşaq səslərlə ünsiyyət qururlar.\nƏgər alpaka nəyisə bəyənməsə və ya qorxsa, tüpürə bilər – bu onların özlərini qoruma üsuludur!\nBalaca alpakalara "kriya" deyilir və onlar doğulandan bir neçə saat sonra ayaq üstə dura bilirlər.',
    'Balıq':
        'Balıqlar suyun altında yaşayan canlılardır və nəfəs almaq üçün qəlsəmələrdən istifadə edirlər. Onlar burunla deyil, suyun içindəki oksigeni qəlsəmələri ilə alırlar.\nBalıqların çoxu üzgəcləri ilə üzür və bədənlərini sağa-sola hərəkət etdirərək irəliləyirlər.\nBalıqların bəziləri çox parlaq və rəngarəng olur. Xüsusilə tropik dənizlərdə yaşayan balıqlar göy, sarı, qırmızı rənglərdə ola bilirlər!\nBəzi balıqlar qışda buzlu suyun altında belə yaşaya bilirlər. Hətta dəniz dibində işıq saçan balıqlar da var!\nBalıqlar çox sakit görünürlər, amma ətrafda baş verənləri hiss etmək üçün bədənlərində xüsusi xətlər var.',
    'Bayquş':
        'Bayquşlar gecə ovlanan quşlardır və çox iti görmə qabiliyyətləri var.\nOnların başı demək olar ki, tam dairə ilə fırlana bilir!\nBayquşlar çox sakit uça bilirlər, bu da ovlarını qorxmadan yaxalamağa kömək edir.\nOnlar əsasən siçanlar, kiçik quşlar və böcəklərlə qidalanırlar.\nBayquşların iri gözləri və kəskin eşitmə qabiliyyəti onları gecənin ustasına çevirir.',
    'Buqələmun':
        'Buqələmunlar çox xüsusi kərtənkələlərdir. Onların bədəni rəng dəyişə bilir! Əhvalına, ətraf mühitə və hətta temperatur dəyişməsinə görə buqələmunun rəngi dəyişir.\nOnların gözləri çox fərqlidir – hər iki gözü fərqli istiqamətə baxa bilir! Bu sayədə onlar ətrafı tam görə bilirlər.\nBuqələmunlar uzun və yapışqan dilləri ilə böcəkləri tuturlar. Dilləri o qədər sürətli çıxır ki, insan gözü ilə izləmək çətindir!\nOnlar çox yavaş hərəkət edirlər və ağac budaqlarında sakit-sakit gəzməyi sevirlər.\nBuqələmunlar təbiətdə gizlənmək üzrə ustadırlar. Dəyişən rəngləri sayəsində düşməndən asanlıqla gizlənə bilirlər.',
    'Bizon':
        'Bizonlar iri, güclü və tüklü bədənləri olan heyvanlardır. Onlar əsasən meşəlik və çəmənlik ərazilərdə yaşayırlar.\nBir bizonun çəkisi bir neçə ton ola bilər! Onlar həm çox güclüdür, həm də sürətli qaça bilirlər.\nBizonların alnında qalın tükləri və qısa, əyri buynuzları olur. Bu buynuzlardan həm müdafiə üçün, həm də öz aralarında yarışarkən istifadə edirlər.\nBizonlar sürülər halında yaşayırlar və çox sosial heyvanlardır. Bir-birilərinə təhlükə zamanı xəbərdarlıq edə bilirlər.\nBalaca bizonlara "buzov" deyilir və onlar doğulandan bir neçə dəqiqə sonra yeriməyə başlayırlar!',
    'Begemot':
        'Begemotlar suyu çox sevən, iri və güclü heyvanlardır. Onlar əsasən Afrikada çay və göllərdə yaşayırlar.\nGün ərzində saatlarla suyun içində qalırlar, çünki dəriyə birbaşa günəş düşəndə quruyur və zərər görə bilər.\nBegemotlar çöldə ağır və yavaş görünsələr də, suyun içində çox çevik və sürətli hərəkət edirlər.\nOnların ağızları çox böyük olur – bir begemot ağzını o qədər geniş aça bilir ki, içinə bir top yerləşə bilər!\nBaxmayaraq ki, çox vaxt sakit görünürlər, begemotlar özlərini və ailələrini qorumaq üçün çox cəsur ola bilirlər.',
    'Baltadimdik':
        'Baltadimdik çox qəribə və maraqlı quşdur! Onun dimdiyi iri və baltaya bənzəyir, buna görə də adı baltadimdik qoyulub.\nBu quş əsasən Afrikanın bataqlıqlarında yaşayır və orada qurbağa, balıq və hətta kiçik timsahları ovlayır!\nBaltadimdik çox sakit və tərpənmədən durmağı sevir. Bəzən saatlarla tərpənmir ki, ov yaxına gəlsin.\nOnların boyu uşaqlardan da hündür ola bilər – bəziləri 1 metr 20 santimetrə qədər uzana bilir!\nƏn maraqlısı isə budur ki, baltadimdik salam verirmiş kimi başını aşağı-yuxarı tərpədir və qəribə səslər çıxarır.',
    'Camış':
        'Camışlar iri və güclü heyvanlardır. Onlar əsasən isti və rütubətli yerlərdə yaşayırlar və suyu çox sevirlər.\nCamışların böyük və əyri buynuzları olur. Bu buynuzlar onlara həm qorxulu görünüş verir, həm də özlərini qorumaq üçün istifadə olunur.\nCamışlar gündə saatlarla palçıq və suda qalmağı sevirlər – bu onların dərisini sərin saxlayır və həşəratlardan qoruyur.\nOnlar əsasən kənd təsərrüfatında istifadə olunur – həm süd verirlər, həm də ağır işlərdə kömək edirlər.\nCamışlar çox dözümlü heyvanlardır və çətin şəraitdə belə yaşaya bilirlər.',
    'Cücə':
        'Cücələr toyuqların balaları olub, çox şirin və oynaq olurlar.\nOnlar yumurtadan çıxdıqdan dərhal sonra analarını tanıyır və onun arxasınca gedirlər.\nCücələr sarı, yumşaq tüklərlə örtülü olur və cik-cik səsləri çıxararaq ünsiyyət qururlar.\nOnlar tez böyüyürlər – cəmi bir neçə həftə ərzində tükləri tökülür və yeni, daha tünd rəngli tüklər çıxır.\nCücələr çox maraqlı və öyrənməyi sevən canlılardır – daim ətrafı kəşf edir və yeni şeylər öyrənirlər.',
    'Ceyran':
        'Ceyranlar çox zərif və sürətli heyvanlardır. Onlar açıq çöllərdə və səhralarda yaşayırlar.\nCeyranların uzun və incə ayaqları var, bu onlara çox sürətli qaçmağa imkan verir – təhlükə zamanı bir ceyran saatda 80 kilometrə qədər sürətlə qaça bilir!\nOnların gözəl, əyri buynuzları olur və bu buynuzlar əsasən erkək ceyranlarda daha böyük olur.\nCeyranlar çox diqqətli heyvanlardır – həmişə təhlükəni hiss etmək üçün qulaqlarını dik saxlayır və ətrafı izləyirlər.\nOnlar sürülər halında yaşayır və bir-birinə xəbərdarlıq etməklə təhlükədən qorunurlar.',
    'Çalağan':
        'Çalağanlar iti gözləri və sürətli uçuşları ilə tanınan yırtıcı quşlardır.\nOnlar göydə dairələr cızaraq ovlarını axtarır və sonra sürətlə şığıyaraq onları tuturlar.\nÇalağanların qanadları çox uzun və ensizdir, bu onlara havada saatlarla qalmağa və küləyi istifadə etməyə imkan verir.\nOnlar əsasən kiçik gəmiricilər, quşlar və hətta ilan kimi sürünənlərlə qidalanırlar.\nÇalağanlar yuvalarını hündür ağaclarda və ya qayalarda qurur və balalarına ov etməyi öyrədirlər.',
    'Çita':
        'Çitalar dünyanın ən sürətli quru heyvanlarıdır! Onlar qısa məsafələrdə saatda 110 kilometrə qədər sürətlə qaça bilirlər.\nÇitaların bədəni qaçmaq üçün mükəmməl uyğunlaşıb – uzun və elastik bədən, güclü ayaqlar və balans saxlamaq üçün uzun quyruq.\nOnların bədənində qara nöqtələr var və bu nöqtələr hər çitada fərqlidir – elə bil barmaq izi kimidir!\nÇitalar əsasən Afrika çöllərində yaşayır və ceyran, antilop kimi sürətli heyvanları ovlayırlar.\nOnlar çox sürətli olsalar da, uzun müddət qaça bilmirlər – adətən 20-30 saniyə qaçdıqdan sonra yorulur və dincəlməlidirlər.',
    'Dənizatı':
        'Dənizatları çox qəribə və maraqlı dəniz canlılarıdır. Onların başı at başına bənzəyir, buna görə də belə adlanırlar!\nDənizatları üzgəcləri ilə çox yavaş hərəkət edirlər və adətən dəniz otlarına quyruqları ilə dolanaraq dayanırlar.\nƏn maraqlısı odur ki, dənizatlarında balalar ata tərəfindən dünyaya gətirilir! Dişi dənizatı yumurtaları erkəyin xüsusi cibinə qoyur və balalar orada inkişaf edir.\nOnlar çox kiçik dəniz canlıları ilə qidalanır və gündə minlərlə kiçik orqanizm yeyə bilirlər.\nDənizatları rənglərini dəyişə bilir və bununla ətraf mühitdə gizlənə bilirlər.',
    'Donuz':
        'Donuzlar çox ağıllı və təmiz heyvanlardır. Onlar insanların düşündüyü kimi çirkli deyil, əksinə, imkan olduqda təmiz yerdə yatmağı sevirlər.\nDonuzların burnu çox həssasdır və onlar torpağın altında belə yeməyi tapa bilirlər. Bu buruna "xortum" deyilir.\nOnlar çox sosial heyvanlardır və qruplar halında yaşamağı sevirlər. Bir-biriləri ilə müxtəlif səslərlə ünsiyyət qururlar.\nBalaca donuzlara "çoşqa" deyilir və onlar çox oynaq və maraqlı olurlar.\nDonuzlar əslində çox zəkalıdırlar – onları hətta bəzi sadə oyunları oynamağa öyrətmək mümkündür!',
    'Dovşan':
        'Dovşanlar uzun qulaqları və sürətli hərəkətləri ilə tanınan şirin heyvanlardır.\nOnların qulaqları çox həssasdır və ən kiçik səsləri belə eşidə bilirlər – bu, təhlükədən qorunmaq üçün çox vacibdir.\nDovşanlar otla qidalanır və xüsusilə kök və yerkökünü çox sevirlər. Onlar yemək yeyərkən daim ətrafı izləyirlər.\nOnlar çox sürətli qaça bilirlər və təhlükə zamanı ziqzaqlarla qaçaraq düşməni çaşdırırlar.\nBalaca dovşanlara "dovşan balası" və ya "bala dovşan" deyilir və onlar gözləri qapalı, tüksüz doğulurlar.',
    'Eşşək':
        'Eşşəklər çox dözümlü və səbirli heyvanlardır. Onlar min illərdir ki, insanlara yük daşımaqda kömək edirlər.\nEşşəklərin qulaqları atlarınkından daha uzundur və bu qulaqlar onlara çox yaxşı eşitmə qabiliyyəti verir.\nOnlar çətin şəraitdə yaşaya bilir və az su ilə kifayətlənə bilirlər. Bu xüsusiyyət onları səhra kimi yerlərdə çox dəyərli edir.\nEşşəklər çox ağıllıdırlar və yolları yaxşı yadda saxlayırlar. Hətta illər sonra belə getdikləri yolu xatırlaya bilirlər.\nOnların məşhur "ia-ia" səsi əslində bir ünsiyyət formasıdır və müxtəlif vəziyyətlərdə fərqli səslər çıxarırlar.',
    'Eland':
        'Elandlar dünyanın ən böyük antilop növlərindən biridir. Onlar əsasən Afrika savannalarında yaşayırlar.\nElandların böyük, burulmuş buynuzları olur və bu buynuzlar həm erkək, həm də dişilərdə ola bilir.\nOnlar çox güclü heyvanlardır və 4 metrə qədər hündürlüyə tulana bilirlər! Bu, təhlükədən qaçmaq üçün çox faydalıdır.\nElandlar otla qidalanır və susuz qalmağa dözə bilirlər, çünki lazımi nəmi yedikləri bitkilərdən alırlar.\nOnlar sakit və ürkək heyvanlardır, amma təhlükə zamanı çox sürətli qaça bilirlər.',
    'Echidna':
        'Echidnalar çox qəribə və maraqlı heyvanlardır. Onlar Avstraliyada yaşayırlar və tiknəli bədənləri var.\nƏn maraqlısı odur ki, echidnalar yumurta qoyan məməlilərdir! Bəli, onlar həm məməli, həm də yumurta qoyurlar – təbiətin əsl möcüzəsidir!\nEchidnaların uzun və yapışqan dilləri var və bu dillə qarışqaları və termitləri tuturlar.\nOnlar təhlükə zamanı özlərini top kimi bükür və tikanlı tərəfini yuxarı çevirirlər.\nEchidnalar çox yavaş hərəkət edirlər, amma çox dəqiq iy bilmə qabiliyyətinə malikdirlər.',
    'Ərincək':
        'Ərincəklər ağaclarda yaşayan və çox yavaş hərəkət edən heyvanlardır. Onlar gündə təxminən 40 metr məsafə qət edirlər!\nƏrincəklərin uzun caynaqları var və bu caynaqlarla ağac budaqlarından asılı qalırlar. Onlar hətta yatarkən belə budaqdan asılı vəziyyətdə qalırlar.\nƏn maraqlısı odur ki, ərincəklər başı aşağı asılı vəziyyətdə qida yeyir, yatır və hətta balalarını dünyaya gətirirlər!\nOnların bədənində xüsusi yosunlar yaşayır və bu, onlara yaşıl rəng verir, beləliklə ağaclarda gizlənə bilirlər.\nƏrincəklər əsasən yarpaqlarla qidalanır və çox az su içirlər – lazımi nəmi yedikləri yarpaqlardan alırlar.',
    'Əqrəb':
        'Əqrəblər səkkiz ayaqlı, quyruqlarında zəhərli iynəsi olan canlılardır.\nOnların bədəni iki hissədən ibarətdir: baş-sinə və qarıncıq. Qarıncığın sonunda qıvrılan quyruq və zəhər iynəsi yerləşir.\nƏqrəblər əsasən gecə vaxtı ov edir və gündüzlər daşların altında və ya qumda gizlənirlər.\nOnlar həşəratlar və kiçik heyvanlarla qidalanırlar, ovlarını əvvəl qısqacları ilə tutur, sonra zəhərləyirlər.\nƏqrəblər ultraviolet işıqda parlayırlar – gecə vaxtı xüsusi lampalarla onları asanlıqla görmək olur!',
    'Folivora':
        'Folivora (və ya tənbəl heyvan) ağaclarda yaşayan və çox yavaş hərəkət edən məməlidir.\nOnlar gündə təxminən 40 metr məsafə qət edirlər və vaxtlarının çoxunu yatmaqla keçirirlər – gündə 15-20 saat yata bilirlər!\nFolivoraların uzun caynaqları var və bu caynaqlarla ağac budaqlarından asılı qalırlar. Onlar hətta yatarkən belə budaqdan asılı vəziyyətdə qalırlar.\nƏn maraqlısı odur ki, folivoralar başı aşağı asılı vəziyyətdə qida yeyir, yatır və hətta balalarını dünyaya gətirirlər!\nOnların bədənində xüsusi yosunlar yaşayır və bu, onlara yaşıl rəng verir, beləliklə ağaclarda gizlənə bilirlər.',
    'Fil':
        'Fillər dünyanın ən böyük quru heyvanlarıdır. Onların uzun xortumları var və bu xortumla həm qida götürür, həm su içir, həm də müxtəlif əşyaları qaldıra bilirlər.\nFillərin böyük qulaqları var və bu qulaqları yelləməklə bədənlərini sərinlədirlər. Qulaqlarının forması və ölçüsü yaşadıqları yerə görə dəyişir.\nOnlar çox ağıllı və sosial heyvanlardır. Ailələri ilə birlikdə yaşayır və bir-birinə kömək edirlər. Hətta öz ailə üzvlərini illər sonra belə tanıya bilirlər!\nFillərin dişləri fil sümüyü adlanır və çox dəyərlidir. Təəssüf ki, bu səbəbdən fillər ovlanır və sayları azalır.\nBalaca fillərə "fil balası" deyilir və onlar doğulduqdan sonra 2-3 il ana südü ilə qidalanırlar.',
    'Flamingo':
        'Flaminqolar uzun boyunları, nazik ayaqları və çəhrayı rəngləri ilə tanınan quşlardır.\nOnlar adətən bir ayaq üstündə dayanırlar – bu, enerji saxlamağa və soyuq sudan qorunmağa kömək edir.\nFlaminqoların rəngi qidalandıqları xərçəngkimilərdən gəlir – nə qədər çox xərçəng yesələr, o qədər parlaq çəhrayı olurlar!\nOnlar böyük qruplarda – koloniyalarda yaşayırlar və bəzən minlərlə flamingo bir yerdə ola bilir.\nFlaminqolar palçıqdan konus şəklində yuvalar düzəldir və yumurtalarını onun üstünə qoyurlar.',
    'Gürzə':
        'Gürzə zəhərli bir ilan növüdür və əsasən Qafqaz və Orta Asiyada yaşayır.\nOnların başında üçbucaq formalı naxışlar olur və bu, onları tanımağa kömək edir.\nGürzələr çox yaxşı ov edə bilirlər – onlar həm görmə, həm də istilik hiss etmə qabiliyyəti ilə şikarlarını tapırlar.\nOnlar əsasən gecə vaxtı aktiv olurlar və gündüzlər daşların altında və ya kolluqlarda gizlənirlər.\nGürzələr kiçik məməlilərlə, xüsusilə gəmiricilərlə qidalanırlar və təbiətdə faydalı rol oynayırlar.',
    'Gəlincik':
        'Gəlinciklər kiçik, uzun bədənli və çevik məməlilərdir. Onlar çox sürətli hərəkət edirlər və kiçik deşiklərdən belə keçə bilirlər.\nOnların yay və qış üçün fərqli rəngli xəzləri olur – qışda ağ, yayda isə qəhvəyi olurlar. Bu, onlara mövsümə görə gizlənməyə kömək edir.\nGəlinciklər çox cəsur heyvanlardır və özlərindən böyük heyvanlarla belə döyüşə bilirlər!\nOnlar əsasən siçan və digər kiçik gəmiricilərlə qidalanırlar, buna görə də fermerlər üçün çox faydalıdırlar.\nGəlinciklər çox maraqlı və öyrənməyi sevən canlılardır – daim ətrafı kəşf edir və yeni şeylər öyrənirlər.',
    'Hamster':
        'Hamsterlər kiçik, yumşaq xəzli və sevimli gəmiricilərdir. Onların yanaqlarında xüsusi ciblər var və bu ciblərdə qida daşıya bilirlər!\nBəzən bir hamster öz çəkisinə bərabər qidanı yanaq ciblərində daşıya bilir – təsəvvür edin!\nOnlar gecə heyvanlarıdır, yəni əsasən gecələr aktiv olurlar və gündüzlər yatırlar.\nHamsterlər çox təmiz heyvanlardır və vaxtlarının çoxunu özlərini təmizləməklə keçirirlər.\nOnlar yuva qurmağı çox sevirlər və yuvalarını yumşaq materiallarla – samanla, kağızla və hətta pambıqla doldururlar.',
    'Xərçəng':
        'Xərçənglər suda yaşayan, bərk örtüklü canlılardır. Onların bədəni zirehlə örtülüdür və bu zireh böyüdükcə dəyişir.\nXərçənglərin bir cüt qısqacı var və bu qısqaclarla həm qida tutur, həm də özlərini qoruyurlar.\nOnlar yan-yan yeriyirlər və təhlükə zamanı çox sürətlə hərəkət edə bilirlər.\nXərçənglər həm şirin, həm də duzlu suda yaşaya bilirlər və əsasən kiçik balıqlar və bitkilərlə qidalanırlar.\nƏn maraqlısı odur ki, xərçənglər qopan qısqaclarını və ayaqlarını yenidən bərpa edə bilirlər!',
    'İlan':
        'İlanlar ayaqsız sürünənlərdir və bütün dünyada müxtəlif növləri var.\nOnların bədəni elastikdir və çənələri çox geniş açılır – bu, özlərindən böyük şikarları belə uda bilməyə imkan verir.\nİlanların dili çatallıdır və onlar bu dili havadakı qoxuları hiss etmək üçün istifadə edirlər.\nBəzi ilanlar zəhərli olur, bəziləri isə şikarlarını sıxaraq ovlayır. Onlar həzm prosesi çox yavaş olduğu üçün az-az qidalanırlar.\nİlanlar dərilərini vaxtaşırı dəyişirlər – köhnə dəri sıyrılır və altından yeni, parlaq dəri çıxır.',
    'Jaquar':
        'Jaquarlar Cənubi və Mərkəzi Amerikada yaşayan iri pişikkimilərdir. Onlar pələnglərə bənzəyirlər, amma bədənlərindəki xallar fərqlidir.\nJaquarlar çox güclü çənələrə malikdirlər və şikarlarının kəlləsini bir dişləməklə sındıra bilirlər!\nOnlar həm ağaclara dırmaşmaqda, həm də üzməkdə çox mahirdirlər. Su onlar üçün problem deyil və çox vaxt çaylarda balıq ovlayırlar.\nJaquarlar əsasən gecələr ov edirlər və gündüzlər istirahət edirlər. Onlar tək yaşamağı sevirlər.\nBaxmayaraq ki, jaquarlar insanlardan uzaq durmağa çalışırlar, onlar təbiətin ən güclü və məğrur vəhşilərindən biri sayılırlar.',
    'Kəpənək':
        'Kəpənəklər rəngarəng qanadları olan həşəratlardır. Onlar əvvəlcə tırtıl olur, sonra barama qurur və nəhayət kəpənəyə çevrilirlər.\nOnların qanadları üzərindəki naxışlar və rənglər çox gözəldir və hər növdə fərqlidir. Bu rənglər həm cəlbedici görünmək, həm də düşmənlərdən qorunmaq üçündür.\nKəpənəklər nektar içmək üçün uzun və spiral şəklində olan xortumlarını istifadə edirlər.\nOnların ömrü çox qısadır – bəzi növlər cəmi bir neçə gün yaşayır, digərləri isə bir neçə həftə.\nKəpənəklər çiçəklərin tozlanmasına kömək edirlər və təbiətdə çox vacib rol oynayırlar.',
    'Kirpi':
        'Kirpilər bədənləri tikanlı olan kiçik məməlilərdir. Təhlükə hiss etdikdə özlərini top kimi bükərək tikanlı tərəfi çölə çevirirlər.\nOnlar əsasən gecələr aktiv olurlar və gündüzlər yatırlar. Kirpilər həşəratlar, soxulcanlar, meyvələr və göbələklərlə qidalanırlar.\nKirpilərin iy bilmə qabiliyyəti çox güclüdür – onlar yeməyi qaranlıqda belə asanlıqla tapa bilirlər.\nQışda kirpilər qış yuxusuna gedirlər və yazın gəlişi ilə oyanırlar.\nBalaca kirpilər doğulduqda tikanlı olurlar, amma bu tikanlar yumşaq olur və zaman keçdikcə sərtləşir.',
    'Kərtənkələ':
        'Kərtənkələlər sürünənlər sinfinə aid olan heyvanlardır və dünyada minlərlə növü var.\nOnların bəziləri rəng dəyişə bilir, məsələn buqələmun kimi. Bu, onlara həm gizlənməyə, həm də bədən temperaturunu tənzimləməyə kömək edir.\nKərtənkələlərin çoxu təhlükə zamanı quyruqlarını ata bilir – bu, düşməni çaşdırmaq üçün bir müdafiə mexanizmidir. Quyruq sonradan yenidən çıxır!\nOnlar əsasən həşəratlarla qidalanır və isti havalarda daha aktiv olurlar.\nKərtənkələlər günəş vannası almağı çox sevirlər – bu, onların soyuqqanlı olduğu üçün bədən temperaturunu artırmağa kömək edir.',
    'Kəklik':
        'Kəkliklər orta ölçülü quşlardır və əsasən dağlıq və çöl ərazilərdə yaşayırlar.\nOnların lələkləri qəhvəyi və boz rənglərdə olur, bu da onlara təbiətdə yaxşı gizlənməyə kömək edir.\nKəkliklər çox yaxşı qaça bilirlər və təhlükə zamanı uçmaqdan daha çox qaçmağı üstün tuturlar.\nOnlar toxumlar, meyvələr və həşəratlarla qidalanırlar. Kəkliklər yuvalarını yerdə qururlar və çoxlu yumurta qoyurlar.\nKəkliklərin səsi çox xoşdur və onlar səhər tezdən və axşamüstü daha çox səslənirlər.',
    'Qaranquş':
        'Qaranquşlar uzun qanadları və haça quyruqları ilə tanınan kiçik quşlardır.\nOnlar çox sürətli və məharətli uçurlar, hətta havada su içə və ya həşərat tuta bilirlər!\nQaranquşlar palçıqdan yuva qururlar və bu yuvaları binaların kənarlarına, tavanlarına yapışdırırlar.\nOnlar köçəri quşlardır – qışda isti ölkələrə uçur, yazda isə geri qayıdırlar.\nQaranquşlar həşəratlarla qidalanır və bir gündə yüzlərlə milçək, ağcaqanad yeyə bilirlər, buna görə də təbiətdə çox faydalıdırlar.',
    'Qartal':
        'Qartallar ən güclü və iri yırtıcı quşlardandır. Onların iti caynaqları və güclü dimdiyi var.\nQartalların görmə qabiliyyəti insanlardan 4-5 dəfə daha yaxşıdır – onlar yüksəklikdən kiçik bir siçanı belə görə bilirlər!\nOnlar çox hündürdə uça bilirlər və bəzən buludlardan da yuxarıda süzürlər.\nQartallar adətən böyük yuvalar qurur və illər boyu eyni yuvadan istifadə edirlər. Bu yuvalar o qədər böyük olur ki, bəzən ağırlığı bir tona çatır!\nOnlar simvol olaraq güc, azadlıq və cəsarəti təmsil edirlər və bir çox ölkənin gerblərində təsvir olunurlar.',
    'Qaz':
        'Qazlar böyük su quşlarıdır və əsasən sürülərlə yaşayırlar.\nOnların uzun boyunları var və uçarkən V şəklində düzülürlər. Bu forma küləyə qarşı müqaviməti azaldır və enerji qənaət etməyə kömək edir.\nQazlar həm suda, həm quruda, həm də havada yaşaya bilirlər. Onlar yaxşı üzür və sürətli uçurlar.\nOnlar otla, toxumlarla və kiçik su canlıları ilə qidalanırlar. Qazlar çox sayıq olurlar və yemək yeyərkən növbə ilə gözətçilik edirlər.\nQazlar çox vəfalıdırlar və adətən ömürlük cüt qururlar. Onlar balalarını qorumaq üçün çox cəsur olurlar.',
    'Qoyun':
        'Qoyunlar yumşaq yun örtüyü ilə tanınan ev heyvanlarıdır. Onların yunu insanlar tərəfindən paltar hazırlamaq üçün istifadə olunur.\nQoyunlar sürü halında yaşamağı sevir və bir-birindən ayrı düşdükdə narahat olurlar.\nOnlar otla qidalanır və gündə bir neçə saat otlamaqla keçirirlər. Qoyunlar çox sakit heyvanlardır, amma yaxşı yaddaşa malikdirlər.\nBalaca qoyunlara "quzu" deyilir və onlar doğulduqdan bir neçə dəqiqə sonra ayağa qalxa bilirlər.\nQoyunlar insanlar tərəfindən min illərdir ki, saxlanılır və onlardan həm ət, həm süd, həm də yun əldə edilir.',
    'Qurd':
        'Qurdlar vəhşi itlər ailəsinə aid olan yırtıcı heyvanlardır. Onlar sürülər halında yaşayır və birlikdə ov edirlər.\nQurdların eşitmə və iy bilmə qabiliyyəti çox güclüdür – onlar kilometrlərlə uzaqdan səsləri eşidə və qoxuları hiss edə bilirlər.\nOnlar gecə heyvanlarıdır və əsasən qaranlıqda aktiv olurlar. Qurdlar çox sürətli qaça bilirlər və uzun məsafələri yorulmadan qət edə bilirlər.\nQurd sürüsündə ciddi bir iyerarxiya var – alfa erkək və dişi sürünü idarə edir, digərləri isə onlara tabe olur.\nQurdlar ulamaqla bir-biriləri ilə ünsiyyət qururlar və bu səs kilometrlərlə uzağa yayıla bilir.',
    'Lama':
        'Lamalar Cənubi Amerikada yaşayan, dəvəyə bənzəyən, amma ondan kiçik olan heyvanlardır.\nOnların uzun boynu və yumşaq, qalın yunu var. Bu yun müxtəlif rənglərdə ola bilir – ağ, qara, qəhvəyi və hətta ala-bula!\nLamalar çox dözümlü heyvanlardır və ağır yükləri uzun məsafələrə daşıya bilirlər. Onlar hətta dağlıq ərazilərdə belə rahat hərəkət edirlər.\nƏgər lama əsəbiləşsə, o, tüpürə bilər – bu onların özlərini müdafiə etmə üsuludur!\nLamalar çox sosial heyvanlardır və sürülər halında yaşayırlar. Onlar bir-biriləri ilə müxtəlif səslərlə ünsiyyət qururlar.',
    'Leopard':
        'Leopardlar pişikkimilər ailəsinə aid olan yırtıcı heyvanlardır. Onların bədənində qara xallar var və bu xallar hər leopardda fərqli olur – elə bil barmaq izi kimidir!\nLeopardlar çox güclü və çevik heyvanlardır. Onlar ağaclara asanlıqla dırmaşa bilir və şikarlarını ağacın üstünə qaldırmağı sevirlər.\nOnlar tək yaşamağı sevir və əsasən gecələr ov edirlər. Leopardlar çox səssiz hərəkət edir və şikarlarına gizlicə yaxınlaşırlar.\nLeopardlar Afrika və Asiyada yaşayırlar və müxtəlif mühitlərə uyğunlaşa bilirlər – həm meşələrdə, həm dağlarda, həm də savannalarda rast gəlmək olar.\nOnlar çox sürətli qaça bilirlər və bir tullanışla 6 metrə qədər məsafəni keçə bilirlər!',
    'Leylek':
        'Leyleklər uzun ayaqları və dimdiyi olan iri quşlardır. Onlar əsasən bataqlıq və çəmənliklərdə yaşayırlar.\nLeyleklərin qanadları çox genişdir və onlar havada süzməyi sevirlər. Uçarkən boyunlarını və ayaqlarını düz saxlayırlar.\nOnlar qurbağa, ilan, balıq və həşəratlarla qidalanırlar. Leyleklər yuvalarını hündür yerlərdə – ağaclarda, qayalarda və hətta binaların damında qururlar.\nLeyleklər köçəri quşlardır – qışda isti ölkələrə uçur, yazda isə geri qayıdırlar.\nBir çox mədəniyyətdə leyleklər uğur və xoşbəxtlik rəmzi sayılır və deyilir ki, onlar körpələri gətirir!',
    'Mamont':
        'Mamontlar nəhəng, tüklü fillərə bənzər heyvanlardır, amma artıq nəsli kəsilib. Onlar Buz dövrü zamanı yaşayıblar.\nMamontların uzun, əyri buynuzları və bədənlərini örtən qalın, uzun tükləri var idi. Bu tüklər onları soyuqdan qoruyurdu.\nOnlar çox iri heyvanlardır – boyları 4 metrə, çəkiləri isə 6 tona qədər ola bilərdi!\nMamontlar otla qidalanırdılar və sürülər halında yaşayırdılar. Onlar çox sosial heyvanlardır və bir-birilərinə qayğı göstərirdilər.\nBəzi mamontlar buzlaqlarda donmuş vəziyyətdə tapılıb və bu, alimlərə onlar haqqında çox məlumat əldə etməyə imkan verib.',
    'Meymun':
        'Meymunlar çox ağıllı və sosial heyvanlardır. Onların əlləri insanların əllərinə bənzəyir və əşyaları tuta bilirlər.\nMeymunların çoxu ağaclarda yaşayır və budaqdan-budağa tullanaraq hərəkət edirlər. Onların quyruqları balansı saxlamağa və bəzi növlərdə hətta budaqlardan asılmağa kömək edir.\nOnlar meyvə, qoz-fındıq, həşərat və kiçik heyvanlarla qidalanırlar. Meymunlar çox maraqlı və öyrənməyi sevən canlılardır.\nOnlar bir-biriləri ilə müxtəlif səslərlə və bədən dili ilə ünsiyyət qururlar. Hətta bəzi meymun növləri sadə alətlər düzəldə və istifadə edə bilirlər!\nMeymunlar ailə qrupları halında yaşayır və balalarına qayğı göstərirlər. Balaca meymunlar çox oynaq və maraqlı olurlar.',
    'Nərə':
        'Nərə balıqları çox iri və qədim balıq növüdür. Onlar 100 ildən çox yaşaya bilir və 1000 kiloqramdan artıq çəkiyə çata bilirlər!\nNərə balıqlarının bədəni sümük lövhələrlə örtülüdür və bu, onlara qədim görünüş verir. Əslində onlar dinozavrlar dövründən qalan canlılardandır.\nOnlar əsasən çayların dibində yaşayır və kiçik su canlıları ilə qidalanırlar. Nərə balıqları kürü tökmək üçün çayların yuxarı axarlarına üzürlər.\nNərə balıqlarının kürüsü "qara kürü" adlanır və çox dəyərlidir. Təəssüf ki, bu səbəbdən onlar çox ovlanır və sayları azalır.\nOnlar çox güclü balıqlardır və suda çox sürətlə hərəkət edə bilirlər.',
    'Orka':
        'Orkalar (və ya qatil balinalar) dünyanın ən böyük delfinləridir. Onların qara-ağ rəngdə parlaq dəriləri var.\nOrkalar çox ağıllı və sosial heyvanlardır. Onlar ailə qrupları halında yaşayır və bu qruplar nəsildən-nəslə ötürülən öz "mədəniyyətlərinə" malikdir.\nOnlar çox sürətlə üzə bilirlər – saatda 50 kilometrə qədər! Orkalar həm də çox dərinə – 100 metrə qədər dala bilirlər.\nOrkalar yırtıcıdırlar və balıq, suiti, hətta böyük balinalarla qidalanırlar. Onlar çox ağıllı ov strategiyaları qururlar və komanda şəklində hərəkət edirlər.\nBaxmayaraq ki, "qatil balina" adlanırlar, təbiətdə insanlara hücum etmirlər və əsasən çox maraq və dostluq göstərirlər.',
    'Ördək':
        'Ördəklər su quşlarıdır və həm suda, həm quruda, həm də havada yaşaya bilirlər.\nOnların ayaqları pərdəlidir və bu, suda üzməyə kömək edir. Ördəklərin lələkləri su keçirmir və onlar hətta yağışlı havada belə quru qalırlar.\nÖrdəklər "vak-vak" səsi çıxarırlar, amma maraqlısı odur ki, bu səsi əsasən dişi ördəklər çıxarır! Erkək ördəklər daha sakit səslər çıxarır.\nOnlar həm bitkilər, həm də kiçik su canlıları ilə qidalanırlar. Ördəklər suyun dibindən yem çıxarmaq üçün başlarını suya salır və quyruqları yuxarıda qalır.\nÖrdəklər köçəri quşlardır və qışda isti ölkələrə uçurlar. Onlar uçarkən V formasında düzülürlər.',
    'Pələng':
        'Pələnglər ən böyük pişikkimilərdən biridir və çox güclü yırtıcılardır. Onların bədənində qara zolaqlı naxışlar var və bu naxışlar hər pələngdə fərqlidir.\nPələnglər çox güclü və çevik heyvanlardır. Onlar 6 metrə qədər uzunluğa tullana bilir və çox sürətli qaçırlar.\nOnlar tək yaşamağı sevir və əsasən gecələr ov edirlər. Pələnglər çox səssiz hərəkət edir və şikarlarına gizlicə yaxınlaşırlar.\nPələnglər Asiyada yaşayırlar və müxtəlif mühitlərə uyğunlaşa bilirlər – həm meşələrdə, həm bataqlıqlarda, həm də dağlarda rast gəlmək olar.\nTəəssüf ki, pələnglər təhlükə altındadır və sayları azalır. Onları qorumaq üçün xüsusi tədbirlər görülür.',
    'Pinqvin':
        'Pinqvinlər uça bilməyən, amma çox yaxşı üzən quşlardır. Onlar əsasən Cənub yarımkürəsində, xüsusilə Antarktidada yaşayırlar.\nPinqvinlərin bədəni qara-ağ rəngdədir – arxası qara, qarını isə ağdır. Bu rəng onları suda gizlənməyə kömək edir.\nOnlar qanadlarını üzgəc kimi istifadə edirlər və suda çox sürətli və məharətli üzürlər. Pinqvinlər balıqla qidalanır və suya şığıyaraq ov edirlər.\nPinqvinlər çox sosial quşlardır və böyük koloniyalarda yaşayırlar. Soyuq havada bir-birinə sıxılaraq istilik saxlayırlar.\nƏn maraqlısı odur ki, pinqvin ataları yumurtaları ayaqlarının üstündə saxlayır və qoruyurlar – hətta iki ay ac qala bilirlər!',
    'Rakun':
        'Rakunlar kiçik, məməli heyvanlardır və gözlərinin ətrafında qara maskaya bənzər naxışları var.\nOnların əlləri çox bacarıqlıdır və əşyaları tuta, açıb-bağlaya bilirlər. Rakunlar yeməklərini yemədən əvvəl adətən suda yuyurlar – sanki təmizləyirlər!\nOnlar gecə heyvanlarıdır və əsasən qaranlıq düşəndən sonra aktiv olurlar. Rakunlar həm ağaclara dırmaşa bilir, həm də yaxşı üzürlər.\nOnlar hər şey yeyən heyvanlardır – meyvə, qoz-fındıq, həşərat, kiçik heyvanlar və hətta zibil qutularında qida tapa bilirlər!\nRakunlar çox ağıllı və maraqlı heyvanlardır, amma vəhşi təbiətdə yaşamalıdırlar, ev heyvanı kimi saxlanmaları düzgün deyil.',
    'Siçan':
        'Siçanlar kiçik, gəmirici məməlilərdir və demək olar ki, dünyanın hər yerində yaşayırlar.\nOnların uzun quyruqları və iti dişləri var. Siçanlar çox sürətli hərəkət edir və kiçik deşiklərdən keçə bilirlər.\nOnlar gecə heyvanlarıdır və əsasən qaranlıqda aktiv olurlar. Siçanlar çox yaxşı iybilmə qabiliyyətinə malikdirlər.\nOnlar hər şey yeyə bilirlər və hətta bəzi plastik və taxta materialları belə gəmirə bilirlər! Siçanlar çox sürətlə çoxalırlar.\nBaxmayaraq ki, çox vaxt zərərli hesab olunurlar, siçanlar çox ağıllı heyvanlardır və hətta laboratoriyalarda müxtəlif testlər üçün istifadə olunurlar.',
    'Sincab':
        'Sincablar kiçik, çevik məməlilərdir və əsasən ağaclarda yaşayırlar.\nOnların uzun, tüklü quyruqları var və bu quyruq həm balans saxlamağa, həm də qışda isti qalmağa kömək edir.\nSincablar qoz-fındıq, toxum və meyvələrlə qidalanırlar. Onlar qış üçün qida ehtiyatı toplayır və torpaqda gizlədirlər.\nƏn maraqlısı odur ki, sincablar min-minlərlə qoz-fındıq gizlədir və sonra iy bilmə qabiliyyətləri ilə onları tapırlar! Amma bəzən unutduqları qozlar cücərib ağac olur.\nSincablar çox cəld və çevikdirlər – ağacdan-ağaca asanlıqla tullana bilirlər və hətta budaqlar arasında baş aşağı qaça bilirlər.',
    'Sərçə':
        'Sərçələr kiçik, qəhvəyi-boz rəngli quşlardır və şəhərlərdə, kəndlərdə geniş yayılıblar.\nOnlar çox sosial quşlardır və adətən dəstələrlə yaşayırlar. Sərçələr cikkildəyərək bir-biri ilə ünsiyyət qururlar.\nOnlar toxum, həşərat və çörək qırıntıları ilə qidalanırlar. Sərçələr insanların yaşadığı yerlərə uyğunlaşıblar və binaların çatlarında, damlarında yuva qururlar.\nSərçələr çimmək üçün torpaqda kiçik çuxurlar tapır və orada "toz vannası" qəbul edirlər – bu, onların lələklərini təmizləməyə kömək edir.\nOnlar çox cəsarətli quşlardır və insanların yaxınlığında belə rahat yaşaya bilirlər.',
    'Şahin':
        'Şahinlər yırtıcı quşlardır və çox iti görmə qabiliyyətinə malikdirlər.\nOnlar havada süzərkən kiçik heyvanları görə bilir və sürətlə şığıyaraq ovlayırlar. Şahinlər saatda 320 kilometrə qədər sürətlə şığıya bilirlər!\nOnların caynaqları və dimdiyi çox güclüdür və şikarlarını tutmaq üçün istifadə olunur. Şahinlər əsasən kiçik quşlar və gəmiricilərlə qidalanırlar.\nŞahinlər yuvalarını hündür qayalarda və ya ağaclarda qururlar. Onlar çox qısqanc ərazi sahibləridir və yuvalarını qoruyurlar.\nTarixən şahinlər ov üçün təlim keçirilirdi və bu, "şahinçilik" adlanan bir sənət idi.',
    'Şir':
        'Şirlər "heyvanlar aləminin kralı" adlanır və çox güclü, məğrur yırtıcılardır.\nErkək şirlərin böyük yalı olur və bu, onları digər pişikkimilərdən fərqləndirir. Bu yal həm qorxulu görünüş verir, həm də döyüşlərdə boyunu qoruyur.\nŞirlər sürülər halında yaşayırlar və bu sürüyə "pride" deyilir. Maraqlısı odur ki, əsasən dişi şirlər ov edir, erkəklər isə ərazini qoruyur!\nOnlar çox güclü səslə nərildəyə bilirlər və bu səs 8 kilometrə qədər məsafədən eşidilir.\nŞirlər əsasən gecə və səhər tezdən ov edirlər. Gündüz vaxtlarını isə kölgədə dincəlməklə keçirirlər.',
    'Tısbağa':
        'Tısbağalar bərk çanaqla örtülmüş sürünənlərdir və çox uzun ömürlüdürlər – bəziləri 100 ildən çox yaşaya bilir!\nOnların çanağı həm ev, həm də qalxan rolunu oynayır. Təhlükə zamanı tısbağa başını və ayaqlarını çanağın içinə çəkir.\nTısbağalar çox yavaş hərəkət edirlər, amma dözümlüdürlər və uzun məsafələri qət edə bilirlər. Onlar həm quruda, həm də suda yaşaya bilirlər.\nOnlar əsasən bitkilərlə qidalanır, amma bəzi növləri həşərat və kiçik su canlıları da yeyir.\nTısbağalar yumurta qoyur və bu yumurtaları qumda gizlədirlər. Maraqlısı odur ki, yumurtanın temperaturu balaca tısbağanın cinsini təyin edir!',
    'Tülkü':
        'Tülkülər it ailəsinə aid olan, amma pişik kimi davranışları olan heyvanlardır.\nOnların sivri burnu, üçbucaq qulaqları və qalın, tüklü quyruğu var. Tülkülər çox gözəl və parlaq xəzə malikdirlər.\nOnlar çox ağıllı və hiyləgər heyvanlardır. Tülkülər siçan, dovşan, quş və həşəratlarla qidalanırlar, amma meyvə və giləmeyvələri də sevirlər.\nTülkülər yeraltı yuvalarda yaşayırlar və bu yuvalara "tülkü yuvası" deyilir. Onlar gecə heyvanlarıdır və əsasən qaranlıqda ov edirlər.\nTülkülər çox çevik və sürətlidirlər – bir tullanışla 2 metrə qədər hündürlüyə sıçraya bilirlər!',
    'Ulaq':
        'Ulaqlar eşşəyə bənzəyən, amma vəhşi təbiətdə yaşayan heyvanlardır.\nOnların uzun qulaqları və qısa, dikduran yalı var. Ulaqlar çox dözümlüdürlər və çətin şəraitdə yaşaya bilirlər.\nOnlar otla qidalanır və az su ilə kifayətlənə bilirlər. Bu xüsusiyyət onları səhra kimi yerlərdə yaşamağa imkan verir.\nUlaqlar çox sürətli qaça bilirlər və dağlıq ərazilərdə belə çevik hərəkət edirlər.\nOnların səsi çox güclüdür və uzaq məsafələrdən eşidilə bilir. Bu səs onlara bir-birini tapmağa və təhlükə barədə xəbərdarlıq etməyə kömək edir.',
    'Vaşaq':
        'Vaşaqlar orta ölçülü pişikkimilərdir və əsasən meşəlik ərazilərdə yaşayırlar.\nOnların qulaqlarının ucunda qara tüklü püskülləri var və bu, onların eşitmə qabiliyyətini gücləndirir.\nVaşaqların pəncələri çox böyükdür və bu, onlara qarda rahat hərəkət etməyə imkan verir – sanki təbii qar ayaqqabıları kimi!\nOnlar əsasən dovşan və digər kiçik məməlilərlə qidalanırlar. Vaşaqlar çox yaxşı ov edə bilirlər və şikarlarını 6 metrə qədər məsafədən tuta bilirlər.\nVaşaqlar çox gizli həyat tərzi keçirirlər və insanlardan uzaq durmağa çalışırlar. Onları təbiətdə görmək çox nadir hadisədir.',
    'Yarasa':
        'Yarasalar uça bilən yeganə məməlilərdir! Onların qanadları əslində dəri ilə örtülmüş uzun barmaqlardır.\nOnların çoxu gecə aktiv olur və ultrasəs vasitəsilə ətrafı "görürlər" – bu, exolokasiya adlanır. Yarasalar səs dalğaları göndərir və onların əks-sədasını eşidərək qaranlıqda belə mükəmməl naviqasiya edirlər.\nOnların əksəriyyəti həşəratlarla qidalanır və bir yarasa gecədə minlərlə ağcaqanad yeyə bilir! Bəzi növləri isə meyvə, nektar və hətta qanla qidalanır.\nYarasalar başı aşağı asılı vəziyyətdə yatırlar və bu, onların qan dövranına uyğunlaşmış bədən quruluşuna görə mümkündür.\nOnlar çox faydalı heyvanlardır, çünki həm həşəratları məhv edir, həm də bitkilərin tozlanmasına kömək edirlər.',
    'Zürafə':
        'Zürafələr dünyanın ən hündür heyvanlarıdır – boyları 5-6 metrə çatır!\nOnların çox uzun boyunları var, amma maraqlısı odur ki, zürafələrin boyunlarında da digər məməlilər kimi cəmi 7 fəqərə var – sadəcə bu fəqərələr çox uzundur.\nZürafələrin bədənində qəhvəyi naxışlar var və bu naxışlar hər zürafədə fərqlidir – elə bil barmaq izi kimidir!\nOnlar əsasən ağacların yüksək budaqlarındakı yarpaqlarla qidalanırlar və buna görə uzun boyunları çox faydalıdır.\nZürafələr çox az yatırlar – gündə cəmi 2 saat! Və onlar yatarkən belə ayaq üstə qalırlar.',
    'Zebra':
        'Zebralar at ailəsinə aid olan, qara-ağ zolaqlı heyvanlardır.\nHər zebranın zolaqlı naxışı unikaldır – elə bil barmaq izi kimidir! Bu naxışlar onlara həm gizlənməyə, həm də milçəklərdən qorunmağa kömək edir.\nZebralar sürülər halında yaşayır və bir-birinə kömək edirlər. Onlar təhlükə zamanı qaçır və ziqzaqlarla hərəkət edərək yırtıcıları çaşdırırlar.\nOnlar otla qidalanır və gündə 16-18 saat otlamaqla keçirirlər. Zebralar çox yaxşı görmə və eşitmə qabiliyyətinə malikdirlər.\nBalaca zebralara "zebra dayça" deyilir və onlar doğulduqdan bir neçə dəqiqə sonra ayağa qalxa və qaça bilirlər!',
  };

  static const Map<String, List<String>> animalFoods = {
    'At': ['Ot', 'Yulaf', 'Saman'],
    'Ayı': ['Bal', 'Balıq', 'Giləmeyvə'],
    'Ağcaqanad': ['Qan', 'Nektar'],
    'Alpaka': ['Ot', 'Yarpaqlar'],
    'Balıq': ['Plankton', 'Kiçik balıqlar'],
    'Bayquş': ['Siçan', 'Kiçik quşlar', 'Böcəklər'],
    'Buqələmun': ['Böcəklər', 'Həşəratlar'],
    'Bizon': ['Ot', 'Bitkilər'],
    'Begemot': ['Ot', 'Su bitkiləri'],
    'Baltadimdik': ['Balıq', 'Qurbağa', 'Kiçik timsahlar'],
    'Camış': ['Ot', 'Su bitkiləri'],
    'Cücə': ['Dən', 'Toxum', 'Böcəklər'],
    'Ceyran': ['Ot', 'Yarpaqlar', 'Bitkilər'],
    'Çalağan': ['Kiçik gəmiricilər', 'Quşlar', 'Sürünənlər'],
    'Çita': ['Ceyran', 'Antilop', 'Kiçik məməlilər'],
    'Dənizatı': ['Kiçik dəniz canlıları', 'Plankton'],
    'Donuz': ['Meyvə', 'Tərəvəz', 'Köklər', 'Qoz-fındıq'],
    'Dovşan': ['Ot', 'Kök', 'Yerkökü', 'Yarpaqlar'],
    'Eşşək': ['Ot', 'Saman', 'Yarpaqlar'],
    'Eland': ['Ot', 'Yarpaqlar', 'Bitkilər'],
    'Echidna': ['Qarışqa', 'Termit', 'Böcəklər'],
    'Ərincək': ['Yarpaqlar', 'Meyvələr'],
    'Əqrəb': ['Həşəratlar', 'Kiçik heyvanlar'],
    'Folivora': ['Yarpaqlar', 'Meyvələr', 'Budaqlar'],
    'Fil': ['Ot', 'Yarpaqlar', 'Meyvələr', 'Budaqlar'],
    'Flamingo': ['Xərçəngkimilər', 'Yosunlar', 'Kiçik su canlıları'],
    'Gürzə': ['Kiçik məməlilər', 'Gəmiricilər'],
    'Gəlincik': ['Siçan', 'Kiçik gəmiricilər'],
    'Hamster': ['Toxum', 'Dən', 'Meyvə', 'Tərəvəz'],
    'Xərçəng': ['Kiçik balıqlar', 'Bitkilər', 'Su canlıları'],
    'İlan': ['Kiçik məməlilər', 'Quşlar', 'Kərtənkələlər', 'Yumurtalar'],
    'Jaquar': ['Balıq', 'Məməlilər', 'Sürünənlər'],
    'Kəpənək': ['Nektar', 'Meyvə şirəsi'],
    'Kirpi': ['Həşəratlar', 'Soxulcanlar', 'Meyvələr', 'Göbələklər'],
    'Kərtənkələ': ['Həşəratlar', 'Kiçik böcəklər'],
    'Kəklik': ['Toxum', 'Meyvə', 'Həşəratlar'],
    'Qaranquş': ['Həşəratlar', 'Milçəklər', 'Ağcaqanadlar'],
    'Qartal': ['Kiçik məməlilər', 'Balıqlar', 'Quşlar'],
    'Qaz': ['Ot', 'Toxum', 'Kiçik su canlıları'],
    'Qoyun': ['Ot', 'Yarpaqlar', 'Bitkilər'],
    'Qurd': ['Ceyran', 'Dovşan', 'Kiçik məməlilər'],
    'Lama': ['Ot', 'Yarpaqlar', 'Bitkilər'],
    'Leopard': ['Antilop', 'Ceyran', 'Meymun', 'Kiçik məməlilər'],
    'Leylek': ['Qurbağa', 'İlan', 'Balıq', 'Həşəratlar'],
    'Mamont': ['Ot', 'Bitkilər', 'Budaqlar'],
    'Meymun': ['Meyvə', 'Qoz-fındıq', 'Həşəratlar', 'Kiçik heyvanlar'],
    'Nərə': ['Kiçik su canlıları', 'Balıqlar'],
    'Orka': ['Balıq', 'Suiti', 'Balina'],
    'Ördək': ['Bitkilər', 'Toxumlar', 'Kiçik su canlıları'],
    'Pələng': ['Maral', 'Ceyran', 'Donuz', 'Kiçik məməlilər'],
    'Pinqvin': ['Balıq', 'Kalamar', 'Xərçəngkimilər'],
    'Rakun': ['Meyvə', 'Qoz-fındıq', 'Həşəratlar', 'Kiçik heyvanlar'],
    'Siçan': ['Dən', 'Toxum', 'Meyvə', 'Tərəvəz', 'Həşəratlar'],
    'Sincab': ['Qoz-fındıq', 'Toxum', 'Meyvələr', 'Göbələklər'],
    'Sərçə': ['Toxum', 'Həşəratlar', 'Çörək qırıntıları'],
    'Şahin': ['Kiçik quşlar', 'Gəmiricilər', 'Həşəratlar'],
    'Şir': ['Antilop', 'Zebra', 'Donuz', 'Maral'],
    'Tısbağa': ['Bitkilər', 'Yosunlar', 'Həşəratlar', 'Kiçik su canlıları'],
    'Tülkü': ['Siçan', 'Dovşan', 'Quş', 'Həşəratlar', 'Meyvə', 'Giləmeyvə'],
    'Ulaq': ['Ot', 'Bitkilər', 'Yarpaqlar'],
    'Vaşaq': ['Dovşan', 'Kiçik məməlilər', 'Quşlar'],
    'Yarasa': ['Həşəratlar', 'Meyvə', 'Nektar', 'Qan'],
    'Zürafə': ['Yarpaqlar', 'Budaqlar', 'Meyvələr'],
    'Zebra': ['Ot', 'Bitkilər', 'Yarpaqlar'],
  };

  static const Map<String, bool> animalHasSound = {
    'At': false,
    'Ayı': true,
    'Ağcaqanad': false,
    'Alpaka': false,
    'Balıq': false,
    'Bayquş': false,
    'Buqələmun': false,
    'Bizon': false,
    'Begemot': false,
    'Baltadimdik': false,
    'Camış': false,
    'Cücə': false,
    'Ceyran': false,
    'Çalağan': false,
    'Çita': false,
    'Dənizatı': false,
    'Donuz': false,
    'Dovşan': false,
    'Eşşək': false,
    'Eland': false,
    'Echidna': false,
    'Ərincək': false,
    'Əqrəb': false,
    'Folivora': false,
    'Fil': false,
    'Flamingo': false,
    'Gürzə': false,
    'Gəlincik': false,
    'Hamster': false,
    'Xərçəng': false,
    'İlan': false,
    'Jaquar': false,
    'Kəpənək': false,
    'Kirpi': false,
    'Kərtənkələ': false,
    'Kəklik': false,
    'Qaranquş': false,
    'Qartal': false,
    'Qaz': false,
    'Qoyun': false,
    'Qurd': false,
    'Lama': false,
    'Leopard': false,
    'Leylek': false,
    'Mamont': false,
    'Meymun': false,
    'Nərə': false,
    'Orka': false,
    'Ördək': false,
    'Pələng': false,
    'Pinqvin': false,
    'Rakun': false,
    'Siçan': false,
    'Sincab': false,
    'Sərçə': false,
    'Şahin': false,
    'Şir': false,
    'Tısbağa': false,
    'Tülkü': false,
    'Ulaq': false,
    'Vaşaq': false,
    'Yarasa': false,
    'Zürafə': false,
    'Zebra': false,
  };

  static const Map<String, bool> animalHasPuzzle = {
    'At': true,
    'Ayı': false,
    'Ağcaqanad': false,
    'Alpaka': false,
    'Balıq': false,
    'Bayquş': false,
    'Buqələmun': false,
    'Bizon': false,
    'Begemot': false,
    'Baltadimdik': false,
    'Camış': false,
    'Cücə': false,
    'Ceyran': false,
    'Çalağan': false,
    'Çita': false,
    'Dənizatı': false,
    'Donuz': false,
    'Dovşan': false,
    'Eşşək': false,
    'Eland': false,
    'Echidna': false,
    'Ərincək': false,
    'Əqrəb': false,
    'Folivora': false,
    'Fil': false,
    'Flamingo': false,
    'Gürzə': false,
    'Gəlincik': false,
    'Hamster': false,
    'Xərçəng': false,
    'İlan': false,
    'Jaquar': false,
    'Kəpənək': false,
    'Kirpi': false,
    'Kərtənkələ': false,
    'Kəklik': false,
    'Qaranquş': false,
    'Qartal': false,
    'Qaz': false,
    'Qoyun': false,
    'Qurd': false,
    'Lama': false,
    'Leopard': false,
    'Leylek': false,
    'Mamont': false,
    'Meymun': false,
    'Nərə': false,
    'Orka': false,
    'Ördək': false,
    'Pələng': false,
    'Pinqvin': false,
    'Rakun': false,
    'Siçan': false,
    'Sincab': false,
    'Sərçə': false,
    'Şahin': false,
    'Şir': false,
    'Tısbağa': false,
    'Tülkü': false,
    'Ulaq': false,
    'Vaşaq': false,
    'Yarasa': false,
    'Zürafə': false,
    'Zebra': false,
  };

  static const Map<String, String> animalYoutubeEmbeds = {
    'At': 'https://www.youtube.com/embed/24FqPV30Af4',
    'Ayı': '',
    'Ağcaqanad': '',
    'Alpaka': '',
    'Balıq': '',
    'Bayquş': 'https://www.youtube.com/embed/d_FEaFgJyfA',
    'Buqələmun': '',
    'Bizon': '',
    'Begemot': '',
    'Baltadimdik': '',
    'Camış': '',
    'Cücə': 'https://www.youtube.com/embed/F38tIGO5TFY',
    'Ceyran': '',
    'Çalağan': '',
    'Çita': 'https://www.youtube.com/embed/V8vejjVgIHg',
    'Dənizatı': 'https://www.youtube.com/embed/UqYUTTqupOY',
    'Donuz': '',
    'Dovşan': 'https://www.youtube.com/embed/fDMP3X9ICfY',
    'Eşşək': '',
    'Eland': '',
    'Echidna': '',
    'Ərincək': '',
    'Əqrəb': '',
    'Folivora': '',
    'Fil': 'https://www.youtube.com/embed/qoXJdQfV1_8',
    'Flamingo': '',
    'Gürzə': '',
    'Gəlincik': '',
    'Hamster': '',
    'Xərçəng': '',
    'İlan': 'https://www.youtube.com/embed/zEto1-ZTbd4',
    'Jaquar': '',
    'Kəpənək': 'https://www.youtube.com/embed/1b87rwtXGzA',
    'Kirpi': 'https://www.youtube.com/embed/F6zPXQx1LPo',
    'Kərtənkələ': '',
    'Kəklik': '',
    'Qaranquş': '',
    'Qartal': 'https://www.youtube.com/embed/6Vfw_PuL9GQ',
    'Qaz': '',
    'Qoyun': '',
    'Qurd': 'https://www.youtube.com/embed/YXMo5w9aMNs',
    'Lama': '',
    'Leopard': '',
    'Leylek': '',
    'Mamont': '',
    'Meymun': 'https://www.youtube.com/embed/VUhU2vJdCbM',
    'Nərə': '',
    'Orka': '',
    'Ördək': 'https://www.youtube.com/embed/0CVe7svYJb0',
    'Pələng': 'https://www.youtube.com/embed/FK3dav4bA4s',
    'Pinqvin': 'https://www.youtube.com/embed/O8qilxaBR20',
    'Rakun': '',
    'Siçan': '',
    'Sincab': 'https://www.youtube.com/embed/FgCaGTOJNXI',
    'Sərçə': '',
    'Şahin': '',
    'Şir': 'https://www.youtube.com/embed/l-VaulQEz2Y',
    'Tısbağa': 'https://www.youtube.com/embed/jSZgkFtF-Ks',
    'Tülkü': 'https://www.youtube.com/embed/c8xJtH6UcQY',
    'Ulaq': '',
    'Vaşaq': '',
    'Yarasa': '',
    'Zürafə': 'https://www.youtube.com/embed/qlMb4R6mj0Y',
    'Zebra': '',
  };

  static final Map<String, LetterConfig> letterConfigs = {};

  static LetterConfig? findLetter(String letter) {
    final letterKey = letter.toUpperCase();
    // Hər dəfə map-lardan yeni obyekt yaradılır
    final letterLower = letter.toLowerCase();
    final imagePath = 'assets/images/${letterLower}/${letterLower}.png';
    final audioPath = 'assets/audios/${letterLower}/${letterLower}.mp3';
    final description = letterDescriptions[letterKey] ?? '';
    final animalNames = animalsByLetter[letterKey] ?? [];
    final animals = <AnimalInfo>[];
    for (final animalName in animalNames) {
      final animalLetter = letterKey;
      final normalizedName = normalizeFileName(animalName);
      final animalImagePath =
          'assets/images/${animalLetter.toLowerCase()}/${normalizedName}.png';
      final animalAudioPath =
          'assets/audios/${animalLetter.toLowerCase()}/${normalizedName}_info_sound.mp3';
      animals.add(
        AnimalInfo(
          name: animalName,
          description: animalInfo[animalName] ?? '',
          imagePath: animalImagePath,
          audioPath: animalAudioPath,
          foods: animalFoods[animalName] ?? [],
          hasSound: animalHasSound[animalName] ?? false,
          hasPuzzle: animalHasPuzzle[animalName] ?? false,
          youtubeEmbed: animalYoutubeEmbeds[animalName],
        ),
      );
    }
    return LetterConfig(
      letter: letterKey,
      imagePath: imagePath,
      audioPath: audioPath,
      description: description,
      animals: animals,
    );
  }

  static AnimalInfo? findAnimal(String letter, String animalName) {
    final letterConfig = findLetter(letter);
    if (letterConfig == null) return null;

    // Əgər heyvan artıq mövcuddursa, onu qaytaraq
    for (var animal in letterConfig.animals) {
      if (animal.name.toLowerCase() == animalName.toLowerCase()) {
        return animal;
      }
    }

    // Əgər heyvan hələ konfiqurasiyada yoxdursa, yaradaq
    final animalLetter = letter.toLowerCase();
    final normalizedName = normalizeFileName(animalName);
    final imagePath = 'assets/images/${animalLetter}/${normalizedName}.png';
    final audioPath =
        'assets/audios/${animalLetter}/${normalizedName}_info_sound.mp3';

    final newAnimalInfo = AnimalInfo(
      name: animalName,
      description: animalInfo[animalName] ?? '',
      imagePath: imagePath,
      audioPath: audioPath,
      foods: animalFoods[animalName] ?? [],
      hasSound: animalHasSound[animalName] ?? false,
      hasPuzzle: animalHasPuzzle[animalName] ?? false,
      youtubeEmbed: animalYoutubeEmbeds[animalName],
    );

    // Yeni yaradılmış heyvanı əlavə edək
    letterConfig.animals.add(newAnimalInfo);
    return newAnimalInfo;
  }

  static String normalizeFileName(String text) {
    final normalized = text
        .toLowerCase()
        .replaceAll('ə', 'e')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ç', 'c')
        .replaceAll(' ', '_');
    return normalized;
  }
}
