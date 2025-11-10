// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:html/parser.dart';

Future<void> main(List<String> args) async {
  var client = HttpClient();
  try {
    var uri = Uri.parse(
        'https://terminreservierung.blutspendedienst.com/unternehmen/072238-1/termine');
    HttpClientRequest request = await client.getUrl(uri);
    HttpClientResponse response = await request.close();
    final stringData = await response.transform(utf8.decoder).join();

    var document = parse(stringData);

    var map = document
        .getElementsByClassName('btn btn-primary btn-small')
        .map((e) => e.innerHtml)
        .map((e) => RegExp('\\((\\d)\\)').firstMatch(e)!.group(1))
        .map((e) => int.parse(e!))
        .fold(0, (value, element) => value + element);
    print('$map/110 frei');
  } finally {
    client.close();
  }
}
