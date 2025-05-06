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
    super.initState();

    Timer(const Duration(seconds: 3), () async {
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
              'assets/images/splash.jpg',
              height: 200,
            ),
            const SizedBox(
              height: 10,
            ),
            Image.asset(
              'assets/images/petLoading.gif',
              height: 200,
            ),
          ],
        ),
      ),
    );
  }
}
