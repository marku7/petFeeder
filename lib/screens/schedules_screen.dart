import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pet_feeder/screens/alarm_screen.dart';
import 'package:pet_feeder/utils/colors.dart';
import 'package:pet_feeder/widgets/text_widget.dart';

class SchedulesScreen extends StatelessWidget {
  const SchedulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: primary,
        title: TextWidget(
          text: 'Schedules',
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Schedule Feed')
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
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
            return ListView.builder(
              itemCount: data.docs.length,
              itemBuilder: (context, index) {
                String formattedTime = DateFormat('HH:mm')
                    .format(DateTime.now()); // 24-hour format

                if (formattedTime == data.docs[index]['time']) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (timeStamp) {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const AlarmScreen()));
                    },
                  );
                }

                return ListTile(
                  leading: SizedBox(
                    width: 350,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month,
                        ),
                        const SizedBox(
                          width: 30,
                        ),
                        TextWidget(
                          text:
                              'Added schedule at: ${data.docs[index]['time']}',
                          fontSize: 18,
                          fontFamily: 'Bold',
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
    );
  }
}
