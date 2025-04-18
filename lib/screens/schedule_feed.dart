import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pet_feeder/screens/schedules_screen.dart';
import 'package:pet_feeder/services/add_schedule_feed.dart';
import 'package:pet_feeder/utils/colors.dart';
import 'package:pet_feeder/widgets/button_widget.dart';
import 'package:pet_feeder/widgets/drawer_widget.dart';
import 'package:pet_feeder/widgets/text_widget.dart';
import 'package:pet_feeder/widgets/toast_widget.dart';
import 'package:pet_feeder/widgets/textfield_widget.dart';

class ScheduleFeedScreen extends StatefulWidget {
  const ScheduleFeedScreen({super.key});

  @override
  State<ScheduleFeedScreen> createState() => _ScheduleFeedScreenState();
}

class _ScheduleFeedScreenState extends State<ScheduleFeedScreen> {
  // configurations
  static const String ipAddress = '192.168.1.1';
  static const int port = 80;
  bool isTesting = true; // Add testing mode flag
  
  bool isRepeated = false;
  TimeOfDay? _selectedTime;
  final gramsController = TextEditingController();

  Future<bool> sendScheduleToHardware(TimeOfDay time, int grams) async {
    if (isTesting) {
      // for testing
      print('TEST MODE: Setting schedule for ${time.format(context)} with $grams grams');
      print('TEST MODE: HTTP Request Details:');
      print('URL: http://$ipAddress:$port/schedule');
      print('Method: POST');
      print('Body: {');
      print('  "hour": "${time.hour}",');
      print('  "minute": "${time.minute}",');
      print('  "grams": "$grams"');
      print('}');
      await Future.delayed(const Duration(seconds: 2)); // Simulate network delay
      return true;
    }

    try {
      print('Sending schedule to hardware: ${time.format(context)} with $grams grams');
      print('HTTP Request Details:');
      print('URL: http://$ipAddress:$port/schedule');
      print('Method: POST');
      print('Body: {');
      print('  "hour": "${time.hour}",');
      print('  "minute": "${time.minute}",');
      print('  "grams": "$grams"');
      print('}');
      
      final response = await http.post(
        Uri.parse('http://$ipAddress:$port/schedule'),
        body: {
          'hour': time.hour.toString(),
          'minute': time.minute.toString(),
          'grams': grams.toString(),
        },
      );

      print('Hardware Response Details:');
      print('Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error sending schedule to hardware: $e');
      print('Error Details:');
      print('IP Address: $ipAddress');
      print('Port: $port');
      print('Time: ${time.format(context)}');
      print('Grams: $grams');
      return false;
    }
  }

  @override
  void dispose() {
    gramsController.dispose();
    super.dispose();
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Set Feeding Time',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        TimeOfDay? selectedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (selectedTime != null) {
                          setState(() {
                            _selectedTime = selectedTime;
                          });
                          print('Selected time: ${selectedTime.format(context)}');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _selectedTime != null
                              ? 'Selected Time: ${_selectedTime!.format(context)}'
                              : 'Select Time',
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFieldWidget(
                label: 'Amount (grams)',
                controller: gramsController,
                inputType: TextInputType.number,
                hint: 'Enter amount in grams',
              ),
              const SizedBox(height: 32),
              const Spacer(),
              Center(
                child: ButtonWidget(
                  onPressed: () async {
                    if (_selectedTime == null) {
                      showToast('Please select a time first');
                      return;
                    }

                    if (gramsController.text.isEmpty) {
                      showToast('Please enter the amount of food');
                      return;
                    }

                    int grams;
                    try {
                      grams = int.parse(gramsController.text);
                      if (grams <= 0) {
                        showToast('Please enter a valid amount');
                        return;
                      }
                    } catch (e) {
                      showToast('Please enter a valid number');
                      return;
                    }

                    final hardwareSuccess = await sendScheduleToHardware(_selectedTime!, grams);
                    
                    if (!hardwareSuccess) {
                      showToast('Failed to set schedule on hardware');
                      return;
                    }

                    String formattedTime =
                        '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
                    
                    print('Saving schedule locally: $formattedTime with $grams grams');
                    addScheduledFeed(
                      DateTime.now().year,
                      DateTime.now().month,
                      DateTime.now().day,
                      formattedTime,
                      grams
                    );
                    
                    showToast('Feed Schedule saved!');
                    print('Schedule saved successfully');
                  },
                  label: 'Save',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Testing Mode: '),
                  Switch(
                    value: isTesting,
                    onChanged: (value) {
                      setState(() {
                        isTesting = value;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}