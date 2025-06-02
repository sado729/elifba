import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import '../core/utils.dart';
import 'puzzle_page.dart';
import 'package:flutter/services.dart';
import 'animal_word_puzzle.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'dart:ui' as ui;
import '../widgets/youtube_video_widget.dart';
import 'basket_game_widget.dart';

class AnimalDetailPage extends StatefulWidget {
  final String animal;
  final List<String>? animals;
  final int? currentIndex;
  const AnimalDetailPage({
    super.key,
    required this.animal,
    this.animals,
    this.currentIndex,
  });

  @override
  State<AnimalDetailPage> createState() => _AnimalDetailPageState();
}

class _AnimalDetailPageState extends State<AnimalDetailPage> {
  final FlutterTts flutterTts = FlutterTts();
  final AudioPlayer audioPlayer = AudioPlayer();
  bool showInfo = true;
  bool showFoods = false;
  bool showPuzzle = false;
  bool showWordPuzzle = false;
  bool showYoutube = false;
  late ConfettiController _confettiController;

  // --- ANİMASİYA üçün əlavə ---
  final GlobalKey _animalImageKey = GlobalKey();
  final Map<int, GlobalKey> _foodButtonKeys = {};

  bool isPlayingInfo =
      false; // Səsin səsləndirilib-səsləndirilmədiyini saxlayır

