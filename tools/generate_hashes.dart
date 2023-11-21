import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:grizzly_io/io_loader.dart';

Future<void> main(List<String> args) async {
  Map<String, Map> total = {};
  var path = 'data/input.tsv';
  var read = await readLTsv(path);
  final decoded = read.toMap().toList();
  decoded.sort((a, b) => a['url'].toString().compareTo(b['url'].toString()));
  for (int i = 0; i < decoded.length; i++) {
    var item = decoded[i];
    var bytes = utf8.encode(item['url'] + i.toString());
    var digest = sha1.convert(bytes).toString();
    total[digest] = item;
  }
  JsonEncoder encoder = const JsonEncoder.withIndent('  ');
  File('data/total_hashed.json').writeAsStringSync(encoder.convert(total));
}
