import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

void main(List<String> args) {
  Map<String, Map> total = {};
  for (var filename in ['lower', 'higher']) {
    var path = 'data/$filename.json';
    var decoded = jsonDecode(File(path).readAsStringSync()) as List;
    for (int i = 0; i < decoded.length; i++) {
      var item = decoded[i];
      var bytes = utf8.encode(item['url'] + i.toString());
      var digest = sha1.convert(bytes).toString();
      total[digest] = item;
    }
  }
  JsonEncoder encoder = const JsonEncoder.withIndent('  ');
  File('data/total_hashed.json').writeAsStringSync(encoder.convert(total));
}
