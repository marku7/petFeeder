import 'package:flutter/material.dart';
import 'package:pet_feeder/screens/schedules_screen.dart';
import 'package:pet_feeder/services/add_schedule_feed.dart';
import 'package:pet_feeder/utils/colors.dart';
import 'package:pet_feeder/widgets/button_widget.dart';
import 'package:pet_feeder/widgets/drawer_widget.dart';
import 'package:pet_feeder/widgets/text_widget.dart';
import 'package:pet_feeder/widgets/toast_widget.dart';

class ScheduleFeedScreen extends StatefulWidget {
  const ScheduleFeedScreen({super.key});

  @override
  State<ScheduleFeedScreen> createState() => _ScheduleFeedScreenState();
}

class _ScheduleFeedScreenState extends State<ScheduleFeedScreen> {
  bool isRepeated = false;

  TimeOfDay? _selectedTime;
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
              const SizedBox(height: 32),
              const Spacer(),
              Center(
                child: ButtonWidget(
                  onPressed: () {
                    String formattedTime =
                        '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
                    addScheduledFeed(DateTime.now().year, DateTime.now().month,
                        DateTime.now().day, formattedTime);
                    showToast('Feed Schedule saved!');
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
