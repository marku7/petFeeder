import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pet_feeder/utils/colors.dart';
import 'package:pet_feeder/widgets/drawer_widget.dart';
import 'package:pet_feeder/widgets/text_widget.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final List<Map<String, dynamic>> data = [
    {
      "Timestamp": "2025-04-03 12:00",
      "Distance": "10 km",
      "Temperature": "25 °C",
      "Weight": "70 kg",
    },
    {
      "Timestamp": "2025-04-03 13:00",
      "Distance": "12 km",
      "Temperature": "28 °C",
      "Weight": "72 kg",
    },
    {
      "Timestamp": "2025-04-03 14:00",
      "Distance": "15 km",
      "Temperature": "30 °C",
      "Weight": "75 kg",
    },
  ];
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Feed')
                    .orderBy('dateTime', descending: true)
                    .snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    print(snapshot.error);
                    return const Center(child: Text('Error'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 50),
                      child: Center(
                          child: CircularProgressIndicator(
                        color: Colors.black,
                      )),
                    );
                  }

                  final data = snapshot.requireData;
                  return StreamBuilder<DatabaseEvent>(
                      stream: FirebaseDatabase.instance.ref("").onValue,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(
                              child: Text("Error: ${snapshot.error}"));
                        }

                        Map<dynamic, dynamic> rdbValue = snapshot
                            .data!.snapshot.value as Map<dynamic, dynamic>;

                        return DataTable(
                            border: TableBorder.all(
                              color: Colors.black,
                              width: 2,
                            ),
                            columns: const [
                              DataColumn(label: Text("Timestamp")),
                              DataColumn(label: Text("Distance")),
                              DataColumn(label: Text("Temperature")),
                              DataColumn(label: Text("Weight")),
                            ],
                            rows: [
                              for (int i = 0; i < 1; i++)
                                DataRow(cells: [
                                  DataCell(StreamBuilder<Object>(
                                      stream: null,
                                      builder: (context, snapshot) {
                                        String rawTime =
                                            rdbValue['feeding']['timestamp'];
                                        int hour =
                                            int.parse(rawTime.substring(0, 2));
                                        int minute =
                                            int.parse(rawTime.substring(2, 4));
                                        int second =
                                            int.parse(rawTime.substring(4, 6));

                                        // Create DateTime (today's date, just for placeholder)
                                        DateTime now = DateTime.now();
                                        DateTime time = DateTime(
                                            now.year,
                                            now.month,
                                            now.day,
                                            hour,
                                            minute,
                                            second);

                                        // Format only the time (e.g., 9:10 PM)
                                        String formattedTime =
                                            DateFormat.jm().format(time);
                                        return Text(formattedTime);
                                      })),
                                  DataCell(Text(
                                      '${rdbValue['distance']['distance']} - High')),
                                  DataCell(Text(
                                      '${rdbValue['temperature']['temperature']}°C')),
                                  DataCell(Text('${data.docs[i]['amount']}g')),
                                ])
                            ]);
                      });
                }),
          ),
        ),
      ),
    );
  }
}
