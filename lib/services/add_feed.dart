import 'package:cloud_firestore/cloud_firestore.dart';

Future addFeed(grams) async {
  final docUser = FirebaseFirestore.instance.collection('Feed').doc();

  final json = {
    'grams': grams,
    'dateTime': DateTime.now(),
  };

  await docUser.set(json);
}
