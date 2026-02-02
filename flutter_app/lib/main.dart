import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

const String defaultServerUrl = 'http://10.0.2.2:8000';

void main() {
  runApp(const YtDownloaderApp());
}

class YtDownloaderApp extends StatelessWidget {
  const YtDownloaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.redAccent);
    return MaterialApp(
      title: 'YT Downloader Pro',
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
      ),
      home: const DownloadHomePage(),
    );
  }
}

class DownloadHomePage extends StatefulWidget {
  const DownloadHomePage({super.key});

  @override
  State<DownloadHomePage> createState() => _DownloadHomePageState();
}

class _DownloadHomePageState extends State<DownloadHomePage> {
  final _urlController = TextEditingController();
  final _serverController = TextEditingController(text: defaultServerUrl);
  Timer? _pollTimer;

  String _formatType = 'audio';
  String _status = 'idle';
  double _progress = 0;
  String? _taskId;
  String? _filename;
  String? _savedPath;
  String? _error;
  bool _isDownloading = false;

  @override
  void dispose() {
    _pollTimer?.cancel();
    _urlController.dispose();
    _serverController.dispose();
    super.dispose();
  }

  Uri _buildUri(String path, [Map<String, String>? query]) {
    var base = _serverController.text.trim();
    if (base.isEmpty) {
      base = defaultServerUrl;
    }
    if (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    final uri = Uri.parse('$base$path');
    return query == null ? uri : uri.replace(queryParameters: query);
  }

  Future<void> _startDownload() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'Te rog introdu un link video.');
      return;
    }

    setState(() {
      _error = null;
      _status = 'starting';
      _progress = 0;
      _taskId = null;
      _filename = null;
      _savedPath = null;
      _isDownloading = true;
    });

    try {
      final uri = _buildUri('/api/download', {
        'url': url,
        'format_type': _formatType,
      });

      final response = await http.post(uri);
      if (response.statusCode != 200) {
        throw Exception('Eroare server: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final taskId = data['task_id']?.toString();
      if (taskId == null || taskId.isEmpty) {
        throw Exception('Task ID invalid.');
      }

      setState(() {
        _taskId = taskId;
        _status = 'pending';
      });

      _startPolling();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _status = 'error';
        _isDownloading = false;
      });
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _pollProgress();
    });
  }

  Future<void> _pollProgress() async {
    final taskId = _taskId;
    if (taskId == null) return;

    try {
      final uri = _buildUri('/api/progress/$taskId');
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('Nu pot citi progresul.');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['status']?.toString() ?? 'pending';
      final progress = (data['progress'] ?? 0).toDouble();
      final error = data['error']?.toString();
      final filename = data['filename']?.toString();

      setState(() {
        _status = status;
        _progress = progress;
        if (filename != null && filename.isNotEmpty) {
          _filename = filename;
        }
        if (error != null && error.isNotEmpty) {
          _error = error;
        }
      });

      if (status == 'completed') {
        _pollTimer?.cancel();
        await _downloadFile();
      } else if (status == 'error') {
        _pollTimer?.cancel();
        setState(() => _isDownloading = false);
      }
    } catch (e) {
      _pollTimer?.cancel();
      setState(() {
        _error = e.toString();
        _status = 'error';
        _isDownloading = false;
      });
    }
  }

  Future<void> _downloadFile() async {
    final taskId = _taskId;
    if (taskId == null) return;

    setState(() => _status = 'downloading_file');

    try {
      final uri = _buildUri('/api/download/$taskId');
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('Nu pot descărca fișierul.');
      }

      final dir = await getApplicationDocumentsDirectory();
      final name = _filename ?? 'download_$taskId';
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(response.bodyBytes);

      setState(() {
        _savedPath = file.path;
        _status = 'saved';
        _progress = 100;
        _isDownloading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _status = 'error';
        _isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusText = switch (_status) {
      'idle' => 'Introdu un link și apasă Descarcă',
      'starting' => 'Inițializare...',
      'pending' => 'Aștept răspuns...',
      'downloading' => 'Se descarcă... ${_progress.toStringAsFixed(0)}%',
      'processing' => 'Se procesează...',
      'downloading_file' => 'Se salvează fișierul...',
      'saved' => 'Gata! Fișier salvat.',
      'error' => 'Eroare la descărcare.',
      _ => _status,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('YT Downloader Pro'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Server URL',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _serverController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'http://10.0.2.2:8000',
                helperText:
                    'Emulator: http://10.0.2.2:8000 | Telefon: http://<IP-PC>:8000',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            Text(
              'Link video',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'https://youtu.be/VIDEO_ID',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            Text(
              'Format',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Audio'),
                    value: 'audio',
                    groupValue: _formatType,
                    onChanged: _isDownloading
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() => _formatType = value);
                          },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Video'),
                    value: 'video',
                    groupValue: _formatType,
                    onChanged: _isDownloading
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() => _formatType = value);
                          },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isDownloading ? null : _startDownload,
                icon: const Icon(Icons.download),
                label: const Text('Descarcă'),
              ),
            ),
            const SizedBox(height: 16),
            if (_isDownloading || _progress > 0)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: _progress == 0 ? null : _progress / 100,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            Text(
              statusText,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            if (_savedPath != null) ...[
              const SizedBox(height: 8),
              Text('Fișier salvat: $_savedPath'),
            ],
          ],
        ),
      ),
    );
  }
}
