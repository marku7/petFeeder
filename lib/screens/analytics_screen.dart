import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pet_feeder/utils/colors.dart';
import 'package:pet_feeder/widgets/drawer_widget.dart';
import 'package:pet_feeder/widgets/text_widget.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:firebase_database/firebase_database.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  double? currentTemperature;
  DateTime? temperatureTimestamp;
  double? currentDistance;
  DateTime? distanceTimestamp;

  @override
  void initState() {
    super.initState();
    fetchTemperatureData();
    fetchDistanceData();
  }

  Future<void> fetchTemperatureData() async {
    try {
      final ref = FirebaseDatabase.instance.ref();
      final snapshot = await ref.child('temperature').get();
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          currentTemperature = double.tryParse(data['temperature']?.toString() ?? '0');
          int timestamp = int.tryParse(data['timestamp']?.toString() ?? '0') ?? 0;
          temperatureTimestamp = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        });
      }
      print(currentTemperature);
    } catch (e) {
      print('Error fetching temperature data: $e');
    }
  }

  Future<void> fetchDistanceData() async {
    try {
      final ref = FirebaseDatabase.instance.ref();
      final snapshot = await ref.child('distance').get();
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          // Parse distance string to double and convert to cm
          currentDistance = double.tryParse(data['distance']?.toString() ?? '0')?.toDouble() ?? 0;
          // Parse timestamp string to int then to DateTime
          int timestamp = int.tryParse(data['timestamp']?.toString() ?? '0') ?? 0;
          distanceTimestamp = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        });
      }
    } catch (e) {
      print('Error fetching distance data: $e');
    }
  }

  String getFoodLevel(double distanceInMm) {
    double distanceInCm = distanceInMm / 10;
    if (distanceInCm <= 5) return 'High';
    if (distanceInCm <= 10) return 'Medium';
    return 'Low';
  }

  Color getLevelColor(double distanceInMm) {
    double distanceInCm = distanceInMm / 10;
    if (distanceInCm <= 5) return Colors.green;
    if (distanceInCm <= 10) return Colors.orange;
    return Colors.red;
  }

  Widget buildLegendItem(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        TextWidget(
          text: text,
          fontSize: 14,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
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
              const SizedBox(height: 10),
              Builder(builder: (context) {
                List<SalesData> chartData = List.generate(7, (index) {
                  DateTime day = startOfWeek.add(Duration(days: index));
                  double temp = currentTemperature ?? 0.0;
                  
                  if (temperatureTimestamp != null && 
                      day.year == temperatureTimestamp!.year &&
                      day.month == temperatureTimestamp!.month &&
                      day.day == temperatureTimestamp!.day) {
                    temp = currentTemperature ?? temp;
                  }
                  print(currentTemperature);
                  
                  return SalesData(day, temp);
                });

                return Container(
                  padding: const EdgeInsets.all(16),
                  child: SfCartesianChart(
                    primaryXAxis: DateTimeAxis(
                      intervalType: DateTimeIntervalType.days,
                      dateFormat: DateFormat.E(),
                      majorGridLines: const MajorGridLines(width: 0),
                    ),
                    primaryYAxis: const NumericAxis(
                      title: AxisTitle(text: "Temperature (°C)"),
                      minimum: 20,
                      maximum: 40,
                    ),
                    series: <CartesianSeries>[
                      LineSeries<SalesData, DateTime>(
                        dataSource: chartData,
                        xValueMapper: (SalesData sales, _) => sales.year,
                        yValueMapper: (SalesData sales, _) => sales.sales,
                        color: secondary,
                        markerSettings: const MarkerSettings(isVisible: true),
                        dataLabelSettings: const DataLabelSettings(
                          isVisible: true,
                          labelAlignment: ChartDataLabelAlignment.top,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
              TextWidget(
                text: 'Food Level',
                fontSize: 28,
                fontFamily: 'Bold',
              ),
              const SizedBox(height: 10),
              Builder(builder: (context) {
                List<SalesData> chartData = List.generate(7, (index) {
                  DateTime day = startOfWeek.add(Duration(days: index));
                  double distance = 150;
                  
                  if (distanceTimestamp != null && 
                      day.year == distanceTimestamp!.year &&
                      day.month == distanceTimestamp!.month &&
                      day.day == distanceTimestamp!.day) {
                    distance = currentDistance ?? distance;
                  }
                  
                  return SalesData(day, distance);
                });

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: SfCartesianChart(
                        primaryXAxis: DateTimeAxis(
                          intervalType: DateTimeIntervalType.days,
                          dateFormat: DateFormat.E(),
                          majorGridLines: const MajorGridLines(width: 0),
                        ),
                        primaryYAxis: const NumericAxis(
                          title: AxisTitle(text: "Distance (mm)"),
                          minimum: 0,
                          maximum: 200,
                        ),
                        series: <CartesianSeries>[
                          LineSeries<SalesData, DateTime>(
                            dataSource: chartData,
                            xValueMapper: (SalesData sales, _) => sales.year,
                            yValueMapper: (SalesData sales, _) => sales.sales,
                            color: secondary,
                            markerSettings: const MarkerSettings(isVisible: true),
                            dataLabelSettings: DataLabelSettings(
                              isVisible: true,
                              labelAlignment: ChartDataLabelAlignment.top,
                              builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: getLevelColor(data.sales),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${(data.sales / 10).toStringAsFixed(1)}cm\n${getFoodLevel(data.sales)}',
                                    style: const TextStyle(color: Colors.white, fontSize: 10),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildLegendItem('0 - 5 cm (High)', Colors.green),
                          const SizedBox(height: 4),
                          buildLegendItem('6 - 10 cm (Medium)', Colors.orange),
                          const SizedBox(height: 4),
                          buildLegendItem('11+ cm (Low)', Colors.red),
                        ],
                      ),
                    ),
                  ],
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
