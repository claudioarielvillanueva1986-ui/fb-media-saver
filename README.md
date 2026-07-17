# FB Media Saver

App Android (Flutter) para **descargar videos y fotos de Facebook** pegando el
enlace, con soporte para iniciar sesión y bajar contenido propio. Monetizada con
**Google AdMob** de forma **no invasiva** (un banner discreto + un intersticial
ocasional, y consentimiento UMP/GDPR donde corresponde).

## Estado del proyecto

| Módulo | Estado |
|---|---|
| Estructura del proyecto + andamiaje nativo Android | ✅ Listo |
| UI principal (pegar link, analizar, descargar) | ✅ Listo |
| Servicio de descarga + guardado en galería | ✅ Listo |
| Extractor de medios de Facebook (HD/SD, fotos, cookies) | ✅ Listo, con tests |
| Login por WebView + captura de cookies | ✅ Listo |
| Permisos por versión de Android (13+ vs. anteriores) | ✅ Listo |
| Historial de descargas (abrir/compartir) | ✅ Listo |
| AdMob (banner + intersticial no invasivo + consentimiento UMP) | ✅ Listo con IDs de prueba |
| Ícono y splash | ✅ Listo (placeholder propio, reemplazable) |
| Firma de APK / release | ✅ Documentada abajo |

## Cómo levantar el proyecto

Requisitos: [Flutter](https://docs.flutter.dev/get-started/install) (canal
stable) y el Android SDK (vía Android Studio o `sdkmanager`), con
`ANDROID_HOME`/`ANDROID_SDK_ROOT` configurado.

```bash
# 1) Traer dependencias
flutter pub get

# 2) Análisis estático y tests (el extractor tiene tests con HTML fijado,
#    no necesitan red)
flutter analyze
flutter test

# 3) Correr en un dispositivo/emulador
flutter run

# 4) Compilar el APK debug
flutter build apk --debug
# Queda en build/app/outputs/flutter-apk/app-debug.apk

# 5) Compilar el APK release
flutter build apk --release
# Queda en build/app/outputs/flutter-apk/app-release.apk
```

> El repo ya incluye el andamiaje nativo de Android (`android/`) generado con
> `flutter create`, con el `AndroidManifest.xml`, `applicationId`
> (`com.fbmediasaver.app`) y `minSdk 23` ya configurados. No hace falta
> volver a correr `flutter create` salvo que quieras regenerarlo desde cero.

### CI (GitHub Actions)

`.github/workflows/build.yml` corre `flutter analyze`, `flutter test` y
compila el APK debug en cada push a `main` (o manualmente vía
"workflow_dispatch"), y lo deja disponible como artifact para descargar.

## Configurar AdMob

1. Creá una cuenta en https://admob.google.com y registrá la app.
2. Reemplazá el **App ID** en `android/app/src/main/AndroidManifest.xml`
   (`com.google.android.gms.ads.APPLICATION_ID`).
3. Reemplazá los **ad unit IDs** en `lib/utils/constants.dart`
   (`bannerAdUnitId`, `interstitialAdUnitId`).
4. Mientras desarrollás, dejá los IDs de **prueba** (los que ya vienen) para no
   arriesgar tu cuenta con clics inválidos.
5. La política "no invasiva" (banner discreto, intersticial cada N descargas
   con cooldown) se controla desde `AppConfig` en `lib/utils/constants.dart`.
6. El consentimiento UMP/GDPR se pide automáticamente al iniciar la app
   (`AdsService._gatherConsent`); el botón de privacidad en la pantalla de
   Inicio reabre el formulario de opciones si Google lo requiere para ese
   usuario.

## Ícono y splash

Los assets fuente están en `assets/icon/` y `assets/splash/` (podés
reemplazarlos por tu propio arte, mismo nombre de archivo). Para regenerar el
ícono y el splash nativo después de cambiarlos:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Firmar el APK release

Por defecto, `flutter build apk --release` firma con la clave de **debug**
(sirve para probar, no para publicar). Para firmar con tu clave real:

1. Generá un keystore (una sola vez, guardalo fuera del repo):
   ```bash
   keytool -genkey -v -keystore ~/fb-media-saver-release.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias fbmediasaver
   ```
2. Copiá `android/key.properties.example` a `android/key.properties`
   (este archivo **no se sube al repo**, ya está en `.gitignore`) y completá
   `storePassword`, `keyPassword`, `keyAlias` y `storeFile` con la ruta a tu
   `.jks`.
3. Compilá normalmente:
   ```bash
   flutter build apk --release
   ```
   `android/app/build.gradle.kts` detecta `key.properties` automáticamente y
   firma con esa clave; si no existe, sigue usando la firma debug para no
   romper el build en desarrollo.

**Nunca subas** tu `.jks`/`.keystore` ni `key.properties` al repositorio.

## Aviso legal y de políticas (leer)

- Descargar contenido de Facebook puede violar los **Términos de Servicio** de
  Meta y derechos de autor de terceros. Usá la app solo con contenido **público**
  o **propio**, y con permiso del titular.
- **Google Play** restringe apps cuya función principal es descargar de redes
  sociales; es probable el rechazo. Alternativas de distribución: APK directo,
  tiendas alternativas, tu propia web.
- **AdMob** comparte esa política de contenido. Evaluá redes alternativas
  (Unity Ads, AppLovin) si AdMob rechaza la app.
- Esta app se entrega con fines educativos; el uso y la distribución son
  responsabilidad del desarrollador.

## Licencia

MIT — ver [LICENSE](LICENSE).
