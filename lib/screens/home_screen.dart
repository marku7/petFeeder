import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pet_feeder/screens/alarm_screen.dart';
import 'package:pet_feeder/services/add_feed.dart';
import 'package:pet_feeder/utils/colors.dart';
import 'package:pet_feeder/widgets/drawer_widget.dart';
import 'package:pet_feeder/widgets/text_widget.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  final int? preselectedGrams;
  
  const HomeScreen({
    super.key, 
    this.preselectedGrams
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String ipAddress = '192.168.43.128';
  int selectedValue = 1;
  final TextEditingController _ipController = TextEditingController();
  static const String _ipAddressKey = 'ip_address';

  @override
  void initState() {
    super.initState();
    _loadSavedIpAddress();
    
    if (widget.preselectedGrams != null) {
      selectedValue = _getValueFromGrams(widget.preselectedGrams!);
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _processFeedWithoutDialog();
      });
    }
  }

  Future<void> _loadSavedIpAddress() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? savedIp = prefs.getString(_ipAddressKey);
      
      if (savedIp != null && savedIp.isNotEmpty) {
        setState(() {
          ipAddress = savedIp;
          _ipController.text = savedIp;
        });
      } else {
        _ipController.text = ipAddress;
      }
    } catch (e) {
      print('Error loading saved IP address: $e');
      _ipController.text = ipAddress;
    }
  }

  Future<void> _saveIpAddress(String ip) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_ipAddressKey, ip);
    } catch (e) {
      print('Error saving IP address: $e');
    }
  }

  int _getValueFromGrams(int grams) {
    switch (grams) {
      case 70:
        return 1;
      case 105:
        return 2;
      case 140:
        return 3;
      case 175:
        return 4;
      case 210:
        return 5;
      default:
        return 1; 
    }
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
              onPressed: () async {
                final newIp = _ipController.text.trim();
                if (newIp.isNotEmpty) {
                  setState(() {
                    ipAddress = newIp;
                  });
                  await _saveIpAddress(newIp);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Successfully changed to "$ipAddress"'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
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
      final feedUrl = 'http://$ipAddress/feeder/on/$seconds';
      
      print('Sending feed command to hardware: $seconds seconds');
      print('HTTP Request Details:');
      print('URL: $feedUrl');
      print('Method: POST');
      
      Fluttertoast.showToast(
        msg: feedUrl,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 3,
        backgroundColor: Colors.black87,
        textColor: Colors.white,
        fontSize: 16.0
      );
      
      final response = await http.post(
        Uri.parse(feedUrl),
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
  
  void showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: const [
              CircularProgressIndicator(color: primary),
              SizedBox(width: 20),
              Text('Feeding...'),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processFeedWithoutDialog() async {
    showLoadingDialog();
    bool success = await sendFeedCommand(selectedValue);
    Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading dialog
    
    if (success) {
      int grams = getGramsFromValue(selectedValue);
      await addFeed(grams);
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to feed. Please check your connection and try again.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
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

                          showLoadingDialog();
                          final success = await sendFeedCommand(selectedValue);
                          Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading dialog
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
              text: widget.preselectedGrams != null
                  ? ''
                  : 'Press the Button to Feed',
              fontSize: 18,
              color: primary,
              fontFamily: 'Bold',
            ),
            const SizedBox(
              height: 10,
            ),
            GestureDetector(
              onTap: () {
                if (widget.preselectedGrams == null) {
                showScheduleDialog();
                }
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