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
  
  bool isRepeated = false;
  TimeOfDay? _selectedTime;
  final gramsController = TextEditingController();

  Future<bool> sendScheduleToHardware(TimeOfDay time, int grams) async {
    try {
      print('Sending schedule to hardware: ${time.format(context)} with $grams grams');
      
      final response = await http.post(
        Uri.parse('http://$ipAddress:$port/schedule'),
        body: {
          'hour': time.hour.toString(),
          'minute': time.minute.toString(),
          'grams': grams.toString(),
        },
      );

      print('Hardware response status: ${response.statusCode}');
      print('Hardware response body: ${response.body}');
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error sending schedule to hardware: $e');
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
            ],
          ),
        ),
      ),
    );
  }
}
