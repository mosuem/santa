import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  var contents = File('data/total_hashed.json').readAsStringSync();
  var map = jsonDecode(contents) as Map<String, dynamic>;
  for (var element in map.entries) {
    await runQrCode(element.key, element.value['url']);
  }
}

Future<void> runQrCode(String name, String content) async {
  var output = '$name.png';
  Directory('codes').createSync();
  var tempDir = Directory('codes_temp');
  tempDir.createSync();
  var tmpFile = 'codes_temp/$output';
  await Process.run('qrencode', [
    ...['-o', tmpFile],
    ...['-l', 'M'],
    content,
  ]);
  await Process.run('convert', [
    tmpFile,
    ...['-resize', '200x200'],
    'codes/$output',
  ]);
  tempDir.deleteSync(recursive: true);
}
