import 'media_item.dart';

/// Un registro del historial de descargas (persistido con shared_preferences).
class DownloadHistoryEntry {
  final String fileName;
  final MediaType type;
  final DateTime date;

  /// Ruta local del archivo (copia propia de la app, no la de la galería:
  /// la galería usa MediaStore y no siempre expone una ruta de archivo
  /// directa para "abrir"/"compartir").
  final String path;

  const DownloadHistoryEntry({
    required this.fileName,
    required this.type,
    required this.date,
    required this.path,
  });

  Map<String, dynamic> toJson() => {
        'fileName': fileName,
        'type': type.name,
        'date': date.toIso8601String(),
        'path': path,
      };

  factory DownloadHistoryEntry.fromJson(Map<String, dynamic> json) =>
      DownloadHistoryEntry(
        fileName: json['fileName'] as String,
        type: MediaType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => MediaType.unknown,
        ),
        date: DateTime.parse(json['date'] as String),
        path: json['path'] as String,
      );
}
