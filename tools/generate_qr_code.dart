import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  var contents = File('data/total_hashed.json').readAsStringSync();
  var map = jsonDecode(contents) as Map<String, dynamic>;
  for (var element in map.entries) {
    var id = element.key;
    print('At $id');
    await runQrCode(
      id,
      'https://santa-database.web.app/?id=$id',
      element.value['name'],
      '${(double.parse(element.value['price'])).toStringAsFixed(2)} €',
    );
  }
}

Future<void> runQrCode(
  String name,
  String content,
  String title,
  String price,
) async {
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
    tmpFile,
  ]);
  await Process.run('convert', [
    tmpFile,
    ...['-gravity', 'north'],
    ...['-extent', '200x300'],
    tmpFile,
  ]);
  await Process.run('convert', [
    tmpFile,
    ...['-gravity', 'South'],
    ...['-pointsize', '18'],
    ...['-font', 'Roboto'],
    ...['-annotate', '+0+80', title],
    tmpFile,
  ]);
  await Process.run('convert', [
    tmpFile,
    ...['-gravity', 'South'],
    ...['-pointsize', '18'],
    ...['-font', 'Roboto-Bold'],
    ...['-annotate', '+0+30', price],
    'codes/$output',
  ]);
  tempDir.deleteSync(recursive: true);
}
