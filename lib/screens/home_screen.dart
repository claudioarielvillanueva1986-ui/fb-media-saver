import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/download_history_entry.dart';
import '../models/media_item.dart';
import '../services/ads_service.dart';
import '../services/download_service.dart';
import '../services/facebook_extractor.dart';
import '../services/history_service.dart';
import '../widgets/banner_ad_widget.dart';
import 'webview_login_screen.dart';

/// Pantalla principal: pegar link -> extraer -> elegir calidad -> descargar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _urlController = TextEditingController();
  final _extractor = FacebookExtractor();
  final _downloader = DownloadService();

  bool _loading = false;
  bool _hasSearched = false;
  double _progress = 0;
  String? _status;
  String? _urlError;
  List<MediaItem> _results = [];

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      setState(() {
        _urlController.text = data!.text!.trim();
        _urlError = null;
      });
    }
  }

  Future<void> _extract() async {
    FocusScope.of(context).unfocus();
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    if (!FacebookExtractor.isFacebookUrl(url)) {
      setState(() => _urlError =
          'Ese enlace no parece ser de Facebook. Pegá un link de un post, '
          'video, reel o foto.');
      return;
    }

    setState(() {
      _loading = true;
      _hasSearched = true;
      _status = 'Analizando el enlace...';
      _urlError = null;
      _results = [];
    });
    try {
      final items = await _extractor.extract(url);
      setState(() => _results = items);
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() {
        _loading = false;
        _status = null;
      });
    }
  }

  Future<void> _download(MediaItem item) async {
    setState(() {
      _loading = true;
      _progress = 0;
      _status = 'Descargando...';
    });
    try {
      final result = await _downloader.download(item, onProgress: (p) {
        setState(() => _progress = p);
      });
      await HistoryService.instance.add(DownloadHistoryEntry(
        fileName: result.fileName,
        type: item.type,
        date: DateTime.now(),
        path: result.path,
      ));
      AdsService.instance.onDownloadCompleted();
      _snack('¡Guardado en la galería!');
    } on PermissionDeniedException catch (e) {
      _showPermissionDialog(e.message);
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() {
        _loading = false;
        _status = null;
      });
    }
  }

  void _showPermissionDialog(String message) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permisos necesarios'),
        content: Text('$message\n\nActivalos desde los ajustes de la app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Abrir ajustes'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FB Media Saver'),
        actions: [
          IconButton(
            tooltip: 'Opciones de privacidad',
            icon: const Icon(Icons.privacy_tip_outlined),
            onPressed: () => AdsService.instance.showPrivacyOptionsIfRequired(),
          ),
          IconButton(
            tooltip: 'Iniciar sesión en Facebook',
            icon: const Icon(Icons.login),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WebViewLoginScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Pegá el enlace de un video o foto público de Facebook',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _urlController,
                  onChanged: (_) {
                    if (_urlError != null) setState(() => _urlError = null);
                  },
                  onSubmitted: (_) => _loading ? null : _extract(),
                  decoration: InputDecoration(
                    hintText: 'https://www.facebook.com/...',
                    border: const OutlineInputBorder(),
                    errorText: _urlError,
                    errorMaxLines: 2,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.content_paste),
                      tooltip: 'Pegar',
                      onPressed: _pasteFromClipboard,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _loading ? null : _extract,
                  icon: const Icon(Icons.search),
                  label: const Text('Analizar'),
                ),
                if (_loading) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                  ),
                  if (_status != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_status!),
                    ),
                ],
                const SizedBox(height: 24),
                if (_results.isNotEmpty)
                  ..._results.map(_resultTile)
                else if (!_loading)
                  _buildEmptyState(),
              ],
            ),
          ),
          const SafeArea(child: BannerAdWidget()),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final icon = _hasSearched ? Icons.search_off : Icons.link;
    final text = _hasSearched
        ? 'No hay resultados para mostrar todavía.'
        : 'Pegá el enlace de un post, reel, video o foto pública de '
            'Facebook y tocá "Analizar" para ver qué se puede descargar.';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(icon, size: 56, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ],
      ),
    );
  }

  Widget _resultTile(MediaItem item) {
    final isVideo = item.type == MediaType.video;
    return Card(
      child: ListTile(
        leading: Icon(isVideo ? Icons.videocam : Icons.image),
        title: Text(isVideo ? 'Video' : 'Foto'),
        subtitle: item.quality != null ? Text('Calidad: ${item.quality}') : null,
        trailing: FilledButton(
          onPressed: _loading ? null : () => _download(item),
          child: const Text('Descargar'),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}
