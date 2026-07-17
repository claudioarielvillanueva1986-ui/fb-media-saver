# Cómo subir esta base a GitHub

El repo ya está creado (vacío) en:
https://github.com/claudioarielvillanueva1986-ui/fb-media-saver

## Opción rápida (recomendada)
Descomprimí el zip, abrí una terminal dentro de la carpeta `fb_media_saver` y corré:

```bash
git init
git add .
git commit -m "Base inicial: scaffold Flutter + AdMob no invasivo"
git branch -M main
git remote add origin https://github.com/claudioarielvillanueva1986-ui/fb-media-saver.git
git push -u origin main
```

GitHub te pedirá autenticación:
- Usuario: tu usuario de GitHub
- Contraseña: usá un **Personal Access Token** (Settings → Developer settings →
  Personal access tokens → Fine-grained o classic con permiso `repo`).
  La contraseña normal ya no funciona para push.

## Después de subir
1. Cloná el repo (o usá la misma carpeta) y abrí **Claude Code** ahí.
2. Pegá el prompt de `PROMPT_CLAUDE_CODE.md`.
3. Claude Code genera el andamiaje nativo, completa la app y compila el APK.
