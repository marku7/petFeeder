import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:pet_feeder/screens/home_screen.dart';
import 'package:pet_feeder/widgets/button_widget.dart';
import 'package:pet_feeder/widgets/text_widget.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    playAudio();
  }

  late AudioPlayer player = AudioPlayer();
  playAudio() async {
    player.setReleaseMode(ReleaseMode.loop);
    player.setVolume(1);

    await player.setSource(
      AssetSource(
        'images/sound.wav',
      ),
    );

    await player.resume();
  }

  pauseAudio() async {
    await player.stop();
  }

  @override
  void dispose() {
    super.dispose();
    pauseAudio();

    player.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              height: 50,
            ),
            TextWidget(
              text: 'Click the FEED BUTTON in your Device!',
              fontSize: 18,
              color: Colors.red,
              fontFamily: 'Bold',
            ),
            const SizedBox(
              height: 50,
            ),
            Image.asset('assets/images/alarm.gif'),
            const Expanded(
              child: SizedBox(
                height: 50,
              ),
            ),
            ButtonWidget(
              radius: 100,
              color: Colors.red,
              label: 'Done Feeding',
              onPressed: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (context) => const HomeScreen()));
              },
            ),
            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: Colors.green,
      //   child: const Icon(
      //     Icons.done,
      //     color: Colors.white,
      //   ),
      //   onPressed: () {},
      // ),
    );
  }
}
