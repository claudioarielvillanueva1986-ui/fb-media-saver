# FB Media Saver

App Android (Flutter) para **descargar videos y fotos de Facebook** pegando el
enlace, con soporte para iniciar sesión y bajar contenido propio. Monetizada con
**Google AdMob** de forma **no invasiva** (un banner discreto + un intersticial
ocasional).

> ⚠️ Esto es una **base / scaffold**. La lógica de extracción y varias piezas se
> completan con Claude Code usando el prompt de `PROMPT_CLAUDE_CODE.md`.

## Estado del proyecto

| Módulo | Estado |
|---|---|
| Estructura del proyecto | ✅ Base lista |
| UI principal (pegar link, analizar, descargar) | ✅ Base funcional |
| Servicio de descarga + guardado en galería | ✅ Base funcional |
| Extractor de medios de Facebook | 🟡 Base (robustecer con Claude Code) |
| Login por WebView + captura de cookies | 🟡 Base (validar flujo) |
| AdMob (banner + intersticial no invasivo) | ✅ Base con IDs de prueba |
| Historial de descargas | ⬜ Pendiente (Claude Code) |
| Ícono, splash, tema | ⬜ Pendiente (Claude Code) |
| Firma de APK / release | ⬜ Pendiente |

## Cómo levantar el proyecto

Este repo contiene la lógica de la app (`lib/`), el manifest de Android y la
config. Para tener un proyecto Flutter **completo y compilable**, generá el
andamiaje nativo sobre esta base:

```bash
# 1) Instalar Flutter (https://docs.flutter.dev/get-started/install)
flutter --version

# 2) Generar carpetas nativas SIN pisar lib/ ni pubspec
flutter create . --platforms=android --project-name fb_media_saver

# 3) Traer dependencias
flutter pub get

# 4) Correr en un dispositivo/emulador
flutter run

# 5) Compilar el APK release
flutter build apk --release
# El APK queda en build/app/outputs/flutter-apk/app-release.apk
```

> Si `flutter create` te pregunta por sobrescribir `AndroidManifest.xml`,
> conservá el de este repo (tiene los permisos y el AdMob App ID).

## Configurar AdMob

1. Creá una cuenta en https://admob.google.com y registrá la app.
2. Reemplazá el **App ID** en `android/app/src/main/AndroidManifest.xml`
   (`com.google.android.gms.ads.APPLICATION_ID`).
3. Reemplazá los **ad unit IDs** en `lib/utils/constants.dart`
   (`bannerAdUnitId`, `interstitialAdUnitId`).
4. Mientras desarrollás, dejá los IDs de **prueba** (los que ya vienen) para no
   arriesgar tu cuenta con clics inválidos.

## Aviso legal y de políticas (leer)

- Descargar contenido de Facebook puede violar los **Términos de Servicio** de
  Meta y derechos de autor de terceros. Usá la app solo con contenido **público**
  o **propio**, y con permiso del titular.
- **Google Play** restringe apps cuya función principal es descargar de redes
  sociales; es probable el rechazo. Alternativas de distribución: APK directo,
  tiendas alternativas, tu propia web.
- **AdMob** comparte esa política de contenido. Evaluá redes alternativas
  (Unity Ads, AppLovin) si AdMob rechaza la app.
- Esta base se entrega con fines educativos; el uso y la distribución son
  responsabilidad del desarrollador.

## Licencia

MIT — ver [LICENSE](LICENSE).
