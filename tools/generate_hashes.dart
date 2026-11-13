import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:grizzly_io/io_loader.dart';

const _supportedExts = ['png', 'webp', 'jpg', 'jpeg'];

File? _findRawScreenshot(Directory rawDir, int rowNum) {
  if (!rawDir.existsSync()) return null;
  final candidates = <String>[
    '$rowNum',
    rowNum.toString().padLeft(2, '0'),
    rowNum.toString().padLeft(3, '0'),
  ];
  for (final base in candidates) {
    for (final ext in _supportedExts) {
      final f = File('${rawDir.path}/$base.$ext');
      if (f.existsSync()) return f;
    }
  }
  return null;
}

Future<String?> _detectImageConverter() async {
  for (final bin in ['magick', 'convert', 'cwebp']) {
    try {
      final res = await Process.run('which', [bin]);
      if (res.exitCode == 0) return bin;
    } catch (_) {}
  }
  return null;
}

Future<ProcessResult> _convertToWebp(
  String converter,
  String inputPath,
  String outputPath,
) {
  if (converter == 'cwebp') {
    return Process.run('cwebp', ['-q', '82', inputPath, '-o', outputPath]);
  }
  return Process.run(converter, [
    inputPath,
    '-strip',
    '-resize',
    '1200x1200>',
    '-quality',
    '82',
    outputPath,
  ]);
}

Future<void> main(List<String> args) async {
  final path = args.isNotEmpty ? args.first : 'data/input.tsv';
  final read = await readLTsv(path);
  final rawRows = read.toMap().toList();

  // Preserve 1-based item index from data/input.tsv (row 2..101 in Google Sheet)
  // before sorting by URL so raw screenshots (1.png..100.png) map accurately.
  final decoded = <Map<String, dynamic>>[];
  final urlFirstRow = <String, int>{};
  for (var idx = 0; idx < rawRows.length; idx++) {
    final copy = Map<String, dynamic>.from(rawRows[idx]);
    final rowNum = idx + 1;
    copy['_origRow'] = rowNum;
    urlFirstRow.putIfAbsent(copy['url'].toString(), () => rowNum);
    decoded.add(copy);
  }

  decoded.sort((a, b) => a['url'].toString().compareTo(b['url'].toString()));

  final rawScreenshotsDir = Directory('data/raw_screenshots');
  final outScreenshotsDir = Directory('web/screenshots');
  String? converter;
  if (rawScreenshotsDir.existsSync()) {
    outScreenshotsDir.createSync(recursive: true);
    converter = await _detectImageConverter();
    if (converter == null) {
      stderr.writeln(
        'No WebP converter found (`magick`, `convert`, or `cwebp`). '
        'Install ImageMagick (`brew install imagemagick` or `sudo apt install imagemagick`).',
      );
      exitCode = 1;
      return;
    }
  }

  final total = <String, Map<String, dynamic>>{};
  var convertedCount = 0;
  final missingRows = <int>[];

  for (var i = 0; i < decoded.length; i++) {
    final item = decoded[i];
    final origRow = item.remove('_origRow') as int;
    final urlStr = item['url'].toString();
    item['physical'] = 'false';
    item.remove('description');
    item.remove('delivery status');

    final bytes = utf8.encode('$urlStr$i');
    final digest = sha1.convert(bytes).toString();

    final rawImage = _findRawScreenshot(rawScreenshotsDir, origRow) ??
        _findRawScreenshot(rawScreenshotsDir, urlFirstRow[urlStr] ?? origRow);
    if (rawImage != null && converter != null) {
      final outPath = '${outScreenshotsDir.path}/$digest.webp';
      final result = await _convertToWebp(converter, rawImage.path, outPath);
      if (result.exitCode != 0) {
        stderr.writeln(
          'Failed converting ${rawImage.path} -> $outPath: ${result.stderr}',
        );
        exitCode = 1;
      } else {
        convertedCount++;
      }
    } else {
      missingRows.add(origRow);
    }

    total[digest] = item;
  }

  const encoder = JsonEncoder.withIndent('  ');
  File('data/total_hashed.json').writeAsStringSync(encoder.convert(total));
  stdout.writeln('Total items hashed: ${total.length}');
  if (rawScreenshotsDir.existsSync()) {
    missingRows.sort();
    stdout.writeln(
      'Screenshots converted to web/screenshots/*.webp: '
      '$convertedCount/${total.length}'
      '${missingRows.isEmpty ? '' : ' (missing item numbers: $missingRows)'}',
    );
  } else {
    stdout.writeln(
      'Note: data/raw_screenshots/ not found yet '
      '(place 1.png..${total.length}.png there and re-run to generate web/screenshots/*.webp).',
    );
  }
}
