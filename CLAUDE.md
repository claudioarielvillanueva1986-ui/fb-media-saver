# Contexto para Claude Code — FB Media Saver

App Flutter (Android) para descargar videos/fotos de Facebook, monetizada con
AdMob de forma no invasiva.

## Arquitectura actual

- `lib/main.dart` — entrypoint, inicializa AdMob, tema Material 3.
- `lib/utils/constants.dart` — config central (AdMob IDs de prueba, política de ads, user-agent).
- `lib/models/media_item.dart` — modelo de medio descargable.
- `lib/services/facebook_extractor.dart` — extrae URLs de medios del HTML del post. **Robustecer.**
- `lib/services/download_service.dart` — descarga con dio + guarda en galería.
- `lib/services/ads_service.dart` — banner + intersticial con reglas no invasivas.
- `lib/screens/home_screen.dart` — UI: pegar link → analizar → descargar.
- `lib/screens/webview_login_screen.dart` — login por WebView + captura de cookies.
- `lib/widgets/banner_ad_widget.dart` — banner reutilizable.
- `android/app/src/main/AndroidManifest.xml` — permisos + AdMob App ID.

## Convenciones

- Comentarios y textos de UI en español.
- Estado con `provider` (o `setState` en pantallas simples).
- Nada de contraseñas: el login es dentro del WebView real de Facebook; solo se
  persisten cookies de sesión con `shared_preferences`.
- Anuncios: banner discreto abajo; intersticial solo cada N descargas y con
  cooldown (ver `AppConfig`). No romper esta política "no invasiva".

## Antes de compilar

El repo trae `lib/`, el manifest y la config, pero NO las carpetas nativas.
Correr `flutter create . --platforms=android --project-name fb_media_saver`
(conservando el AndroidManifest del repo) y luego `flutter pub get`.

## Pendientes principales

1. Robustecer `FacebookExtractor` (reels, /watch, /share, /photo, fotos HD, álbumes).
2. Integrar cookies del WebView en el extractor y el download_service.
3. Pantalla de historial de descargas.
4. Ícono, splash y pulido de tema.
5. Manejo de errores y estados vacíos.
6. Firma de release y documentación de build del APK.
