import 'package:flutter/material.dart';
import 'package:habit_hero/habit_page.dart';
import 'package:habit_hero/text_shdows.dart';
import 'firebase_help_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomCardWidget extends StatefulWidget {
  final String title;
  final String description;
  final String method;
  final TimeOfDay timeOfDay;
  final bool is_confirmed;
  final int streakValue;
  final int curr_days;
  final int goal_days;
  final int timerValue;
  final int intervalTime;
  final int numConfirmations;
  final int done_today;
  final int habit_points;

  CustomCardWidget({
    Key? key,
    required this.title,
    required this.description,
    required this.method,
    required this.timeOfDay,
    required this.is_confirmed,
    required this.streakValue,
    required this.curr_days,
    required this.goal_days,
    required this.timerValue,
    required this.intervalTime,
    required this.numConfirmations,
    required this.done_today,
    required this.habit_points,
  }) : super(key: key);

  @override
  State<CustomCardWidget> createState() => _CustomCardWidgetState();
}

class _CustomCardWidgetState extends State<CustomCardWidget> {

  int habitStreak = 0; // Define habitStreak at the class level
  int curr_days = 0;
  int topStreak = 0;

  @override
  void initState() {
    super.initState();
    fetchHabitStreak();
    fetchTopStreak();
  }

  Future<void> fetchHabitStreak() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseFirestore db = FirebaseFirestore.instance;
    final User? user = auth.currentUser;
    final userId = user?.uid;
    final DocumentSnapshot<Map<String, dynamic>> docSnapshot = await db.collection('Users').doc(userId).collection('Habit_${widget.title}').doc('Method_info').get();
    final int fetchedStreak = docSnapshot.data()?['streak'] ?? 0; // Safely access 'streak' and provide a default value
    final int fetchedWeekCurr = docSnapshot.data()?['week_curr'] ?? 0; 

