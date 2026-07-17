import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/media_item.dart';
import '../utils/constants.dart';

/// Error de extracción con mensaje ya listo para mostrar en la UI (español).
class FacebookExtractorException implements Exception {
  final String message;
  const FacebookExtractorException(this.message);

  @override
  String toString() => message;
}

/// Extrae URLs directas de medios (video/foto) a partir del enlace de un
/// post, reel, video o foto de Facebook.
///
/// Soporta facebook.com/watch, /reel/, /share/v|r|p/, /videos/, /photo,
/// fb.watch, m.facebook.com y web.facebook.com.
///
/// Estrategia:
///  1) Normalizar y validar que el enlace sea de Facebook.
///  2) Descargar el HTML (User-Agent de escritorio; con cookies de sesión si
///     hay una guardada, para poder leer contenido propio/privado).
///  3) Buscar, en orden de prioridad, los patrones de video HD/SD que expone
///     Facebook en el HTML embebido, y si no hay video, la/s imagen/es
///     og:image (eligiendo la de mayor resolución si hay varias).
///  4) Deshacer el escape de las URLs encontradas (\uXXXX, \/, &amp;, %XX).
class FacebookExtractor {
  final http.Client _client;

  /// Cookies de sesión a usar en la request. Si es `null`, se intenta cargar
  /// la sesión guardada por [WebViewLoginScreen] (clave `fb_cookies` en
  /// shared_preferences).
  Map<String, String>? sessionCookies;

  FacebookExtractor({http.Client? client, this.sessionCookies})
      : _client = client ?? http.Client();

  static const String cookiesPrefsKey = 'fb_cookies';

  static const _hdVideoPatterns = [
    r'"hd_src_no_ratelimit":"(.*?)"',
    r'"browser_native_hd_url":"(.*?)"',
    r'"playable_url_quality_hd":"(.*?)"',
    r'"hd_src":"(.*?)"',
  ];

  static const _sdVideoPatterns = [
    r'"sd_src_no_ratelimit":"(.*?)"',
    r'"browser_native_sd_url":"(.*?)"',
    r'"playable_url":"(.*?)"',
    r'"sd_src":"(.*?)"',
  ];

  static const _loginMarkers = [
    'id="login_form"',
    'name="login_form"',
    'you must log in',
    'debés iniciar sesión',
    'debes iniciar sesión',
    "content isn't available right now",
    'el contenido no está disponible',
  ];

  Future<List<MediaItem>> extract(String postUrl) async {
    final normalized = _normalizeAndValidate(postUrl);
    await _loadStoredCookiesIfNeeded();

    final headers = <String, String>{
      'User-Agent': AppConfig.desktopUserAgent,
      'Accept-Language': 'es-ES,es;q=0.9,en;q=0.8',
      if (sessionCookies != null && sessionCookies!.isNotEmpty)
        'Cookie': sessionCookies!.entries
            .map((e) => '${e.key}=${e.value}')
            .join('; '),
    };

    late final http.Response res;
    try {
      res = await _client.get(Uri.parse(normalized), headers: headers);
    } on Exception {
      throw const FacebookExtractorException(
        'No se pudo conectar. Revisá tu conexión a internet e intentá de nuevo.',
      );
    }

    if (res.statusCode == 429) {
      throw const FacebookExtractorException(
        'Facebook limitó las solicitudes por ahora (rate limit). Esperá unos '
        'minutos e intentá de nuevo.',
      );
    }
    if (res.statusCode != 200) {
      throw FacebookExtractorException(
        'No se pudo cargar el enlace (HTTP ${res.statusCode}).',
      );
    }

    final body = res.body;
    if (_looksLikeLoginWall(body)) {
      throw const FacebookExtractorException(
        'Este contenido es privado o requiere haber iniciado sesión. Iniciá '
        'sesión desde el ícono de la app e intentá de nuevo.',
      );
    }

    final videos = _extractVideos(body);
    final items = videos.isNotEmpty ? videos : _extractPhotos(body);

    if (items.isEmpty) {
      throw const FacebookExtractorException(
        'No se encontraron videos ni fotos en ese enlace. Verificá que el '
        'post sea público o que hayas iniciado sesión si es contenido propio.',
      );
    }
    return items;
  }

  // --- Normalización y validación ---

  static const _facebookHosts = {
    'facebook.com',
    'www.facebook.com',
    'm.facebook.com',
    'web.facebook.com',
    'fb.watch',
    'fb.me',
  };

