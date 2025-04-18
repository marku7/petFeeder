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

class ScheduleFeedScreen extends StatefulWidget {
  const ScheduleFeedScreen({super.key});

  @override
  State<ScheduleFeedScreen> createState() => _ScheduleFeedScreenState();
}

class _ScheduleFeedScreenState extends State<ScheduleFeedScreen> {
  // configurations
  static const String ipAddress = '192.168.1.1';
  static const int port = 80;
  bool isTesting = true;
  
  bool isRepeated = false;
  TimeOfDay? _selectedTime;
  final TextEditingController _gramsController = TextEditingController();

  @override
  void dispose() {
    _gramsController.dispose();
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
                                    '100 grams (demo)',
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
                        : 'Selected Time:',
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
                child: TextField(
                  controller: _gramsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    border: InputBorder.none,
                    hintText: 'Amount (grams)',
                  ),
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
                  onPressed: () {
                    if (_selectedTime != null && _gramsController.text.isNotEmpty) {
                      String formattedTime =
                          '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
                      addScheduledFeed(
                        DateTime.now().year,
                        DateTime.now().month,
                        DateTime.now().day,
                        formattedTime,
                        int.parse(_gramsController.text),
                      );
                      showToast('Feed Schedule saved!');
                      _gramsController.clear();
                      setState(() {
                        _selectedTime = null;
                      });
                    } else {
                      showToast('Please fill in all fields');
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