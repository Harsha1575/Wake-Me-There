import 'package:flutter/material.dart';
import 'map_screen.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

void playAlarm() {
  print('🚨 Alarm Triggered! Playing alarm sound...');
  // Add sound, vibration, or notification logic here
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
  runApp(MyApp());
}

void scheduleAlarm(int totalMinutes) {
  int delayMinutes = totalMinutes - 10;

  if (delayMinutes > 0) {
    print('Alarm set for $delayMinutes minutes from now.');
    AndroidAlarmManager.oneShot(
      Duration(minutes: delayMinutes),
      0, // Unique ID for the alarm
      playAlarm,
      exact: true,
      wakeup: true, // Ensures the device wakes up
    );
  } else {
    print('Triggering alarm immediately.');
    playAlarm();
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wake Me There',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MapScreen(),
    );
  }
}
