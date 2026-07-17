import 'package:http/http.dart' as http;
import '../models/media_item.dart';
import '../utils/constants.dart';

/// Extrae URLs directas de medios a partir de la URL de un post público de
/// Facebook (post, reel o video).
///
/// ESTADO: base funcional / punto de partida. Facebook cambia su HTML seguido,
/// así que Claude Code debe robustecer los patrones. Estrategia general:
///  1) Descargar el HTML de la página (User-Agent de escritorio).
///  2) Buscar patrones "playable_url" / "playable_url_quality_hd" (video) y
///     og:image / imágenes de alta resolución (fotos).
///  3) Deshacer el escape de las URLs (% -> %, \/ -> /).
///
/// Para contenido del usuario logueado, DownloadService usa las cookies de
/// sesión capturadas por el WebView (ver webview_login_screen.dart).
class FacebookExtractor {
  final http.Client _client;
  final Map<String, String>? sessionCookies;

  FacebookExtractor({http.Client? client, this.sessionCookies})
      : _client = client ?? http.Client();

  Future<List<MediaItem>> extract(String postUrl) async {
    final normalized = _normalizeUrl(postUrl);
    final headers = <String, String>{
      'User-Agent': AppConfig.desktopUserAgent,
      'Accept-Language': 'en-US,en;q=0.9',
      if (sessionCookies != null && sessionCookies!.isNotEmpty)
        'Cookie': sessionCookies!.entries
            .map((e) => '${e.key}=${e.value}')
            .join('; '),
    };

    final res = await _client.get(Uri.parse(normalized), headers: headers);
    if (res.statusCode != 200) {
      throw Exception('No se pudo cargar el post (HTTP ${res.statusCode}).');
    }
    final body = res.body;
    final items = <MediaItem>[];

    // --- Video: playable_url_quality_hd tiene prioridad ---
    final hd = _firstMatch(body, RegExp(r'playable_url_quality_hd":"(.*?)"'));
    final sd = _firstMatch(body, RegExp(r'playable_url":"(.*?)"'));
    if (hd != null) {
      items.add(MediaItem(url: _unescape(hd), type: MediaType.video, quality: 'HD'));
    }
    if (sd != null && sd != hd) {
      items.add(MediaItem(url: _unescape(sd), type: MediaType.video, quality: 'SD'));
    }

    // --- Imagen: og:image como respaldo ---
    if (items.isEmpty) {
      final og = _firstMatch(
        body,
        RegExp(r'<meta property="og:image" content="(.*?)"'),
      );
      if (og != null) {
        items.add(MediaItem(url: _unescape(og), type: MediaType.image));
      }
    }

    if (items.isEmpty) {
      throw Exception(
          'No se encontraron medios. Verificá que el post sea público o iniciá sesión.');
    }
    return items;
  }

  String _normalizeUrl(String url) {
    var u = url.trim();
    if (!u.startsWith('http')) u = 'https://$u';
    // Preferir m.facebook.com suele devolver HTML más simple de parsear.
    return u;
  }

  String? _firstMatch(String source, RegExp re) {
    final m = re.firstMatch(source);
    return m?.group(1);
  }

  String _unescape(String s) => s
      .replaceAll(r'\/', '/')
      .replaceAll(r'%', '%')
      .replaceAll(r'/', '/')
      .replaceAll(r'&', '&')
      .replaceAll(r'\\', '');
}