  /// Valida (sin lanzar excepciones) si [rawUrl] parece un enlace de
  /// Facebook. Útil para validar el input en la UI antes de analizar.
  static bool isFacebookUrl(String rawUrl) {
    var u = rawUrl.trim();
    if (u.isEmpty) return false;
    if (!u.startsWith('http://') && !u.startsWith('https://')) {
      u = 'https://$u';
    }
    final uri = Uri.tryParse(u);
    final host = uri?.host.toLowerCase() ?? '';
    return uri != null &&
        (_facebookHosts.contains(host) || host.endsWith('.facebook.com'));
  }

  String _normalizeAndValidate(String rawUrl) {
    final u = rawUrl.trim();
    if (u.isEmpty) {
      throw const FacebookExtractorException('Pegá un enlace de Facebook.');
    }
    if (!isFacebookUrl(u)) {
      throw const FacebookExtractorException(
        'Ese enlace no parece ser de Facebook. Pegá un link de un post, '
        'video, reel o foto (facebook.com, m.facebook.com o fb.watch).',
      );
    }
    final normalized =
        u.startsWith('http://') || u.startsWith('https://') ? u : 'https://$u';
    final uri = Uri.parse(normalized);
    return uri.toString();
  }

  bool _looksLikeLoginWall(String body) {
    final lower = body.toLowerCase();
    return _loginMarkers.any((m) => lower.contains(m.toLowerCase()));
  }

  // --- Cookies de sesión persistidas ---

  Future<void> _loadStoredCookiesIfNeeded() async {
    if (sessionCookies != null && sessionCookies!.isNotEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(cookiesPrefsKey);
      if (raw == null || raw.isEmpty) return;
      sessionCookies = _parseCookieHeader(raw);
    } catch (_) {
      // Sin acceso a shared_preferences (p.ej. en tests puros): seguimos
      // como usuario anónimo.
    }
  }

  Map<String, String> _parseCookieHeader(String raw) {
    final map = <String, String>{};
    for (final part in raw.split(';')) {
      final trimmed = part.trim();
      final idx = trimmed.indexOf('=');
      if (idx <= 0) continue;
      map[trimmed.substring(0, idx)] = trimmed.substring(idx + 1);
    }
    return map;
  }

  // --- Video ---

  List<MediaItem> _extractVideos(String body) {
    final hdRaw = _firstOf(body, _hdVideoPatterns);
    final sdRaw = _firstOf(body, _sdVideoPatterns);
    final hdUrl = hdRaw != null ? _unescape(hdRaw) : null;
    final sdUrl = sdRaw != null ? _unescape(sdRaw) : null;

    final items = <MediaItem>[];
    if (hdUrl != null) {
      items.add(MediaItem(url: hdUrl, type: MediaType.video, quality: 'HD'));
    }
    if (sdUrl != null && sdUrl != hdUrl) {
      items.add(MediaItem(url: sdUrl, type: MediaType.video, quality: 'SD'));
    }
    return items;
  }

  String? _firstOf(String body, List<String> patterns) {
    for (final p in patterns) {
      final m = RegExp(p).firstMatch(body);
      if (m != null) return m.group(1);
    }
    return null;
  }

  // --- Fotos ---

  List<MediaItem> _extractPhotos(String body) {
    final imgs = RegExp(r'<meta property="og:image" content="(.*?)"')
        .allMatches(body)
        .map((m) => m.group(1)!)
        .toList();
    if (imgs.isEmpty) return [];

    if (imgs.length > 1) {
      final widths = RegExp(r'<meta property="og:image:width" content="(\d+)"')
          .allMatches(body)
          .map((m) => int.parse(m.group(1)!))
          .toList();
      if (widths.length == imgs.length) {
        var bestIndex = 0;
        for (var i = 1; i < widths.length; i++) {
          if (widths[i] > widths[bestIndex]) bestIndex = i;
        }
        return [MediaItem(url: _unescape(imgs[bestIndex]), type: MediaType.image)];
      }
    }
    // Sin info de resolución (o una sola imagen): la primera suele ser la
    // principal del post.
    return [MediaItem(url: _unescape(imgs.first), type: MediaType.image)];
  }

  // --- Unescape de URLs embebidas en el HTML/JSON ---

  String _unescape(String raw) {
    var s = raw;
    // \uXXXX -> carácter unicode real
    s = s.replaceAllMapped(RegExp(r'\\u([0-9a-fA-F]{4})'), (m) {
      final code = int.parse(m.group(1)!, radix: 16);
      return String.fromCharCode(code);
    });
    // Barras escapadas
    s = s.replaceAll(r'\/', '/');
    // Entidades HTML comunes
    s = s
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
    // Percent-encoding remanente (%3D, %26, etc.)
    try {
      s = Uri.decodeFull(s);
    } catch (_) {
      // Secuencia % inválida: dejamos el string tal cual.
    }
    return s;
  }
}
