import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pet_feeder/screens/alarm_screen.dart';
import 'package:pet_feeder/services/add_feed.dart';
import 'package:pet_feeder/utils/colors.dart';
import 'package:pet_feeder/widgets/drawer_widget.dart';
import 'package:pet_feeder/widgets/text_widget.dart';
import 'package:pet_feeder/widgets/textfield_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextWidget(
              text: 'Feed Pet Now',
              fontSize: 18,
              color: primary,
              fontFamily: 'Bold',
            ),
            const SizedBox(
              height: 10,
            ),
            GestureDetector(
              onTap: () {
                showScheduleDialog();
              },
              child: Image.asset(
                'assets/images/Capture.png',
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            TextWidget(
              text:
                  'Last Feed: ${DateFormat.yMMMd().add_jm().format(DateTime.now())}',
              fontSize: 14,
              color: Colors.black,
              fontFamily: 'Medium',
            ),
          ],
        ),
      ),
    );
  }

  final amount = TextEditingController();

  showScheduleDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Input value (in grams)'),
          content: StatefulBuilder(builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFieldWidget(
                  label: 'value',
                  controller: amount,
                  inputType: TextInputType.number,
                ),
              ],
            );
          }),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                DateTime now = DateTime.now();
                String formattedTime =
                    DateFormat('HH:mm').format(now); // 24-hour format
                addFeed(int.parse(amount.text), DateTime.now().year,
                    DateTime.now().month, DateTime.now().day, formattedTime);
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const AlarmScreen()));
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
