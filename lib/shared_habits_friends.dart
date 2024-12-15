import 'shared_firebase_help.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'firebase_help_functions.dart';
import 'habit_page.dart';

Future<List<String>> getSharedHabitsWithPartner(String partner) async {
  String userId = FirebaseAuth.instance.currentUser!.uid;
  final FirebaseFirestore db = FirebaseFirestore.instance;
  FirestoreService firestoreService = FirestoreService();
  List<String> HabitList = await firestoreService.getHabitNames(userId);
  List<String> sharedHabits = [];
  for (String habit in HabitList){
    var sharedHabitCollection = await db.collection('Users').doc(userId).collection('SharedHabit_$habit').limit(1).get();
    if(sharedHabitCollection.docs.isNotEmpty) {
      sharedHabits.add(habit);
    }
  }
  print('hero' + sharedHabits.toString());
  List<String> sharedHabitsCopy = List.from(sharedHabits);
  print('hero' + sharedHabitsCopy.toString());
  for (String habit in sharedHabitsCopy){
    Map<String, dynamic> sharedHabitCollection = await getHabitInfoDoc(userId, habit);
    if(!sharedHabitCollection['partner'].contains(partner) || sharedHabitCollection['active'] < sharedHabitCollection['partner'].length){
      sharedHabits.remove(habit);
    }
  }

  return Future.value(sharedHabitsCopy);
}

bool flag = true;

class sharedHabitSmallCard extends StatefulWidget {
  final String habitName;
  final TimeOfDay reminder;
  final int done_today;
  const sharedHabitSmallCard({
    Key? key,
    required this.habitName,
    required this.reminder,
    required this.done_today,
  }) : super(key: key);

  @override
  State<sharedHabitSmallCard> createState() => _sharedHabitSmallCardState();
}

class _sharedHabitSmallCardState extends State<sharedHabitSmallCard> {

  void _handleTap(BuildContext context) async {
    flag = false;
    String userId = FirebaseAuth.instance.currentUser!.uid;
    var H_info = await getHabitInfoDoc(userId, widget.habitName);
    var M_info = await getMethodInfoDoc(userId, widget.habitName);
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => HabitPage(
          habitName: widget.habitName,
          habitDescription: H_info['description'],
          habitMethod: H_info['method'],
          timerValue: M_info['timer_val'] ?? 0,
          intervalTime: M_info['interval'] ?? 0,
          numConfirmations: 0,
          habitPoints: M_info['habit_points'],
        ),
      ),
      (Route<dynamic> route) => false, // This removes all previous routes from the stack
    );
    flag = true;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _handleTap(context),
      child: Container(
        constraints: BoxConstraints(
          minHeight: 100.0, // Set a minimum height if needed
        ),
        child: Card(
          color: Color.fromARGB(199, 21, 101, 192),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Column(
                  children: <Widget>[
                    Text(
                      widget.habitName,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "Reminder: " + widget.reminder.format(context),
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 20),
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Image.asset(
                    widget.done_today ==1 ? 'app_images/check.png' : 'app_images/X.png', // Path to your asset image
                    width: widget.done_today ==1 ? 40 : 37, // Optional: Set the width of the image
                    height: widget.done_today ==1 ? 40 : 37, // Optional: Set the height of the image
                    fit: BoxFit.cover, // Optional: Set how the image should be fit into the widget
                  ),
                ),
              ]
            ),
          ),
        ),
      ),
    );
  }
}

// This function will show a dialog with all the shared habits with a partner
Future<void> showSharedHabitsDialog(BuildContext context, String partner) async {
  List<String> habitNames = await getSharedHabitsWithPartner(partner);
  String userId = FirebaseAuth.instance.currentUser!.uid;

  List<Future<sharedHabitSmallCard>> habitCardFutures = habitNames.map((habitName) async {
    var R_info = await getReminderInfoDoc(userId, habitName);
    var M_info = await getMethodInfoDoc(userId, habitName);
    return sharedHabitSmallCard(
      habitName: habitName,
      reminder: TimeOfDay(hour: R_info['hour'], minute: R_info['minute']),
      done_today: M_info['done_today'],
    );
  }).toList();

  List<sharedHabitSmallCard> habitCards = await Future.wait(habitCardFutures);

  showDialog(
    context: context,
    barrierDismissible: false, // Prevents dialog from closing when tapping outside
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Shared Habits'),
        content: SingleChildScrollView(
          child: ListBody(
            children: habitCards,
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Close'),
            onPressed: () {
              if(flag) Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}


// This function will remove all shared habits with a partner
Future<void> removeSharedHabitsWithPartner(String partner) async {
  List<String> HabitList = await getSharedHabitsWithPartner(partner);
  String userId = FirebaseAuth.instance.currentUser!.uid;
  final FirebaseFirestore db = FirebaseFirestore.instance;
  for (String habit in HabitList){
    Map<String, dynamic> sharedHabitCollection = await getHabitInfoDoc(userId, habit);
    if(sharedHabitCollection['partner'].contains(partner))
    for (String ptr in sharedHabitCollection['partner']) {
      await db.collection('Users').doc(userId).collection('SharedHabit_$habit').doc(partner).delete();
      delete_partners_habit(habit, ptr);
    }
    await removeHabit_fromCloud(habit);
  }
}