import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeedSchedule {
  final String time;
  final int grams;
  final DateTime createdAt;
  final String date;

  FeedSchedule({
    required this.time,
    required this.grams,
    required this.createdAt,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'grams': grams,
      'createdAt': createdAt.toIso8601String(),
      'date': date,
    };
  }

  factory FeedSchedule.fromJson(Map<String, dynamic> json) {
    return FeedSchedule(
      time: json['time'],
      grams: json['grams'],
      createdAt: DateTime.parse(json['createdAt']),
      date: json['date'] ?? DateFormat('MMM d, yyyy').format(DateTime.now()),
    );
  }
  
  bool isPast() {
    final now = DateTime.now();
    print("DEBUG [FeedSchedule]: Checking if schedule time ${this.time} on ${this.date} is past current time ${DateFormat('h:mm a').format(now)}");
    
    final nextOccurrence = getNextOccurrence();
    // Use seconds-level precision
    return now.isAfter(nextOccurrence) && (now.difference(nextOccurrence).inSeconds > 30);
  }
  
  DateTime getNextOccurrence() {
    final now = DateTime.now();
    
    final Map<String, int>? timeComponents = _parseTimeString(time);
    if (timeComponents == null) {
      print("DEBUG [FeedSchedule]: Failed to parse time string: $time");
      return now.add(const Duration(days: 1));
    }
    
    int hour = timeComponents['hour']!;
    final minute = timeComponents['minute']!;
    final isPm = timeComponents['isPm']! == 1;
    
    if (isPm && hour < 12) {
      hour += 12;
    } else if (!isPm && hour == 12) {
      hour = 0;
    }
    
    DateTime scheduleDate;
    try {
      scheduleDate = DateFormat('MMM d, yyyy').parse(date);
      print("DEBUG [FeedSchedule]: Parsed date: $scheduleDate from $date");
    } catch (e) {
      print("DEBUG [FeedSchedule]: Failed to parse date: $date, using today");
      scheduleDate = DateTime(now.year, now.month, now.day);
    }
    
    DateTime scheduleTime = DateTime(
      scheduleDate.year, 
      scheduleDate.month, 
      scheduleDate.day, 
      hour, 
      minute
    );
    
    if (now.isAfter(scheduleTime)) {
      print("DEBUG [FeedSchedule]: ${this.time} on ${this.date} - Time has passed, scheduling for tomorrow");
      scheduleTime = scheduleTime.add(const Duration(days: 1));
    }
    
    print("DEBUG [FeedSchedule]: ${this.time} on ${this.date} - Next occurrence: $scheduleTime");
    return scheduleTime;
  }
  
  int getMinutesUntilDue() {
    final now = DateTime.now();
    final nextOccurrence = getNextOccurrence();
    
    final minutes = nextOccurrence.difference(now).inMinutes;
    print("DEBUG [FeedSchedule]: ${this.time} on ${this.date} - Minutes until due: $minutes");
    return minutes;
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
}

class LocalStorageService {
  static const _scheduleKey = 'feed_schedules';
  
  Future<void> saveSchedule(FeedSchedule schedule) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      List<FeedSchedule> schedules = await getSchedules();
      
      bool exists = schedules.any((s) => s.time == schedule.time && s.date == schedule.date);
      if (exists) {
        // Delete the existing schedule
        await deleteSchedule(schedule.time, schedule.date);
        schedules = await getSchedules();
      }
      
      print("DEBUG [LocalStorage]: Saving schedule for ${schedule.time} on ${schedule.date} - ${schedule.grams}g");
      
      schedules.add(schedule);
      
      final jsonList = schedules.map((s) => s.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      
      await prefs.setString(_scheduleKey, jsonString);
      print("DEBUG [LocalStorage]: Saved schedule successfully");
    } catch (e) {
      print("ERROR [LocalStorage]: Error saving schedule: $e");
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_scheduleKey);
    }
  }
  
  Future<List<FeedSchedule>> getSchedules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final value = prefs.get(_scheduleKey);
      if (value != null && value is! String) {
        print("DEBUG [LocalStorage]: Found invalid data type, clearing preferences");
        await prefs.remove(_scheduleKey);
        return [];
      }
      
      final jsonString = prefs.getString(_scheduleKey);
      if (jsonString == null || jsonString.isEmpty) {
        print("DEBUG [LocalStorage]: No schedules found");
        return [];
      }
      
      try {
        final jsonList = jsonDecode(jsonString) as List;
        final schedules = jsonList.map((json) => FeedSchedule.fromJson(json as Map<String, dynamic>)).toList();
        print("DEBUG [LocalStorage]: Retrieved ${schedules.length} schedules");
        return schedules;
      } catch (e) {
        print("ERROR [LocalStorage]: Error parsing schedule JSON: $e");
        // Reset preferences if there's an error
        await prefs.remove(_scheduleKey);
        return [];
      }
    } catch (e) {
      print("ERROR [LocalStorage]: Error retrieving schedules: $e");
      return [];
    }
  }
  
  Future<void> deleteSchedule(String time, [String? date]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final schedules = await getSchedules();
      final updatedSchedules = schedules.where((s) => 
        date != null ? !(s.time == time && s.date == date) : s.time != time
      ).toList();
      
      print("DEBUG [LocalStorage]: Deleting schedule for $time on ${date ?? 'any date'}");
      
      // Convert to JSON
      final jsonList = updatedSchedules.map((s) => s.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      
      await prefs.setString(_scheduleKey, jsonString);
    } catch (e) {
      print("ERROR [LocalStorage]: Error deleting schedule: $e");
    }
  }
  
  Future<void> removeCompletedSchedules() async {
    try {
      final schedules = await getSchedules();
      if (schedules.isEmpty) return;
      
      final now = DateTime.now();
      
      final String formattedHour = now.hour == 0 ? "12" : 
                               (now.hour > 12 ? "${now.hour - 12}" : "${now.hour}");
      final String formattedMinute = now.minute.toString().padLeft(2, '0');
      final String period = now.hour < 12 ? 'am' : 'pm';
      final String currentTimeStr = "$formattedHour:$formattedMinute$period";
      
      print("DEBUG [LocalStorage]: Current time for removal check: $currentTimeStr");
      print("DEBUG [LocalStorage]: Checking schedules: ${schedules.map((s) => '${s.time} on ${s.date}').toList()}");
      
      bool removedAny = false;
      
      for (var schedule in schedules) {
        if (schedule.isPast()) {
          print("DEBUG [LocalStorage]: Removing past schedule: ${schedule.time} on ${schedule.date}");
          await deleteSchedule(schedule.time, schedule.date);
          removedAny = true;
        }
      }
    } catch (e) {
      print("ERROR [LocalStorage]: Error removing completed schedules: $e");
    }
  }
  
  Future<FeedSchedule?> getNextSchedule() async {
    try {
      final schedules = await getSchedules();
      if (schedules.isEmpty) return null;
      
      schedules.sort((a, b) => 
        a.getNextOccurrence().compareTo(b.getNextOccurrence())
      );
      
      final nextSchedule = schedules.first;
      print("DEBUG [LocalStorage]: Next schedule: ${nextSchedule.time} on ${nextSchedule.date} - ${nextSchedule.grams}g");
      
      return nextSchedule;
    } catch (e) {
      print("ERROR [LocalStorage]: Error getting next schedule: $e");
      return null;
    }
  }
  
  Future<int> getMinutesUntilNextSchedule() async {
    try {
      final nextSchedule = await getNextSchedule();
      if (nextSchedule == null) return -1; // No schedules
      
      return nextSchedule.getMinutesUntilDue();
    } catch (e) {
      print("ERROR [LocalStorage]: Error calculating minutes until next schedule: $e");
      return -1;
    }
  }
  
  Future<void> resetAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print("DEBUG [LocalStorage]: Reset all data");
    } catch (e) {
      print("ERROR [LocalStorage]: Error resetting data: $e");
    }
  }
} 