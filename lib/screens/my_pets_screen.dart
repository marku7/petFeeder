import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pet_feeder/screens/add_pet_screen.dart';
import 'package:pet_feeder/utils/colors.dart';
import 'package:pet_feeder/widgets/button_widget.dart';
import 'package:pet_feeder/widgets/drawer_widget.dart';
import 'package:pet_feeder/widgets/text_widget.dart';

class MyPetsScreen extends StatelessWidget {
  const MyPetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data for pets (replace with actual data from a database or state management)
    final List<Map<String, String>> pets = [
      {
        'name': 'Buddy',
        'age': '2',
        'breed': 'Golden Retriever',
        'image': 'assets/images/logo.png',
      },
      {
        'name': 'Mittens',
        'age': '3',
        'breed': 'Siamese Cat',
        'image': 'assets/images/logo.png',
      },
      {
        'name': 'Charlie',
        'age': '1',
        'breed': 'Beagle',
        'image': 'assets/images/logo.png',
      },
    ];

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
        children: [
          StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('Pets').snapshots(),
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
                return Expanded(
                  child: ListView.builder(
                    itemCount: data.docs.length,
                    itemBuilder: (context, index) {
                      final pet = data.docs[index];

                      return ListTile(
                        leading: pet['img'] != null
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(pet['img']!),
                              )
                            : const CircleAvatar(
                                child: Icon(Icons.pets),
                              ),
                        title: Text(pet['name'] ?? ''),
                        subtitle:
                            Text('${pet['breed']} - ${pet['age']} years old'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PetDetailsPage(pet: pet.data()),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              }),
          const SizedBox(
            height: 20,
          ),
          ButtonWidget(
            radius: 100,
            label: 'Add Pet',
            onPressed: () {
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) => const AddPetScreen()));
            },
          ),
          const SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }
}

class PetDetailsPage extends StatelessWidget {
  final dynamic pet;

  const PetDetailsPage({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          pet['name'] ?? 'Pet Details',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: pet['img'] != null
                  ? Image.network(
                      pet['img']!,
                      height: 200,
                      width: 200,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 200,
                      width: 200,
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.pets,
                        size: 100,
                        color: Colors.grey[700],
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            Text(
              'Name: ${pet['name']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Age: ${pet['age']} years old',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Breed: ${pet['breed']}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