    if(mounted){
      setState(() {
      habitStreak = fetchedStreak;
      curr_days = fetchedWeekCurr;
    });
    }
  }
    Future<void> fetchTopStreak() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseFirestore db = FirebaseFirestore.instance;
    final User? user = auth.currentUser;
    final userId = user?.uid;
    final DocumentSnapshot<Map<String, dynamic>> docSnapshot = await db.collection('Users').doc(userId).get();
    final int fetchedStreak = docSnapshot.data()?['top_streak'] ?? 0; // Safely access 'streak' and provide a default value

    if(mounted){
      setState(() {
      topStreak = fetchedStreak;
    });
    }
  }
 
  void navigateToHabitPage(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HabitPage(
          habitName: widget.title,
          habitDescription: widget.description,
          //habitStreak: methodInfo["streak"] ?? 0, // Uncomment if needed
          habitMethod:widget.method,
          timerValue: widget.timerValue,
          intervalTime: widget.intervalTime,
          numConfirmations: widget.numConfirmations,
          habitPoints: widget.habit_points,
        ),
      ),
    ).then((_){
      fetchTopStreak();
      fetchHabitStreak();
    });
  }
  @override
  Widget build(BuildContext context) {
    String timeOfDay_str = widget.timeOfDay.format(context);
    String is_confirmed_str = widget.is_confirmed ? '' : ' not';
    return InkWell(
      onTap: () => (mounted) ? setState(() => navigateToHabitPage(context)) : null,
      child: Tooltip(
        message: 'Tap to view habit details',
        child: Card(
          color: Color.fromARGB(199, 21, 101, 192),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Tooltip(
                              message: 'Habit title',
                              child: Text(
                                widget.title, // Use the title parameter here
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  shadows: CustomTextShadow.shadows,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Tooltip(
                                message: 'Reminder and completion status',
                                child: Text(
                                  'Reminder time is $timeOfDay_str.\nYou have$is_confirmed_str finished your habit for today!', // Use is_confirmed here
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      children: <Widget>[
                        Column(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: <Widget>[
                                Tooltip(
                                  message: 'Habit streak icon',
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    child: Image.asset(
                                      'app_images/fire_icon.png',
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 18,
                                  child: Tooltip(
                                    message: 'Current habit streak',
                                    child: Text(
                                      '${habitStreak}', // Use streakValue here
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        shadows: CustomTextShadow.shadows,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Tooltip(
                                message: widget.done_today == 1 ? 'Habit completed today' : 'Habit not completed today',
                                child: Image.asset(
                                  widget.done_today == 1 ? 'app_images/check.png' : 'app_images/X.png', // Path to your asset image
                                  width: widget.done_today == 1 ? 40 : 37, // Optional: Set the width of the image
                                  height: widget.done_today == 1 ? 40 : 37, // Optional: Set the height of the image
                                  fit: BoxFit.cover, // Optional: Set how the image should be fit into the widget
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: Stack(
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(top: 24.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Tooltip(
                                  message: 'Progress towards goal',
                                  child: SizedBox(
                                    height: 30,
                                    child: LinearProgressIndicator(
                                      value: curr_days / widget.goal_days, // Use curr_days and goal_days here
                                      backgroundColor: Colors.blue[300],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        (curr_days >= widget.goal_days) ? Colors.green.shade600 : Color.fromARGB(255, 255, 255, 2), // Conditional color assignment
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.center,
                              child: Container(
                                margin: EdgeInsets.only(top: 20), // Adjust this value to lower the text as needed
                                child: Tooltip(
                                  message: 'Current progress in days',
                                  child: Text(
                                    '${curr_days} of ${widget.goal_days} days done!', // Use curr_days and goal_days here
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      shadows: CustomTextShadow.shadows,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StringListViewWidget extends StatefulWidget {
  final List<String> stringList;


  StringListViewWidget({Key? key, required this.stringList}) : super(key: key);

  @override
  State<StringListViewWidget> createState() => _StringListViewWidgetState();
}

class _StringListViewWidgetState extends State<StringListViewWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;
    final userId = user?.uid;
    FirestoreService firestoreService = FirestoreService();

    Future<bool> doesHabitCollectionExist(String userId, String habitName) async {
      FirebaseFirestore db = FirebaseFirestore.instance;
      CollectionReference habitCollection = db.collection('Users').doc(userId).collection('Habit_$habitName');
      QuerySnapshot habitSnapshot = await habitCollection.limit(1).get();
      return habitSnapshot.docs.isNotEmpty;
    }

    return FutureBuilder<List<String>>(
    future: Future.wait(widget.stringList.map((habitName) async {
      if (await doesHabitCollectionExist(userId!, habitName)) {
        return habitName;
      }
      return null;
    }).toList()).then((list) => list.where((item) => item != null).cast<String>().toList()),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return CircularProgressIndicator();
      } else if (snapshot.hasError) {
        return Text('Error: ${snapshot.error}');
      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return Center(
          child: Text(
            "You don't have any habits yet, create a new habit now and begin your journey!",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.0,
              shadows: CustomTextShadow.shadows,
            ),
            textAlign: TextAlign.center,
          ),
        );
      } else {
        final filteredList = snapshot.data!;
        return ListView.builder(
          itemCount: filteredList.length,
          itemBuilder: (context, index) {
            return FutureBuilder<List<dynamic>>(
              future: Future.wait([
                firestoreService.getHabitInfo(userId!, filteredList[index]),
                firestoreService.getMethodInfo(userId, filteredList[index]),
                firestoreService.getReminderInfo(userId, filteredList[index]),
              ]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData) {
                  return Text('No data');
                } else {
                  // Assuming snapshot.data[0] is habitInfo, snapshot.data[1] is methodInfo, and snapshot.data[2] is reminderInfo
                  Map<String, dynamic> habitInfo = snapshot.data![0];
                  Map<String, dynamic> methodInfo = snapshot.data![1];
                  Map<String, dynamic> reminderInfo = snapshot.data![2];
                  // Use habitInfo, methodInfo, and reminderInfo as needed
                  return ListTile(
                    title: Container(
                      margin: EdgeInsets.all(8.0),
                      child: SizedBox(
                        height: 180,
                        width: 300,
                        child: FutureBuilder<List<dynamic>>(
                          future: Future.wait([
                            firestoreService.getHabitInfo(userId, filteredList[index]),
                            firestoreService.getMethodInfo(userId, filteredList[index]),
                            firestoreService.getReminderInfo(userId, filteredList[index]),
                          ]),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            } else if (!snapshot.hasData) {
                              return Text('No data');
                            } else {
                              var habitInfo = snapshot.data![0] as Map<String, dynamic>;
                              var methodInfo = snapshot.data![1] as Map<String, dynamic>;
                              var reminderInfo = snapshot.data![2] as Map<String, dynamic>;

                              return CustomCardWidget(
                                title: filteredList[index],
                                description: habitInfo["description"] ?? '',
                                method: habitInfo["method"] ?? 'None',
                              timeOfDay: TimeOfDay(
                                  hour: reminderInfo["hour"] ?? 0,
                                  minute: reminderInfo["minute"] ?? 0,
                                ),
                                is_confirmed: methodInfo["done_today"] == 0 ? false : true,
                                streakValue: methodInfo["streak"] ?? 0,
                                curr_days: methodInfo["week_curr"] ?? 0,
                                goal_days: methodInfo["week_goal"] ?? 0,
                                timerValue: methodInfo["timer_val"] ?? 0,
                                intervalTime: methodInfo["interval"] ?? 0,
                                numConfirmations: methodInfo["confirm_num"] ?? 0,
                                done_today: methodInfo["done_today"] ?? 0,
                                habit_points: methodInfo["habit_points"] ?? 0,
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  );
                }
              },
            );
          },
        );
      }
    });
  }
}
