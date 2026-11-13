import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const ScreenshotHelperApp());
}

class WishRow {
  final int rowNumber; // 1..100
  final String name;
  final String price;
  final String brand;
  final String url;

  const WishRow({
    required this.rowNumber,
    required this.name,
    required this.price,
    required this.brand,
    required this.url,
  });
}

class ScreenshotHelperApp extends StatelessWidget {
  const ScreenshotHelperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Toy Appeal Screenshot Helper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const ScreenshotWorkflowPage(),
    );
  }
}

class ScreenshotWorkflowPage extends StatefulWidget {
  const ScreenshotWorkflowPage({super.key});

  @override
  State<ScreenshotWorkflowPage> createState() => _ScreenshotWorkflowPageState();
}

class _ScreenshotWorkflowPageState extends State<ScreenshotWorkflowPage> {
  Directory? _santaRoot;
  List<WishRow> _items = [];
  int _currentIndex = 0; // 0-based into _items

  bool _watchClipboardAndDirs = true;
  bool _proposeCropBeforeSave = false;
  bool _autoOpenNextUrl = true;

  Timer? _pollTimer;
  bool _busyPolling = false;
  final Set<String> _seenDigests = {};
  DateTime _lastSeenFileTime = DateTime.now();

  // Pending image for in-app crop proposal mode (or "Edit Last" crop):
  ui.Image? _pendingDecodedImage;
  int? _pendingTargetRowNum; // rowNumber this crop will save to
  bool _advanceAfterCrop = true;

  // Normalized crop rect [0..1] (default cuts out browser tabs & Amazon top bar,
  // framing product image on the left + title & price on the right).
  Rect _normalizedCrop = const Rect.fromLTWH(0.05, 0.14, 0.82, 0.70);

  int? _lastSavedRowNum;
  Uint8List? _lastSavedBytes;
  String _statusMessage = 'Initializing...';
  bool _runningGenerateHashes = false;

