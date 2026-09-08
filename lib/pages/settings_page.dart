import 'package:flutter/material.dart';

import '../core/config.dart';
import '../core/progress.dart';
import '../core/settings.dart';

/// Valideyn bölməsi — `showParentalGate()` arxasından açılır.
///
/// Uşağın əlinə keçməməli hər şey buradadır: səs kanalları, titrəmə,
/// animasiya, pazl çətinliyi və progresin silinməsi.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // CLAUDE.md gotcha #10: Android 16 edge-to-edge rejimini məcbur edir, sistem
    // panelləri `body`-nin üstünə düşür. Fon `Container`-i insetdən KƏNARDA
    // qalır ki, panellərin arxasını da boyasın; inset yalnız scroll-a verilir.
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final settings = AppSettings.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ayarlar',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.deepPurple.shade700,
        child: AnimatedBuilder(
          animation: settings,
          builder: (context, _) {
            final master = settings.masterSound;
            return ListView(
              padding: EdgeInsets.fromLTRB(12, 12, 12, 24 + bottomInset),
              children: [
                const _SectionHeader('Səs'),
                _Section(
                  children: [
                    SwitchListTile(
                      secondary: Icon(
                        master ? Icons.volume_up : Icons.volume_off,
                      ),
                      title: const Text('Bütün səslər'),
                      subtitle: const Text('Tətbiqdəki bütün səsləri susdurur'),
                      value: master,
                      onChanged: (v) => settings.masterSound = v,
                    ),
                    const Divider(height: 1),
                    // Master söndürülübsə alt açarlar sönür, amma DƏYƏRLƏRİ
                    // qalır — master geri açılanda əvvəlki vəziyyət qayıdır.
                    SwitchListTile(
                      secondary: const Icon(Icons.record_voice_over_outlined),
                      title: const Text('İzah və nəqletmə'),
                      subtitle: const Text('Hərf və heyvan haqqında danışıq'),
                      value: settings.narrationSound,
                      onChanged:
                          master ? (v) => settings.narrationSound = v : null,
                    ),
                    SwitchListTile(
                      secondary: const Icon(Icons.pets_outlined),
                      title: const Text('Heyvan səsləri'),
                      value: settings.animalSound,
                      onChanged:
                          master ? (v) => settings.animalSound = v : null,
                    ),
                    SwitchListTile(
                      secondary: const Icon(Icons.celebration_outlined),
                      title: const Text('Effektlər'),
                      subtitle: const Text('Klik, qalibiyyət, səhifə çevirmə'),
                      value: settings.effectSound,
                      onChanged:
                          master ? (v) => settings.effectSound = v : null,
                    ),
                  ],
                ),

                const _SectionHeader('Oyun'),
                _Section(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.vibration),
                      title: const Text('Titrəmə'),
                      subtitle: const Text('Hərfi cızarkən qısa titrəyiş'),
                      value: settings.haptics,
                      onChanged: (v) => settings.haptics = v,
                    ),
                    SwitchListTile(
                      secondary: const Icon(Icons.animation),
                      title: const Text('Animasiyanı azalt'),
                      subtitle: const Text(
                        'Konfeti və təbrik effektlərini söndürür',
                      ),
                      value: settings.reduceMotion,
                      onChanged: (v) => settings.reduceMotion = v,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.extension_outlined),
                      title: const Text('Pazl çətinliyi'),
                      subtitle: const Text('Şəkil pazlındaki parça sayı'),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 3, label: Text('3 × 3')),
                          ButtonSegment(value: 4, label: Text('4 × 4')),
                        ],
                        selected: {settings.puzzleGridSize},
                        onSelectionChanged:
                            (s) => settings.puzzleGridSize = s.first,
                      ),
                    ),
                  ],
                ),

                const _SectionHeader('Valideyn'),
                _Section(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      title: const Text('Progresi sıfırla'),
                      subtitle: const Text(
                        'Bütün ulduzları və bölmələri silir',
                      ),
                      onTap: () => _confirmResetProgress(context),
                    ),
                  ],
                ),

                const _SectionHeader('Məlumat'),
                _Section(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.library_music_outlined),
                      title: const Text('Səs mənbələri'),
                      onTap: () => _showSoundCredits(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('Tətbiq haqqında'),
                      subtitle: Text('Versiya $kAppVersion'),
                      onTap: () => _showAbout(context),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Sıfırlamanın ikinci qoruyucu qatı.
  ///
  /// Valideyn qapısı basıb-saxlama olduğuna görə zəifdir (dizayn sənədi §2.1) —
  /// geri qaytarıla bilməyən əməliyyat ona görə ayrıca açıq təsdiq istəyir.
  Future<void> _confirmResetProgress(BuildContext context) async {
    final store = ProgressStore.instance;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            icon: const Icon(Icons.warning_amber_rounded, size: 40),
            title: const Text('Bütün ulduzlar silinsin?'),
            content: Text(
              'Yığılmış ${store.totalStars} ulduz və tamamlanmış bütün bölmələr '
              'silinəcək. Bu addımı geri qaytarmaq mümkün deyil.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Ləğv et'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Bəli, sil'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    await store.reset();
    messenger.showSnackBar(
      const SnackBar(content: Text('Progres sıfırlandı.')),
    );
  }

  void _showSoundCredits(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Səs mənbələri'),
            content: const SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tətbiqdəki heyvan səsləri açıq lisenziyalı mənbələrdən '
                    'istifadə olunub:',
                  ),
                  SizedBox(height: 12),
                  Text('• bigsoundbank.com — CC0 (Public Domain)'),
                  SizedBox(height: 6),
                  Text('• soundbible.com — Public Domain və CC BY 3.0'),
                  SizedBox(height: 6),
                  Text('• fws.gov, nps.gov — Public Domain arxivləri'),
                  SizedBox(height: 16),
                  Text(
                    'CC BY 3.0 müəllifləri:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Mike Koenig, Daniel Simon, J Dawg, Mark Mattingly, '
                    'Cat Stevens',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Bağla'),
              ),
            ],
          ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Əlifba'),
            content: const SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Versiya $kAppVersion'),
                  SizedBox(height: 4),
                  Text(kAppPackageId),
                  SizedBox(height: 16),
                  Text(
                    'Məxfilik',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Bu tətbiq heç bir şəxsi məlumat toplamır, internetə '
                    'qoşulmur və reklam göstərmir. Bütün şəkillər və səslər '
                    'tətbiqin içindədir; yığılmış ulduzlar yalnız bu cihazda '
                    'saxlanılır.',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Bağla'),
              ),
            ],
          ),
    );
  }
}

/// Tünd bənövşəyi fonun üstündəki bölmə başlığı.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withAlpha((0.75 * 255).toInt()),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

/// Ayarları qruplaşdıran ağ kart — tünd fonda mətn oxunaqlı qalsın.
class _Section extends StatelessWidget {
  const _Section({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }
}
