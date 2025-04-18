import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:pet_feeder/utils/colors.dart';
import 'package:pet_feeder/widgets/drawer_widget.dart';
import 'package:pet_feeder/widgets/text_widget.dart';

class TemperatureScreen extends StatelessWidget {
  const TemperatureScreen({super.key});

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
            text: 'Current Temperature:',
            fontSize: 18,
            fontFamily: 'Bold',
          ),
          const SizedBox(
            height: 20,
          ),
          StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instance.ref("temperature").onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                Map<dynamic, dynamic> data =
                    snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                return Center(
                  child: TextWidget(
                    text: '${data['temperature']}°C',
                    fontSize: 48,
                    fontFamily: 'Bold',
                    color: Colors.red,
                    decoration: TextDecoration.underline,
                  ),
                );
              }),
          const SizedBox(
            height: 20,
          ),
          Image.asset(
            'assets/images/high-temperature.png',
            height: 300,
          ),
        ],
      ),
    );
  }
}
