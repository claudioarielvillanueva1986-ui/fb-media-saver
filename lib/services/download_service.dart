import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saver_gallery/saver_gallery.dart';
import '../models/media_item.dart';

/// Descarga un MediaItem y lo guarda en la galería del dispositivo.
/// Reporta progreso 0.0 -> 1.0 mediante el callback onProgress.
class DownloadService {
  final Dio _dio = Dio();

  Future<bool> ensurePermissions() async {
    // En Android 13+ conviene photos/videos; en versiones previas storage.
    final statuses = await [
      Permission.photos,
      Permission.videos,
      Permission.storage,
    ].request();
    return statuses.values.any((s) => s.isGranted);
  }

  Future<String> download(
    MediaItem item, {
    void Function(double progress)? onProgress,
  }) async {
    final ok = await ensurePermissions();
    if (!ok) {
      throw Exception('Se necesitan permisos para guardar en la galería.');
    }

    final tmpDir = await getTemporaryDirectory();
    final filePath = '${tmpDir.path}/${item.suggestedFileName}';

    await _dio.download(
      item.url,
      filePath,
      onReceiveProgress: (received, total) {
        if (total > 0) onProgress?.call(received / total);
      },
    );

    final result = await SaverGallery.saveFile(
      file: filePath,
      name: item.suggestedFileName,
      androidRelativePath: item.type == MediaType.video
          ? 'Movies/FBMediaSaver'
          : 'Pictures/FBMediaSaver',
      androidExistNotSave: false,
    );

    // Limpieza del temporal
    try {
      await File(filePath).delete();
    } catch (_) {}

    if (!result.isSuccess) {
      throw Exception('No se pudo guardar en la galería.');
    }
    return item.suggestedFileName;
  }
}
