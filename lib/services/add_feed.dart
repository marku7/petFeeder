import 'package:cloud_firestore/cloud_firestore.dart';

Future addFeed(amount, year, month, day, time) async {
  final docUser = FirebaseFirestore.instance.collection('Feed').doc();

  final json = {
    'amount': amount,
    'year': year,
    'month': month,
    'day': day,
    'time': time,
    'dateTime': DateTime.now(),
  };

  await docUser.set(json);
}
