/// Configuración central de la app.
///
/// IMPORTANTE (AdMob):
/// Los IDs de abajo son los IDs OFICIALES DE PRUEBA de Google. Sirven para
/// desarrollar sin arriesgar tu cuenta. Antes de publicar, reemplazalos por
/// tus IDs reales de AdMob (App ID va en AndroidManifest.xml, y los ad unit
/// ids van acá).
class AppConfig {
  static const String appName = 'FB Media Saver';

  // --- AdMob (IDs de PRUEBA de Google) ---
  // Reemplazar por los reales antes de publicar.
  static const String admobAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const String bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String interstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  // --- Política de anuncios "no invasiva" ---
  // Intersticial: solo después de N descargas completadas y con cooldown.
  static const int interstitialEveryNDownloads = 3;
  static const Duration interstitialCooldown = Duration(minutes: 3);

  // --- Facebook ---
  static const String fbMobileHome = 'https://m.facebook.com/';
  // User-Agent tipo escritorio ayuda a obtener enlaces de video en algunos casos.
  static const String desktopUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/122.0 Safari/537.36';
}
