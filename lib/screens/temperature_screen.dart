import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:pet_feeder/utils/colors.dart';
import 'package:pet_feeder/widgets/drawer_widget.dart';
import 'package:pet_feeder/widgets/text_widget.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class TemperatureScreen extends StatefulWidget {
  const TemperatureScreen({super.key});

  @override
  State<TemperatureScreen> createState() => _TemperatureScreenState();
}

class _TemperatureScreenState extends State<TemperatureScreen> with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..repeat(reverse: true);
    
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_blinkController);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
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
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              height: 40,
            ),
            TextWidget(
              text: 'Current Temperature:',
              fontSize: 22,
              fontFamily: 'Bold',
            ),
            const SizedBox(
              height: 20,
            ),
            StreamBuilder<DatabaseEvent>(
                stream: FirebaseDatabase.instance.ref("temperature").onValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }

                  Map<dynamic, dynamic> data =
                      snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                  double temperature = double.parse(data['temperature'].toString());
                  
                  IconData statusIcon;
                  Color iconColor;
                  String statusText;
                  String actionText;
                  
                  double gaugeMaximum = 60.0;
                  if (temperature >= 60) {
                    gaugeMaximum = ((temperature / 10).ceil() * 10) + 10;
                  }
                  
                  bool isEmergencyStatus = false;
                  
                  if (temperature > 41.0) {
                    statusIcon = Icons.warning_amber;
                    iconColor = Colors.red;
                    statusText = "Hyperthermia";
                    actionText = "Emergency! Immediate vet care";
                    isEmergencyStatus = true;
                  } else if (temperature >= 39.8 && temperature <= 41.0) {
                    statusIcon = Icons.thermostat;
                    iconColor = Colors.deepOrange;
                    statusText = "High Fever";
                    actionText = "Vet Visit Needed";
                  } else if (temperature >= 39.3 && temperature < 39.8) {
                    statusIcon = Icons.thermostat;
                    iconColor = Colors.amber;
                    statusText = "Mild Fever";
                    actionText = "Monitor your pet closely";
                  } else if (temperature >= 38.3 && temperature < 39.3) {
                    statusIcon = Icons.check_circle;
                    iconColor = Colors.green;
                    statusText = "Normal";
                    actionText = "Your pet is in normal temperature";
                  } else if (temperature >= 36.0 && temperature < 38.3) {
                    statusIcon = Icons.ac_unit;
                    iconColor = const Color(0xFF6FB6DD);
                    statusText = "Mild Hypothermia";
                    actionText = "Monitor and warm your pet";
                  } else {
                    statusIcon = Icons.warning_amber;
                    iconColor = const Color(0xFF1565C0);
                    statusText = "Severe Hypothermia";
                    actionText = "Emergency! Immediate vet care";
                    isEmergencyStatus = true;
                  }
                  
                  Color barColor;
                  if (temperature > 41.0) {
                    barColor = Colors.red;
                  } else if (temperature >= 39.8) {
                    barColor = Colors.deepOrange;
                  } else if (temperature >= 39.3) {
                    barColor = Colors.amber;
                  } else if (temperature >= 38.3) {
                    barColor = Colors.green;
                  } else if (temperature >= 36.0) {
                    barColor = const Color(0xFF6FB6DD);
                  } else {
                    barColor = const Color(0xFF1565C0);
                  }
                  
                  double gaugeHeight = screenSize.height * 0.45;
                  double circleSize = 30;
                  
                  return Column(
                    children: [
                      Center(
                        child: isEmergencyStatus
                          ? FadeTransition(
                              opacity: _opacityAnimation,
                              child: TextWidget(
                                text: '${data['temperature']}°C',
                                fontSize: 56,
                                fontFamily: 'Bold',
                                color: iconColor,
                              ),
                            )
                          : TextWidget(
                              text: '${data['temperature']}°C',
                              fontSize: 56,
                              fontFamily: 'Bold',
                              color: iconColor,
                            ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                return Container(
                                  width: screenSize.width * 0.3,
                                  height: gaugeHeight,
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Stack(
                                    alignment: Alignment.bottomCenter,
                                    children: [
                                      Positioned(
                                        left: (screenSize.width * 0.3 - circleSize) / 2 - 18,
                                        bottom: 0,
                                        child: Container(
                                          width: circleSize,
                                          height: circleSize,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: barColor,
                                            border: Border.all(
                                              color: const Color(0xFFE5E5E5),
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: circleSize / 2,
                                        child: SfLinearGauge(
                                          orientation: LinearGaugeOrientation.vertical,
                                          minimum: 0,
                                          maximum: gaugeMaximum,
                                          interval: gaugeMaximum <= 60 ? 10 : 20,
                                          showAxisTrack: true,
                                          axisTrackStyle: const LinearAxisTrackStyle(
                                            thickness: 20,
                                            color: Colors.white,
                                            edgeStyle: LinearEdgeStyle.bothCurve,
                                            borderColor: Color(0xFFE5E5E5),
                                            borderWidth: 1,
                                          ),
                                          axisLabelStyle: const TextStyle(
                                            fontSize: 16,
                                            fontFamily: 'Regular',
                                          ),
                                          majorTickStyle: const LinearTickStyle(
                                            length: 12,
                                            thickness: 1.5,
                                            color: Colors.grey,
                                          ),
                                          minorTickStyle: const LinearTickStyle(
                                            length: 6,
                                            thickness: 1,
                                            color: Colors.grey,
                                          ),
                                          barPointers: [
                                            LinearBarPointer(
                                              value: temperature,
                                              thickness: 20,
                                              position: LinearElementPosition.cross,
                                              edgeStyle: LinearEdgeStyle.endCurve,
                                              color: barColor,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  isEmergencyStatus
                                      ? FadeTransition(
                                          opacity: _opacityAnimation,
                                          child: Icon(
                                            statusIcon,
                                            color: iconColor,
                                            size: 32,
                                          ),
                                        )
                                      : Icon(
                                          statusIcon,
                                          color: iconColor,
                                          size: 32,
                                        ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: isEmergencyStatus
                                        ? FadeTransition(
                                            opacity: _opacityAnimation,
                                            child: TextWidget(
                                              text: statusText,
                                              fontSize: 22,
                                              fontFamily: 'Bold',
                                              color: iconColor,
                                            ),
                                          )
                                        : TextWidget(
                                            text: statusText,
                                            fontSize: 22,
                                            fontFamily: 'Bold',
                                            color: iconColor,
                                          ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 25),
                              child: TextWidget(
                                text: actionText,
                                fontSize: 18,
                                fontFamily: 'Regular',
                                color: isEmergencyStatus ? Colors.red : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
          ],
        ),
      ),
    );
  }
}
