import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pet_feeder/screens/home_screen.dart';
import 'package:pet_feeder/utils/colors.dart';
import 'package:pet_feeder/widgets/text_widget.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    Timer(const Duration(seconds: 5), () async {
      // Test if location services are enabled.
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 200,
            ),
            const SizedBox(
              height: 20,
            ),
            TextWidget(
              text: 'Pet Feeder',
              fontSize: 50,
              fontFamily: 'Bold',
              color: primary,
            ),
          ],
        ),
      ),
    );
  }
}
