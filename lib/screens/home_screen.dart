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
  bool isTesting = true; // testing mode

  Future<bool> sendFeedCommand(int grams) async {
    if (isTesting) {
      print('TEST MODE: Sending feed command for $grams grams');
      print('TEST MODE: HTTP Request Details:');
      print('URL: http://$ipAddress:$port/feed');
      print('Method: POST');
      print('Body: {"grams": "$grams"}');
      await Future.delayed(const Duration(seconds: 2));
      return true;
    }

    try {
      print('Sending feed command to hardware: $grams grams');
      print('HTTP Request Details:');
      print('URL: http://$ipAddress:$port/feed');
      print('Method: POST');
      print('Body: {"grams": "$grams"}');
      
      final response = await http.post(
        Uri.parse('http://$ipAddress:$port/feed'),
        body: {
          'grams': grams.toString(),
        },
      );

      print('Hardware Response Details:');
      print('Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error sending feed command: $e');
      print('Error Details:');
      print('IP Address: $ipAddress');
      print('Port: $port');
      print('Grams: $grams');
      return false;
    }
  }

  showScheduleDialog() {
    bool isLoading = false; // Track loading state

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing while loading
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Input value (in grams)'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFieldWidget(
                    label: 'value',
                    controller: amount,
                    inputType: TextInputType.number,
                    enabled: !isLoading, // Disable input while loading
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('Testing Mode: '),
                      Switch(
                        value: isTesting,
                        onChanged: isLoading ? null : (value) { // Disable switch while loading
                          setState(() {
                            isTesting = value;
                          });
                        },
                      ),
                    ],
                  ),
                  if (isLoading) ...[
                    const SizedBox(height: 10),
                    const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () { // Disable cancel while loading
                    Navigator.of(context).pop();
                  },
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (amount.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter an amount'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          try {
                            int grams = int.parse(amount.text);
                            if (grams <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a valid amount'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            // Set loading state
                            setState(() {
                              isLoading = true;
                            });

                            final success = await sendFeedCommand(grams);

                            // Close dialog immediately after successful command
                            Navigator.of(context).pop();

                            if (success) {
                              DateTime now = DateTime.now();
                              String formattedTime = DateFormat('HH:mm').format(now);

                              addFeed(
                                grams,
                                DateTime.now().year,
                                DateTime.now().month,
                                DateTime.now().day,
                                formattedTime
                              );

                              if (mounted) {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => const ConfirmationScreen()
                                ));
                              }
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to send feed command. Please check your connection and try again.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a valid number'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            // Reset loading state if dialog is still open
                            if (mounted) {
                              setState(() {
                                isLoading = false;
                              });
                            }
                          }
                        },
                  child: const Text('OK'),
                ),
              ],
            );
          },
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
        actions: [
          IconButton(
            icon: Icon(isTesting ? Icons.bug_report : Icons.check),
            onPressed: () {
              setState(() {
                isTesting = !isTesting;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isTesting ? 'Testing mode ON' : 'Testing mode OFF'),
                  backgroundColor: isTesting ? Colors.blue : Colors.green,
                ),
              );
            },
          ),
        ],
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
            const SizedBox(height: 20),
            TextWidget(
              text: isTesting ? 'Testing Mode: ON' : 'Testing Mode: OFF',
              fontSize: 14,
              color: isTesting ? Colors.blue : Colors.green,
              fontFamily: 'Medium',
            ),
          ],
        ),
      ),
    );
  }

  final amount = TextEditingController();
}
