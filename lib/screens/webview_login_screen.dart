import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

/// Login del usuario en Facebook mediante WebView.
///
/// Tras iniciar sesión, capturamos las cookies de sesión (c_user, xs, etc.)
/// para poder descargar contenido propio/privado del usuario. Las cookies se
/// guardan localmente con shared_preferences.
///
/// NOTA: No pedimos ni almacenamos la contraseña; el usuario se autentica en
/// la web real de Facebook dentro del WebView. Solo persistimos las cookies.
class WebViewLoginScreen extends StatefulWidget {
  const WebViewLoginScreen({super.key});

  @override
  State<WebViewLoginScreen> createState() => _WebViewLoginScreenState();
}

class _WebViewLoginScreenState extends State<WebViewLoginScreen> {
  final _cookieManager = CookieManager.instance();
  bool _saving = false;

  Future<void> _captureCookies(String url) async {
    setState(() => _saving = true);
    final cookies = await _cookieManager.getCookies(
      url: WebUri('https://facebook.com'),
    );
    final map = {for (final c in cookies) c.name: c.value.toString()};
    // c_user + xs son señales de sesión iniciada.
    if (map.containsKey('c_user') && map.containsKey('xs')) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'fb_cookies',
        map.entries.map((e) => '${e.key}=${e.value}').join('; '),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesión guardada.')),
        );
        Navigator.pop(context, true);
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar sesión en Facebook'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(AppConfig.fbMobileHome)),
        initialSettings: InAppWebViewSettings(
          userAgent: AppConfig.desktopUserAgent,
          javaScriptEnabled: true,
        ),
        onLoadStop: (controller, url) async {
          if (url == null) return;
          // Al volver al home tras loguearse, intentamos capturar cookies.
          await _captureCookies(url.toString());
        },
      ),
    );
  }
}
