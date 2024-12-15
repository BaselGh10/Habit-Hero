import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:timezone/timezone.dart' as tz;
String habit_name='';
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initializeNotifications() async {
  //tz.initializeTimeZones(); // Ensure this is called
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}
DateTime createDateTime(int hour, int minute) {
  DateTime now = DateTime.now(); // Get the current date and time

  // Create a DateTime object with the specified hour and minute
  return DateTime(now.year, now.month, now.day, hour, minute);
}
Future<void> checkAndScheduleReminder(String userId, String habitName) async {
  try {
    FirebaseFirestore db = FirebaseFirestore.instance;

    // Fetch habit information
    DocumentSnapshot habitDoc = await db
        .collection('Users')
        .doc(userId)
        .collection('Habit_$habitName')
        .doc('Method_info')
        .get();

    if (habitDoc.exists) {
      Map<String, dynamic> habitData = habitDoc.data() as Map<String, dynamic>;
      int weekCurr = habitData['week_curr'] as int;
      int weekGoal = habitData['week_goal'] as int;

      // Check if week_curr is less than week_goal
      if (weekCurr < weekGoal) {
        // Fetch reminder time
        DocumentSnapshot reminderDoc = await db
            .collection('Users')
            .doc(userId)
            .collection('Habit_$habitName')
            .doc('Reminder_info')
            .get();

        if (reminderDoc.exists) {
          Map<String, dynamic> reminderData =
              reminderDoc.data() as Map<String, dynamic>;
          int reminderHour = reminderData['hour'] as int;
          int reminderMinute = reminderData['minute'] as int;
          

          // Schedule notification
          await scheduleNotification(reminderHour, reminderMinute, habitName);
        } else {
          print('Reminder document does not exist.');
        }
      }
    } else {

      FirebaseFirestore db = FirebaseFirestore.instance;

      // Fetch habit information
      DocumentSnapshot habitDoc = await db
          .collection('Users')
          .doc(userId)
          .collection('SharedHabit_$habitName')
          .doc('Method_info')
          .get();

      if (habitDoc.exists) {
        Map<String, dynamic> habitData = habitDoc.data() as Map<String, dynamic>;
        int weekCurr = habitData['week_curr'] as int;
        int weekGoal = habitData['week_goal'] as int;

        // Check if week_curr is less than week_goal
        if (weekCurr < weekGoal) {
          // Fetch reminder time
          DocumentSnapshot reminderDoc = await db
              .collection('Users')
              .doc(userId)
              .collection('SharedHabit_$habitName')
              .doc('Reminder_info')
              .get();

          if (reminderDoc.exists) {
            Map<String, dynamic> reminderData =
                reminderDoc.data() as Map<String, dynamic>;
            int reminderHour = reminderData['hour'] as int;
            int reminderMinute = reminderData['minute'] as int;
            

            // Schedule notification
            await scheduleNotification(reminderHour, reminderMinute, habitName);
          } else {
            print('Reminder document does not exist.');
          }
        }
      }
      else print('Habit document does not exist.');

    }
  } catch (e) {
    print('Error checking habit information: $e');
  }
}

Future<void> scheduleNotification(
    int hour, int minute, String habitName) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'your_channel_id',
    'your_channel_name',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker',
  );
  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);
DateTime notificationTime = createDateTime(hour, minute);
  // Schedule notification
await flutterLocalNotificationsPlugin.zonedSchedule(
    0,
    'Habit Reminder',
    'It\'s time to complete your habit: $habitName',
    tz.TZDateTime.from(notificationTime, tz.local),
    platformChannelSpecifics,
    payload: 'Reminder Payload',
    androidAllowWhileIdle: true,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.wallClockTime,
  );
  scheduleFirestoreUpdate( habitName, tz.TZDateTime.from(notificationTime, tz.local));

}


Future<void> cancelNotification() async {
  await flutterLocalNotificationsPlugin.cancel(0);
}

Future<void> scheduleFirestoreUpdate(
 String habitName, tz.TZDateTime scheduledDate) async {
  final Duration timeUntilUpdate =
      scheduledDate.difference(tz.TZDateTime.now(tz.local));

  // Wait until the scheduled time
  Future.delayed(timeUntilUpdate, () async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final notificationsRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('notifications');

      final ref = FirebaseStorage.instance.ref().child('app_images/alarm.png');
      String url = await ref.getDownloadURL();

      await notificationsRef.add({
        'habitName': habitName,
       
        'timestamp': DateTime.now(),
        'senderPhotoUrl': url,
        'body': 'It\'s time to complete your habit: $habitName',
      });
    } catch (e) {
      print('Error updating Firestore: $e');
    }
  });
}

