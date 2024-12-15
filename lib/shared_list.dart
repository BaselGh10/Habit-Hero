import 'package:flutter/material.dart';
import 'package:habit_hero/habit_page.dart';
import 'package:habit_hero/text_shdows.dart';
import 'firebase_help_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'shared_firebase_help.dart';
import 'notify_func.dart';
import 'edit_remove_habit.dart';

Future<bool> habitExists(String habitName) async {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final User? user = auth.currentUser;
  final userId = user?.uid;
  final DocumentSnapshot<Map<String, dynamic>> docSnapshot = await FirebaseFirestore.instance.collection('Users').doc(userId).collection('SharedHabit_$habitName').doc('Method_info').get();
  return docSnapshot.exists && docSnapshot != {} && docSnapshot.data() != null;
}

class CustomCardWidget_shared extends StatefulWidget {
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
  final VoidCallback updateParentState;

  CustomCardWidget_shared({
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
    required this.updateParentState,
  }) : super(key: key);

  @override
  State<CustomCardWidget_shared> createState() => _CustomCardWidget_sharedState();
}

class _CustomCardWidget_sharedState extends State<CustomCardWidget_shared> {
  int fetchedActive = 0;
  List<dynamic> partner = [];
  String request_state = "from";
  bool activatedButton = true;
  bool _isLoading = true;

  int habitStreak = 0; // Define habitStreak at the class level
  int curr_days = 0;
  int topStreak = 0;

  @override
  void initState() {
    super.initState();
    fetchHabitStreak();
    fetchTopStreak();
    print('habit points: ${widget.habit_points}');
  }

  Future<void> fetchHabitStreak() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseFirestore db = FirebaseFirestore.instance;
    final User? user = auth.currentUser;
    final userId = user?.uid;
    final DocumentSnapshot<Map<String, dynamic>> docSnapshot = await db.collection('Users').doc(userId).collection('SharedHabit_${widget.title}').doc('Method_info').get();
    final int fetchedStreak = docSnapshot.data()?['streak'] ?? 0; // Safely access 'streak' and provide a default value
    final int fetchedWeekCurr = docSnapshot.data()?['week_curr'] ?? 0; 
    final DocumentSnapshot<Map<String, dynamic>> docSnapshot_2 = await db.collection('Users').doc(userId).collection('SharedHabit_${widget.title}').doc('Habit_info').get();
    fetchedActive = docSnapshot_2.data()?['active'] ?? 0;
    partner = docSnapshot_2.data()?['partner'] ?? [];
    request_state = docSnapshot_2.data()?['request'] ?? "from";

