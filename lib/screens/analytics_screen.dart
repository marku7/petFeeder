import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pet_feeder/utils/colors.dart';
import 'package:pet_feeder/widgets/drawer_widget.dart';
import 'package:pet_feeder/widgets/text_widget.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();

    // Find the Monday of the current week
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return Scaffold(
      drawer: const DrawerWidget(),
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: primary,
        title: TextWidget(
          text: 'Pet Feeder',
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextWidget(
                text: 'Pet Temperature',
                fontSize: 28,
                fontFamily: 'Bold',
              ),
              const SizedBox(
                height: 10,
              ),
              Builder(builder: (context) {
                List<SalesData> chartData = List.generate(7, (index) {
                  DateTime day = startOfWeek.add(Duration(days: index));
                  double sales = 28.59; // Example sales data
                  return SalesData(day, sales);
                });
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: SfCartesianChart(
                    primaryXAxis: DateTimeAxis(
                      intervalType:
                          DateTimeIntervalType.days, // Daily intervals
                      dateFormat: DateFormat
                          .E(), // Show short day names (Mon, Tue, etc.)
                      majorGridLines: const MajorGridLines(
                          width: 0), // Hide grid lines if needed
                    ),
                    primaryYAxis: const NumericAxis(
                      title: AxisTitle(text: "Pet Temperature (°C)"),
                    ),
                    series: <CartesianSeries>[
                      LineSeries<SalesData, DateTime>(
                        dataSource: chartData,
                        xValueMapper: (SalesData sales, _) => sales.year,
                        yValueMapper: (SalesData sales, _) => sales.sales,
                        color: secondary,
                        markerSettings: const MarkerSettings(
                            isVisible: true), // Show markers on data points
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(
                height: 20,
              ),
              TextWidget(
                text: 'Food Temperature',
                fontSize: 28,
                fontFamily: 'Bold',
              ),
              const SizedBox(
                height: 10,
              ),
              Builder(builder: (context) {
                List<SalesData> chartData = List.generate(7, (index) {
                  DateTime day = startOfWeek.add(Duration(days: index));
                  double sales =
                      25 + (Random().nextInt(7) + 1); // Example sales data
                  return SalesData(day, sales);
                });
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: SfCartesianChart(
                    primaryXAxis: DateTimeAxis(
                      intervalType:
                          DateTimeIntervalType.days, // Daily intervals
                      dateFormat: DateFormat
                          .E(), // Show short day names (Mon, Tue, etc.)
                      majorGridLines: const MajorGridLines(
                          width: 0), // Hide grid lines if needed
                    ),
                    primaryYAxis: const NumericAxis(
                      title: AxisTitle(text: "Food Temperature (°C)"),
                    ),
                    series: <CartesianSeries>[
                      LineSeries<SalesData, DateTime>(
                        dataSource: chartData,
                        xValueMapper: (SalesData sales, _) => sales.year,
                        yValueMapper: (SalesData sales, _) => sales.sales,
                        color: secondary,
                        markerSettings: const MarkerSettings(
                            isVisible: true), // Show markers on data points
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class SalesData {
  SalesData(this.year, this.sales);
  final DateTime year;
  final double sales;
}
