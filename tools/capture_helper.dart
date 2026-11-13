// Interactive local helper to save screenshots as data/raw_screenshots/<N>.png
// while reviewing items in your browser (supports macOS & Linux).
//
// Usage:
//   dart run tools/capture_helper.dart [--open]
//
// Workflow per item:
//   1. Open the printed URL in an Incognito browser window (or pass --open to
//      auto-open Chrome Incognito).
//   2. Copy a screenshot or product image to clipboard (e.g. right-click ->
//      "Copy image", macOS Cmd+Ctrl+Shift+4, or Linux Shift+Ctrl+PrtSc) and
//      press Enter; OR save a screenshot to ~/Downloads or ~/Desktop and type
//      `d` + Enter.
//   3. Type `s` + Enter to skip an item, or `q` + Enter to quit.

import 'dart:io';

import 'package:grizzly_io/io_loader.dart';

const _exts = ['png', 'webp', 'jpg', 'jpeg'];

bool _hasScreenshot(Directory dir, int num) {
  for (final base in [
    '$num',
    num.toString().padLeft(2, '0'),
    num.toString().padLeft(3, '0'),
  ]) {
    for (final ext in _exts) {
      if (File('${dir.path}/$base.$ext').existsSync()) return true;
    }
  }
  return false;
}

File? _newestSavedImage() {
  final home = Platform.environment['HOME'];
  if (home == null) return null;
  final files = <File>[];
  for (final sub in ['Downloads', 'Desktop']) {
    final dir = Directory('$home/$sub');
    if (!dir.existsSync()) continue;
    files.addAll(
      dir.listSync().whereType<File>().where((f) {
        final lower = f.path.toLowerCase();
        return _exts.any((e) => lower.endsWith('.$e'));
      }),
    );
  }
  if (files.isEmpty) return null;
  files.sort(
    (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
  );
  return files.first;
}

Future<void> _openInIncognito(String url) async {
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

Future<bool> _saveClipboardPng(File dest) async {
  if (Platform.isMacOS) {
    final absPath = dest.absolute.path.replaceAll('"', r'\"');
    final res = await Process.run('osascript', [
      '-e',
      'set png_data to the clipboard as «class PNGf»',
      '-e',
      'set fp to open for access POSIX file "$absPath" with write permission',
      '-e',
      'set eof fp to 0',
      '-e',
      'write png_data to fp',
      '-e',
      'close access fp',
    ]);
    return res.exitCode == 0 && dest.existsSync() && dest.lengthSync() > 0;
  }

  for (final cmd in [
    ['xclip', '-selection', 'clipboard', '-t', 'image/png', '-o'],
    ['wl-paste', '--type', 'image/png'],
  ]) {
    try {
      final res = await Process.run(
        cmd.first,
        cmd.sublist(1),
        stdoutEncoding: null,
      );
      final bytes = res.stdout;
      if (res.exitCode == 0 && bytes is List<int> && bytes.isNotEmpty) {
        dest.writeAsBytesSync(bytes);
        return true;
      }
    } catch (_) {}
  }
  return false;
}

Future<void> main(List<String> args) async {
  final autoOpen = args.contains('--open');
  final inputFile = File('data/input.tsv');
  if (!inputFile.existsSync()) {
    stderr.writeln('data/input.tsv not found. Export the Google Sheet first.');
    exitCode = 1;
    return;
  }

  final rawDir = Directory('data/raw_screenshots')..createSync(recursive: true);
  final rows = (await readLTsv(inputFile.path)).toMap().toList();

  stdout.writeln(
    'Loaded ${rows.length} items from data/input.tsv.\n'
    'Commands at prompt: [Enter]=save from clipboard | [d]=move newest image from ~/Downloads or ~/Desktop | [o]=open in incognito Chrome | [s]=skip | [q]=quit\n',
  );

  final seenUrls = <String, int>{};
  for (var idx = 0; idx < rows.length; idx++) {
    final num = idx + 1;
    final item = rows[idx];
    final url = (item['url'] ?? '').toString();
    final prevNum = seenUrls[url];
    if (prevNum != null && _hasScreenshot(rawDir, prevNum)) {
      stdout.writeln(
        '[$num/${rows.length}] Duplicate URL of #$prevNum — will reuse screenshot automatically.',
      );
      continue;
    }
    seenUrls.putIfAbsent(url, () => num);
    if (_hasScreenshot(rawDir, num)) continue;

    final name = item['name'] ?? '';
    final price = item['price'] ?? '';

    stdout.writeln('----------------------------------------');
    stdout.writeln('[$num/${rows.length}] $name ($price EUR)');
    stdout.writeln('URL: $url');

    if (autoOpen && url.isNotEmpty) {
      await _openInIncognito(url);
    }

    while (true) {
      stdout.write('[$num/${rows.length}] Action ([Enter]/d/o/s/q): ');
      final line = stdin.readLineSync()?.trim().toLowerCase();
      if (line == null || line == 'q') {
        stdout.writeln(
          'Exiting. Run `dart run tools/generate_hashes.dart` when ready.',
        );
        return;
      }
      if (line == 's') {
        stdout.writeln('Skipped #$num.');
        break;
      }
      if (line == 'o') {
        await _openInIncognito(url);
        continue;
      }
      if (line == 'd') {
        final newest = _newestSavedImage();
        if (newest == null) {
          stdout.writeln('No image found in ~/Downloads or ~/Desktop.');
          continue;
        }
        final ext = newest.path.split('.').last.toLowerCase();
        final dest = '${rawDir.path}/$num.$ext';
        newest.renameSync(dest);
        stdout.writeln('Moved ${newest.path} -> $dest');
        break;
      }
      final dest = File('${rawDir.path}/$num.png');
      if (await _saveClipboardPng(dest)) {
        stdout.writeln(
          'Saved clipboard image (${dest.lengthSync()} bytes) -> ${dest.path}',
        );
        break;
      }
      stdout.writeln(
        'No PNG image found on clipboard. Copy an image first (or use `d` for ~/Downloads & ~/Desktop, `o` to open URL, `s` to skip).',
      );
    }
  }

  stdout.writeln(
    '\nAll items checked! Run `dart run tools/generate_hashes.dart` next.',
  );
}
