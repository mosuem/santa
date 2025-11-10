import 'dart:convert';
import 'dart:io';

final cols = [
  "Comment",
  "brand",
  "isTaken",
  "name",
  "number",
  "paypal",
  "physical",
  "price",
  "snipit",
  "url",
];
Future<void> main(List<String> args) async {
  var output = File('export.tsv');
  var input = File(args.first);
  var inputString = await input.readAsString();
  var json = jsonDecode(inputString) as Map<String, dynamic>;
  await output.create();
  final lines = <String>[];
  lines.add(['hash', ...cols].join('\t'));
  for (var element in json.entries) {
    lines.add(
        [element.key, ...cols.map((col) => element.value[col])].join('\t'));
  }

  await output.writeAsString(lines.join('\n'));
}
