import 'package:cloud_firestore/cloud_firestore.dart';

Future addScheduledFeed(time, grams) async {
  final docUser =
      FirebaseFirestore.instance.collection('Schedule Feed').doc(time);

  final json = {
    'grams': grams,
    'time': time,
    'dateTime': DateTime.now(),
  };

  await docUser.set(json);
}
