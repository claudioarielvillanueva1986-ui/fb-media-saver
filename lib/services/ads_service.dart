import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/constants.dart';

/// Servicio de anuncios AdMob con enfoque NO INVASIVO:
/// - Un banner discreto en la parte inferior de algunas pantallas.
/// - Un intersticial ocasional, solo tras varias descargas y con cooldown.
///
/// Nota de política: Google Play/AdMob restringen apps cuya función principal
/// es descargar de redes sociales. Ver README antes de publicar.
class AdsService extends ChangeNotifier {
  AdsService._();
  static final AdsService instance = AdsService._();

  bool _initialized = false;
  int _completedDownloads = 0;
  DateTime? _lastInterstitialShown;
  InterstitialAd? _interstitialAd;

  Future<void> init() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
    _loadInterstitial();
  }

  // --- Banner ---
  BannerAd createBanner({VoidCallback? onLoaded}) {
    return BannerAd(
      size: AdSize.banner,
      adUnitId: AppConfig.bannerAdUnitId,
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded?.call(),
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
      request: const AdRequest(),
    )..load();
  }

  // --- Intersticial ---
  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: AppConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (_) => _interstitialAd = null,
      ),
    );
  }

  /// Llamar cada vez que se completa una descarga. Muestra intersticial
  /// solo si se cumplen las condiciones no invasivas.
  void onDownloadCompleted() {
    _completedDownloads++;
    if (_completedDownloads % AppConfig.interstitialEveryNDownloads != 0) return;

    final now = DateTime.now();
    if (_lastInterstitialShown != null &&
        now.difference(_lastInterstitialShown!) <
            AppConfig.interstitialCooldown) {
      return;
    }

    final ad = _interstitialAd;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitial();
      },
    );
    ad.show();
    _lastInterstitialShown = now;
  }
}