  static const Map<String, String> animalInfo = {
    'At':
        'Atlar çox sürətli və zəkalı heyvanlardır. Onlar min illərdir ki, insanlara kömək edirlər – həm yük daşıyıblar, həm də insanları bir yerdən başqa yerə aparıblar.\nAtlar çox yaxşı yaddaşa malikdir və sahibini illərlə unutmaya bilirlər. Onlar həm də bir-birini tanıya və dostluq edə bilirlər.\nAtların qulaqları daim hərəkət edir – onlar bununla həm səsləri eşidirlər, həm də əhval-ruhiyyələrini göstərirlər.\nAtlar ot yeyirlər və çox vaxt ayaq üstə yatırlar. Bəli, atlar uzanmadan da dincələ bilirlər!\nBalaca ata tay deyilir və o çox oynaq və sevimli olur. Taylar doğulduqdan bir neçə dəqiqə sonra ayağa qalxa bilirlər!',
    'Ayı':
        'Ayılar çox güclü və ağıllı heyvanlardır. Onların burnu çox iti olur, hətta kilometrlərlə uzaqdan yeməyin qoxusunu ala bilirlər! Ayılar çox vaxt tək yaşayır və meşələrdə, dağlarda və bəzən buzlu yerlərdə görülür.\nƏn məşhur ayı növlərindən biri qütb ayısıdır – o, tamamilə ağ rəngdə olur və buzlu dənizlərdə yaşayır.Amma qəhvəyi ayılar və qara ayılar da var. Onlar əsasən meşələrdə olur və bal, meyvə, balıq və hətta kiçik heyvanlarla qidalanırlar.\nAyılar qışda uzun bir yuxuya gedirlər. Bu yuxuya qış yuxusu deyilir. Onlar bir neçə ay heç oyanmadan yatırlar!\nAyılar çox sevimli görünür, amma əslində çox güclüdürlər. Körpə ayılar – yəni ayı balaları – çox şirin və oynaq olurlar, anaları onları qorumağa çox diqqət edir.',
    'Ağcaqanad':
        'Ağcaqanadlar çox kiçik, amma maraqlı canlılardır. Onlar uçarkən vızıltı kimi bir səs çıxarırlar – bu səs qanadlarını çox sürətli çaldıqları üçün yaranır.\nAğcaqanadlar əsasən axşam və gecə saatlarında aktiv olurlar və isti havanı sevirlər.\nOnların bəziləri insanların qanını sorur, amma bunu yalnız dişi ağcaqanadlar edir! Çünki onlar yumurta qoymaq üçün xüsusi qidalara ehtiyac duyurlar.\nAğcaqanadların qoxuya qarşı çox həssas burunları var. Onlar insanın tər qoxusunu hiss edib yaxınlaşırlar.',
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
        'Baltadimdik çox qəribə və maraqlı quşdur! Onun dimdiyi iri və baltaya bənzəyir, buna görə də adı baltadimdik qoyulub.\nBu quş əsasən Afrikanın bataqlıqlarında yaşayır və orada qurbağa, balıq və hətta kiçik timsahları ovlayır!\nBaltadimdik çox sakit və tərpənmədən durmağı sevir. Bəzən saatlarla tərpənmir ki, ov yaxına gəlsin.\nOnların boyu uşaqlardan da hündür ola bilər – bəziləri 1 metr 20 santimetrə qədər uzana bilir!\nƏn maraqlısı isə budur ki, baltadimdik salam verirmiş kimi başını aşağı-yuxarı tərpədir və qəribə səslər çıxarır!',
    'Camış':
        'Camışlar iri və güclü heyvanlardır. Onlar çox vaxt suyun içində olmağı sevirlər, çünki sərinləmək üçün bu onlara kömək edir.\nOnların dərisi qalın, buynuzları isə uzun və qıvrım olur. Buynuzları həm müdafiə, həm də digər camışlarla əlaqə qurmaq üçün istifadə olunur.\nCamışlar çox çalışqan heyvanlardır. Onlar kənd təsərrüfatında insanlara kömək edir, ağır işlər görür və torpaq şumlayırlar.\nSuyu və palçığı sevmələri sayəsində onlar bataqlıq və rütubətli yerlərdə çox rahat yaşayırlar.\nCamış südü çox qidalıdır və ondan dadlı pendir və qatıq hazırlanır!',
    'Cücə':
        'Cücələr toyuqların balalarıdır və çox şirin, tüklü olurlar.\nOnlar yumurtadan çıxanda sarı rəngdə və balaca olurlar.\nCücələr ilk günlərdə anasının altında gizlənməyi və isti qalmağı sevirlər.\nOnlar qısa zamanda böyüyür və özləri yem axtarmağa başlayırlar.\nCücələr "cik-cik" səsi ilə danışırlar və bir yerdə gəzməyi çox sevirlər.',
    'Ceyran':
        'Ceyranlar çox zərif, çevik və sürətli heyvanlardır. Onlar adətən açıq çöllərdə və dağətəyi yerlərdə yaşayırlar.\nCeyranın böyük gözləri və uzun qulaqları ona ətrafı yaxşı görməyə və eşitməyə kömək edir.\nƏn maraqlısı isə odur ki, ceyranlar çox sürətli qaça bilirlər – bəziləri saatda 80 kilometrə qədər sürətə çatır!\nOnlar adətən sürü halında yaşayır və təhlükə hiss etdikdə hamısı birlikdə qaçmağa başlayır.\nCeyranlar həm də Azərbaycan təbiətinin gözəl simvollarından biridir və qoruma altındadırlar.',
    'Çalağan':
        'Çalağan — yırtıcı bir quşdur və göydə çox yüksəkdən uça bilir.\nOnun iti gözləri o qədər güclüdür ki, yerdəki kiçik heyvanları uzaqdan görə bilir.\nÇalağan əsasən siçan, ilan və kiçik quşlarla qidalanır.\nOnun iti caynaqları və güclü dimdiyi ovunu tutmağa kömək edir.\nÇalağanlar öz yuvalarını dağlarda və hündür ağacların başında qururlar.',
    'Çita':
        'Çita dünyanın ən sürətli heyvanıdır! O, cəmi bir neçə saniyədə saatda 100 kilometr sürətə çata bilər.\nÇitaların bədəni incə, ayaqları uzun və əzələli olur – bu da onlara sürətli qaçmaqda kömək edir.\nOnların üzündəki qara zolaqlar sanki göz yaşına bənzəyir və günəşin işığından gözlərini qoruyur.\nÇitalar adətən tək yaşayır və gündüz ovlanmağı sevirlər, çünki çox yaxşı görürlər.\nOnlar sürətlə qaçsalar da, bu gücü uzun müddət davam etdirə bilmirlər və tez yorulurlar.',
    'Dənizatı':
        'Dənizatları kiçik, qəribə görünüşlü dəniz heyvanlarıdır. Onların bədəni at şəkilinə bənzəyir, buna görə də adları belədir.\nDənizatları suyun içində çox yavaş hərəkət edir, amma onları görmək çox maraqlıdır.\nOnlar kiçik quyruqları ilə suyun dibində oturur və su bitkilərinə yapışırlar.\nDənisatları çox nadir hallarda sürətlə üzürlər, çünki onlar təhlükədən qaçmaq üçün bədənlərini kiçik borular kimi suda gizlədirlər.\nQadın dənisatları öz bala balıqlarını kişilərin qarnında daşıyır – bu çox xüsusi bir xüsusiyyətdir!',
    'Donuz':
        'Donuzlar çox ağıllı və təmiz heyvanlardır. Onlar özlərini və yerlərini çox yaxşı təmizləyirlər.\nDonuzların burunları çox həssasdır və torpaqda yemək axtarmaq üçün istifadə olunur.\nDonuzlar çox yemək sevir, amma onların sevimli yeməkləri göbələklər və meyvələrdir.\nDonuzlar çox sosial heyvanlardır və sürü şəklində yaşayırlar. Onlar bir-birləri ilə səsli və jestlərlə danışırlar.\nBir maraqlı fakt: donuzlar suda üzə bilirlər, baxmayaraq ki, çox vaxt torpaqda qalmağı üstün tuturlar.',
    'Eşşək':
        'Eşşəklər çox çalışqan və dözümlü heyvanlardır. Onlar çox ağır yükləri daşıya bilirlər.\nEşşəklərin qulaqları uzun və çox həssasdır. Onlar səsləri çox yaxşı eşidir və insanlar onlarla rahat ünsiyyət qururlar.\nEşşəklər insanlarla çox yaxın dost ola bilərlər və bəzən ev heyvanı kimi saxlanılırlar.\nOnların səsi – "i-ay" – çox fərqlidir və uzaqdan asanlıqla tanınır.\nEşşəklər çox ağıllı heyvanlardır və yaxşı yaddaşa malikdirlər.',
    'Eland':
        'Eland Afrika savannalarının ən böyük və ən güclü ceyran növüdür. Onlar çox hündür və ağır heyvanlardır.\nElandların buynuzları uzun və spiral şəklində bükülür, həm kişi, həm də dişi elandlarda olur.\nOnlar çox sakit və ağıllı heyvanlardır, adətən sürü halında yaşayırlar.\nElandlar uzun məsafələrdə yemək və su axtarmaq üçün çox yaxşı qaça bilirlər.\nOnlar həmçinin çox yaxşı tullanırlar və təhlükə olduqda sürətlə qaçaraq gizlənirlər.',
    'Echidna':
        'Echidnalar tikanlı, kiçik və qəribə heyvanlardır. Onlar Avstraliyada yaşayırlar və tikanları onları düşmənlərdən qoruyur.\nBu heyvanlar çox yavaş hərəkət edir, amma tikanlarını qaldırıb özlərini qorumağa hazırdırlar.\nEchidnaların dili çox uzun və yapışqan olur, bu da onları qarışqalar və termitlərlə yemək üçün kömək edir.\nOnlar yumurtlayan məməlilərdən biridir, yəni ana echidna yumurtanı daşıyır və sonra bala dünyaya gəlir.\nEchidnalar gecə aktiv olurlar və çox gizli həyat sürürlər.',
    'Ərincək':
        'Ərincəklər çox kiçik və sürətli quşlardır. Onlar havada dayanmaq və qanadlarını saniyədə 50-80 dəfə çırpmaq qabiliyyətinə malikdirlər.\nƏrincəklər ən kiçik quşlardan biridir, bəziləri ancaq 5 santimetr uzunluğundadır.\nOnlar çiçəklərin şirəsini içərək yaşayırlar və çox vacib tozlayıcıdırlar.\nƏrincəklər çox parlaqdırlar və onların tükləri günəş işığında göy qurşağı kimi parıldayır.\nƏrincəklər bir neçə saniyə havada dayana bilər və geri geri də uça bilirlər!',
    'Əqrəb':
        'Əqrəblər çox kiçik, amma çox güclü canlılardır. Onların quyruğunun ucu zəhərlidir və düşmənlərini qorxutmaq üçün istifadə olunur.\nƏqrəblər gecə aktiv olurlar və gündüzləri torpağın altında gizlənirlər.\nOnlar çox dözümlüdür və isti, quraq yerlərdə yaşamağa yaxşı uyğunlaşırlar.\nƏqrəblərin bədənində xüsusi işıq verən orqanlar var, bəzən gecə onları işıqlandırır.\nƏqrəblər çox yaxşı qorunurlar, zəhərləri yalnız lazım olduqda istifadə olunur.',
    'Folivora':
        'Folivora, yəni yavaşhərəkatlılar, dünyanın ən yavaş heyvanlarındandır. Onlar əsasən Cənubi Amerikada yaşayırlar.\nOnların hərəkətləri çox yavaşdır, bəzən bir gündə yalnız bir neçə metr hərəkət edirlər.\nYavaşhərəkatlılar uzun və kəskin dırnaqlara malikdirlər, onları ağaclara yapışmaq üçün istifadə edirlər.\nBu heyvanlar çox sakit və dinc təbiətə malikdir, çox vaxt ağaclarda asılı vəziyyətdə yatırlar.\nYavaşhərəkatlıların tükü yaşıl yosunlarla örtülür, bu da onlara ağaclarda kamuflyaj olmağa kömək edir.',
    'Fil':
        'Fil dünyanın ən böyük quru heyvanıdır. Onların uzun hortumu çox güclüdür və bir çox işləri görmək üçün istifadə olunur.\nFillər çox ağıllı və sosial heyvanlardır, ailə kimi qruplar şəklində yaşayırlar.\nOnlar bir-birini çox yaxşı anlayırlar və duyğularını göstərmək üçün qulaqlarını və hortumlarını istifadə edirlər.\nFillər həmçinin çox yaxşı yaddaşa malikdirlər və uzun illər əvvəl baş verənləri xatırlaya bilirlər.\nOnların dərisi çox qalın olsa da, günəşdən qorunmaq üçün palçıq vannası etməyi çox sevirlər.',
    'Flamingo':
        'Flamingolar uzun, incə ayaqları və parlaq çəhrayı rəngləri ilə məşhurdur. Onların rəngi yemək yedikləri kiçik qarışqalar və su yosunlarından gəlir.\nFlamingolar suda dayanarkən tez-tez bir ayaqları üstündə dururlar, bu onlara rahatlıq verir.\nOnların dimdiyi xüsusi formadadır, bu, onları suda yemək axtarmaqda kömək edir.\nFlamingolar çox sosial quşlardır, böyük sürülərdə yaşayır və birlikdə hərəkət edirlər.\nBu quşlar uzun məsafələrə uçmaqda çox yaxşıdırlar və mühacirət edərək isti yerlərə gedirlər.',
    'Gürzə':
        'Gürzə Azərbaycanda yaşayan çox zəhərli ilan növüdür. Onun zəhəri çox güclüdür və insanlara qarşı qorunmaq lazımdır.\nGürzələr adətən torpaq altında və ya daşların arasında gizlənirlər.\nOnlar çox sürətli və çevik hərəkət edirlər, təhlükə hiss etdikdə dərhal qaça bilirlər.\nGürzələrin dərisi gözəl naxışlarla örtülüdür, bu, onları təbiətdə kamuflyaj edir.\nİlanlar yerə yaxın yaşayırlar və heyvanları ovlamaq üçün zəhərlərindən istifadə edirlər.',
    'Gəlincik':
        'Gəlinciklər kiçik və sürətli heyvanlardır. Onlar əsasən meşə və düzənliklərdə yaşayırlar.\nOnların bədəni incə və çevikdir, bu da onlara tez qaçmaq və kiçik yerlərdən keçmək imkanı verir.\nGəlinciklərin tükü il boyu dəyişir, qışda daha qalın və açıq rəngdə olur.\nOnlar gecə və gündüz aktiv ola bilirlər, amma çox vaxt axşam və səhər yemək axtarırlar.\nGəlinciklər kiçik heyvanlarla qidalanırlar və çox yaxşı ovçulardırlar.',
    'Hamster':
        'Hamsterlər kiçik və çox şirin gəmiricilərdir. Onların yanaq cibləri var, orada yeməkləri saxlayıb daşıya bilirlər.\nOnlar gecə və səhər saatlarında daha aktiv olurlar, çox vaxt yuxuda keçirirlər.\nHamsterlər öz yuvalarını qazar və içərisini yumşaq materiallarla doldururlar.\nOnlar çox tez çoxalırlar və bir dəfə çox bala dünyaya gətirə bilirlər.\nHamsterlər çox təmiz heyvanlardır və tez-tez özlərini yuyurlar.',
    'Xərçəng':
        'Xərçənglər suda yaşayan kiçik canlılardır. Onların iki böyük çənələri var, bunlarla özlərini qoruyurlar və yemək tuturlar.\nXərçənglər yavaş-yavaş hərəkət edirlər və tez-tez suyun dibində daşların arasında gizlənirlər.\nOnlar qabığını dəyişdirərək böyüyürlər, bu prosesə "qabıq dəyişmə" deyilir.\nXərçənglər həm duzlu, həm də təmiz suda yaşaya bilirlər.\nOnlar əsasən kiçik balıqlar, bitkilər və heyvan qalıqları ilə qidalanırlar.',
    'İlan':
        'İlanlar uzun, əyri bədənli və sürünən heyvanlardır. Onların ayaqları yoxdur, amma çox sürətlə sürünərək hərəkət edirlər.\nOnlar dərilərini mütəmadi olaraq dəyişirlər və bu prosesə "tüklənmə" deyilir.\nİlanların bəziləri zəhərlidir, bəziləri isə zəhərsizdir. Zəhərli ilanlar düşmənlərini qorxutmaq və ov tutmaq üçün zəhərindən istifadə edirlər.\nİlanlar çox yaxşı kamuflyaj olurlar, yəni təbiətdə gizlənmək üçün dərilərinin rəngini dəyişirlər.\nOnlar əsasən kiçik heyvanlarla qidalanırlar və çox yaxşı ovçudurlar.',
    'Jaquar':
        'Jaquar böyük və güclü pişiklərdən biridir. Onların bədəni ləkələrlə örtülüdür, bu onları meşədə gizlənməyə kömək edir.\nJaquarlar çox yaxşı üzür və suyu sevirlər, buna görə də onların yaşadıqları yerlərdə göllər və çaylar olur.\nOnlar gecə və səhər vaxtı daha aktivdirlər, ovlarını gizlənərək yaxalayırlar.\nJaquarlar təkcə ovçuluqla deyil, həm də çox ağıllı heyvanlardır.\nOnlar qısa məsafələrdə sürətlə qaça bilirlər və çox yaxşı tullanırlar.',
    'Kəpənək':
        'Kəpənəklər çox gözəl və rəngarəng qanadlara malikdirlər. Onlar çiçəklərdən nektar içməklə qidalanırlar.\nKəpənəklərin həyat dövrü yumurtadan başlayır, sonra tırtıl olur, sonra isə kokonda dəyişərək kəpənəyə çevrilir.\nOnlar çox zərif canlılardır və havada yüngülcə uçurlar.\nKəpənəklər müxtəlif rəngləri ilə təbiətdə özlərini qoruyur və düşmənlərdən gizlənirlər.\nOnlar bahar və yay aylarında çox aktiv olurlar və bağlarda tez-tez görünürlər.',
    'Kirpi':
        'Kirpinin bədəni kiçik tikanlarla örtülüdür, bu tikanlar ona düşmənlərdən qorunmaqda kömək edir.\nƏgər kirpi təhlükə hiss etsə, özünü topa bənzər bükür və tikanlarını qabağa çıxarır.\nKirpilər gecə heyvanlarıdır, onlar gecə yemək axtarırlar.\nOnlar həşəratlarla, qurdlardan və kiçik heyvanlardan qidalanırlar.\nKirpinin qulaqları və gözləri çox yaxşı işləyir, bu da onlara düşməni vaxtında görməkdə kömək edir.',
    'Kərtənkələ':
        'Kərtənkələlər sürünən heyvanlardır və çox sürətlə hərəkət edə bilirlər.\nOnların bədəni uzun və nazikdir, bəzilərinin quyruqları çox uzun olur.\nKərtənkələlər quyruqlarını düşmənləri tuta bilməsi üçün qurban verə bilərlər – quyruq kəsiləndən sonra yenisi yenidən çıxır.\nOnlar günəşdə oturmaqdan çox xoşları gəlir, çünki günəş onları isti saxlayır.\nKərtənkələlər əsasən həşəratlarla və kiçik canlılarla qidalanırlar.',
    'Kəklik':
        'Kəkliklər dağlarda və təpələrdə yaşayan kiçik quşlardır.\nOnların bədəni yumşaq tüklərlə örtülüdür və rəngləri torpaq rənglərinə bənzəyir, bu da onları düşmənlərdən gizlədir.\nKəkliklər çox yaxşı qaça bilirlər və uçmaq bacarıqları da var, amma çox uzağa uçmazlar.\nOnlar əsasən toxumlarla, otlarla və kiçik həşəratlarla qidalanırlar.\nKəkliklərin səsi dağlarda çox gözəl eşidilir və onlar öz ərazilərini səs ilə bildirirlər.',
    'Qaranquş':
        'Qaranquşlar kiçik, çevik və sürətli quşlardır. Onlar çox gözəl uçarlar və uzun məsafələr qət edə bilirlər.\nBu quşlar yazda gəlir və yay boyunca yaşayarlar, sonra isə isti ölkələrə köç edərlər.\nQaranquşlar yuvalarını adətən insan evlərinin yaxınlığında, divarların altında tikirlər.\nOnlar kiçik həşəratlarla, qanadlı böcəklərlə və toxumlarla qidalanırlar.\nQaranquşlar insanların yanında yaşamağa öyrəşiblər və onların səsi çox xoş gəlir.',
    'Qartal':
        'Qartal güclü qanadlara malik böyük bir quşdur. O, göydə çox yüksəkdən uça bilir və uzaqdan ovunu görə bilir.\nOnun iti gözləri ovunu tapmaqda ona kömək edir.\nQartallar çox güclü dırnaqlara sahibdir və bu dırnaqlarla ovlarını tutur və qidalanır.\nOnlar əsasən balıqlar, kiçik məməlilər və digər quşlarla qidalanırlar.\nQartallar çox yaxşı uçarlar və bəzən çox uzun müddət havada qala bilirlər.',
    'Qaz':
        'Qazlar su quşlarıdır və çox yaxşı üzə bilirlər. Onların qanadları güclüdür və uzun məsafələr uça bilirlər.\nQazlar səsli və gurultulu səsləri ilə tanınırlar, bu səslər onları bir-birindən ayırmağa kömək edir.\nOnlar sürü halında yaşayırlar və qışda isti ölkələrə köç edirlər.\nQazlar əsasən otlarla, toxumlarla və bəzən kiçik həşəratlarla qidalanırlar.\nQazların uzun boyunları və möhkəm ayaqları onları su və quruda rahat hərəkət etməyə imkan verir.',
    'Qoyun':
        'Qoyunlar yunları ilə məşhurdur və onların yunları çox yumşaqdır.\nOnlar qrup halında yaşayırlar və bir-birilərini qoruyurlar.\nQoyunlar əsasən otlarla qidalanırlar və geniş otlaqlarda otlayırlar.\nQoyunların yaxşı qoxu və eşitmə duyğuları vardır, bu onlara təhlükəni vaxtında hiss etməyə kömək edir.\nQoyunlar insanlara çox faydalıdır, çünki onlardan yun, ət və süd alınır.',
    'Qurd':
        'Qurdlar meşə və dağlarda yaşayan və çox ağıllı heyvanlardır.\nOnlar sürü halında yaşayırlar və bir-birilərinə kömək edirlər.\nQurdlar gecə daha aktiv olurlar və əsasən kiçik heyvanlarla, quşlarla və bəzi bitkilərlə qidalanırlar.\nQurdların güclü dişləri və sürətli qaçma qabiliyyəti vardır.\nOnlar meşədə özlərini gizlətmək üçün möhkəm tikanlı kolların arasını sevirlər.',
    'Lama':
        'Lamalar cənub Amerikada yaşayan heyvanlardır və çox yumşaq tükləri var.\nOnlar dağlarda və soyuq yerlərdə yaşayırlar, buna görə soyuğa çox dözümlüdürlər.\nLamalar sürü halında yaşayırlar və bir-biri ilə səs və bədən hərəkətləri ilə danışırlar.\nOnlar əsasən otlarla, yarpaqlarla və bəzən meyvələrlə qidalanırlar.\nLamalar insanlara yük daşımaqda kömək edən dost heyvanlardır.',
    'Leopard':
        'Leopardlar böyük və güclü pişik növlərindən biridir.\nOnların bədənində qəhvəyi və sarı rəngdə ləkələr var, bu da onları meşədə gizlənməyə kömək edir.\nLeopardlar çox sürətli qaça və yüksək ağaclara tırmana bilirlər.\nOnlar əsasən gecə ovlanırlar və müxtəlif heyvanlarla qidalanırlar.\nLeopardlar öz tək yaşayırlar və ərazilərini qoruyurlar.',
    'Leylek':
        'Leyleklər böyük və uzun ayaqlı quşlardır.\nOnlar yazda gəlib yuva qurur və yayda balalarını böyüdürlər.\nLeyleklər uzun məsafələrə köç edir, isti ölkələrə gedirlər.\nOnlar əsasən balıqlar, qurbağalar və kiçik heyvanlarla qidalanırlar.\nLeyleklərin uzun və güclü qanadları onları göydə rahat uçmağa imkan verir.',
    'Mamont':
        'Mamontlar çox-çox illər əvvəl yaşamış, nəhəng və tüklü fillərə bənzəyən heyvanlardır.\nOnların uzun əyilmiş dişləri və qalın tükləri buz dövründə soyuğa qarşı onları qoruyurdu.\nMamontlar sürü halında yaşayır və bir-birilərinə kömək edirdilər.\nOnlar əsasən ot, yarpaq və ağac qabıqları ilə qidalanırdılar.\nBugünkü fillər mamontların uzaq qohumları sayılır.',
    'Meymun':
        'Meymunlar çox ağıllı və oynaq heyvanlardır.\nOnlar ağaclarda tullanmağı və sallanmağı çox sevirlər.\nMeymunlar bir-biriləri ilə səslər və üz ifadələri ilə ünsiyyət qururlar.\nƏsasən meyvə, banan, yarpaq və qoz-fındıqla qidalanırlar.\nBəzi meymunlar alət istifadə edə bilir və problemləri həll etməyi bacarır!',
    'Nərə':
        'Nərə çox qədim balıqlardan biridir və böyük ölçülərə çata bilir.\nO, əsasən Xəzər dənizində və böyük çaylarda yaşayır.\nNərənin bədəni uzunsov olur və üstündə sərt lövhələr var.\nBu balıq yumurtalarını çayların təmiz yerlərində qoyur.\nNərə balığının kürüsü – qara kürü – çox qiymətli və dadlı sayılır.',
    'Orka':
        'Orka, həm balinaya, həm də delfinə bənzəyən böyük və ağıllı dəniz heyvanıdır.\nOnlar qara-ağ rəngdə olur və çox sürətli üzə bilirlər.\nOrkalar ailə kimi qruplarda yaşayır və birlikdə ov edirlər.\nOnlar balıq, suiti, hətta başqa balinalarla belə qidalanırlar.\nOrkalar çox ağıllıdır və bir-biriləri ilə səslər vasitəsilə danışa bilirlər!',
    'Ördək':
        'Ördəklər həm suda, həm də quruda rahat hərəkət edə bilən maraqlı quşlardır.\nOnların ayaqları üzgəc kimidir, bu da onlara suda asan üzməyə kömək edir.\nÖrdəklər "vak-vak" səsi çıxarır və bu səslə bir-biriləri ilə danışırlar.\nOnlar əsasən su bitkiləri, kiçik balıqlar və həşəratlarla qidalanırlar.\nÖrdəklər yumurta qoyur və balalarını tükləri çıxana qədər qoruyur.',
    'Pələng':
        'Pələng böyük və güclü bir pişik növüdür, bədəni zolaqlarla bəzənib.\nO, meşələrdə tək yaşayır və ovunu səssizcə izləyib hücum edir.\nPələnglər üzməyi çox sevir və hətta bəzən suyun içində ov edirlər.\nOnlar əsasən geyik, ceyran və digər heyvanlarla qidalanırlar.\nPələngin nəriltisi çox uzaqdan eşidilə bilər və qorxulu səslənir.',
    'Pinqvin':
        'Pinqvinlər uça bilməyən, amma çox yaxşı üzə bilən quşlardır.\nOnlar əsasən çox soyuq yerlərdə, xüsusən Antarktidada yaşayırlar.\nPinqvinlərin bədəni qara-ağ rəngdədir və bu onları buz üstündə tanınmaz edir.\nOnlar balıq və kiçik dəniz canlıları ilə qidalanırlar.\nPinqvinlər bir-birilərinə səs və hərəkətlərlə "söhbət" edirlər və ailə olaraq birlikdə qalırlar.',
    'Rakun':
        'Rakunlar gecə fəal olan kiçik və ağıllı heyvanlardır.\nOnların üzündə maska kimi qaralar var və bu, onları çox fərqli göstərir.\nRakunlar su kənarlarında yaşayır və əllərini suya salıb yeməkləri yuyurlar.\nOnlar meyvə, həşərat və kiçik heyvanlarla qidalanırlar.\nRakunlar çox yaxşı dırmaşır və ağaclarda rahat gizlənə bilirlər.',
    'Siçan':
        'Siçanlar kiçik, sürətli və ağıllı heyvanlardır.\nOnlar gecə vaxtı daha aktiv olurlar və yemək axtarırlar.\nSiçanlar çox yaxşı qaça bilirlər və kiçik yerlərdən asanlıqla keçir.\nOnlar müxtəlif növ yeməklərlə qidalanırlar, xüsusən dənli bitkiləri sevirlər.\nSiçanlar çox tez çoxalır və bir çox bala verə bilirlər.',
    'Sincab':
        'Sincablar kiçik və çevik heyvanlardır, uzun quyruqları ilə məşhurdurlar.\nOnlar əsasən meşələrdə yaşayır və ağaclarda dırmaşmağı çox sevirlər.\nSincablar qoz-fındıq, giləmeyvə və toxumlarla qidalanırlar.\nOnlar gələcəklər üçün yeməklərini yığır və gizlədirlər.\nSincabların tullanıb-dırmaşmağı çox sürətlidir və bu onları yırtıcılardan qoruyur.',
    'Sərçə':
        'Sərçələr kiçik və çox aktiv quşlardır.\nOnlar tez-tez bağlarda və şəhər yerlərində görünürlər.\nSərçələr müxtəlif növ toxumlar və həşəratlarla qidalanırlar.\nOnların cəh-cəh səsi çox xoş və rahatladıcıdır.\nSərçələr birlikdə kiçik qruplarda yaşayırlar və bir-birilərinə kömək edirlər.',
    'Şahin':
        'Şahinlər sürətli və güclü yırtıcı quşlardır.\nOnlar yüksəkdən uça bilib ovlarını diqqətlə izləyirlər.\nŞahinlər ən yaxşı görmə qabiliyyətinə malik quşlardandır.\nOnlar əsasən kiçik heyvanlar və quşlarla qidalanırlar.\nŞahinlər öz yuvalarını yüksək ağaclarda və qayalarda qururlar.',
    'Şir':
        'Şirlər meşələrin və savannaların ən güclü heyvanlarından biridir.\nOnlar ailə şəklində qrup halında yaşayırlar və buna "pələng" deyil, "qəbilə" deyilir.\nŞirlər öz nəriltisi ilə bütün savannaya səs salırlar və bu, çox qorxuducudur.\nOnlar əsasən böyük heyvanlarla qidalanırlar və gecə ovlanmağa üstünlük verirlər.\nŞirlərin kişilərinin başında böyük və parlaq saqqal olur.',
    'Tısbağa':
        'Tısbağalar uzunömürlü heyvanlardır və çox yavaş hərəkət edirlər.\nOnların bədəni sərt qabıqla örtülüb və bu, onları yırtıcılardan qoruyur.\nTısbağalar həm quru, həm də su ətrafında yaşayırlar.\nOnlar əsasən bitkilərlə qidalanırlar, bəzən isə balıq və kiçik heyvanları da yeyirlər.\nTısbağalar dərin yuxuya gedə bilirlər və uzun müddət yemədən qala bilirlər.',
    'Tülkü':
        'Tülkülər ağıllı və çevik heyvanlardır.\nOnlar meşələrdə, çöllərdə və bəzən insanlara yaxın yaşayırlar.\nTülkülər gecə ovlanırlar və yaxşı gizlənə bilirlər.\nOnların uzun və tüklü quyruğu soyuq havada istilik verir.\nTülkülər müxtəlif yeməklərlə qidalanır, məsələn, kiçik heyvanlar, meyvələr və həşəratlar.',
    'Ulaq':
        'Ulaq çox güclü və davamlı at növüdür.\nOnlar dağlıq yerlərdə və sərt şəraitdə işləmək üçün yetişdirilirlər.\nUlaqlar yükləri daşımaqda və uzun məsafələr getməkdə çox bacarıqlıdırlar.\nOnlar sakit və səbirli heyvanlardır.\nUlaq atlardan fərqli olaraq daha iri və möhkəm bədənə malikdir.',
    'Vaşaq':
        'Vaşaq orta ölçülü yırtıcı pişik növüdür.\nOnun qulaqlarının ucunda qara tüklər var, bu onu daha gözəl göstərir.\nVaşaq meşələrdə və dağlıq yerlərdə yaşayır.\nOnlar gecələri ovlanırlar və çox yaxşı gizlənə bilirlər.\nVaşaq qısa, qalın tükü ilə soyuqdan qorunur və tullanmaqda çox sürətlidir.',
    'Yarasa':
        'Yarasalar gecə uçan yeganə məməlilərdir.\nOnlar çox yaxşı eşidirlər və səs dalğalarını istifadə edərək yolu tapırlar, buna "eko-lokasiya" deyilir.\nYarasalar əsasən gecə ovlanırlar və həşəratlarla qidalanırlar.\nOnlar qrup halında mağaralarda və ağacların altında yaşayırlar.\nYarasalar kiçik ölçülərə malikdir, amma çox sürətli uça bilirlər.',
    'Zürafə':
        'Zürafələr dünyanın ən uzun boylu heyvanlarıdır.\nOnların boynu çox uzun olur və yüksək ağaclardan yarpaqlar yeyirlər.\nZürafələrin dili çox uzun və tutqun qara rəngdədir, bu, onları bitkiləri yeməkdə kömək edir.\nOnlar sürətlə qaça bilirlər və çox sakit heyvanlardır.\nZürafələr qruplar halında yaşayırlar və bir-birlərini qoruyurlar.',
    'Zebra':
        'Zebralar ağ-qara zolaqlı at növüdür.\nHər zebranın zolaqları fərqlidir, heç biri bir-birinə bənzəmir.\nZebralar sürü halında yaşayır və birlikdə qorunurlar.\nOnlar əsasən otla qidalanırlar və çox sürətli qaça bilirlər.\nZebralar Afrikanın geniş çöllərində yaşayırlar.',
  };

