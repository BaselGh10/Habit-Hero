import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'firebase_help_functions.dart';
import 'habit_reminders.dart';
import 'notify_func.dart';
import 'shared_firebase_help.dart';

Future<void> manageHabits() async {
  FirestoreService firestoreService = FirestoreService();
  try {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;
    final userId = user?.uid;

    if (userId == null) {
      throw Exception("User not logged in");
    }

    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference userDoc = db.collection('Users').doc(userId);

    // Fetch the current user document
    final userDocSnapshot = await userDoc.get();
    Map<String, dynamic> userData = userDocSnapshot.data() as Map<String, dynamic>? ?? {};
    Timestamp? lastFixTimestamp = userData['last_fix'];

    // If last_fix does not exist, initialize it with Timestamp.now() and skip the habit updates
    if (lastFixTimestamp == null) {
      await userDoc.set({'last_fix': Timestamp.now()}, SetOptions(merge: true));
      return; // Skip the rest if last_fix was just initialized
    }

    List<String> habitNames = await firestoreService.getHabitNames(userId);
    for (String name in habitNames) {
      await updateHabitLastFix(name, lastFixTimestamp, userId);
      await checkAndScheduleReminder(userId, name);
    }

    // Update last_fix without deleting existing fields
    await userDoc.update({'last_fix': Timestamp.now()});

  } catch (e) {
    print("Error managing habits: $e");
  }
}

Future<int> getWeekGoalDifference(String habitName) async {
  try {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;
    final userId = user?.uid;

    if (userId == null) {
      throw Exception("User not logged in");
    }

    Map<String, dynamic> methodInfoDoc = await getMethodInfoDoc(userId, habitName);

    if (methodInfoDoc.isEmpty) {
      throw Exception("Method_info document does not exist");
    }

    int weekGoal = methodInfoDoc["week_goal"];
    int weekCurr = methodInfoDoc["week_curr"];

    return weekGoal - weekCurr;
  } catch (e) {
    print("Error getting week goal difference: $e");
    return 0; // Consider how you want to handle errors. Returning 0 is a simple placeholder.
  }
}

int calculateDaysLeftInWeek() {
  DateTime now = DateTime.now();
  int currentDayOfWeek = now.weekday; // In Dart, Monday is 1 and Sunday is 7

  // Adjusting the current day of the week to start from Sunday as 0
  int adjustedDayOfWeek = currentDayOfWeek % 7;

  // Calculating days left in the week, excluding today
  int daysLeft = 6 - adjustedDayOfWeek;

  return daysLeft;
}

Future<void> updateHabitLastFix(String habitName, Timestamp? lastFixTimestamp, String userId) async {
  DateTime now = DateTime.now();
  DateTime lastFixDate = lastFixTimestamp?.toDate() ?? DateTime.now();
  DateTime startOfToday = DateTime(now.year, now.month, now.day);
  DateTime startOfWeek = startOfToday.subtract(Duration(days: now.weekday % 7));
  DateTime startOfLastWeek = startOfWeek.subtract(Duration(days: 7));

  print("Habit: $habitName");
  print('Last fix timestamp: $lastFixTimestamp');
  print("Last fix: $lastFixDate");
  print("Start of today: $startOfToday");
  print("Start of week: $startOfWeek");
  print("Start of last week: $startOfLastWeek");


  // If last_fix is today, do nothing
  if (lastFixDate.isAfter(startOfToday)) {
    print("Habit: $habitName + Last fix is today");
    return;
  } 
  

  // If last_fix was not today but from the current week, reset done_today
  if (lastFixDate.isBefore(startOfToday) && lastFixDate.isAfter(startOfWeek)) {
    await resetDoneToday(habitName, userId);
  } 
  
  await editDoneToday(habitName, 0);

  // Handle last_fix in the last week
  if (lastFixDate.isBefore(startOfWeek) && lastFixDate.isAfter(startOfLastWeek)) {
    if (await getWeekGoalDifference(habitName) <= 0) {
      await resetWeekCurr(habitName, userId);
      print("Habit: $habitName + last fix in last week");
      habitPartnersLastFix(habitName).then((value) {
        if (value[0]) {
          createNotification("Your partner (${value[1]}) didn't confirm the habit ($habitName) last week!", habitName, null);
          print("Your partner (${value[1]}) didn't confirm the habit ($habitName) last week!");
          editStreak(habitName, true, value[1]);
        }
      });
      return;
    }
    print('getWeekGoalDifference: ${await getWeekGoalDifference(habitName)}');
    await editStreak(habitName, true, null);
    var username= await getUserName();
    createNotification("You didn't complete the habit's ($habitName) goal last week!", habitName, null);
    print("You didn't complete the habit's ($habitName) goal last week!");
    //cloudFunction_support(username, "You didn't complete the habit's ($habitName) goal last week!");
  }

  // Check if last_fix was from before the current week or today is Sunday
  if (lastFixDate.isBefore(startOfWeek) || now.weekday == DateTime.sunday) {
    await resetWeekCurr(habitName, userId);
  }

  // Handle last_fix before last week
  if (lastFixDate.isBefore(startOfLastWeek)) {
    await editStreak(habitName, true, null);
    var username= await getUserName();
    createNotification("You haven't confirmed the habit ($habitName) in a long time!", habitName, null);
    print("You haven't confirmed the habit ($habitName) in a long time!");
    return;
  }

  habitPartnersLastFix(habitName).then((value) {
    if (value[0]) {
      createNotification("Your partner (${value[1]}) didn't confirm the habit ($habitName) last week!", habitName, null);
      print("Your partner (${value[1]}) didn't confirm the habit ($habitName) last week!");
      editStreak(habitName, true, value[1]);
    }
  });

  print("Habit: $habitName + other cases");
}

