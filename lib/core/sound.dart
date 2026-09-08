import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'settings.dart';

// `GatedPlayer` işlədən hər fayla kanal enumu da lazımdır — iki ayrı import
// tələb etməmək üçün buradan ötürülür.
export 'settings.dart' show SoundChannel;

/// Ayarlara tabe olan `AudioPlayer` sarğısı.
///
/// **Tətbiqdə birbaşa `AudioPlayer` qurulmamalıdır** — hər səs bu sinifdən
/// keçməlidir. Səbəb: keçidi hər çalınma nöqtəsinə əl ilə yazmaq kövrəkdir.
/// Bu qat yazılarkən tətbiqdə 7 pleyer var idi, sənəd bitənə qədər 9 oldu —
/// yeni pleyer əlavə edən adam mute yoxlamasını yazmağı unutsa, səs söndürülmüş
/// halda belə çalınardı. Keçid pleyerin öz içindədirsə, unutmaq mümkün deyil.
///
/// CLAUDE.md gotcha #5 saxlanılır: daxili `AudioPlayer` sahə elanında sinxron
/// qurulur, `setAsset` isə try/catch içində çağırılır.
class GatedPlayer {
  /// [settings] yalnız testlər üçün verilir; tətbiqdə həmişə tək nüsxə işlənir.
  GatedPlayer(this.channel, {AppSettings? settings})
    : _settings = settings ?? AppSettings.instance {
    _settings.addListener(_onSettingsChanged);
  }

  /// Bu pleyerin səs kanalı — hansı ayarın onu susdurduğunu təyin edir.
  final SoundChannel channel;

  final AppSettings _settings;
  final AudioPlayer _inner = AudioPlayer();

  /// Kanal susdurulubmu.
  bool get isMuted => !_settings.isOn(channel);

  /// Səs sona çatanda hadisə verir — düymənin "oxunur" vəziyyətini sıfırlamaq
  /// üçün.
  ///
  /// Xam `playerStateStream` bilərəkdən açılmır: səhifələr `just_audio`
  /// tiplərini (`PlayerState`, `ProcessingState`) tanımamalıdır, əks halda
  /// pleyeri əvəz etmək bütün səhifələrə toxunmaq deməkdir.
  Stream<void> get onCompleted => _inner.playerStateStream.where(
    (s) => s.processingState == ProcessingState.completed,
  );

  /// Səs faylını yükləyir. Susdurulmuş kanalda da yüklənir ki, ayar geri
  /// açılanda ilk toxunuş gecikməsin.
  Future<void> setAsset(String asset) => _inner.setAsset(asset);

  /// Çalmağa BAŞLAYIR və kanalın açıq olub-olmadığını qaytarır.
  ///
  /// `false` = susdurulub, heç nə çalınmadı — çağıran tərəf "oxunur" bayrağını
  /// qaldırmamalıdır (əks halda düymə əbədi "Dayandır" vəziyyətində ilişir,
  /// çünki heç vaxt `completed` hadisəsi gəlməyəcək).
  ///
  /// Səsin BİTMƏSİNİ gözləmir: `just_audio`-nun `play()`-i çalınma bitəndə
  /// tamamlanır, bu isə düymə vəziyyətini idarə etmək üçün yararsızdır —
  /// onun üçün [playerStateStream] var.
  Future<bool> play() async {
    if (isMuted) return false;
    unawaited(_guard(_inner.play(), 'oxunmadı'));
    return true;
  }

  /// Əvvələ qayıdıb yenidən çalır — təkrarlanan qısa effektlər üçün
  /// (klik, səhifə çevirmə).
  Future<bool> replay() async {
    if (isMuted) return false;
    try {
      await _inner.seek(Duration.zero);
    } catch (e) {
      debugPrint('Səs əvvələ qaytarılmadı: $e');
      return false;
    }
    unawaited(_guard(_inner.play(), 'oxunmadı'));
    return true;
  }

  Future<void> stop() => _guard(_inner.stop(), 'dayandırılmadı');

  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    _inner.dispose();
  }

  /// Kanal söndürüləndə oxunmaqda olan səs DƏRHAL kəsilir — "susdur" düyməsi
  /// yarımçıq nağılın bitməsini gözlətməməlidir.
  void _onSettingsChanged() {
    if (!isMuted) return;
    unawaited(stop());
  }

  Future<void> _guard(Future<void> action, String what) async {
    try {
      await action;
    } catch (e) {
      debugPrint('Səs $what: $e');
    }
  }
}
