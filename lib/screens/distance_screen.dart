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
            text: 'Current Food Storage Distance:',
            fontSize: 18,
            fontFamily: 'Bold',
          ),
          const SizedBox(
            height: 20,
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

                return SfRadialGauge(axes: <RadialAxis>[
                  RadialAxis(minimum: 0, maximum: 250, ranges: <GaugeRange>[
                    GaugeRange(
                        startValue: 0, endValue: 50, color: Colors.green),
                    GaugeRange(
                        startValue: 50, endValue: 150, color: Colors.orange),
                    GaugeRange(
                        startValue: 100, endValue: 250, color: Colors.red)
                  ], pointers: <GaugePointer>[
                    NeedlePointer(value: double.parse(data['distance']))
                  ], annotations: <GaugeAnnotation>[
                    GaugeAnnotation(
                        widget: Container(
                            child: Text(data['distance'],
                                style: const TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold))),
                        angle: 90,
                        positionFactor: 0.5)
                  ])
                ]);
              })
        ],
      ),
    );
  }
}
