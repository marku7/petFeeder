import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pet_feeder/screens/schedules_screen.dart';
import 'package:pet_feeder/services/add_schedule_feed.dart';
import 'package:pet_feeder/utils/colors.dart';
import 'package:pet_feeder/widgets/button_widget.dart';
import 'package:pet_feeder/widgets/drawer_widget.dart';
import 'package:pet_feeder/widgets/text_widget.dart';
import 'package:pet_feeder/widgets/toast_widget.dart';
import 'package:pet_feeder/widgets/textfield_widget.dart';
import 'package:http/http.dart' as http;

class ScheduleFeedScreen extends StatefulWidget {
  const ScheduleFeedScreen({super.key});

  @override
  State<ScheduleFeedScreen> createState() => _ScheduleFeedScreenState();
}

class _ScheduleFeedScreenState extends State<ScheduleFeedScreen> {
  // configurations
  static const String ipAddress = '192.168.43.128';
  int selectedValue = 1;
  TimeOfDay? _selectedTime;

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

  Future<bool> sendScheduleCommand(String time, int seconds) async {
    try {
      print('Sending schedule command to hardware');
      print('HTTP Request Details:');
      print('URL: http://$ipAddress/scheduleOn/$time/$seconds');
      print('Method: POST');
      
      final response = await http.post(
        Uri.parse('http://$ipAddress/scheduleOn/$time/$seconds'),
      );

      print('Hardware Response Details:');
      print('Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error sending schedule command: $e');
      print('Error Details:');
      print('IP Address: $ipAddress');
      print('Time: $time');
      print('Seconds: $seconds');
      return false;
    }
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
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const SchedulesScreen()));
            },
            icon: const Icon(
              Icons.calendar_month,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SCHEDULED FEED',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('Schedule Feed')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(child: Text('Error loading schedules'));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final schedules = snapshot.data?.docs ?? [];
                    
                    return ListView.builder(
                      itemCount: schedules.length,
                      itemBuilder: (context, index) {
                        final schedule = schedules[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${schedule['grams']} grams',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${schedule['time']} | ${schedule['month']}/${schedule['day']}/${schedule['year']}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(),
              const SizedBox(height: 20),
              const Text(
                'Create New Feeding Schedule',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  title: Text(
                    _selectedTime != null
                        ? '${_selectedTime!.format(context)}'
                        : 'Select Time',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  onTap: () async {
                    TimeOfDay? selectedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (selectedTime != null) {
                      setState(() {
                        _selectedTime = selectedTime;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    RadioListTile<int>(
                      title: const Text('70 grams (appx.)'),
                      value: 1,
                      groupValue: selectedValue,
                      onChanged: (value) {
                        setState(() {
                          selectedValue = value!;
                        });
                      },
                    ),
                    RadioListTile<int>(
                      title: const Text('105 grams (appx.)'),
                      value: 2,
                      groupValue: selectedValue,
                      onChanged: (value) {
                        setState(() {
                          selectedValue = value!;
                        });
                      },
                    ),
                    RadioListTile<int>(
                      title: const Text('140 grams (appx.)'),
                      value: 3,
                      groupValue: selectedValue,
                      onChanged: (value) {
                        setState(() {
                          selectedValue = value!;
                        });
                      },
                    ),
                    RadioListTile<int>(
                      title: const Text('175 grams (appx.)'),
                      value: 4,
                      groupValue: selectedValue,
                      onChanged: (value) {
                        setState(() {
                          selectedValue = value!;
                        });
                      },
                    ),
                    RadioListTile<int>(
                      title: const Text('210 grams (appx.)'),
                      value: 5,
                      groupValue: selectedValue,
                      onChanged: (value) {
                        setState(() {
                          selectedValue = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () async {
                    if (_selectedTime != null) {
                      final hour = _selectedTime!.hourOfPeriod;
                      final minute = _selectedTime!.minute;
                      final period = _selectedTime!.period == DayPeriod.am ? 'am' : 'pm';
                      final formattedTime = '$hour:${minute.toString().padLeft(2, '0')}$period';

                      final success = await sendScheduleCommand(formattedTime, selectedValue);

                      if (success) {
                        final grams = getGramsFromValue(selectedValue);

                        await addScheduledFeed(
                          formattedTime,
                          grams
                        );

                        showToast('Feed Schedule saved!');
                        setState(() {
                          _selectedTime = null;
                          selectedValue = 1;
                        });
                      } else {
                        showToast('Failed to set schedule. Please check your connection.');
                      }
                    } else {
                      showToast('Please select a time');
                    }
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}