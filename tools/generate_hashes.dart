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
    item['physical'] = i < 30 ? 'true' : 'false';
    var bytes = utf8.encode(item['url'] + i.toString());
    item.remove('description');
    var digest = sha1.convert(bytes).toString();
    total[digest] = item;
  }
  JsonEncoder encoder = const JsonEncoder.withIndent('  ');
  var entries = total.entries.toList();
  var physical = Map.fromEntries(entries.take(30));
  print(physical.length);
  print(physical['0af6ba9e27aafab1f3b3968bd9d8d4e4e4b0d0a7']);
  var virtual = Map.fromEntries(entries.skip(30));
  print(virtual.length);
  print(total.length);
  File('data/physical_hashed.json')
      .writeAsStringSync(encoder.convert(physical));
  File('data/virtual_hashed.json').writeAsStringSync(encoder.convert(virtual));
  File('data/total_hashed.json').writeAsStringSync(encoder.convert(total));
}
