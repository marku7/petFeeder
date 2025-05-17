import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:pet_feeder/utils/colors.dart';
import 'package:pet_feeder/widgets/drawer_widget.dart';
import 'package:pet_feeder/widgets/text_widget.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class TemperatureScreen extends StatelessWidget {
  const TemperatureScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            height: 50,
          ),
          TextWidget(
            text: 'Current Temperature:',
            fontSize: 18,
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
                
                double gaugeMaximum = 60.0;
                if (temperature >= 60) {
                  gaugeMaximum = ((temperature / 10).ceil() * 10) + 10;
                }
                
                if (temperature > 37.5) {
                  statusIcon = Icons.wb_sunny;
                  iconColor = Colors.red;
                } else if (temperature < 25) {
                  statusIcon = Icons.ac_unit;
                  iconColor = Colors.blue;
                } else {
                  statusIcon = Icons.check_circle;
                  iconColor = Colors.green;
                }
                
                Color barColor;
                if (temperature > 37.5) {
                  barColor = const Color(0xFFE74C3C);
                } else if (temperature > 25) {
                  barColor = const Color(0xFF4CAF50);
                } else {
                  barColor = const Color(0xFF279CDE);
                }
                
                return Column(
                  children: [
                    Center(
                      child: TextWidget(
                        text: '${data['temperature']}°C',
                        fontSize: 48,
                        fontFamily: 'Bold',
                        color: temperature > 37.5 
                            ? Colors.red 
                            : temperature < 25 
                                ? Colors.blue
                                : Colors.green,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 400,
                      child: Center(
                        child: Column(
                          children: [
                            SizedBox(
                              width: 100,
                              height: 350,
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  Positioned(
                                    left: 23,
                                    bottom: 0,
                                    child: Container(
                                      width: 25,
                                      height: 25,
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
                                    bottom: 12,
                                    child: SfLinearGauge(
                                      orientation: LinearGaugeOrientation.vertical,
                                      minimum: 0,
                                      maximum: gaugeMaximum,
                                      interval: gaugeMaximum <= 60 ? 10 : 20,
                                      showAxisTrack: true,
                                      axisTrackStyle: const LinearAxisTrackStyle(
                                        thickness: 15,
                                        color: Colors.white,
                                        edgeStyle: LinearEdgeStyle.bothCurve,
                                        borderColor: Color(0xFFE5E5E5),
                                        borderWidth: 1,
                                      ),
                                      axisLabelStyle: const TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'Regular',
                                      ),
                                      majorTickStyle: const LinearTickStyle(
                                        length: 10,
                                        thickness: 1,
                                        color: Colors.grey,
                                      ),
                                      minorTickStyle: const LinearTickStyle(
                                        length: 5,
                                        thickness: 1,
                                        color: Colors.grey,
                                      ),
                                      barPointers: [
                                        LinearBarPointer(
                                          value: temperature,
                                          thickness: 15,
                                          position: LinearElementPosition.cross,
                                          edgeStyle: LinearEdgeStyle.endCurve,
                                          color: barColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  statusIcon,
                                  color: iconColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 5),
                                TextWidget(
                                  text: 'Your Pet temperature is ${temperature > 37.5 ? 'Hot' : temperature < 25 ? 'Cold' : 'Normal'}',
                                  fontSize: 15,
                                  fontFamily: 'Bold',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
        ],
      ),
    );
  }
}
