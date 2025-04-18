import 'package:cloud_firestore/cloud_firestore.dart';

Future addScheduledFeed(year, month, day, time) async {
  final docUser =
      FirebaseFirestore.instance.collection('Schedule Feed').doc(time);

  final json = {
    'year': year,
    'month': month,
    'day': day,
    'time': time,
    'dateTime': DateTime.now(),
  };

  await docUser.set(json);
}
