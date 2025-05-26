import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pet_feeder/firebase_options.dart';
import 'package:pet_feeder/screens/feed_alarm_screen.dart';
import 'package:pet_feeder/screens/splash_screen.dart';
import 'package:pet_feeder/screens/notification_screen.dart';
import 'package:pet_feeder/services/local_storage_service.dart';
import 'package:pet_feeder/services/notification_service.dart';
import 'package:pet_feeder/services/pet_detection_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Timer? _scheduleTimer;
FeedSchedule? _nextSchedule;
BuildContext? _navigationContext;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print("DEBUG [Main]: App starting up");
  
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  
  try {
    await NotificationService().initialize();
    print("DEBUG [Main]: Notification service initialized");
    
    setupNotificationClickHandling();
    
    await PetDetectionService().startMonitoring();
    print("DEBUG [Main]: Pet detection service started");
    
    await Firebase.initializeApp(
      name: 'petfeeding-41649',
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    print("DEBUG [Main]: Setting up schedule countdown");
    
    try {
      final storageService = LocalStorageService();
      await storageService.removeCompletedSchedules();
      
      await setupScheduleCountdown();
      
      await rescheduleAllNotifications();
    } catch (e) {
      print("ERROR [Main]: Error during initialization, resetting data: $e");
      await LocalStorageService().resetAllData();
    }
  } catch (e) {
    print("ERROR [Main]: Fatal error during initialization: $e");
  }
  
  runApp(const MyApp());
}

void setupNotificationClickHandling() {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails().then((details) {
    if (details != null && details.didNotificationLaunchApp) {
      print("DEBUG [Main]: App launched from notification: ${details.notificationResponse?.id}");
      
      if (details.notificationResponse?.payload != null) {
        final payload = details.notificationResponse!.payload!;
        handleNotificationPayload(payload);
      } else {
        // Only show pet detection screen if no payload (pet detection doesn't use a payload)
        if (navigatorKey.currentState != null) {
          navigatorKey.currentState!.push(
            MaterialPageRoute(
              builder: (context) => const NotificationScreen(),
            ),
          );
        }
      }
    }
  });
}

void openPetDetectionScreen() {
  Future.delayed(const Duration(milliseconds: 500), () {
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (context) => const NotificationScreen(),
        ),
      );
    }
  });
}

void handleNotificationPayload(String payload) {
  try {
    final payloadParts = payload.split('|');
    if (payloadParts.length >= 3) {
      final time = payloadParts[0];
      final grams = int.parse(payloadParts[1]);
      final date = payloadParts[2];
      
      print("DEBUG [Main]: Handling notification payload - time: $time, grams: $grams, date: $date");
      
      final schedule = FeedSchedule(
        time: time,
        grams: grams,
        createdAt: DateTime.now(),
        date: date,
      );
      
      Future.delayed(const Duration(milliseconds: 500), () {
        if (navigatorKey.currentState != null) {
          navigatorKey.currentState!.push(
            MaterialPageRoute(
              builder: (context) => FeedAlarmScreen(schedule: schedule),
            ),
          );
        }
      });
    }
  } catch (e) {
    print("ERROR [Main]: Error handling notification payload: $e");
  }
}

Future<void> rescheduleAllNotifications() async {
  try {
    final storage = LocalStorageService();
    final schedules = await storage.getSchedules();
    
    print("DEBUG [Main]: Rescheduling all notifications for ${schedules.length} schedules");
    
    for (final schedule in schedules) {
      await NotificationService().scheduleFeedNotification(
        schedule.time,
        schedule.grams,
        schedule.date
      );
    }
    
    print("DEBUG [Main]: All notifications rescheduled");
  } catch (e) {
    print("ERROR [Main]: Failed to reschedule notifications: $e");
  }
}

Future<void> setupScheduleCountdown() async {
  try {
    // Cancel any existing timer
    _scheduleTimer?.cancel();
    
    final storageService = LocalStorageService();
    
    _nextSchedule = await storageService.getNextSchedule();
    
    if (_nextSchedule == null) {
      print("DEBUG [Main]: No scheduled feeds found");
      return;
    }
    
    final minutesUntil = _nextSchedule!.getMinutesUntilDue();
    
    print("DEBUG [Main]: Next schedule (${_nextSchedule!.time}, ${_nextSchedule!.grams}g) due in $minutesUntil minutes");
    
    if (minutesUntil <= 2) {
      print("DEBUG [Main]: Schedule due in less than 2 minutes, checking every 5 seconds");
      _scheduleTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        _checkCurrentSchedule();
      });
    } else {
      final timerDuration = Duration(minutes: minutesUntil > 2 ? minutesUntil - 2 : 0);
      
      print("DEBUG [Main]: Setting timer for ${timerDuration.inMinutes} minutes before starting frequent checks");
      
      _scheduleTimer = Timer(timerDuration, () {
        print("DEBUG [Main]: Starting frequent checks for schedule");
        _scheduleTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
          _checkCurrentSchedule();
        });
      });
    }
  } catch (e) {
    print("ERROR [Main]: Error in setupScheduleCountdown: $e");
  }
}

void _checkCurrentSchedule() async {
  try {
    if (_nextSchedule == null) return;
    
    final now = DateTime.now();
    
    final String formattedHour = now.hour == 0 ? "12" : 
                               (now.hour > 12 ? "${now.hour - 12}" : "${now.hour}");
    final String formattedMinute = now.minute.toString().padLeft(2, '0');
    final String period = now.hour < 12 ? 'am' : 'pm';
    final String currentTime = "$formattedHour:$formattedMinute$period";
    
    print("DEBUG [Main-Check]: Current time: $currentTime, Target time: ${_nextSchedule!.time}");
    
    final nextOccurrence = _nextSchedule!.getNextOccurrence();
    final diffInSeconds = nextOccurrence.difference(now).inSeconds;
    
    print("DEBUG [Main-Check]: Seconds until scheduled time: $diffInSeconds");
    
    if (currentTime == _nextSchedule!.time) {
      print("DEBUG [Main-Check]: TIME MATCH! Triggering feed alarm");
      
      _scheduleTimer?.cancel();
      
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (context) => FeedAlarmScreen(schedule: _nextSchedule!),
          ),
        );
      }
      
      await LocalStorageService().removeCompletedSchedules();
      
      await setupScheduleCountdown();
    } else {
      final minutesUntil = _nextSchedule!.getMinutesUntilDue();
      
      if (minutesUntil > 60 || (diffInSeconds < -60)) {
        print("DEBUG [Main-Check]: Resetting countdown - either far in future or we missed it");
        _scheduleTimer?.cancel();
        await setupScheduleCountdown();
      }
    }
  } catch (e) {
    print("ERROR [Main-Check]: Error checking current schedule: $e");
    _scheduleTimer?.cancel();
    await setupScheduleCountdown();
  }
}

Future<void> refreshScheduleCountdown() async {
  try {
    print("DEBUG [Main]: Refreshing schedule countdown");
    await setupScheduleCountdown();
    await rescheduleAllNotifications();
  } catch (e) {
    print("ERROR [Main]: Error refreshing schedule countdown: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'FeediPaw',
      home: const SplashScreen(),
    );
  }
}
