import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:grizzly_io/io_loader.dart';

Future<void> main(List<String> args) async {
  var path = 'data/input.tsv';
  var read = await readLTsv(path);
  final decoded = read.toMap().toList();
  Map<String, Map> total = {};
  decoded.sort((a, b) => a['url'].toString().compareTo(b['url'].toString()));
  for (int i = 0; i < decoded.length; i++) {
    var item = decoded[i];
    item['physical'] = 'false';
    var bytes = utf8.encode(item['url'] + i.toString());
    item.remove('description');
    var digest = sha1.convert(bytes).toString();
    total[digest] = item;
  }
  JsonEncoder encoder = const JsonEncoder.withIndent('  ');
  File('data/total_hashed.json').writeAsStringSync(encoder.convert(total));
  print('Total: ${total.length}');
}
