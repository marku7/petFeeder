import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pet_feeder/screens/alarm_screen.dart';
import 'package:pet_feeder/services/add_feed.dart';
import 'package:pet_feeder/utils/colors.dart';
import 'package:pet_feeder/widgets/drawer_widget.dart';
import 'package:pet_feeder/widgets/text_widget.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // configurations
  String ipAddress = '192.168.43.128';
  int selectedValue = 1;
  final TextEditingController _ipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ipController.text = ipAddress;
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  void showIpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Configure IP Address'),
          content: TextField(
            controller: _ipController,
            decoration: const InputDecoration(
              labelText: 'IP Address',
              hintText: 'Enter device IP address',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  ipAddress = _ipController.text;
                });
                Navigator.of(context).pop();
              },
              child: const Text('SAVE'),
            ),
          ],
        );
      },
    );
  }

  int getGramsFromValue(int value) {
    switch (value) {
      case 1:
        return 70;
      case 2:
        return 105;
      case 3:
        return 140;
      case 4:
        return 175;
      case 5:
        return 210;
      default:
        return 70;
    }
  }

  Future<bool> sendFeedCommand(int seconds) async {
    try {
      print('Sending feed command to hardware: $seconds seconds');
      print('HTTP Request Details:');
      print('URL: http://$ipAddress/feederOn/$seconds');
      print('Method: POST');
      
      final response = await http.post(
        Uri.parse('http://$ipAddress/feederOn/$seconds'),
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
      print('Seconds: $seconds');
      return false;
    }
  }

  void showScheduleDialog() {
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Amount'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<int>(
                    title: const Text('70 grams (appx.)'),
                    value: 1,
                    groupValue: selectedValue,
                    onChanged: isLoading ? null : (value) {
                      setState(() {
                        selectedValue = value!;
                      });
                    },
                  ),
                  RadioListTile<int>(
                    title: const Text('105 grams (appx.)'),
                    value: 2,
                    groupValue: selectedValue,
                    onChanged: isLoading ? null : (value) {
                      setState(() {
                        selectedValue = value!;
                      });
                    },
                  ),
                  RadioListTile<int>(
                    title: const Text('140 grams (appx.)'),
                    value: 3,
                    groupValue: selectedValue,
                    onChanged: isLoading ? null : (value) {
                      setState(() {
                        selectedValue = value!;
                      });
                    },
                  ),
                  RadioListTile<int>(
                    title: const Text('175 grams (appx.)'),
                    value: 4,
                    groupValue: selectedValue,
                    onChanged: isLoading ? null : (value) {
                      setState(() {
                        selectedValue = value!;
                      });
                    },
                  ),
                  RadioListTile<int>(
                    title: const Text('210 grams (appx.)'),
                    value: 5,
                    groupValue: selectedValue,
                    onChanged: isLoading ? null : (value) {
                      setState(() {
                        selectedValue = value!;
                      });
                    },
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
                  onPressed: isLoading ? null : () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() {
                            isLoading = true;
                          });

                          final success = await sendFeedCommand(selectedValue);
                          
                          Navigator.of(context).pop();

                          if (success) {
                            int grams = getGramsFromValue(selectedValue);

                            await addFeed(
                              grams,
                            );

                            if (mounted) {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => const ConfirmationScreen(),
                              ));
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to feed. Please check your connection and try again.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }

                          if (mounted) {
                            setState(() {
                              isLoading = false;
                            });
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
          text: 'FeediPaw',
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 80.0),
        child: FloatingActionButton(
          mini: true,
          onPressed: showIpDialog,
          child: const Icon(Icons.broadcast_on_personal_outlined),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextWidget(
              text: 'Press the Button to Feed',
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
}