    if(mounted){
      setState(() {
      habitStreak = fetchedStreak;
      curr_days = fetchedWeekCurr;
      _isLoading = false;
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
      //_isLoading = false;
    });
    }
  }
 
  void navigateToHabitPage(BuildContext context) async {
    if (!(await habitExists(widget.title))) {
      SnackBar snackBar = SnackBar(
        content: Text('This habit no longer exists!'),
        duration: Duration(seconds: 2),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return;
    }
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HabitPage(
            habitName: widget.title,
            habitDescription: widget.description,
            //habitStreak: methodInfo["streak"] ?? 0, // Uncomment if needed
            habitMethod: widget.method,
            timerValue: widget.timerValue,
            intervalTime: widget.intervalTime,
            numConfirmations: widget.numConfirmations,
            habitPoints: widget.habit_points,
          ),
        ),
      ).then((_) {
        fetchTopStreak();
        fetchHabitStreak();
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    String timeOfDay_str = widget.timeOfDay.format(context);
    String is_confirmed_str = widget.is_confirmed ? '' : ' not';
    return (_isLoading)? CircularProgressIndicator() : Tooltip(
      message: 'Tap to open the habit page',
      child: InkWell(
        onTap:  () async {
          if (mounted) {
            if (fetchedActive < partner.length) {
              return;
            }
            navigateToHabitPage(context);
          }
        },
        child: Container(
          constraints: BoxConstraints(
            minHeight: 900.0, // Set a minimum height if needed
          ),
          child: Card(
            color: Color.fromARGB(199, 21, 101, 192),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                //mainAxisSize: MainAxisSize.min, // Use MainAxisSize.min if needed
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
                                  message: '${widget.title}',
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
                            (fetchedActive < partner.length && request_state == "to")? 
                            Row(
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Tooltip(
                                    message: 'Reminder time is $timeOfDay_str.', // Use is_confirmed here
                                    child: Text(
                                      'Reminder time is $timeOfDay_str.', // Use is_confirmed here
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2, // Adjust the number of lines as needed
                                    ),
                                  ),
                                ),
      
                              ],
                            )
                            : Row(
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Tooltip(
                                    message: 'Reminder time is $timeOfDay_str.\nYou have$is_confirmed_str finished your habit for today!', // Use is_confirmed here
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
                        children:<Widget>[
                          (fetchedActive < partner.length)? Column(
                            children: [
                              Center(
                                child: Tooltip(
                                  message: 'Inactive habit!',
                                  child: Text(
                                    "Inactive\nhabit!",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize:10.0,
                                      shadows: CustomTextShadow.shadows,  
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                                // IconButton(
                                //   icon: Icon(Icons.info, color: Colors.white),
                                //   onPressed: () {
                                //     showDialog(
                                //       context: context,
                                //       builder: (BuildContext context) {
                                //         return AlertDialog(
                                //           title: Text('Description'),
                                //           content: Column(
                                //             mainAxisSize: MainAxisSize.min,
                                //             children: [
                                //               Text((widget.description != "") ? widget.description : 'No description provided'),
                                //               SizedBox(height: 20), // Add some spacing
                                //               Text('Partners:', style: TextStyle(fontWeight: FontWeight.bold)),
                                //               ...partner.map((partnerName) => Text(partnerName)).toList(), // Display each partner
                                //             ],
                                //           ),
                                //           actions: <Widget>[
                                //             TextButton(
                                //               child: Text('Close'),
                                //               onPressed: () {
                                //                 Navigator.of(context).pop();
                                //               },
                                //             ),
                                //           ],
                                //         );
                                //       },
                                //     );
                                //   },
                                // ),
                            ],
                          ) : Column(
                          children: <Widget>[
                            Column(
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: <Widget>[
                                    Container(
                                      width: 50,
                                      height: 50,
                                      child: Image.asset(
                                        'app_images/fire_icon.png',
                                      ),
                                    ),
                                    Positioned(
                                      top: 18,
                                      child: Tooltip(
                                        message: 'Your top streak is $topStreak', // Use streakValue here
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
                                  child: Image.asset(
                                    widget.done_today ==1 ? 'app_images/check.png' : 'app_images/X.png', // Path to your asset image
                                    width: widget.done_today ==1 ? 40 : 37, // Optional: Set the width of the image
                                    height: widget.done_today ==1 ? 40 : 37, // Optional: Set the height of the image
                                    fit: BoxFit.cover, // Optional: Set how the image should be fit into the widget
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        ]
                        )
                      
      
                      ],
                    ),
                    (fetchedActive < partner.length)? 
                    (request_state == "to") ?
                    SizedBox(height: 25) : SizedBox(height: 0) : SizedBox(height: 0),
                    (fetchedActive < partner.length)? 
                    (request_state == "to") ?
                      Row( children: [
                        Tooltip(
                          message: 'Activate the habit',
                          child: TextButton(
                            onPressed: activatedButton
                              ? () async{
                                  if (mounted) setState(() {
                                    activatedButton = false;
                                  });
                                  editactive_all(widget.title, partner.cast<String>());
                                  edit_request_state(widget.title);
                                  widget.updateParentState();
                                  for(String partner in partner){
                                    //await createNotification("Your partner $partner has activated your habit $widget.title", widget.title, partner);
                                    createNotification("Your partner $partner has activated your habit $widget.title", widget.title, partner);
                                  }
                                  if (mounted) setState(() {
                                    activatedButton = true;
                                  });
                                }
                              : null,
                            child: Text(
                              "Activate",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.0,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Tooltip(
                          message: 'Decline the habit',
                          child: TextButton(
                            onPressed: activatedButton
                              ? () async {
                                  bool confirm = await showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Tooltip(
                                          message: 'Dialog Title',
                                          child: Text('Confirm Decline'),
                                        ),
                                        content: Tooltip(
                                          message: 'Dialog Content',
                                          child: Text('Are you sure you want to decline?'),
                                        ),
                                        actions: <Widget>[
                                          Tooltip(
                                            message: 'I don\'t want to decline',
                                            child: TextButton(
                                              child: Tooltip(
                                                message: 'Cancel the action',
                                                child: Text('Cancel'),
                                              ),
                                              onPressed: () {
                                                Navigator.of(context).pop(false); // Return false
                                              },
                                            ),
                                          ),
                                          Tooltip(
                                            message: 'I am sure I want to decline',
                                            child: TextButton(
                                              child: Tooltip(
                                                message: 'Confirm the action',
                                                child: Text('Yes'),
                                              ),
                                              onPressed: () async {
                                                for (String partner in partner) {
                                                  //await createNotification("Your partner $partner has declined your habit $widget.title", widget.title, partner);
                                                  createNotification("Your partner $partner has declined your habit ${widget.title}", widget.title, partner);
                                                }
                                                Navigator.of(context).pop(true); // Return true
                                              },
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                          
                                  if (confirm && mounted) {
                                    setState(() {
                                      activatedButton = false;
                                    });
                                    for (String partner in partner)
                                      delete_partners_habit(widget.title, partner);
                                    await removeHabit_fromCloud(widget.title);
                                    widget.updateParentState();
                                    if (mounted)
                                    setState(() {
                                      activatedButton = true;
                                    });
                                  }
                                }
                              : null,
                            child: Text(
                              "Decline",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.0,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            ),
                          ),
                        ),
                           SizedBox(width: 58.0),
                           IconButton(
                          icon: Tooltip(
                            message: 'More information',
                            child: Icon(Icons.info, color: Colors.grey[400]),
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Tooltip(
                                    message: 'Dialog Title',
                                    child: Text('Description:'),
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Tooltip(
                                        message: 'Description of the item',
                                        child: Text((widget.description != "") ? widget.description : 'No description provided'),
                                      ),
                                      SizedBox(height: 20), // Add some spacing
                                      Tooltip(
                                        message: 'List of partners',
                                        child: Text('Partners:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                      ...partner.map((partnerName) => Tooltip(
                                        message: 'Partner name',
                                        child: Text(partnerName),
                                      )).toList(), // Display each partner
                                    ],
                                  ),
                                  actions: <Widget>[
                                    Tooltip(
                                      message: 'Close the dialog',
                                      child: TextButton(
                                        child: Text('Close'),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ]
                      )
                      : Row(
                        children: [
                          Center(
                          child: Tooltip(
                            message: 'Wait for your partners to activate it!',
                            child: Text(
                              "Wait for your partners to activate it!",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 15.0,
                                shadows: CustomTextShadow.shadows,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            SizedBox(height: 1),
                            Padding(
                              padding: const EdgeInsets.only(left: 5.0),
                              child: IconButton(
                                icon: Tooltip(
                                  message: 'Delete this item',
                                  child: Icon(Icons.delete),
                                ),
                                color: Colors.grey[400],
                                onPressed: () async {
                                  bool is_removed = await removeHabit(context, widget.title);
                                  if (is_removed && mounted) {
                                    setState(() {
                                      widget.updateParentState();
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        ]
                      ): Row(
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
                                    child: SizedBox( height: 30,
                                    child: LinearProgressIndicator(
                                      value: curr_days / widget.goal_days, // Use curr_days and goal_days here
                                      backgroundColor: Colors.blue[300],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        //widget.is_confirmed ? Colors.green.shade600 : Color.fromARGB(255, 255, 255, 2), // Conditional color assignment
                                        (curr_days >= widget.goal_days) ? Colors.green.shade600 : Color.fromARGB(255, 255, 255, 2), // Conditional color assignment
                                      ),
                                    ),),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.center,
                                  child: Container(
                                  margin: EdgeInsets.only(top: 20), // Adjust this value to lower the text as needed
                                  child: Tooltip(
                                    message: 'Progress: ${curr_days} of ${widget.goal_days} days done!', // Use curr_days and goal_days here
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
      ),
    );
  }
}

class StringListViewWidget_shared extends StatefulWidget {
  final List<String> stringList;


  StringListViewWidget_shared({Key? key, required this.stringList}) : super(key: key);

  @override
  State<StringListViewWidget_shared> createState() => _StringListViewWidget_sharedState();
}

class _StringListViewWidget_sharedState extends State<StringListViewWidget_shared> {
  @override
  void initState() {
    super.initState();
  }

  void _updateState() {
    if (mounted) setState(() {
      // Update the state as needed
    });
  }


  @override
  Widget build(BuildContext context) {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;
    final userId = user?.uid;
    FirestoreService firestoreService = FirestoreService();

    Future<bool> doesHabitCollectionExist(String userId, String habitName) async {
      FirebaseFirestore db = FirebaseFirestore.instance;
      CollectionReference habitCollection = db.collection('Users').doc(userId).collection('SharedHabit_$habitName');
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
        return Text('Error: ${snapshot.error}, please try again');
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
                getHabitInfoDoc(userId!, filteredList[index]),
                getMethodInfoDoc(userId, filteredList[index]),
                getReminderInfoDoc(userId, filteredList[index]),
              ]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}, please try again');
                } else if (!snapshot.hasData) {
                  return Text('No data');
                } else {
                  return ListTile(
                    title: Container(
                      margin: EdgeInsets.all(8.0),
                      child: SizedBox(
                        height: 180,
                        width: 300,
                        child: FutureBuilder<List<dynamic>>(
                          future: Future.wait([
                            getHabitInfoDoc(userId!, filteredList[index]),
                            getMethodInfoDoc(userId, filteredList[index]),
                            getReminderInfoDoc(userId, filteredList[index]),
                          ]),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}, please try again');
                            } else if (!snapshot.hasData) {
                              return Text('No data');
                            } else {
                              var habitInfo = snapshot.data![0] as Map<String, dynamic>;
                              var methodInfo = snapshot.data![1] as Map<String, dynamic>;
                              var reminderInfo = snapshot.data![2] as Map<String, dynamic>;
                              return CustomCardWidget_shared(
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
                                numConfirmations: 0,
                                done_today: methodInfo["done_today"] ?? 0,
                                habit_points: methodInfo["habit_points"] ?? 0,
                                updateParentState: _updateState,
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
