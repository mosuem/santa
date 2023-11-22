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
    var bytes = utf8.encode(item['url'] + i.toString());
    item.remove('description');
    var digest = sha1.convert(bytes).toString();
    total[digest] = item;
  }
  JsonEncoder encoder = const JsonEncoder.withIndent('  ');
  var physical = Map.fromEntries(total.entries.take(30));
  print(physical.length);
  var virtual = Map.fromEntries(total.entries.skip(30));
  print(virtual.length);
  File('data/physical_hashed.json')
      .writeAsStringSync(encoder.convert(physical));
  File('data/virtual_hashed.json').writeAsStringSync(encoder.convert(virtual));
}
