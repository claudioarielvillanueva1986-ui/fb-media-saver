import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/media_item.dart';
import 'facebook_extractor.dart' show FacebookExtractor;

/// Se necesita el permiso de galería/almacenamiento y el usuario lo negó.
class PermissionDeniedException implements Exception {
  final String message;
  const PermissionDeniedException(this.message);

  @override
  String toString() => message;
}

/// Resultado de una descarga: nombre de archivo y ruta local propia (para
/// poder abrir/compartir desde el Historial más adelante).
class DownloadResult {
  final String fileName;
  final String path;
  const DownloadResult({required this.fileName, required this.path});
}

/// Descarga un [MediaItem], lo guarda en la galería del dispositivo y deja
/// además una copia propia en el almacenamiento de la app (para el
/// Historial, ya que la galería usa MediaStore y no siempre devuelve una
/// ruta de archivo utilizable). Reporta progreso 0.0 -> 1.0.
class DownloadService {
  final Dio _dio = Dio();

  Future<bool> ensurePermissions() async {
    if (!Platform.isAndroid) return true;

    final sdkInt = await _androidSdkInt();
    // Android 13+ (API 33): permisos granulares de fotos/videos.
    // Android 12 y anteriores: permiso clásico de almacenamiento.
    final perms = sdkInt >= 33
        ? [Permission.photos, Permission.videos]
        : [Permission.storage];

    final statuses = await perms.request();
    return statuses.values.any((s) => s.isGranted);
  }

  Future<int> _androidSdkInt() async {
    final info = await DeviceInfoPlugin().androidInfo;
    return info.version.sdkInt;
  }

  Future<DownloadResult> download(
    MediaItem item, {
    void Function(double progress)? onProgress,
    Map<String, String>? cookies,
  }) async {
    final ok = await ensurePermissions();
    if (!ok) {
      throw const PermissionDeniedException(
        'Se necesitan permisos de fotos/videos o almacenamiento para guardar '
        'en la galería.',
      );
    }

    final cookieHeader = await _resolveCookieHeader(cookies);
    final fileName = item.suggestedFileName;
    final tmpDir = await getTemporaryDirectory();
    final tmpPath = '${tmpDir.path}/$fileName';

    await _dio.download(
      item.url,
      tmpPath,
      options: cookieHeader == null
          ? null
          : Options(headers: {'Cookie': cookieHeader}),
      onReceiveProgress: (received, total) {
        if (total > 0) onProgress?.call(received / total);
      },
    );

    final galleryResult = await SaverGallery.saveFile(
      filePath: tmpPath,
      fileName: fileName,
      androidRelativePath: item.type == MediaType.video
          ? 'Movies/FBMediaSaver'
          : 'Pictures/FBMediaSaver',
      skipIfExists: false,
    );
    if (!galleryResult.isSuccess) {
      try {
        await File(tmpPath).delete();
      } catch (_) {}
      throw Exception('No se pudo guardar en la galería.');
    }

    // Copia propia para el Historial (abrir/compartir).
    final historyDir = await _historyDir();
    final historyPath = '${historyDir.path}/$fileName';
    await File(tmpPath).copy(historyPath);

    try {
      await File(tmpPath).delete();
    } catch (_) {}

    return DownloadResult(fileName: fileName, path: historyPath);
  }

  /// Usa las cookies pasadas explícitamente o, si no hay, las guardadas por
  /// el login (mismo mecanismo que [FacebookExtractor]), para poder bajar
  /// medios de contenido privado del usuario.
  Future<String?> _resolveCookieHeader(Map<String, String>? cookies) async {
    if (cookies != null && cookies.isNotEmpty) {
      return cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(FacebookExtractor.cookiesPrefsKey);
    } catch (_) {
      return null;
    }
  }

  Future<Directory> _historyDir() async {
    Directory? dir;
    try {
      dir = await getExternalStorageDirectory();
    } catch (_) {
      // No disponible (p.ej. iOS): usamos el directorio de documentos.
    }
    dir ??= await getApplicationDocumentsDirectory();
    final historyDir = Directory('${dir.path}/FBMediaSaver');
    if (!await historyDir.exists()) {
      await historyDir.create(recursive: true);
    }
    return historyDir;
  }
}
