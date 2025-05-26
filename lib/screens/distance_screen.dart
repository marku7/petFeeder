import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:pet_feeder/utils/colors.dart';
import 'package:pet_feeder/widgets/drawer_widget.dart';
import 'package:pet_feeder/widgets/text_widget.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class DistanceScreen extends StatelessWidget {
  const DistanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DrawerWidget(),
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: primary,
        title: TextWidget(
          text: 'Food Level',
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
              height: 30,
            ),
            TextWidget(
              text: 'Current Food Storage Level:',
              fontSize: 18,
              fontFamily: 'Bold',
            ),
            const SizedBox(
              height: 10,
            ),
            StreamBuilder<DatabaseEvent>(
                stream: FirebaseDatabase.instance.ref("distance").onValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }

                  Map<dynamic, dynamic> data =
                      snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                  double distance = double.parse(data['distance'].toString());
                  
                  String foodLevel;
                  Color valueColor;
                  
                  if (distance >= 10) {
                    foodLevel = "Low";
                    valueColor = Colors.red;
                  } else if (distance >= 5) {
                    foodLevel = "Medium";
                    valueColor = Colors.amber;
                  } else {
                    foodLevel = "High";
                    valueColor = Colors.green;
                  }

                  return Column(
                    children: [
                      TextWidget(
                        text: distance.toString(),
                        fontSize: 48,
                        fontFamily: 'Bold',
                        color: valueColor,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        height: 250,
                        width: 300,
                        padding: const EdgeInsets.all(10),
                        child: SfRadialGauge(
                          enableLoadingAnimation: true,
                          animationDuration: 1500,
                          axes: <RadialAxis>[
                            RadialAxis(
                              minimum: 0,
                              maximum: 15,
                              startAngle: 150,
                              endAngle: 30,
                              interval: 5,
                              showFirstLabel: false,
                              axisLineStyle: const AxisLineStyle(
                                thickness: 0,
                              ),
                              majorTickStyle: const MajorTickStyle(
                                length: 0,
                              ),
                              minorTickStyle: const MinorTickStyle(
                                length: 0,
                              ),
                              ranges: <GaugeRange>[
                                GaugeRange(
                                  startValue: 0,
                                  endValue: 5,
                                  color: Colors.green,
                                  startWidth: 30,
                                  endWidth: 30,
                                  label: 'High',
                                  labelStyle: const GaugeTextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  sizeUnit: GaugeSizeUnit.logicalPixel,
                                ),
                                GaugeRange(
                                  startValue: 5,
                                  endValue: 10,
                                  color: Colors.amber,
                                  startWidth: 30,
                                  endWidth: 30,
                                  label: 'Medium',
                                  labelStyle: const GaugeTextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  sizeUnit: GaugeSizeUnit.logicalPixel,
                                ),
                                GaugeRange(
                                  startValue: 10,
                                  endValue: 15,
                                  color: Colors.red,
                                  startWidth: 30,
                                  endWidth: 30,
                                  label: 'Low',
                                  labelStyle: const GaugeTextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  sizeUnit: GaugeSizeUnit.logicalPixel,
                                ),
                              ],
                              pointers: <GaugePointer>[
                                NeedlePointer(
                                  value: distance > 15 ? 15 : distance,
                                  needleLength: 0.7,
                                  needleStartWidth: 1,
                                  needleEndWidth: 8,
                                  enableAnimation: true,
                                  animationType: AnimationType.ease,
                                  animationDuration: 1500,
                                  knobStyle: const KnobStyle(
                                    knobRadius: 10,
                                    sizeUnit: GaugeSizeUnit.logicalPixel,
                                    borderWidth: 0.05,
                                    borderColor: Colors.black45,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                              annotations: <GaugeAnnotation>[
                                GaugeAnnotation(
                                  widget: Container(
                                    margin: const EdgeInsets.only(top: 80),
                                    child: Text(
                                      foodLevel,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: valueColor,
                                      ),
                                    ),
                                  ),
                                  angle: 90,
                                  positionFactor: 0.5,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        "Indication levels:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              "0 - 5",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(Icons.arrow_forward, color: Colors.black, size: 24),
                          const SizedBox(width: 10),
                          TextWidget(
                            text: "High",
                            fontSize: 18,
                            color: Colors.green,
                            fontFamily: 'Bold',
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              "5 - 10",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(Icons.arrow_forward, color: Colors.black, size: 24),
                          const SizedBox(width: 10),
                          TextWidget(
                            text: "Medium",
                            fontSize: 18,
                            color: Colors.amber,
                            fontFamily: 'Bold',
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              "10 & above",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(Icons.arrow_forward, color: Colors.black, size: 24),
                          const SizedBox(width: 10),
                          TextWidget(
                            text: "Low",
                            fontSize: 18,
                            color: Colors.red,
                            fontFamily: 'Bold',
                          ),
                        ],
                      ),
                    ],
                  );
                })
          ],
        ),
      ),
    );
  }
}
