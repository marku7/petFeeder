import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pet_feeder/utils/colors.dart';
import 'package:pet_feeder/widgets/drawer_widget.dart';
import 'package:pet_feeder/widgets/text_widget.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  double? currentTemperature;
  DateTime? temperatureTimestamp;
  double? currentFoodLevel;
  DateTime? foodLevelTimestamp;
  
  Map<String, double> temperatureHistory = {};
  Map<String, double> foodLevelHistory = {};

  @override
  void initState() {
    super.initState();
    loadStoredData().then((_) {
      fetchTemperatureData();
      fetchFoodLevelData();
    });
  }
  
  Future<void> loadStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final tempKeys = prefs.getKeys().where((key) => key.startsWith('temp_')).toList();
    for (var key in tempKeys) {
      final dateStr = key.substring(5);
      final value = prefs.getDouble(key) ?? 0.0;
      temperatureHistory[dateStr] = value;
    }
    
    final foodKeys = prefs.getKeys().where((key) => key.startsWith('food_')).toList();
    for (var key in foodKeys) {
      final dateStr = key.substring(5);
      final value = prefs.getDouble(key) ?? 0.0;
      foodLevelHistory[dateStr] = value;
    }
    
    setState(() {});
  }
  
  Future<void> storeTemperatureData(DateTime timestamp, double value) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(timestamp);
    
    if (!temperatureHistory.containsKey(dateStr)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('temp_$dateStr', value);
      
      setState(() {
        temperatureHistory[dateStr] = value;
      });
    }
  }
  
  Future<void> storeFoodLevelData(DateTime timestamp, double value) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(timestamp);
  
    if (!foodLevelHistory.containsKey(dateStr)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('food_$dateStr', value);
      
      setState(() {
        foodLevelHistory[dateStr] = value;
      });
    }
  }

  Future<void> fetchTemperatureData() async {
    try {
      final ref = FirebaseDatabase.instance.ref();
      final snapshot = await ref.child('temperature').get();
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final temp = double.tryParse(data['temperature']?.toString() ?? '0');
        int timestamp = int.tryParse(data['timestamp']?.toString() ?? '0') ?? 0;
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        
        setState(() {
          currentTemperature = temp;
          temperatureTimestamp = date;
        });
        
        if (temp != null) {
          await storeTemperatureData(date, temp);
        }
      }
      print(currentTemperature);
    } catch (e) {
      print('Error fetching temperature data: $e');
    }
  }

  Future<void> fetchFoodLevelData() async {
    try {
      final ref = FirebaseDatabase.instance.ref();
      final snapshot = await ref.child('distance').get();
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final foodLevel = (double.tryParse(data['distance']?.toString() ?? '0') ?? 0) / 10;
        int timestamp = int.tryParse(data['timestamp']?.toString() ?? '0') ?? 0;
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        
        setState(() {
          currentFoodLevel = foodLevel;
          foodLevelTimestamp = date;
        });
        
        await storeFoodLevelData(date, foodLevel);
      }
    } catch (e) {
      print('Error fetching food level data: $e');
    }
  }

  String getFoodLevelStatus(double distanceInCm) {
    if (distanceInCm <= 5) return 'High';
    if (distanceInCm <= 10) return 'Medium';
    return 'Low';
  }

  Color getLevelColor(double distanceInCm) {
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

  String getDayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);
    final difference = today.difference(dateDay).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    
    return DateFormat('E').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final List<DateTime> lastFourDays = List.generate(4, (index) => 
      now.subtract(Duration(days: index))
    ).reversed.toList();

    return Scaffold(
      drawer: const DrawerWidget(),
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: primary,
        title: TextWidget(
          text: 'Analytics',
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
                List<SalesData> tempChartData = lastFourDays.map((day) {
                  double temp = 25.0;
                  
                  String dateKey = DateFormat('yyyy-MM-dd').format(day);
                  
                  if (temperatureHistory.containsKey(dateKey)) {
                    temp = temperatureHistory[dateKey]!;
                  }
                  else if (day.year == now.year && day.month == now.month && day.day == now.day && 
                      temperatureTimestamp != null && currentTemperature != null) {
                    temp = currentTemperature!;
                  }
                  
                  return SalesData(getDayLabel(day), temp);
                }).toList();
                
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: SfCartesianChart(
                    primaryXAxis: CategoryAxis(
                      majorGridLines: const MajorGridLines(width: 0),
                    ),
                    primaryYAxis: NumericAxis(
                      title: AxisTitle(text: "Temperature (°C)"),
                      minimum: 20,
                      maximum: 40,
                      interval: 5,
                    ),
                    series: <CartesianSeries>[
                      LineSeries<SalesData, String>(
                        dataSource: tempChartData,
                        xValueMapper: (SalesData sales, _) => sales.day,
                        yValueMapper: (SalesData sales, _) => sales.value,
                        color: primary,
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
                List<SalesData> foodLevelChartData = lastFourDays.map((day) {
                  double foodLevel = 15.0;
                  
                  String dateKey = DateFormat('yyyy-MM-dd').format(day);
                  
                  if (foodLevelHistory.containsKey(dateKey)) {
                    foodLevel = foodLevelHistory[dateKey]!;
                  }
                  else if (day.year == now.year && day.month == now.month && day.day == now.day && 
                      foodLevelTimestamp != null && currentFoodLevel != null) {
                    foodLevel = currentFoodLevel!;
                  }
                  
                  return SalesData(getDayLabel(day), foodLevel);
                }).toList();
                
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: SfCartesianChart(
                        primaryXAxis: CategoryAxis(
                          majorGridLines: const MajorGridLines(width: 0),
                        ),
                        primaryYAxis: NumericAxis(
                          title: AxisTitle(text: "Food Level (cm)"),
                          minimum: 0,
                          maximum: 20,
                          interval: 5,
                        ),
                        series: <CartesianSeries>[
                          LineSeries<SalesData, String>(
                            dataSource: foodLevelChartData,
                            xValueMapper: (SalesData sales, _) => sales.day,
                            yValueMapper: (SalesData sales, _) => sales.value,
                            color: primary,
                            markerSettings: const MarkerSettings(isVisible: true),
                            dataLabelSettings: DataLabelSettings(
                              isVisible: true,
                              labelAlignment: ChartDataLabelAlignment.top,
                              builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: getLevelColor(data.value),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${data.value.toStringAsFixed(1)}cm\n${getFoodLevelStatus(data.value)}',
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
  SalesData(this.day, this.value);
  final String day;
  final double value;
}
