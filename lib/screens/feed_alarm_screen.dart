import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:pet_feeder/main.dart' as main_app;
import 'package:pet_feeder/screens/home_screen.dart';
import 'package:pet_feeder/services/local_storage_service.dart';
import 'package:pet_feeder/utils/colors.dart';
import 'package:pet_feeder/widgets/text_widget.dart';

class FeedAlarmScreen extends StatefulWidget {
  final FeedSchedule schedule;
  
  const FeedAlarmScreen({
    super.key,
    required this.schedule,
  });

  @override
  State<FeedAlarmScreen> createState() => _FeedAlarmScreenState();
}

class _FeedAlarmScreenState extends State<FeedAlarmScreen> with WidgetsBindingObserver {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final LocalStorageService _storageService = LocalStorageService();
  bool _isPlaying = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print("DEBUG [FeedAlarmScreen]: Initialized for schedule - time: ${widget.schedule.time}, grams: ${widget.schedule.grams}");
    _playAlarm();
  }
  
  @override
  void dispose() {
    _stopAlarm();
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.dispose();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _playAlarm();
    } else {
      _stopAlarm();
    }
  }
  
  Future<void> _playAlarm() async {
    try {
      print("DEBUG [FeedAlarmScreen]: Playing alarm sound");
      await _audioPlayer.play(AssetSource('images/sound.wav'));
      _audioPlayer.setReleaseMode(ReleaseMode.loop);
      setState(() {
        _isPlaying = true;
      });
      print("DEBUG [FeedAlarmScreen]: Alarm sound playing successfully");
    } catch (e) {
      print("DEBUG [FeedAlarmScreen]: Error playing alarm sound: $e");
    }
  }
  
  Future<void> _stopAlarm() async {
    if (_isPlaying) {
      print("DEBUG [FeedAlarmScreen]: Stopping alarm sound");
      await _audioPlayer.stop();
      setState(() {
        _isPlaying = false;
      });
    }
  }

  Future<void> _deleteSchedule() async {
    try {
      print("DEBUG [FeedAlarmScreen]: Deleting schedule - time: ${widget.schedule.time}, date: ${widget.schedule.date}");
      await _storageService.deleteSchedule(widget.schedule.time, widget.schedule.date);
      
      // Refresh the countdown timer after deleting a schedule
      await main_app.refreshScheduleCountdown();
      
      print("DEBUG [FeedAlarmScreen]: Schedule deleted successfully");
    } catch (e) {
      print("ERROR [FeedAlarmScreen]: Error deleting schedule: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _stopAlarm();
        
        // Delete the schedule when using back button
        await _deleteSchedule();
        
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Icon(
                    Icons.notifications_active,
                    size: 80,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 30),
                TextWidget(
                  text: 'Time to Feed Your Pet!',
                  fontSize: 24,
                  color: primary,
                  fontFamily: 'Bold',
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      TextWidget(
                        text: 'Schedule Details',
                        fontSize: 18,
                        color: Colors.grey.shade700,
                        fontFamily: 'Medium',
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.access_time, color: primary),
                          const SizedBox(width: 10),
                          TextWidget(
                            text: widget.schedule.time,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today, color: primary),
                          const SizedBox(width: 10),
                          TextWidget(
                            text: widget.schedule.date,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.pets, color: primary),
                          const SizedBox(width: 10),
                          TextWidget(
                            text: '${widget.schedule.grams} grams',
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                GestureDetector(
                  onTap: () async {
                    _stopAlarm();
                    await _deleteSchedule();
                    
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => HomeScreen(
                          preselectedGrams: widget.schedule.grams,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primary.withOpacity(0.3),
                          spreadRadius: 3,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'FEED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                TextButton(
                  onPressed: () async {
                    _stopAlarm();
                    
                    await _deleteSchedule();
                    
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Dismiss',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 