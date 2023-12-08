import 'dart:convert';
import 'dart:io';

import 'package:santa/item.dart';

void main(List<String> args) {
  var dataStr = File('lib/data.json').readAsStringSync();
  var items = (jsonDecode(dataStr) as Map)
      .entries
      .map((e) => Item.fromMap(e.value))
      .toList();
  var nonTaken = items.where((element) => element.isTaken == null);
  var physicalNonTaken = items
      .where((element) => element.isTaken == null)
      .where((element) => element.physical);
  print(physicalNonTaken.length);
  print(
      nonTaken.map((e) => e.price).reduce((value, element) => value + element));
}
