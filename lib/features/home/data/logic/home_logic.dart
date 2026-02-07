import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../models/study_reminder.dart';

class HomeLogic {
  final AudioPlayer _audioPlayer = AudioPlayer();

  // 1. Get Greeting
  String getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  // 2. Load Recordings
  Future<List<FileSystemEntity>> loadRecordings() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    List<FileSystemEntity> files = appDocDir.listSync();

    // Filter for .m4a and sort by newest
    var audioFiles = files.where((file) => file.path.endsWith('.m4a')).toList();
    audioFiles.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

    return audioFiles;
  }

  // 3. Audio Controls
  Future<void> playAudio(String path) async {
    await _audioPlayer.stop(); // Stop any previous audio
    await _audioPlayer.play(DeviceFileSource(path));
  }

  Future<void> stopAudio() async {
    await _audioPlayer.stop();
  }

  // Expose stream to know when audio finishes
  Stream<void> get onPlayerComplete => _audioPlayer.onPlayerComplete;

  // 4. Initial Dummy Data
  List<StudyReminder> getInitialReminders() {
    return [
      StudyReminder(
          title: "Literature Quiz",
          subject: "Literature",
          date: DateTime.now().add(const Duration(days: 2)),
          type: "Quiz"
      ),
    ];
  }
}