import 'package:cloud_firestore/cloud_firestore.dart';

Future addPet(name, age, breed, img) async {
  final docUser = FirebaseFirestore.instance.collection('Pets').doc();

  final json = {
    'name': name,
    'age': age,
    'breed': breed,
    'img': img,
    'id': docUser.id,
    'dateTime': DateTime.now(),
  };

  await docUser.set(json);
}
