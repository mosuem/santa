import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  var contents = File('data/physical_hashed.json').readAsStringSync();
  var map = jsonDecode(contents) as Map<String, dynamic>;
  Directory('codes').deleteSync(recursive: true);
  Directory('codes').createSync();
  Directory('codes_temp').createSync();
  for (var element in map.entries) {
    var id = element.key;
    print('At $id');
    await runQrCode(
      id,
      'https://toy-appeal-muc.web.app/?id=$id',
      element.value['name'],
      '${(double.parse(element.value['price']) * (int.tryParse(element.value['number']) ?? 1)).toStringAsFixed(2)} €',
    );
  }
  Directory('codes_temp').deleteSync(recursive: true);
  print('done');
}

Future<void> runQrCode(
  String name,
  String content,
  String title,
  String price,
) async {
  var output = '$name.png';
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
}
