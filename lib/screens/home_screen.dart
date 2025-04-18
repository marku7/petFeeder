import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pet_feeder/screens/alarm_screen.dart';
import 'package:pet_feeder/services/add_feed.dart';
import 'package:pet_feeder/utils/colors.dart';
import 'package:pet_feeder/widgets/drawer_widget.dart';
import 'package:pet_feeder/widgets/text_widget.dart';
import 'package:pet_feeder/widgets/textfield_widget.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // configurations
  static const String ipAddress = '192.168.1.1'; // ip address of arduino
  static const int port = 80; // port of arduino

  Future<bool> sendFeedCommand(int grams) async {
    try {
      final response = await http.post(
      Uri.parse('http://$ipAddress:$port/feed'),
      body: {
        'grams': grams.toString(),
      },
    );

      return response.statusCode == 200;
    } catch (e) {
      print('Error sending feed command: $e');
      return false;
    }
  }

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
                Navigator.of(context).pop();
              },
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () async {
               final success = await sendFeedCommand(int.parse(amount.text));

               if (success) {
                DateTime now = DateTime.now();
                String formattedTime = DateFormat('HH:mm').format(now);

                addFeed(
                  int.parse(amount.text),
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day,
                  formattedTime
                  );

                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const AlarmScreen()
                  ));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to send feed command. Please check your connection and try again.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

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
}
