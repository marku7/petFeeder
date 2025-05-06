import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:pet_feeder/main.dart' as main_app;
import 'package:pet_feeder/screens/schedules_screen.dart';
import 'package:pet_feeder/screens/feed_alarm_screen.dart';
import 'package:pet_feeder/services/local_storage_service.dart';
import 'package:pet_feeder/services/notification_service.dart';
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
  final LocalStorageService _storageService = LocalStorageService();
  List<FeedSchedule> _schedules = [];
  bool _isLoading = true;
  int selectedValue = 1;
  TimeOfDay? _selectedTime;
  DateTime _selectedDate = DateTime.now();
  bool _shouldCheckActiveSchedules = true;
  
  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() {
      _isLoading = true;
      _shouldCheckActiveSchedules = false;
    });
    
    try {
      await _storageService.removeCompletedSchedules();
      
      final schedules = await _storageService.getSchedules();
      
      setState(() {
        _schedules = schedules;
        _isLoading = false;
        _shouldCheckActiveSchedules = true;
      });
      
      if (_shouldCheckActiveSchedules) {
        _checkActiveSchedules();
      }
    } catch (e) {
      print("ERROR [ScheduleFeed]: Error loading schedules: $e");
      setState(() {
        _isLoading = false;
        _shouldCheckActiveSchedules = true;
      });
    }
  }
  
  void _checkActiveSchedules() {
    final now = DateTime.now();
    
    final String formattedHour = now.hour == 0 ? "12" : 
                               (now.hour > 12 ? "${now.hour - 12}" : "${now.hour}");
    final String formattedMinute = now.minute.toString().padLeft(2, '0');
    final String period = now.hour < 12 ? 'am' : 'pm';
    final String currentTime = "$formattedHour:$formattedMinute$period";
    final String currentDate = DateFormat('MMM d, yyyy').format(now);
    
    print("DEBUG [ScheduleFeed]: Checking active schedules. Current time: $currentTime, Date: $currentDate");
    
    if (_schedules.isEmpty) {
      return;
    }
    
    print("DEBUG [ScheduleFeed]: Available schedules: ${_schedules.map((s) => '${s.time} on ${s.date}').toList()}");

    for (var schedule in _schedules) {
      if (schedule.time == currentTime && !_isLoading) {
        final DateTime nextOccurrence = schedule.getNextOccurrence();
        final bool isDueNow = now.difference(nextOccurrence).inMinutes.abs() <= 1;
        
        if (isDueNow) {
          print("DEBUG [ScheduleFeed]: Found matching schedule! Time: ${schedule.time}, Date: ${schedule.date}, Grams: ${schedule.grams}");
          WidgetsBinding.instance.addPostFrameCallback(
            (timeStamp) {
              print("DEBUG [ScheduleFeed]: Launching feed alarm screen for ${schedule.time} on ${schedule.date}");
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => FeedAlarmScreen(schedule: schedule),
              ));
            },
          );
          break;
        }
      }
    }
  }
  
  Future<void> _refreshScheduleCountdown() async {
    await main_app.refreshScheduleCountdown();
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
                  builder: (context) => const SchedulesScreen())).then((_) {
                _loadSchedules();
                _refreshScheduleCountdown();
              });
            },
            icon: const Icon(
              Icons.calendar_month,
            ),
          ),
          IconButton(
            onPressed: () async {
              setState(() {
                _shouldCheckActiveSchedules = false;
              });
              
              await _loadSchedules();
              await _refreshScheduleCountdown();
              
              // Re-enable after a short delay
              Future.delayed(const Duration(milliseconds: 500), () {
                setState(() {
                  _shouldCheckActiveSchedules = true;
                });
              });
            },
            icon: const Icon(
              Icons.refresh,
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _schedules.isEmpty
                        ? const Center(child: Text('No schedules'))
                        : ListView.builder(
                            itemCount: _schedules.length,
                      itemBuilder: (context, index) {
                              final schedule = _schedules[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                            children: [
                              const Icon(Icons.calendar_today),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                              '${schedule.grams} grams',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                              '${schedule.time} - ${schedule.date}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () async {
                                        await _storageService.deleteSchedule(schedule.time, schedule.date);
                                        showToast('Schedule deleted');
                                        _loadSchedules();
                                        _refreshScheduleCountdown();
                      },
                                    ),
                                  ],
                                ),
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
                child: ListTile(
                  title: Text(
                    DateFormat('MMM d, yyyy').format(_selectedDate),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        _selectedDate = pickedDate;
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
                    backgroundColor: _selectedTime != null ? primary : Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _selectedTime == null ? null : () async {
                      final hour = _selectedTime!.hourOfPeriod;
                      final minute = _selectedTime!.minute;
                      final period = _selectedTime!.period == DayPeriod.am ? 'am' : 'pm';
                      final formattedTime = '$hour:${minute.toString().padLeft(2, '0')}$period';
                      final formattedDate = DateFormat('MMM d, yyyy').format(_selectedDate);
                      final grams = getGramsFromValue(selectedValue);

                    final schedule = FeedSchedule(
                      time: formattedTime,
                      grams: grams,
                      createdAt: DateTime.now(),
                      date: formattedDate,
                    );
                    
                    if (schedule.isPast()) {
                      showToast('Cannot schedule a time that has already passed for the selected date');
                      return;
                    }
                    
                    final minutesUntil = schedule.getMinutesUntilDue();
                    
                    await _storageService.saveSchedule(schedule);

                    await NotificationService().scheduleFeedNotification(
                          formattedTime,
                          grams,
                          formattedDate
                        );

                    // Show more informative toast message
                    if (minutesUntil < 1) {
                      showToast('Feed scheduled for right now!');
                    } else if (minutesUntil == 1) {
                      showToast('Feed scheduled in 1 minute. Notification will appear shortly!');
                    } else {
                      showToast('Feed scheduled for $formattedTime on $formattedDate.');
                    }
                    
                        setState(() {
                          _selectedTime = null;
                          _selectedDate = DateTime.now();
                          selectedValue = 1;
                        });
                    
                    _loadSchedules();
                    _refreshScheduleCountdown();
                  },
                  child: Text(
                    'Save',
                    style: TextStyle(
                      color: _selectedTime != null ? Colors.white : Colors.black,
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