  final FocusNode _keyboardFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pendingDecodedImage?.dispose();
    _keyboardFocus.dispose();
    super.dispose();
  }

  Directory? _locateSantaRoot() {
    var dir = Directory.current.absolute;
    for (var i = 0; i < 5; i++) {
      final pubspec = File('${dir.path}/pubspec.yaml');
      if (pubspec.existsSync() &&
          pubspec.readAsStringSync().contains('name: santa')) {
        return dir;
      }
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }
    return null;
  }

  Directory get _rawScreenshotsDir =>
      Directory('${_santaRoot!.path}/data/raw_screenshots');

  static const _exts = ['png', 'webp', 'jpg', 'jpeg'];

  File? _existingScreenshotFile(int rowNum) {
    final dir = _rawScreenshotsDir;
    if (!dir.existsSync()) return null;
    for (final base in [
      '$rowNum',
      rowNum.toString().padLeft(2, '0'),
      rowNum.toString().padLeft(3, '0'),
    ]) {
      for (final ext in _exts) {
        final f = File('${dir.path}/$base.$ext');
        if (f.existsSync() && f.lengthSync() > 0) return f;
      }
    }
    return null;
  }

  bool _isRowDone(int idx) {
    final item = _items[idx];
    if (_existingScreenshotFile(item.rowNumber) != null) return true;
    // Also count duplicate URLs where an earlier row already has a screenshot.
    for (var j = 0; j < idx; j++) {
      if (_items[j].url == item.url &&
          _existingScreenshotFile(_items[j].rowNumber) != null) {
        return true;
      }
    }
    return false;
  }

  Future<void> _initAll() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    _santaRoot = _locateSantaRoot();
    await _baselineCurrentClipboardAndFiles();
    _loadTsv();
    _pollTimer = Timer.periodic(
      const Duration(milliseconds: 450),
      (_) => _pollForNewScreenshot(),
    );
  }

  void _loadTsv() {
    if (_santaRoot == null) {
      setState(() {
        _statusMessage = 'Could not locate santa repo root.';
      });
      return;
    }
    final tsvFile = File('${_santaRoot!.path}/data/input.tsv');
    if (!tsvFile.existsSync()) {
      setState(() {
        _items = [];
        _statusMessage =
            'Missing ${tsvFile.path}. Copy it from Cloudtop or export from Sheets, then click Reload.';
      });
      return;
    }

    _rawScreenshotsDir.createSync(recursive: true);
    final lines = const LineSplitter()
        .convert(tsvFile.readAsStringSync())
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (lines.length < 2) {
      setState(() {
        _items = [];
        _statusMessage = 'data/input.tsv is empty.';
      });
      return;
    }

    final headers = lines.first.split('\t').map((h) => h.trim()).toList();
    int colIndex(String name) => headers.indexOf(name);
    final nameCol = colIndex('name');
    final priceCol = colIndex('price');
    final brandCol = colIndex('brand');
    final urlCol = colIndex('url');

    final parsed = <WishRow>[];
    for (var i = 1; i < lines.length; i++) {
      final cols = lines[i].split('\t');
      String cell(int c) => (c >= 0 && c < cols.length) ? cols[c].trim() : '';
      parsed.add(
        WishRow(
          rowNumber: i,
          name: cell(nameCol),
          price: cell(priceCol),
          brand: cell(brandCol),
          url: cell(urlCol),
        ),
      );
    }

    var firstMissing = 0;
    _items = parsed;
    for (var i = 0; i < _items.length; i++) {
      if (!_isRowDone(i)) {
        firstMissing = i;
        break;
      }
      if (i == _items.length - 1) firstMissing = _items.length - 1;
    }

    setState(() {
      _currentIndex = firstMissing;
      final done = _completedCount;
      _statusMessage = done == _items.length
          ? 'All ${_items.length} items already have screenshots!'
          : 'Ready at item #${_items[_currentIndex].rowNumber} ($done/${_items.length} done). Take a screenshot to auto-save & advance!';
    });

    if (_autoOpenNextUrl &&
        _items.isNotEmpty &&
        !_isRowDone(_currentIndex)) {
      _openUrlInIncognito(_items[_currentIndex].url);
    }
  }

  int get _completedCount {
    var count = 0;
    for (var i = 0; i < _items.length; i++) {
      if (_isRowDone(i)) count++;
    }
    return count;
  }

  Future<void> _baselineCurrentClipboardAndFiles() async {
    _lastSeenFileTime = DateTime.now();
    final clip = await _readClipboardPng();
    if (clip != null && clip.isNotEmpty) {
      _seenDigests.add(sha1.convert(clip).toString());
    }
    final latestFile = _findNewestWatchedFile(after: DateTime(2000));
    if (latestFile != null) {
      try {
        final bytes = await latestFile.readAsBytes();
        if (bytes.isNotEmpty) {
          _seenDigests.add(sha1.convert(bytes).toString());
        }
      } catch (_) {}
    }
  }

  Future<Uint8List?> _readClipboardPng() async {
    if (Platform.isMacOS) {
      final tmp = File('${Directory.systemTemp.path}/santa_clip_probe.png');
      final res = await Process.run('osascript', [
        '-e',
        'set png_data to the clipboard as «class PNGf»',
        '-e',
        'set fp to open for access POSIX file "${tmp.path}" with write permission',
        '-e',
        'set eof fp to 0',
        '-e',
        'write png_data to fp',
        '-e',
        'close access fp',
      ]);
      if (res.exitCode == 0 && tmp.existsSync() && tmp.lengthSync() > 0) {
        return tmp.readAsBytesSync();
      }
      return null;
    }

    final wayland = Platform.environment['WAYLAND_DISPLAY'];
    final commands = <List<String>>[
      if (wayland != null && wayland.isNotEmpty)
        ['wl-paste', '--no-newline', '--type', 'image/png'],
      ['xclip', '-selection', 'clipboard', '-t', 'image/png', '-o'],
      if (wayland == null || wayland.isEmpty)
        ['wl-paste', '--no-newline', '--type', 'image/png'],
    ];
    for (final cmd in commands) {
      try {
        final res = await Process.run(
          cmd.first,
          cmd.sublist(1),
          stdoutEncoding: null,
        );
        final out = res.stdout;
        if (res.exitCode == 0 && out is List<int> && out.length > 64) {
          return Uint8List.fromList(out);
        }
      } catch (_) {}
    }
    return null;
  }

  File? _findNewestWatchedFile({required DateTime after}) {
    final home = Platform.environment['HOME'];
    if (home == null) return null;
    final candidates = <File>[];
    for (final rel in ['Pictures/Screenshots', 'Pictures', 'Downloads']) {
      final d = Directory('$home/$rel');
      if (!d.existsSync()) continue;
      try {
        for (final entity in d.listSync()) {
          if (entity is! File) continue;
          final lower = entity.path.toLowerCase();
          if (!_exts.any((e) => lower.endsWith('.$e'))) continue;
          final stat = entity.statSync();
          if (stat.size > 64 && stat.modified.isAfter(after)) {
            candidates.add(entity);
          }
        }
      } catch (_) {}
    }
    if (candidates.isEmpty) return null;
    candidates.sort(
      (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
    );
    return candidates.first;
  }

  Future<void> _pollForNewScreenshot() async {
    if (!_watchClipboardAndDirs ||
        _busyPolling ||
        _items.isEmpty ||
        _pendingDecodedImage != null) {
      return;
    }
    _busyPolling = true;
    try {
      Uint8List? newBytes;
      final clipBytes = await _readClipboardPng();
      if (clipBytes != null) {
        final digest = sha1.convert(clipBytes).toString();
        if (!_seenDigests.contains(digest)) {
          _seenDigests.add(digest);
          _lastSeenFileTime = DateTime.now();
          newBytes = clipBytes;
        }
      }

      if (newBytes == null) {
        final newestFile = _findNewestWatchedFile(after: _lastSeenFileTime);
        if (newestFile != null) {
          await Future<void>.delayed(const Duration(milliseconds: 180));
          final fileBytes = await newestFile.readAsBytes();
          if (fileBytes.length > 64) {
            final digest = sha1.convert(fileBytes).toString();
            _lastSeenFileTime = newestFile.statSync().modified;
            if (!_seenDigests.contains(digest)) {
              _seenDigests.add(digest);
              newBytes = fileBytes;
            }
          }
        }
      }

      if (newBytes != null && mounted) {
        final targetRow = _items[_currentIndex].rowNumber;
        if (_proposeCropBeforeSave) {
          await _openCropEditor(
            newBytes,
            targetRowNum: targetRow,
            advanceAfter: true,
          );
        } else {
          await _saveBytesAndAdvance(newBytes, targetRowNum: targetRow);
        }
      }
    } finally {
      _busyPolling = false;
    }
  }

  Future<void> _grabFullScreenAndProposeCrop() async {
    if (_items.isEmpty) return;
    setState(() {
      _statusMessage = 'Capturing screen...';
    });
    final tmpPath =
        '${Directory.systemTemp.path}/santa_grab_${DateTime.now().millisecondsSinceEpoch}.png';
    final tmpFile = File(tmpPath);

    final attempts = <List<String>>[
      if (Platform.isMacOS) ['screencapture', '-x', tmpPath],
      ['gnome-screenshot', '-f', tmpPath],
      ['grim', tmpPath],
      ['spectacle', '-b', '-n', '-o', tmpPath],
      ['scrot', tmpPath],
      ['import', '-window', 'root', tmpPath],
    ];

    var captured = false;
    for (final cmd in attempts) {
      try {
        final res = await Process.run(cmd.first, cmd.sublist(1));
        if (res.exitCode == 0 && tmpFile.existsSync() && tmpFile.lengthSync() > 0) {
          captured = true;
          break;
        }
      } catch (_) {}
    }

    if (!captured) {
      setState(() {
        _statusMessage =
            'Direct screen grab blocked by Wayland compositor — just press PrtSc (with "Propose Crop in App" enabled) and it will load right here!';
      });
      return;
    }

    final bytes = await tmpFile.readAsBytes();
    try {
      tmpFile.deleteSync();
    } catch (_) {}
    _seenDigests.add(sha1.convert(bytes).toString());
    await _openCropEditor(
      bytes,
      targetRowNum: _items[_currentIndex].rowNumber,
      advanceAfter: true,
    );
  }

  Future<void> _openCropEditor(
    Uint8List bytes, {
    required int targetRowNum,
    required bool advanceAfter,
  }) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    _pendingDecodedImage?.dispose();
    setState(() {
      _pendingDecodedImage = frame.image;
      _pendingTargetRowNum = targetRowNum;
      _advanceAfterCrop = advanceAfter;
      _statusMessage =
          'Adjust proposed crop rectangle if needed (drag inside to move, corners to resize, or drag outside to draw new), then press Enter.';
    });
    _keyboardFocus.requestFocus();
  }

  Future<void> _confirmCropAndSave() async {
    final img = _pendingDecodedImage;
    final targetRow = _pendingTargetRowNum;
    if (img == null || targetRow == null) return;

    final srcRect = Rect.fromLTWH(
      (_normalizedCrop.left * img.width).clamp(0.0, img.width - 1.0),
      (_normalizedCrop.top * img.height).clamp(0.0, img.height - 1.0),
      (_normalizedCrop.width * img.width).clamp(1.0, img.width.toDouble()),
      (_normalizedCrop.height * img.height).clamp(1.0, img.height.toDouble()),
    );
    final outW = srcRect.width.round().clamp(1, img.width);
    final outH = srcRect.height.round().clamp(1, img.height);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      img,
      srcRect,
      Rect.fromLTWH(0, 0, outW.toDouble(), outH.toDouble()),
      Paint()..filterQuality = FilterQuality.high,
    );
    final picture = recorder.endRecording();
    final croppedImage = await picture.toImage(outW, outH);
    final byteData =
        await croppedImage.toByteData(format: ui.ImageByteFormat.png);
    croppedImage.dispose();

    if (byteData == null) return;
    final croppedBytes = byteData.buffer.asUint8List();
    _seenDigests.add(sha1.convert(croppedBytes).toString());

    final shouldAdvance = _advanceAfterCrop;
    _pendingDecodedImage?.dispose();
    setState(() {
      _pendingDecodedImage = null;
      _pendingTargetRowNum = null;
    });

    if (shouldAdvance) {
      await _saveBytesAndAdvance(croppedBytes, targetRowNum: targetRow);
    } else {
      final outFile = File('${_rawScreenshotsDir.path}/$targetRow.png');
      await outFile.writeAsBytes(croppedBytes, flush: true);
      setState(() {
        _lastSavedRowNum = targetRow;
        _lastSavedBytes = croppedBytes;
        _statusMessage = 'Updated cropped screenshot for #$targetRow.';
      });
    }
  }

  void _cancelCrop() {
    _pendingDecodedImage?.dispose();
    setState(() {
      _pendingDecodedImage = null;
      _pendingTargetRowNum = null;
      _statusMessage = 'Cancelled crop.';
    });
  }

  Future<void> _saveBytesAndAdvance(
    Uint8List pngBytes, {
    required int targetRowNum,
  }) async {
    _rawScreenshotsDir.createSync(recursive: true);
    // Remove any older extension variant for this row number first.
    for (final ext in _exts) {
      final old = File('${_rawScreenshotsDir.path}/$targetRowNum.$ext');
      if (old.existsSync()) {
        try {
          old.deleteSync();
        } catch (_) {}
      }
    }
    final dest = File('${_rawScreenshotsDir.path}/$targetRowNum.png');
    await dest.writeAsBytes(pngBytes, flush: true);

    // Find next incomplete item.
    int? nextMissing;
    for (var offset = 1; offset <= _items.length; offset++) {
      final candidate = (_currentIndex + offset) % _items.length;
      if (!_isRowDone(candidate)) {
        nextMissing = candidate;
        break;
      }
    }

    setState(() {
      _lastSavedRowNum = targetRowNum;
      _lastSavedBytes = pngBytes;
      if (nextMissing != null) {
        _currentIndex = nextMissing;
        _statusMessage =
            'Saved #$targetRowNum! Advancing to #${_items[_currentIndex].rowNumber} ($_completedCount/${_items.length} done).';
      } else {
        _statusMessage =
            'Saved #$targetRowNum — ALL ${_items.length} ITEMS COMPLETE! Running generate_hashes.dart...';
      }
    });

    if (nextMissing != null) {
      if (_autoOpenNextUrl) {
        await _openUrlInIncognito(_items[nextMissing].url);
      }
    } else {
      await _runGenerateHashes();
    }
  }

  Future<void> _undoLastSaved() async {
    final row = _lastSavedRowNum;
    if (row == null) return;
    final f = _existingScreenshotFile(row);
    if (f != null && f.existsSync()) {
      f.deleteSync();
    }
    final idx = _items.indexWhere((w) => w.rowNumber == row);
    setState(() {
      _lastSavedRowNum = null;
      _lastSavedBytes = null;
      if (idx >= 0) _currentIndex = idx;
      _statusMessage = 'Deleted #$row — ready to retake.';
    });
    if (idx >= 0 && _autoOpenNextUrl) {
      await _openUrlInIncognito(_items[idx].url);
    }
  }

  Future<void> _openUrlInIncognito(String url) async {
    if (url.isEmpty) return;
    if (Platform.isMacOS) {
      final res = await Process.run('open', [
        '-na',
        'Google Chrome',
        '--args',
        '--incognito',
        url,
      ]);
      if (res.exitCode != 0) {
        await Process.run('open', [url]);
      }
      return;
    }
    try {
      await Process.start(
        'google-chrome',
        ['--incognito', url],
        mode: ProcessStartMode.detached,
      );
    } catch (_) {
      await Process.start('xdg-open', [url], mode: ProcessStartMode.detached);
    }
  }

  Future<void> _runGenerateHashes() async {
    if (_santaRoot == null || _runningGenerateHashes) return;
    setState(() {
      _runningGenerateHashes = true;
      _statusMessage =
          'Running `dart run tools/generate_hashes.dart` (converting to web/screenshots/*.webp)...';
    });
    try {
      final res = await Process.run(
        'dart',
        ['run', 'tools/generate_hashes.dart'],
        workingDirectory: _santaRoot!.path,
      );
      setState(() {
        _statusMessage = res.exitCode == 0
            ? res.stdout.toString().trim()
            : 'generate_hashes failed: ${res.stderr}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _runningGenerateHashes = false;
        });
      }
    }
  }

  void _stepItem(int delta) {
    if (_items.isEmpty) return;
    final next = (_currentIndex + delta) % _items.length;
    setState(() {
      _currentIndex = next < 0 ? next + _items.length : next;
      _statusMessage =
          'Moved to item #${_items[_currentIndex].rowNumber}.';
    });
    if (_autoOpenNextUrl) {
      _openUrlInIncognito(_items[_currentIndex].url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final doneCount = _completedCount;
    final currentItem =
        (_items.isNotEmpty && _currentIndex < _items.length)
            ? _items[_currentIndex]
            : null;

    return KeyboardListener(
      focusNode: _keyboardFocus,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is! KeyDownEvent) return;
        if (_pendingDecodedImage != null) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter) {
            _confirmCropAndSave();
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
            _cancelCrop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _items.isEmpty
                ? 'Screenshot Helper'
                : 'Toy Appeal — $doneCount / ${_items.length} Done',
          ),
          actions: [
            FilledButton.tonalIcon(
              onPressed: _runningGenerateHashes ? null : _runGenerateHashes,
              icon: _runningGenerateHashes
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_fix_high, size: 18),
              label: const Text('Build WebP + Hashes'),
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Watch Clipboard & Screenshots'),
                    selected: _watchClipboardAndDirs,
                    onSelected: (v) =>
                        setState(() => _watchClipboardAndDirs = v),
                  ),
                  FilterChip(
                    label: const Text('Propose Crop in App'),
                    tooltip:
                        'When OFF: saves your Linux screenshot immediately & opens next URL.\n'
                        'When ON: opens an adjustable proposed crop box before saving.',
                    selected: _proposeCropBeforeSave,
                    onSelected: (v) =>
                        setState(() => _proposeCropBeforeSave = v),
                  ),
                  FilterChip(
                    label: const Text('Auto-Open Next URL'),
                    selected: _autoOpenNextUrl,
                    onSelected: (v) => setState(() => _autoOpenNextUrl = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_statusMessage, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _loadTsv,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reload data/input.tsv'),
                            ),
                          ],
                        ),
                      )
                    : _pendingDecodedImage != null
                        ? _buildCropEditorView()
                        : _buildMainWorkflowView(currentItem!, doneCount),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCropEditorView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Crop Item #$_pendingTargetRowNum',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _statusMessage,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => setState(() {
                _normalizedCrop = const Rect.fromLTWH(0.05, 0.14, 0.82, 0.70);
              }),
              icon: const Icon(Icons.crop_free, size: 18),
              label: const Text('Reset Box'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => setState(() {
                _normalizedCrop = const Rect.fromLTWH(0.0, 0.0, 1.0, 1.0);
              }),
              icon: const Icon(Icons.fullscreen, size: 18),
              label: const Text('Full Image'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _cancelCrop,
              child: const Text('Cancel (Esc)'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _confirmCropAndSave,
              icon: const Icon(Icons.check),
              label: Text(
                _advanceAfterCrop ? 'Save Crop & Next (Enter)' : 'Save Crop (Enter)',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: CropProposalCanvas(
            image: _pendingDecodedImage!,
            normalizedRect: _normalizedCrop,
            onRectChanged: (r) => setState(() => _normalizedCrop = r),
          ),
        ),
      ],
    );
  }

  Widget _buildMainWorkflowView(WishRow item, int doneCount) {
    final currentFile = _existingScreenshotFile(item.rowNumber);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(
          value: _items.isEmpty ? 0 : doneCount / _items.length,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Chip(
                      label: Text(
                        '#${item.rowNumber} / ${_items.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${item.name}  •  ${item.price} €  (${item.brand})',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    if (currentFile != null)
                      const Chip(
                        avatar: Icon(Icons.check_circle, color: Colors.greenAccent, size: 18),
                        label: Text('Captured'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  item.url,
                  maxLines: 2,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _openUrlInIncognito(item.url),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open in Chrome Incognito'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: _grabFullScreenAndProposeCrop,
                      icon: const Icon(Icons.crop),
                      label: const Text('Grab Screen & Propose Crop'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _stepItem(-1),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _stepItem(1),
                      icon: const Icon(Icons.skip_next),
                      label: const Text('Skip / Next'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        for (var i = 0; i < _items.length; i++) {
                          if (!_isRowDone(i)) {
                            setState(() => _currentIndex = i);
                            if (_autoOpenNextUrl) {
                              _openUrlInIncognito(_items[i].url);
                            }
                            return;
                          }
                        }
                      },
                      icon: const Icon(Icons.fast_forward),
                      label: const Text('Jump to First Missing'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _statusMessage,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
              ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _lastSavedBytes == null
                        ? const Center(
                            child: Text(
                              'How to use:\n\n'
                              '• Keep this window open on the side.\n'
                              '• Take a screenshot in Chrome using your Linux screenshot shortcut (e.g. PrtSc).\n'
                              '  GNOME remembers your selected rectangle between shots!\n'
                              '• As soon as the screenshot hits your clipboard or ~/Pictures/Screenshots,\n'
                              '  it is saved automatically and the next product opens in Chrome Incognito.\n'
                              '• Or toggle "Propose Crop in App" above to adjust a pre-selected crop box right here.',
                              textAlign: TextAlign.center,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Last Saved: Item #$_lastSavedRowNum',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const Spacer(),
                                  TextButton.icon(
                                    onPressed: () => _openCropEditor(
                                      _lastSavedBytes!,
                                      targetRowNum: _lastSavedRowNum!,
                                      advanceAfter: false,
                                    ),
                                    icon: const Icon(Icons.crop, size: 18),
                                    label: Text('Re-Crop #$_lastSavedRowNum'),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: _undoLastSaved,
                                    icon: const Icon(Icons.undo, size: 18),
                                    label: Text('Undo & Retake #$_lastSavedRowNum'),
                                  ),
                                ],
                              ),
                              const Divider(),
                              Expanded(
                                child: Center(
                                  child: Image.memory(
                                    _lastSavedBytes!,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _DragMode { none, move, topLeft, topRight, bottomLeft, bottomRight, drawNew }

class CropProposalCanvas extends StatefulWidget {
  final ui.Image image;
  final Rect normalizedRect;
  final ValueChanged<Rect> onRectChanged;

  const CropProposalCanvas({
    super.key,
    required this.image,
    required this.normalizedRect,
    required this.onRectChanged,
  });

  @override
  State<CropProposalCanvas> createState() => _CropProposalCanvasState();
}

class _CropProposalCanvasState extends State<CropProposalCanvas> {
  _DragMode _mode = _DragMode.none;
  Offset? _dragStartNorm;
  Rect? _startRectNorm;

  Rect _computeImageDisplayRect(Size canvasSize) {
    final imgW = widget.image.width.toDouble();
    final imgH = widget.image.height.toDouble();
    final scale = math.min(canvasSize.width / imgW, canvasSize.height / imgH);
    final w = imgW * scale;
    final h = imgH * scale;
    final dx = (canvasSize.width - w) / 2;
    final dy = (canvasSize.height - h) / 2;
    return Rect.fromLTWH(dx, dy, w, h);
  }

  Offset _toNormalized(Offset localPos, Rect imgRect) {
    final nx = ((localPos.dx - imgRect.left) / imgRect.width).clamp(0.0, 1.0);
    final ny = ((localPos.dy - imgRect.top) / imgRect.height).clamp(0.0, 1.0);
    return Offset(nx, ny);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
        final imgRect = _computeImageDisplayRect(canvasSize);
        final cropPx = Rect.fromLTWH(
          imgRect.left + widget.normalizedRect.left * imgRect.width,
          imgRect.top + widget.normalizedRect.top * imgRect.height,
          widget.normalizedRect.width * imgRect.width,
          widget.normalizedRect.height * imgRect.height,
        );

        return GestureDetector(
          onPanStart: (details) {
            final p = details.localPosition;
            const handleRadius = 18.0;
            if ((p - cropPx.topLeft).distance <= handleRadius) {
              _mode = _DragMode.topLeft;
            } else if ((p - cropPx.topRight).distance <= handleRadius) {
              _mode = _DragMode.topRight;
            } else if ((p - cropPx.bottomLeft).distance <= handleRadius) {
              _mode = _DragMode.bottomLeft;
            } else if ((p - cropPx.bottomRight).distance <= handleRadius) {
              _mode = _DragMode.bottomRight;
            } else if (cropPx.contains(p)) {
              _mode = _DragMode.move;
            } else {
              _mode = _DragMode.drawNew;
            }
            _dragStartNorm = _toNormalized(p, imgRect);
            _startRectNorm = widget.normalizedRect;
          },
          onPanUpdate: (details) {
            if (_dragStartNorm == null || _startRectNorm == null) return;
            final cur = _toNormalized(details.localPosition, imgRect);
            final start = _dragStartNorm!;
            final r = _startRectNorm!;
            const minSize = 0.05;

            Rect updated = r;
            switch (_mode) {
              case _DragMode.move:
                final dx = cur.dx - start.dx;
                final dy = cur.dy - start.dy;
                final newLeft = (r.left + dx).clamp(0.0, 1.0 - r.width);
                final newTop = (r.top + dy).clamp(0.0, 1.0 - r.height);
                updated = Rect.fromLTWH(newLeft, newTop, r.width, r.height);
              case _DragMode.topLeft:
                final left = cur.dx.clamp(0.0, r.right - minSize);
                final top = cur.dy.clamp(0.0, r.bottom - minSize);
                updated = Rect.fromLTRB(left, top, r.right, r.bottom);
              case _DragMode.topRight:
                final right = cur.dx.clamp(r.left + minSize, 1.0);
                final top = cur.dy.clamp(0.0, r.bottom - minSize);
                updated = Rect.fromLTRB(r.left, top, right, r.bottom);
              case _DragMode.bottomLeft:
                final left = cur.dx.clamp(0.0, r.right - minSize);
                final bottom = cur.dy.clamp(r.top + minSize, 1.0);
                updated = Rect.fromLTRB(left, r.top, r.right, bottom);
              case _DragMode.bottomRight:
                final right = cur.dx.clamp(r.left + minSize, 1.0);
                final bottom = cur.dy.clamp(r.top + minSize, 1.0);
                updated = Rect.fromLTRB(r.left, r.top, right, bottom);
              case _DragMode.drawNew:
                final left = math.min(start.dx, cur.dx);
                final top = math.min(start.dy, cur.dy);
                final right = math.max(start.dx, cur.dx);
                final bottom = math.max(start.dy, cur.dy);
                if (right - left >= minSize && bottom - top >= minSize) {
                  updated = Rect.fromLTRB(left, top, right, bottom);
                }
              case _DragMode.none:
                break;
            }
            widget.onRectChanged(updated);
          },
          onPanEnd: (_) => _mode = _DragMode.none,
          child: CustomPaint(
            size: canvasSize,
            painter: _CropOverlayPainter(
              image: widget.image,
              imgRect: imgRect,
              cropRect: cropPx,
            ),
          ),
        );
      },
    );
  }
}

class _CropOverlayPainter extends CustomPainter {
  final ui.Image image;
  final Rect imgRect;
  final Rect cropRect;

  _CropOverlayPainter({
    required this.image,
    required this.imgRect,
    required this.cropRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      imgRect,
      Paint()..filterQuality = FilterQuality.medium,
    );

    final dimPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final overlayPath = Path()
      ..addRect(imgRect)
      ..addRect(cropRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(overlayPath, dimPaint);

    final borderPaint = Paint()
      ..color = Colors.tealAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRect(cropRect, borderPaint);

    final handlePaint = Paint()..color = Colors.tealAccent;
    for (final corner in [
      cropRect.topLeft,
      cropRect.topRight,
      cropRect.bottomLeft,
      cropRect.bottomRight,
    ]) {
      canvas.drawCircle(corner, 7, handlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.imgRect != imgRect ||
        oldDelegate.cropRect != cropRect;
  }
}
