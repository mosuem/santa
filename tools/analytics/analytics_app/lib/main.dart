import 'dart:convert';
import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:santa/item.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    var startTime = DateTime(2023, 11, 27);
    var dataStr = File('lib/data.json').readAsStringSync();
    var items = (jsonDecode(dataStr) as Map)
        .entries
        .map((e) => Item.fromMap(e.value))
        .toList();
    LineChartData data = LineChartData(
      minX: 1,
      maxY: 100,
      extraLinesData: ExtraLinesData(verticalLines: [
        VerticalLine(
          x: DateTime(2023, 11, 27, 16, 39)
              .difference(startTime)
              .inHours
              .toDouble(),
          label: VerticalLineLabel(
            show: true,
            alignment: Alignment.center,
            labelResolver: (p0) => 'Digest',
          ),
        ),
        VerticalLine(
          x: DateTime(2023, 12, 4, 18, 46)
              .difference(startTime)
              .inHours
              .toDouble(),
          label: VerticalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            labelResolver: (p0) => 'misc-muc',
          ),
        ),
        VerticalLine(
          x: DateTime(2023, 11, 27, 10, 44)
              .difference(startTime)
              .inHours
              .toDouble(),
          label: VerticalLineLabel(
            show: true,
            alignment: Alignment.centerLeft,
            labelResolver: (p0) => 'muc-social',
          ),
        ),
        VerticalLine(
          x: DateTime(2023, 12, 4, 16, 39)
              .difference(startTime)
              .inHours
              .toDouble(),
          label: VerticalLineLabel(
            show: true,
            alignment: Alignment.centerLeft,
            labelResolver: (p0) => 'muc-social reminder',
          ),
        ),
        VerticalLine(
          x: DateTime(2023, 11, 28, 12, 00)
              .difference(startTime)
              .inHours
              .toDouble(),
          label: VerticalLineLabel(
            show: true,
            alignment: Alignment.center,
            labelResolver: (p0) => 'muc chat',
          ),
        ),
        VerticalLine(
          x: DateTime(2023, 12, 5, 16, 36)
              .difference(startTime)
              .inHours
              .toDouble(),
          label: VerticalLineLabel(
            show: true,
            alignment: Alignment.center,
            labelResolver: (p0) => 'hh/ber',
          ),
        ),
        VerticalLine(
          x: DateTime(2023, 12, 4, 18, 38)
              .difference(startTime)
              .inHours
              .toDouble(),
          label: VerticalLineLabel(
            show: true,
            alignment: Alignment.centerRight,
            labelResolver: (p0) => 'womens',
          ),
        ),
      ]),
      lineBarsData: [
        LineChartBarData(
          spots: List.generate(
            (14) * 24,
            (index) {
              return FlSpot(
                index.toDouble(),
                getBefore(items, startTime.add(Duration(hours: index)))
                    .toDouble(),
              );
            },
          ),
          dotData: const FlDotData(
            show: false,
          ),
        ),
      ],
      gridData: const FlGridData(
        horizontalInterval: 5,
        verticalInterval: 24,
      ),
    );
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: LineChart(data),
          ),
        ),
      ),
    );
  }
}

int getBefore(List<Item> items, DateTime dateTime) {
  return items
      .map((element) => element.isTaken)
      .whereType<DateTime>()
      .where((element) => element.isBefore(dateTime))
      .length;
}