  static const Map<String, List<String>> animalFoods = {
    'At': ['Ot', 'Yulaf', 'Saman'],
    'Ayı': ['Bal', 'Balıq', 'Giləmeyvə'],
    'Ceyran': ['Ot', 'Yarpaqlar'],
    'Fil': ['Ot', 'Meyvə', 'Yarpaqlar'],
    'Pələng': ['Ət', 'Kiçik heyvanlar'],
    'İlan': ['Siçan', 'Quş', 'Yumurta'],
    'Qartal': ['Balıq', 'Quş', 'Kiçik məməlilər'],
    'Dovşan': ['Ot', 'Kök', 'Yarpaqlar'],
    'Balıq': ['Plankton', 'Kiçik balıqlar'],
    // ... digər heyvanlar üçün qida əlavə edə bilərsən ...
  };

  // --- Əlavə: Səs və puzzle üçün map-lar ---
  static const Map<String, bool> animalHasSound = {
    'At': false,
    'Ayı': true,
    'Ceyran': false,
    'Fil': false,
    'Pələng': false,
    'İlan': false,
    'Qartal': false,
    'Dovşan': false,
    'Balıq': false,
    // ... digər heyvanlar ...
  };

  static const Map<String, bool> animalHasPuzzle = {
    'At': true,
    'Ayı': false,
    'Ceyran': false,
    'Fil': false,
    'Pələng': false,
    'İlan': false,
    'Qartal': false,
    'Dovşan': false,
    'Balıq': false,
    // ... digər heyvanlar ...
  };

