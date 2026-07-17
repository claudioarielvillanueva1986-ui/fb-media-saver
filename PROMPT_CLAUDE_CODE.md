# Prompt para Claude Code — FB Media Saver

Copiá y pegá el bloque de abajo en Claude Code (dentro de la carpeta del repo ya
clonado). Está pensado para que Claude Code complete la app sobre la base que ya
existe. Podés ejecutarlo entero o por secciones.

---

## PROMPT (pegar en Claude Code)

```
Sos un ingeniero senior de Flutter/Android. Trabajás sobre este repositorio, que
ya tiene una BASE del proyecto "FB Media Saver": una app para descargar videos y
fotos de Facebook (contenido público y del usuario logueado), monetizada con
Google AdMob de forma NO invasiva. Leé primero CLAUDE.md y README.md para
entender la arquitectura y las convenciones. Respetá el código y la estructura
existentes; extendé, no reescribas sin motivo.

OBJETIVO GENERAL
Dejar la app compilable y funcional, generando el APK, con estas características:
1. Pegar un enlace de Facebook (post, /watch, reel, /share, foto, o m.facebook)
   y detectar automáticamente los medios descargables.
2. Descargar video (HD/SD si están disponibles) y fotos a la galería, con barra
   de progreso, y guardarlas en carpetas propias (Movies/FBMediaSaver,
   Pictures/FBMediaSaver).
3. Login opcional del usuario dentro de un WebView de Facebook para poder
   descargar contenido propio/privado; persistir cookies de sesión y usarlas
   tanto en el extractor como en las descargas. Nunca pedir ni guardar la
   contraseña.
4. AdMob no invasivo: banner discreto abajo + intersticial solo cada N descargas
   con cooldown (respetar AppConfig). Nada de pop-ups molestos ni al abrir.

TAREAS CONCRETAS (hacelas en orden, verificando que compila en cada paso)

A) Andamiaje y compilación
   - Ejecutá: flutter create . --platforms=android --project-name fb_media_saver
     conservando el AndroidManifest.xml del repo (no lo pises; si create genera
     otro, fusioná manteniendo permisos y el meta-data de AdMob).
   - flutter pub get y resolvé cualquier conflicto de versiones.
   - Ajustá android/app/build.gradle: minSdkVersion 23 (o el que exija
     google_mobile_ads / flutter_inappwebview), compileSdk y targetSdk actuales,
     y applicationId (ej: com.fbmediasaver.app).
   - Asegurá que `flutter build apk --debug` compile sin errores.

B) Extractor robusto (lib/services/facebook_extractor.dart)
   - Soportá y normalizá estas formas de URL: facebook.com/watch,
     /reel/, /share/v/, /videos/, /photo, fb.watch, m.facebook.com y
     web.facebook.com. Extraé el id cuando aplique.
   - Para video: buscá playable_url_quality_hd y playable_url; también probá
     patrones "browser_native_hd_url" / "browser_native_sd_url" y hd_src / sd_src.
     Devolvé HD y SD como opciones separadas cuando existan.
   - Para fotos: og:image y, si hay varias resoluciones, elegí la mayor.
   - Deshacé correctamente el escape de las URLs (\uXXXX, \/, &amp;, %XX).
   - Si hay cookies de sesión guardadas (shared_preferences, clave 'fb_cookies'),
     incluílas en el header Cookie de las requests.
   - Manejo de errores claro y en español: post privado, sin medios, rate limit.
   - Escribí tests unitarios con HTML de ejemplo fijado (fixtures) para no
     depender de la red.

C) Descargas e historial
   - Integrá las cookies en download_service para contenido privado.
   - Creá una pantalla "Historial" (lib/screens/downloads_screen.dart) que liste
     lo descargado (persistido con shared_preferences: nombre, tipo, fecha, ruta)
     con opciones de abrir y compartir (open_filex / share_plus).
   - Agregá navegación (BottomNavigationBar o Drawer) entre Inicio e Historial.

D) Permisos
   - Manejá permisos por versión de Android (13+ READ_MEDIA_*, <=12 storage) con
     permission_handler, mostrando un diálogo si el usuario los rechaza.

E) AdMob no invasivo
   - Verificá que el banner cargue solo cuando hay conexión y que no empuje la
     UI de forma molesta.
   - Intersticial: respetá interstitialEveryNDownloads y interstitialCooldown.
   - Agregá manejo del consentimiento (UMP / GDPR) con
     google_mobile_ads ConsentInformation para EEA (mostrar formulario si aplica).

F) Pulido
   - Ícono de app y splash (podés usar flutter_launcher_icons y
     flutter_native_splash; agregalos a dev_dependencies y documentá el comando).
   - Estados vacíos y de carga prolijos; tema claro/oscuro coherente (azul FB).
   - Validación del input de URL (mostrar error si no es de Facebook).

G) Documentación y release
   - Actualizá README con los pasos finales de build.
   - Documentá cómo firmar el APK release (keystore + key.properties) SIN subir
     secretos al repo.
   - Dejá `flutter build apk --release` funcionando y explicá dónde queda el APK.

REGLAS
- Comentarios y textos de UI en español.
- No introduzcas dependencias innecesarias; si agregás alguna, justificá y
  actualizá pubspec.
- No hardcodees IDs reales de AdMob: dejá los de prueba y documentá dónde
  cambiarlos.
- Hacé commits pequeños y descriptivos por cada bloque (A, B, C, ...).
- Al terminar cada bloque, corré el análisis estático (flutter analyze) y los
  tests, y arreglá lo que falle.

ENTREGABLE FINAL
- App compilando en debug y release.
- Extractor con tests pasando.
- Historial funcionando.
- AdMob no invasivo verificado.
- README actualizado con instrucciones de build y firma.
Empezá por el bloque A y avanzá secuencialmente, mostrándome un resumen al
completar cada bloque.
```

---

## Notas de uso

- **Legal/políticas:** revisá la sección de aviso legal del README antes de
  publicar. Google Play y AdMob restringen este tipo de apps.
- **AdMob real:** solo cambiá los IDs de prueba por los reales cuando vayas a
  publicar, para evitar suspensiones por clics inválidos durante el desarrollo.
- **Iterar:** si algo del extractor deja de funcionar (Facebook cambia el HTML
  seguido), volvé a pedirle a Claude Code que actualice los patrones del bloque B
  con un ejemplo real del HTML.
