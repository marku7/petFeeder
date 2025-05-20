import 'package:flutter/material.dart';
import 'package:pet_feeder/screens/add_pet_screen.dart';
import 'package:pet_feeder/screens/analytics_screen.dart';
import 'package:pet_feeder/screens/camera_screen.dart';
import 'package:pet_feeder/screens/distance_screen.dart';
import 'package:pet_feeder/screens/history_screen.dart';
import 'package:pet_feeder/screens/home_screen.dart';
import 'package:pet_feeder/screens/my_pets_screen.dart';
import 'package:pet_feeder/screens/schedule_feed.dart';
import 'package:pet_feeder/screens/temperature_screen.dart';
import 'package:pet_feeder/screens/pet_detection_screen.dart';
import 'package:pet_feeder/utils/colors.dart';
import 'package:pet_feeder/widgets/button_widget.dart';
import 'package:pet_feeder/widgets/text_widget.dart';

class DrawerWidget extends StatefulWidget {
  const DrawerWidget({super.key});

  @override
  State<DrawerWidget> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<DrawerWidget> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Drawer(
        child: ListView(
          padding: const EdgeInsets.only(top: 0),
          children: <Widget>[
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: primary,
              ),
              accountEmail: ButtonWidget(
                label: 'Add Pet',
                onPressed: () {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (context) => const AddPetScreen()));
                },
                radius: 100,
                color: Colors.white,
                width: 80,
                height: 35,
                textColor: Colors.black,
                fontSize: 12,
              ),
              accountName: TextWidget(
                text: 'Pet Feeder',
                fontSize: 14,
                color: Colors.white,
              ),
              currentAccountPicture: const Padding(
                padding: EdgeInsets.all(5.0),
                child: CircleAvatar(
                  radius: 10,
                  backgroundImage: AssetImage('assets/images/icon.png'),
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.front_hand_outlined),
              title: TextWidget(
                text: 'Feed Pet',
                fontSize: 12,
                color: Colors.black,
                fontFamily: 'Bold',
              ),
              onTap: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (context) => const HomeScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.av_timer_rounded),
              title: TextWidget(
                text: 'Schedule Feed',
                fontSize: 12,
                color: Colors.black,
                fontFamily: 'Bold',
              ),
              onTap: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (context) => const ScheduleFeedScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.storage),
              title: TextWidget(
                text: 'Food Level',
                fontSize: 12,
                color: Colors.black,
                fontFamily: 'Bold',
              ),
              onTap: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (context) => const DistanceScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.heat_pump_outlined),
              title: TextWidget(
                text: 'Pet Temperature',
                fontSize: 12,
                color: Colors.black,
                fontFamily: 'Bold',
              ),
              onTap: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (context) => const TemperatureScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: TextWidget(
                text: 'Feeding History',
                fontSize: 12,
                color: Colors.black,
                fontFamily: 'Bold',
              ),
              onTap: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (context) => const HistoryScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.pets_outlined),
              title: TextWidget(
                text: 'My Pets',
                fontSize: 12,
                color: Colors.black,
                fontFamily: 'Bold',
              ),
              onTap: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (context) => const MyPetsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: TextWidget(
                text: 'Analytics',
                fontSize: 12,
                color: Colors.black,
                fontFamily: 'Bold',
              ),
              onTap: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (context) => const AnalyticsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: TextWidget(
                text: 'Live Monitoring',
                fontSize: 12,
                color: Colors.black,
                fontFamily: 'Bold',
              ),
              onTap: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (context) => const CameraScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.pets),
              title: TextWidget(
                text: 'Pet Detection',
                fontSize: 12,
                color: Colors.black,
                fontFamily: 'Bold',
              ),
              onTap: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (context) => const PetDetectionScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }
}
