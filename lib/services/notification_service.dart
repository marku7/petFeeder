import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_init;
import 'package:intl/intl.dart';
import 'package:pet_feeder/services/local_storage_service.dart';
import 'package:pet_feeder/screens/feed_alarm_screen.dart';
import 'package:pet_feeder/screens/home_screen.dart';
import 'package:pet_feeder/screens/notification_screen.dart';
import 'package:pet_feeder/main.dart' as main_app;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  final LocalStorageService _storageService = LocalStorageService();

  static const String channelId = 'pet_feeder_channel';
  static const String channelName = 'Pet Feeder Notifications';
  static const String channelDescription = 'Scheduled pet feeding notifications';
  
  static const String feedTimeAction = 'FEED_TIME_ACTION';
  static const String feedScheduleInfo = 'FEED_SCHEDULE_INFO';
  
  // Notification type identifier
  static const String exactTimeNotif = "EXACT_TIME";

  Future<void> initialize() async {
    tz_init.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initializationSettings = 
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );
    
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print("DEBUG [NotificationService]: Notification tapped: ${response.id}");
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (main_app.navigatorKey.currentState != null) {
            main_app.navigatorKey.currentState!.push(
              MaterialPageRoute(
                builder: (context) => const NotificationScreen(),
              ),
            );
          }
        });
      },
    );
    
    await _createNotificationChannel();
    await _requestPermissions();
  }
  
  void _handleNotificationResponse(NotificationResponse response) {
    print("DEBUG [NotificationService]: Handling notification response: ${response.id}, ${response.payload}");
    
    if (response.payload != null) {
      try {
        final payloadData = response.payload!.split('|');
        if (payloadData.length >= 3) {
          final time = payloadData[0];
          final grams = int.parse(payloadData[1]);
          final date = payloadData[2];
          
          _storageService.deleteSchedule(time, date);
          
          if (response.notificationResponseType == NotificationResponseType.selectedNotification) {
            navigateToFeedAlarmScreen(time, grams, date);
          } else {
            main_app.refreshScheduleCountdown();
          }
        }
      } catch (e) {
        print("ERROR [NotificationService]: Error parsing notification payload: $e");
      }
    } else {
      if (main_app.navigatorKey.currentState != null) {
        main_app.navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (context) => const NotificationScreen(),
          ),
        );
      }
    }
  }
  
  static void _handleBackgroundNotificationResponse(NotificationResponse response) {
    print("DEBUG [NotificationService]: Received background notification response");
    
    if (response.payload != null) {
      try {
        final payloadData = response.payload!.split('|');
        if (payloadData.length >= 3) {
          final time = payloadData[0];
          final date = payloadData[2];
          
          print("DEBUG [NotificationService]: Extracted background payload - time: $time, date: $date");
          
          final storageService = LocalStorageService();
          storageService.deleteSchedule(time, date);
        }
      } catch (e) {
        print("ERROR [NotificationService]: Error in background notification handling: $e");
      }
    }
  }
  
  void navigateToFeedAlarmScreen(String time, int grams, String date) {
    try {
      final schedule = FeedSchedule(
        time: time,
        grams: grams,
        createdAt: DateTime.now(),
        date: date,
      );
      
      if (main_app.navigatorKey.currentState != null) {
        main_app.navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (context) => FeedAlarmScreen(schedule: schedule),
          ),
        );
      }
    } catch (e) {
      print("ERROR [NotificationService]: Error navigating to feed alarm screen: $e");
    }
  }
  
  void navigateToHomeScreen(int grams) {
    try {
      if (main_app.navigatorKey.currentState != null) {
        main_app.navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (context) => HomeScreen(preselectedGrams: grams),
          ),
        );
      }
    } catch (e) {
      print("ERROR [NotificationService]: Error navigating to home screen: $e");
    }
  }
  
  Future<void> _requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      print("DEBUG [NotificationService]: Android notification permissions requested");
    }
  }
  
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.max,
      enableLights: true,
      enableVibration: true,
      showBadge: true,
    );
    
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    
    print("DEBUG [NotificationService]: Notification channel created");
  }

  Future<void> scheduleFeedNotification(String time, int grams, [String? date]) async {
    print("DEBUG [NotificationService]: Scheduling notification for time: $time, date: ${date ?? 'today'}, grams: $grams");
    final timeComponents = _parseTimeString(time);
    if (timeComponents == null) {
      print("DEBUG [NotificationService]: Failed to parse time string: $time");
      return;
    }

    final int hour = timeComponents['hour']!;
    final int minute = timeComponents['minute']!;
    final bool isPm = timeComponents['isPm']! == 1;

    int hour24 = hour;
    if (isPm && hour != 12) {
      hour24 = hour + 12;
    } else if (!isPm && hour == 12) {
      hour24 = 0;
    }

    final DateTime now = DateTime.now();
    final String formattedDate = date ?? DateFormat('MMM d, yyyy').format(now);
    
    DateTime scheduledDate;
    try {
      final DateTime parsedDate = DateFormat('MMM d, yyyy').parse(formattedDate);
      scheduledDate = DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
        hour24,
        minute,
      );
    } catch (e) {
      scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        hour24,
        minute,
      );
    }

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    print("DEBUG [NotificationService]: Feed time: ${scheduledDate.toString()}");
    
    if (scheduledDate.isBefore(now)) {
      // If already in the past, schedule for next available time (5 seconds from now)
      scheduledDate = now.add(const Duration(seconds: 5));
    }

    final tz.TZDateTime exactFeedTzTime = tz.TZDateTime.from(scheduledDate, tz.local);
    
    final String idString = (formattedDate) + time;
    final int feedTimeNotificationId = idString.hashCode;
    
    // Create payload for exact time notification
    final String notificationPayload = "$time|$grams|$formattedDate";
    
    try {
      // Cancel any existing notifications
      await flutterLocalNotificationsPlugin.cancel(feedTimeNotificationId);
    } catch (e) {
      print("DEBUG [NotificationService]: Error cancelling existing notifications: $e");
    }
    
    const AndroidNotificationDetails feedTimeAndroidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      styleInformation: BigTextStyleInformation(''),
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      autoCancel: false,
      playSound: true,
      enableLights: true,
      enableVibration: true,
      ticker: 'Pet Feeding Time Now',
    );
    
    const NotificationDetails feedTimeDetails = NotificationDetails(
      android: feedTimeAndroidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    
    final String dateDisplay = date != null ? " on $formattedDate" : "";
    
    await flutterLocalNotificationsPlugin.zonedSchedule(
      feedTimeNotificationId,
      'Time to Feed Your Pet!',
      'Feed your pet $grams grams of food now!',
      exactFeedTzTime,
      feedTimeDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: notificationPayload,
    );
    
    print("DEBUG [NotificationService]: Feed time notification scheduled successfully with id: $feedTimeNotificationId");
  }

  Map<String, int>? _parseTimeString(String timeString) {
    final RegExp timeRegex = RegExp(r'(\d+):(\d+)(am|pm)');
    final match = timeRegex.firstMatch(timeString);
    
    if (match == null) return null;
    
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final isPm = match.group(3) == 'pm';
    
    return {
      'hour': hour,
      'minute': minute,
      'isPm': isPm ? 1 : 0,
    };
  }
  
  Future<void> scheduleImmediateTestNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      playSound: true,
    );
    
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    
    await flutterLocalNotificationsPlugin.show(
      999,
      'Test Notification',
      'This is a test notification to verify that the notification system is working properly.',
      platformDetails,
    );
    
    print("DEBUG [NotificationService]: Test notification sent successfully");
  }

  Future<void> showPetDetectionNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'pet_detection_channel',
      'Pet Detection',
      channelDescription: 'Notifications for pet detection',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      autoCancel: true,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      'Pet Detected!',
      'Your pet has been detected near the feeder',
      details,
    );
  }
} 