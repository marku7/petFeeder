import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:pet_feeder/main.dart' as main_app;
import 'package:pet_feeder/screens/feed_alarm_screen.dart';
import 'package:pet_feeder/services/local_storage_service.dart';
import 'package:pet_feeder/utils/colors.dart';
import 'package:pet_feeder/widgets/text_widget.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  List<FeedSchedule> _schedules = [];
  bool _isLoading = true;
  Timer? _checkTimer;
  bool _shouldCheckActiveSchedules = true;
  
  @override
  void initState() {
    super.initState();
    _loadSchedules();
    
    // Set up a timer to check every 5 seconds while on this screen
    _checkTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_shouldCheckActiveSchedules) {
        _checkActiveSchedules();
      }
    });
  }
  
  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSchedules() async {
    setState(() {
      _isLoading = true;
      // Temporarily disable active schedule checking during refresh
      _shouldCheckActiveSchedules = false;
    });
    
    try {
      await _storageService.removeCompletedSchedules();
      
      final schedules = await _storageService.getSchedules();
      
      setState(() {
        _schedules = schedules;
        _isLoading = false;
        // Re-enable active schedule checking after data is loaded
        _shouldCheckActiveSchedules = true;
      });
    } catch (e) {
      print("ERROR [SchedulesScreen]: Error loading schedules: $e");
      setState(() {
        _isLoading = false;
        _shouldCheckActiveSchedules = true;
      });
    }
  }
  
  Future<void> _refreshScheduleCountdown() async {
    // Call the global method to refresh the countdown timer
    await main_app.refreshScheduleCountdown();
  }

  void _checkActiveSchedules() {
    final now = DateTime.now();
    
    // Format time to match stored format (e.g., "8:30am" not "8:30 am")
    final String formattedHour = now.hour == 0 ? "12" : 
                               (now.hour > 12 ? "${now.hour - 12}" : "${now.hour}");
    final String formattedMinute = now.minute.toString().padLeft(2, '0');
    final String period = now.hour < 12 ? 'am' : 'pm';
    final String currentTime = "$formattedHour:$formattedMinute$period";
    final String currentDate = DateFormat('MMM d, yyyy').format(now);
    
    print("DEBUG [SchedulesScreen]: Checking active schedules. Current time: $currentTime, Date: $currentDate");
    
    if (_schedules.isEmpty) {
      return;
    }
    
    print("DEBUG [SchedulesScreen]: Available schedules: ${_schedules.map((s) => '${s.time} on ${s.date}').toList()}");

    for (var schedule in _schedules) {
      // Only trigger the alarm exactly at the match time, not when refreshing the list
      if (schedule.time == currentTime && !_isLoading) {
        // Check if the date matches or if it's due today based on scheduling logic
        final DateTime nextOccurrence = schedule.getNextOccurrence();
        final bool isDueNow = now.difference(nextOccurrence).inMinutes.abs() <= 1;
        
        if (isDueNow) {
          print("DEBUG [SchedulesScreen]: Found matching schedule! Time: ${schedule.time}, Date: ${schedule.date}, Grams: ${schedule.grams}");
          WidgetsBinding.instance.addPostFrameCallback(
            (timeStamp) {
              print("DEBUG [SchedulesScreen]: Launching feed alarm screen for ${schedule.time} on ${schedule.date}");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: primary,
        title: TextWidget(
          text: 'Schedules',
          fontSize: 18,
          color: Colors.white,
        ),
        actions: [
          IconButton(
            onPressed: () async {
              // Temporarily disable active schedule checking during refresh
              setState(() {
                _shouldCheckActiveSchedules = false;
              });
              
              await _loadSchedules();
              await _refreshScheduleCountdown();
              
              // Re-enable after the refresh is complete
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
      body: _isLoading
          ? const Padding(
                padding: EdgeInsets.only(top: 50),
                child: Center(
                    child: CircularProgressIndicator(
                  color: Colors.black,
                )),
            )
          : _schedules.isEmpty
              ? const Center(child: Text('No schedules available'))
              : ListView.builder(
                  itemCount: _schedules.length,
              itemBuilder: (context, index) {
                    final schedule = _schedules[index];
                    final minutesUntil = schedule.getMinutesUntilDue();
                    
                    return Dismissible(
                      key: Key(index.toString() + schedule.time + schedule.date),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) async {
                        await _storageService.deleteSchedule(schedule.time, schedule.date);
                        await _refreshScheduleCountdown();
                        setState(() {
                          _schedules.removeAt(index);
                        });
                      },
                      child: ListTile(
                        leading: const Icon(Icons.calendar_month),
                        title: TextWidget(
                          text: 'Scheduled feed: ${schedule.time}',
                          fontSize: 18,
                          fontFamily: 'Bold',
                        ),
                        subtitle: Text(
                          '${schedule.grams} grams • ${schedule.date}' + 
                          (minutesUntil < 60 ? ' • Coming up in $minutesUntil min' : '')
                    ),
                  ),
                );
              },
                ),
    );
  }
}