Future<void> resetDoneToday(String habitName, String userId) async {
  print('getWeekGoalDifference: ${await getWeekGoalDifference(habitName)}');
  print('calculateDaysLeftInWeek: ${calculateDaysLeftInWeek()}');
  if(await getWeekGoalDifference(habitName) > calculateDaysLeftInWeek() + 1) {
    await editStreak(habitName, true, null);
    createNotification("You have no days left to complete the habit's ($habitName) goal!", habitName, null);
    print("You have no days left to complete the habit's ($habitName) goal!");
    //cloudFunction_support(username, "You have no days left to complete the habit's ($habitName) goal!");
  }
}

Future<void> resetWeekCurr(String habitName, String userId) async {
  await editWeekCurr(habitName, true);
}

Future<List<dynamic>> habitPartnersLastFix(String habit) async {
  DateTime now = DateTime.now();
  DateTime startOfToday = DateTime(now.year, now.month, now.day);
  DateTime startOfWeek = startOfToday.subtract(Duration(days: now.weekday % 7));
  DateTime startOfLastWeek = startOfWeek.subtract(Duration(days: 7));
  String userId = FirebaseAuth.instance.currentUser!.uid;
  var H_info = await getHabitInfoDoc(userId, habit);
  var partners = H_info['partner'];
  FirebaseFirestore db = FirebaseFirestore.instance;

  // Calculate the date 7 days ago
  //DateTime sevenDaysAgo = now.subtract(Duration(days: 7));
  if (partners == null) {
    return [false, null];
  }
  for (String partner in partners) {
    String pID = await getPartnerId(partner);
    DocumentReference partnerDoc = db.collection('Users').doc(pID);
    final userDocSnapshot = await partnerDoc.get();
    Map<String, dynamic> partnerData = userDocSnapshot.data() as Map<String, dynamic>? ?? {};
    Timestamp? lastFixTimestamp = partnerData['last_fix'];

    if (lastFixTimestamp != null && lastFixTimestamp.toDate().isBefore(startOfLastWeek)) {
      return [true, partner];
    }

    var PM_info = await getMethodInfoDoc(pID, habit);
    var PM_weekGoal = PM_info['week_goal'];
    var PM_weekCurr = PM_info['week_curr'];
    if (PM_weekGoal - PM_weekCurr > calculateDaysLeftInWeek() + 1) {
      return [true, partner];
    }

    if (lastFixTimestamp != null && lastFixTimestamp.toDate().isBefore(startOfWeek)) {
      if(PM_weekGoal - PM_weekCurr > 0) {
        return [true, partner];
      }
    }
  }
  return [false, null];
}