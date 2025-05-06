import 'package:intl/intl.dart';
import 'package:pet_feeder/services/local_storage_service.dart';

Future addScheduledFeed(String time, int grams) async {
  final schedule = FeedSchedule(
    time: time,
    grams: grams,
    createdAt: DateTime.now(),
    date: DateFormat('MMM d, yyyy').format(DateTime.now()),
  );

  await LocalStorageService().saveSchedule(schedule);
  return true;
}
