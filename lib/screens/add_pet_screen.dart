import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:pet_feeder/screens/my_pets_screen.dart';
import 'package:pet_feeder/services/add_pet.dart';
import 'package:pet_feeder/utils/colors.dart';
import 'package:pet_feeder/widgets/button_widget.dart';
import 'package:pet_feeder/widgets/drawer_widget.dart';
import 'package:pet_feeder/widgets/text_widget.dart';
import 'package:pet_feeder/widgets/toast_widget.dart';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});

  @override
  _AddPetScreenState createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _breedController = TextEditingController();

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
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(
                  text: 'Pet Name:',
                  fontSize: 16,
                  isBold: true,
                ),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(hintText: 'Enter pet name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the pet name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextWidget(
                  text: 'Pet Age:',
                  fontSize: 16,
                  isBold: true,
                ),
                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(hintText: 'Enter pet age'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the pet age';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextWidget(
                  text: 'Pet Breed:',
                  fontSize: 16,
                  isBold: true,
                ),
                TextFormField(
                  controller: _breedController,
                  decoration:
                      const InputDecoration(hintText: 'Enter pet breed'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the pet breed';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextWidget(
                  text: 'Pet Image:',
                  fontSize: 16,
                  isBold: true,
                ),
                const SizedBox(height: 10),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      uploadPicture('gallery');
                    },
                    child: imageURL == ''
                        ? const Center(
                            child: Icon(
                              Icons.image,
                              size: 120.0,
                              color: Colors.grey,
                            ),
                          )
                        : SizedBox(
                            width: 300,
                            height: 300,
                            child: Image.network(imageURL),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ButtonWidget(
                    label: 'Submit',
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Handle form submission
                        final name = _nameController.text;
                        final age = _ageController.text;
                        final breed = _breedController.text;
                        addPet(name, age, breed, imageURL);
                        // You can save this data to a database or perform other actions
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: TextWidget(
                              text: 'Pet added successfully!',
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        );
                        Navigator.of(context).pushReplacement(MaterialPageRoute(
                            builder: (context) => const MyPetsScreen()));
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  late String fileName = '';

  late File imageFile;

  late String imageURL = '';

  Future<void> uploadPicture(String inputSource) async {
    final picker = ImagePicker();
    XFile pickedImage;
    try {
      pickedImage = (await picker.pickImage(
          source: inputSource == 'camera'
              ? ImageSource.camera
              : ImageSource.gallery,
          maxWidth: 1920))!;

      fileName = path.basename(pickedImage.path);
      imageFile = File(pickedImage.path);

      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => const Padding(
            padding: EdgeInsets.only(left: 30, right: 30),
            child: AlertDialog(
                title: Row(
              children: [
                CircularProgressIndicator(
                  color: Colors.black,
                ),
                SizedBox(
                  width: 20,
                ),
                Text(
                  'Loading . . .',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'QRegular'),
                ),
              ],
            )),
          ),
        );

        await firebase_storage.FirebaseStorage.instance
            .ref('Pictures/$fileName')
            .putFile(imageFile);
        imageURL = await firebase_storage.FirebaseStorage.instance
            .ref('Pictures/$fileName')
            .getDownloadURL();

        setState(() {});

        Navigator.of(context).pop();
        showToast('Image uploaded!');
      } on firebase_storage.FirebaseException catch (error) {
        if (kDebugMode) {
          print(error);
        }
      }
    } catch (err) {
      if (kDebugMode) {
        print(err);
      }
    }
  }
}
