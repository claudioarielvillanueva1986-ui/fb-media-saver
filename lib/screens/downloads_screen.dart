import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../models/download_history_entry.dart';
import '../models/media_item.dart';
import '../services/history_service.dart';

/// Historial de descargas: lista lo guardado (nombre, tipo, fecha) con
/// opciones para abrir o compartir cada archivo.
class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  List<DownloadHistoryEntry> _entries = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await HistoryService.instance.list();
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  Future<bool> _fileExists(DownloadHistoryEntry entry) =>
      File(entry.path).exists();

  Future<void> _open(DownloadHistoryEntry entry) async {
    if (!await _fileExists(entry)) {
      _snack('El archivo ya no está disponible en este dispositivo.');
      return;
    }
    await OpenFilex.open(entry.path);
  }

  Future<void> _share(DownloadHistoryEntry entry) async {
    if (!await _fileExists(entry)) {
      _snack('El archivo ya no está disponible en este dispositivo.');
      return;
    }
    await SharePlus.instance.share(ShareParams(files: [XFile(entry.path)]));
  }

  Future<void> _remove(DownloadHistoryEntry entry) async {
    await HistoryService.instance.remove(entry);
    _load();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de descargas')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _entries.length,
                    itemBuilder: (context, index) =>
                        _buildTile(_entries[index]),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download_done_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Todavía no descargaste nada.\n'
                    'Los videos y fotos que descargues van a aparecer acá.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTile(DownloadHistoryEntry entry) {
    final isVideo = entry.type == MediaType.video;
    return Card(
      child: ListTile(
        leading: Icon(isVideo ? Icons.videocam : Icons.image),
        title: Text(entry.fileName, overflow: TextOverflow.ellipsis),
        subtitle: Text(_formatDate(entry.date)),
        onTap: () => _open(entry),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Compartir',
              icon: const Icon(Icons.share_outlined),
              onPressed: () => _share(entry),
            ),
            IconButton(
              tooltip: 'Eliminar del historial',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _remove(entry),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} '
        '${two(date.hour)}:${two(date.minute)}';
  }
}