  // Youtube embed kodları üçün map
  static const Map<String, String> animalYoutubeEmbeds = {
    'At': 'https://www.youtube.com/embed/24FqPV30Af4',
    // ... digər heyvanlar üçün əlavə edə bilərsən ...
  };

  void _playAnimalSound(String animal) async {
    final animalLetter = getFirstLetter(animal);
    final animalName = normalizeFileName(animal);
    final audioAsset = 'animals/$animalLetter/${animalName}_sound.mp3';
    try {
      await audioPlayer.stop();
      await audioPlayer.play(AssetSource(audioAsset));
    } catch (e) {}
  }

  void _toggleAnimalInfo(String animal) async {
    final animalLetter = getFirstLetter(animal);
    final animalName = normalizeFileName(animal);
    final audioAsset = 'animals/$animalLetter/${animalName}_info_sound.mp3';

    if (isPlayingInfo) {
      await audioPlayer.stop();
      setState(() {
        isPlayingInfo = false;
      });
    } else {
      await audioPlayer.stop();
      await audioPlayer.play(AssetSource(audioAsset));
      setState(() {
        isPlayingInfo = true;
      });
      audioPlayer.onPlayerComplete.listen((event) {
        setState(() {
          isPlayingInfo = false;
        });
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    // flutterTts səsləndirmə event-ləri
    flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          isPlayingInfo = false;
        });
      }
    });
    flutterTts.setCancelHandler(() {
      if (mounted) {
        setState(() {
          isPlayingInfo = false;
        });
      }
    });
    flutterTts.setPauseHandler(() {
      if (mounted) {
        setState(() {
          isPlayingInfo = false;
        });
      }
    });
    flutterTts.setErrorHandler((msg) {
      if (mounted) {
        setState(() {
          isPlayingInfo = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AnimalDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animal != oldWidget.animal) {
      audioPlayer.stop();
      flutterTts.stop();
      setState(() {
        isPlayingInfo = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final animal = widget.animal;
    final animalLetter = getFirstLetter(animal);
    final animalName = normalizeFileName(animal);
    final imageAsset = 'animals/$animalLetter/$animalName.png';
    final puzzleAsset = 'animals/$animalLetter/${animalName}_puzzle.jpg';
    final info = animalInfo[animal] ?? 'Bu heyvan haqqında məlumat yoxdur.';
    final foods = animalFoods[animal] ?? [];
    final animalsList = widget.animals;
    final currentIndex = widget.currentIndex;
    final animalSoundAsset = 'animals/$animalLetter/${animalName}_sound.mp3';

    final List<_ActionButtonData> actions = [
      _ActionButtonData(
        tooltip: 'Haqqında',
        icon: Icons.info,
        selected: showInfo,
        onTap: () {
          setState(() {
            showInfo = true;
            showFoods = false;
            showPuzzle = false;
            showWordPuzzle = false;
            showYoutube = false;
          });
        },
        visible: true,
      ),
      if (foods.isNotEmpty)
        _ActionButtonData(
          tooltip: 'Qidaları',
          icon: Icons.restaurant,
          selected: showFoods,
          onTap: () {
            setState(() {
              showFoods = true;
              showInfo = false;
              showPuzzle = false;
              showWordPuzzle = false;
              showYoutube = false;
            });
          },
          visible: true,
        ),
    ];
    // Səs iconunu yalnız map-da true olan heyvanlar üçün əlavə et
    if (animalHasSound[animal] == true) {
      actions.add(
        _ActionButtonData(
          tooltip: 'Heyvanın səsi',
          icon: Icons.volume_up,
          selected: false,
          onTap: () {
            _playAnimalSound(animal);
            setState(() {
              showYoutube = false;
            });
          },
          visible: true,
        ),
      );
    }
    // Puzzle iconunu yalnız map-da true olan heyvanlar üçün əlavə et
    if (animalHasPuzzle[animal] == true) {
      actions.add(
        _ActionButtonData(
          tooltip: 'Puzzle',
          icon: Icons.extension,
          selected: showPuzzle,
          onTap: () {
            setState(() {
              showPuzzle = true;
              showInfo = false;
              showFoods = false;
              showWordPuzzle = false;
              showYoutube = false;
            });
          },
          visible: true,
        ),
      );
    }
    // Hərf oyunu iconu (ən sağda)
    actions.add(
      _ActionButtonData(
        tooltip: 'Hərf oyunu',
        icon: Icons.spellcheck,
        selected: showWordPuzzle,
        onTap: () {
          setState(() {
            showWordPuzzle = true;
            showInfo = false;
            showFoods = false;
            showPuzzle = false;
            showYoutube = false;
          });
        },
        visible: true,
      ),
    );
    // Yeni: Səbət oyunu buttonu
    actions.add(
      _ActionButtonData(
        tooltip: 'Səbət oyunu',
        icon: Icons.sports_basketball,
        selected: false,
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder:
                (context) => Padding(
                  padding: MediaQuery.of(context).viewInsets,
                  child: SizedBox(
                    height: 480,
                    child: BasketGameWidget(letter: animal[0]),
                  ),
                ),
          );
        },
        visible: true,
      ),
    );
    // Youtube video iconu yalnız map-da varsa əlavə et
    if (animalYoutubeEmbeds[animal] != null &&
        animalYoutubeEmbeds[animal]!.isNotEmpty) {
      actions.add(
        _ActionButtonData(
          tooltip: 'Youtube video',
          icon: Icons.ondemand_video,
          selected: showYoutube,
          onTap: () {
            setState(() {
              showYoutube = true;
              showInfo = false;
              showFoods = false;
              showPuzzle = false;
              showWordPuzzle = false;
            });
          },
          visible: true,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 26,
          ),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Geri',
        ),
        title: LayoutBuilder(
          builder: (context, constraints) {
            return FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                animal,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 24, // daha kiçik font
                ),
              ),
            );
          },
        ),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Heyvan şəkli və oxlar bir blokda
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withAlpha(
                            (0.08 * 255).toInt(),
                          ),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.deepPurple.shade50,
                        width: 1.2,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 18,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ClipRRect(
                              key: _animalImageKey,
                              borderRadius: BorderRadius.circular(28),
                              child: Image.asset(
                                imageAsset,
                                width: 180,
                                height: 180,
                                fit: BoxFit.contain,
                                errorBuilder:
                                    (context, error, stackTrace) => Container(
                                      width: 180,
                                      height: 180,
                                      color: Colors.grey.shade200,
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        size: 40,
                                      ),
                                    ),
                              ),
                            ),
                          ],
                        ),
                        // Ortalanmış oxlar
                        if (animalsList != null &&
                            currentIndex != null &&
                            animalsList.length > 1) ...[
                          if (currentIndex > 0)
                            Positioned(
                              left: 0,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Tooltip(
                                  message: 'Əvvəlki',
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.arrow_back_ios,
                                      size: 36,
                                    ),
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => AnimalDetailPage(
                                                animal:
                                                    animalsList[currentIndex -
                                                        1],
                                                animals: animalsList,
                                                currentIndex: currentIndex - 1,
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          if (currentIndex < animalsList.length - 1)
                            Positioned(
                              right: 0,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Tooltip(
                                  message: 'Növbəti',
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 36,
                                    ),
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => AnimalDetailPage(
                                                animal:
                                                    animalsList[currentIndex +
                                                        1],
                                                animals: animalsList,
                                                currentIndex: currentIndex + 1,
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                  // Şəkil ilə buttonlar arasında məsafə
                  const SizedBox(height: 18),
                  // Action buttonlar ayrıca və ortada
                  Builder(
                    builder: (context) {
                      return FutureBuilder<List<Widget>>(
                        future: _buildVisibleActions(actions),
                        builder: (context, snapshot) {
                          final visibleActions = snapshot.data ?? [];
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: separatedBySpace(visibleActions),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  if (showWordPuzzle) ...[
                    const Text(
                      'Heyvanın adını düzgün yığ!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimalWordPuzzle(word: animal),
                  ],
                  if (showYoutube && animalYoutubeEmbeds[animal] != null) ...[
                    const SizedBox(height: 16),
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.black,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: YoutubeVideoWidget(
                            embedUrl: animalYoutubeEmbeds[animal]!,
                          ),
                        ),
                      ),
                    ),
                  ],
                  Expanded(
                    child: SingleChildScrollView(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child:
                            showPuzzle
                                ? Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: PuzzlePage(animal: animal),
                                )
                                : Column(
                                  children: [
                                    if (showInfo)
                                      Container(
                                        width: double.infinity,
                                        height:
                                            MediaQuery.of(context).size.height *
                                            0.55,
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 22,
                                          vertical: 20,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.deepPurple.shade50,
                                          borderRadius: BorderRadius.circular(
                                            22,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.deepPurple
                                                  .withAlpha(
                                                    (0.08 * 255).toInt(),
                                                  ),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                          border: Border.all(
                                            color: Colors.deepPurple.shade100,
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.max,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          14,
                                                        ),
                                                    onTap:
                                                        () => _toggleAnimalInfo(
                                                          animal,
                                                        ),
                                                    child: AnimatedContainer(
                                                      duration: const Duration(
                                                        milliseconds: 180,
                                                      ),
                                                      curve: Curves.easeInOut,
                                                      padding:
                                                          const EdgeInsets.all(
                                                            7,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            isPlayingInfo
                                                                ? Colors
                                                                    .deepPurple
                                                                    .shade100
                                                                : Colors
                                                                    .transparent,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              14,
                                                            ),
                                                        border: Border.all(
                                                          color:
                                                              isPlayingInfo
                                                                  ? Colors
                                                                      .deepPurple
                                                                  : Colors
                                                                      .deepPurple
                                                                      .shade100,
                                                          width:
                                                              isPlayingInfo
                                                                  ? 2
                                                                  : 1.1,
                                                        ),
                                                        boxShadow:
                                                            isPlayingInfo
                                                                ? [
                                                                  BoxShadow(
                                                                    color: Colors
                                                                        .deepPurple
                                                                        .withAlpha(
                                                                          (0.10 *
                                                                                  255)
                                                                              .toInt(),
                                                                        ),
                                                                    blurRadius:
                                                                        8,
                                                                    offset:
                                                                        const Offset(
                                                                          0,
                                                                          2,
                                                                        ),
                                                                  ),
                                                                ]
                                                                : [],
                                                      ),
                                                      child: Tooltip(
                                                        message:
                                                            'Haqqında səsləndir',
                                                        child: Icon(
                                                          isPlayingInfo
                                                              ? Icons
                                                                  .stop_circle
                                                              : Icons
                                                                  .record_voice_over,
                                                          size: 28,
                                                          color:
                                                              isPlayingInfo
                                                                  ? Colors
                                                                      .deepPurple
                                                                  : Colors
                                                                      .deepPurple
                                                                      .shade400,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Icon(
                                                  Icons.info_outline,
                                                  color: Colors.deepPurple,
                                                  size: 26,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Heyvan haqqında',
                                                  style: TextStyle(
                                                    color:
                                                        Colors
                                                            .deepPurple
                                                            .shade700,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            Expanded(
                                              child: SingleChildScrollView(
                                                child: Text(
                                                  info,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF3D2067),
                                                    height: 1.4,
                                                  ),
                                                  textAlign: TextAlign.start,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (showFoods)
                                      Container(
                                        constraints: const BoxConstraints(
                                          maxWidth: 520,
                                        ),
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 22,
                                          vertical: 20,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.deepPurple.shade50,
                                          borderRadius: BorderRadius.circular(
                                            22,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.deepPurple
                                                  .withAlpha(
                                                    (0.08 * 255).toInt(),
                                                  ),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                          border: Border.all(
                                            color: Colors.deepPurple.shade100,
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Qidaları:',
                                              style: const TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: Row(
                                                children: List.generate(foods.length, (
                                                  idx,
                                                ) {
                                                  final food = foods[idx];
                                                  final foodImage =
                                                      'foods/${normalizeFileName(food)}.png';
                                                  _foodButtonKeys.putIfAbsent(
                                                    idx,
                                                    () => GlobalKey(),
                                                  );
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6.0,
                                                        ),
                                                    child: Material(
                                                      color: Colors.transparent,
                                                      child: InkWell(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              18,
                                                            ),
                                                        onTap:
                                                            () {}, // gələcəkdə istifadə üçün
                                                        child: AnimatedContainer(
                                                          duration:
                                                              const Duration(
                                                                milliseconds:
                                                                    200,
                                                              ),
                                                          curve:
                                                              Curves.easeInOut,
                                                          decoration: BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  18,
                                                                ),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Colors
                                                                    .deepPurple
                                                                    .withAlpha(
                                                                      (0.08 * 255)
                                                                          .toInt(),
                                                                    ),
                                                                blurRadius: 8,
                                                                offset:
                                                                    const Offset(
                                                                      0,
                                                                      2,
                                                                    ),
                                                              ),
                                                            ],
                                                            border: Border.all(
                                                              color:
                                                                  Colors
                                                                      .deepPurple
                                                                      .shade100,
                                                              width: 1.2,
                                                            ),
                                                          ),
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 12,
                                                                vertical: 10,
                                                              ),
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              ClipRRect(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                                child: Image.asset(
                                                                  foodImage,
                                                                  width: 56,
                                                                  height: 56,
                                                                  fit:
                                                                      BoxFit
                                                                          .contain,
                                                                  errorBuilder:
                                                                      (
                                                                        context,
                                                                        error,
                                                                        stackTrace,
                                                                      ) => Container(
                                                                        width:
                                                                            56,
                                                                        height:
                                                                            56,
                                                                        color:
                                                                            Colors.grey.shade200,
                                                                        child: const Icon(
                                                                          Icons
                                                                              .fastfood,
                                                                          size:
                                                                              28,
                                                                        ),
                                                                      ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                height: 8,
                                                              ),
                                                              Container(
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          10,
                                                                      vertical:
                                                                          4,
                                                                    ),
                                                                decoration: BoxDecoration(
                                                                  color:
                                                                      Colors
                                                                          .deepPurple
                                                                          .shade100,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        10,
                                                                      ),
                                                                ),
                                                                child: Text(
                                                                  food,
                                                                  style: const TextStyle(
                                                                    fontSize:
                                                                        15,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color:
                                                                        Colors
                                                                            .deepPurple,
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                height: 6,
                                                              ),
                                                              ElevatedButton(
                                                                key:
                                                                    _foodButtonKeys[idx],
                                                                onPressed: () {
                                                                  _animateFoodToAnimal(
                                                                    idx,
                                                                  );
                                                                },
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .white,
                                                                  foregroundColor:
                                                                      Colors
                                                                          .deepPurple,
                                                                  elevation: 0,
                                                                  padding:
                                                                      const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            16,
                                                                        vertical:
                                                                            8,
                                                                      ),
                                                                  shape: RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          12,
                                                                        ),
                                                                    side: BorderSide(
                                                                      color:
                                                                          Colors
                                                                              .deepPurple
                                                                              .shade200,
                                                                    ),
                                                                  ),
                                                                ),
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    const Icon(
                                                                      Icons
                                                                          .favorite,
                                                                      size: 18,
                                                                      color:
                                                                          Colors
                                                                              .pink,
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 6,
                                                                    ),
                                                                    Text(
                                                                      'Qidalandır',
                                                                      style: const TextStyle(
                                                                        fontSize:
                                                                            15,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _animateFoodToAnimal(int foodIdx) async {
    final foodKey = _foodButtonKeys[foodIdx];
    if (foodKey == null) return;
    final animalBox =
        _animalImageKey.currentContext?.findRenderObject() as RenderBox?;
    final foodBox = foodKey.currentContext?.findRenderObject() as RenderBox?;
    if (animalBox == null || foodBox == null) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    final start = foodBox.localToGlobal(foodBox.size.center(Offset.zero));
    final end = animalBox.localToGlobal(animalBox.size.center(Offset.zero));
    OverlayEntry? entry;
    entry = OverlayEntry(
      builder:
          (context) => _FlyingHeartAnimation(
            start: start,
            end: end,
            onArrive: () {
              entry?.remove();
              _showArriveEffect(end, overlay);
            },
          ),
    );
    overlay.insert(entry);
  }

  void _showArriveEffect(Offset center, OverlayState overlay) {
    final effectEntry = OverlayEntry(
      builder: (context) => _ArriveEffect(center: center),
    );
    overlay.insert(effectEntry);
    Future.delayed(const Duration(seconds: 1), () {
      effectEntry.remove();
    });
  }

  Future<bool> _assetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Widget>> _buildVisibleActions(
    List<_ActionButtonData> actions,
  ) async {
    List<Widget> result = [];
    for (final action in actions) {
      if (action.visibleFuture != null) {
        final visible = await action.visibleFuture!;
        if (visible) {
          result.add(_ActionButton(action: action));
        }
      } else if (action.visible) {
        result.add(_ActionButton(action: action));
      }
    }
    return result;
  }
}

class _FlyingHeartAnimation extends StatefulWidget {
  final Offset start;
  final Offset end;
  final VoidCallback onArrive;
  const _FlyingHeartAnimation({
    required this.start,
    required this.end,
    required this.onArrive,
  });

  @override
  State<_FlyingHeartAnimation> createState() => _FlyingHeartAnimationState();
}

class _FlyingHeartAnimationState extends State<_FlyingHeartAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _position;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _position = Tween<Offset>(begin: widget.start, end: widget.end).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onArrive();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: _position.value.dx - 16,
          top: _position.value.dy - 16,
          child: Opacity(
            opacity: 1 - _controller.value * 0.3,
            child: Icon(Icons.favorite, color: Colors.pink, size: 32),
          ),
        );
      },
    );
  }
}

class _ArriveEffect extends StatefulWidget {
  final Offset center;
  const _ArriveEffect({required this.center});

  @override
  State<_ArriveEffect> createState() => _ArriveEffectState();
}

class _ArriveEffectState extends State<_ArriveEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.center.dx - 32,
      top: widget.center.dy - 32,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 1.0 + 0.7 * _controller.value;
          final opacity = 1.0 - _controller.value;
          return Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.pinkAccent.withAlpha((0.7 * 255).toInt()),
                      Colors.pink.withAlpha((0.0 * 255).toInt()),
                    ],
                    stops: [0.5, 1.0],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.favorite, color: Colors.pink, size: 32),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ActionButtonData {
  final String tooltip;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool visible;
  final Future<bool>? visibleFuture;

  _ActionButtonData({
    required this.tooltip,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.visible = false,
    this.visibleFuture,
  });
}

class _ActionButton extends StatelessWidget {
  final _ActionButtonData action;
  const _ActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: action.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color:
                action.selected
                    ? Colors.deepPurple.shade100
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  action.selected
                      ? Colors.deepPurple
                      : Colors.deepPurple.shade100,
              width: action.selected ? 2 : 1.1,
            ),
            boxShadow:
                action.selected
                    ? [
                      BoxShadow(
                        color: Colors.deepPurple.withAlpha(
                          (0.10 * 255).toInt(),
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : [],
          ),
          child: Tooltip(
            message: action.tooltip,
            child: Icon(
              action.icon,
              size: 28,
              color:
                  action.selected
                      ? Colors.deepPurple
                      : Colors.deepPurple.shade400,
            ),
          ),
        ),
      ),
    );
  }
}

List<Widget> separatedBySpace(List<Widget> widgets, {double space = 10}) {
  final result = <Widget>[];
  for (var i = 0; i < widgets.length; i++) {
    result.add(widgets[i]);
    if (i != widgets.length - 1) {
      result.add(SizedBox(width: space));
    }
  }
  return result;
}
