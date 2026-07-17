# Contexto para Claude Code — FB Media Saver

App Flutter (Android) para descargar videos/fotos de Facebook, monetizada con
AdMob de forma no invasiva.

## Arquitectura actual

- `lib/main.dart` — entrypoint, inicializa AdMob (con consentimiento UMP), tema Material 3.
- `lib/utils/constants.dart` — config central (AdMob IDs de prueba, política de ads, user-agent).
- `lib/models/media_item.dart` — modelo de medio descargable.
- `lib/models/download_history_entry.dart` — registro del historial de descargas.
- `lib/services/facebook_extractor.dart` — extrae URLs de medios (video HD/SD, fotos) del HTML del post; usa cookies de sesión si hay. Ver tests en `test/services/`.
- `lib/services/download_service.dart` — descarga con dio (con cookies), guarda en galería y deja copia propia para el Historial. Permisos por versión de Android.
- `lib/services/history_service.dart` — persiste el historial de descargas (shared_preferences).
- `lib/services/ads_service.dart` — banner + intersticial no invasivo + consentimiento UMP/GDPR.
- `lib/screens/main_navigation_screen.dart` — navegación inferior Inicio/Historial.
- `lib/screens/home_screen.dart` — UI: pegar link → analizar → descargar.
- `lib/screens/downloads_screen.dart` — Historial: abrir/compartir descargas.
- `lib/screens/webview_login_screen.dart` — login por WebView + captura de cookies.
- `lib/widgets/banner_ad_widget.dart` — banner reutilizable.
- `android/app/src/main/AndroidManifest.xml` — permisos + AdMob App ID.
- `android/app/src/main/kotlin/.../MainActivity.kt` — applicationId `com.fbmediasaver.app`, minSdk 23.

## Convenciones

- Comentarios y textos de UI en español.
- Estado con `provider` (o `setState` en pantallas simples).
- Nada de contraseñas: el login es dentro del WebView real de Facebook; solo se
  persisten cookies de sesión con `shared_preferences`.
- Anuncios: banner discreto abajo; intersticial solo cada N descargas y con
  cooldown (ver `AppConfig`). No romper esta política "no invasiva".

## Antes de compilar

El repo ya incluye el andamiaje nativo de Android (generado con
`flutter create . --platforms=android --project-name fb_media_saver`,
conservando el `AndroidManifest.xml` original). Alcanza con `flutter pub get`.

## Pendientes / ideas futuras

1. Soporte álbumes/carruseles de fotos (descargar todas las fotos de un
   álbum, no solo la principal).
2. iOS (hoy el foco es Android; `flutter_launcher_icons`/`native_splash`
   están configurados solo para `android: true`).
3. Firma real de release: ver README, sección "Firmar el APK release"
   (`android/key.properties.example`).
