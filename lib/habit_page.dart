
import 'package:animated_floating_buttons/animated_floating_buttons.dart';
import 'package:animated_button/animated_button.dart';
import 'package:flutter/material.dart';
import 'package:habit_hero/confirmation.dart';
import 'package:habit_hero/home.dart';
import 'package:habit_hero/muli_confirm.dart';
import 'package:habit_hero/text_shdows.dart';
import 'package:habit_hero/timer.dart';
import 'edit_remove_habit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_help_functions.dart';
import 'shared_firebase_help.dart';


class HabitPage extends StatefulWidget {
  final String habitName;
  final String habitDescription;
  //final int habitStreak;
  final String habitMethod;
  final int timerValue;
  final int intervalTime;
  final int numConfirmations;
  final int habitPoints;

  HabitPage({super.key,
    required this.habitName,
    required this.habitDescription,
    //required this.habitStreak,
    required this.habitMethod,
    required this.timerValue,
    required this.intervalTime,
    required this.numConfirmations,
    required this.habitPoints,
  });

  @override
  State<HabitPage> createState() => _HabitPageState();
}

class _HabitPageState extends State<HabitPage> {
  GlobalKey<AnimatedFloatingActionButtonState> fabKey = GlobalKey();
  String m_description = '';
  bool _isNavigating = false;
  TimeOfDay reminder = TimeOfDay(hour: 0, minute: 0);
  List<String>? partner_name = null;
  List<String> partner_id = [];
  List<int> curr_partner = [];
  int goal = 0;
  int done_today = 0;

  Widget floatActionButton(IconData icon, VoidCallback onPressed) {
    return FloatingActionButton(
      onPressed: onPressed,
      heroTag: null, // Important if you have multiple FABs
      child: Icon(icon,),
    );
  }
  int habitStreak = 0;
  int habit_Points = 0; 

  @override
  void initState() {
    super.initState();
    fetchHabitStreak();
    fetchPoints();
    fetchDescriptionAndUpdate();
    setValues();
  }

  setValues() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;
    final userId = user?.uid;
    var R_info = await getReminderInfoDoc(userId!, widget.habitName);
    var H_info = await getHabitInfoDoc(userId, widget.habitName);
    if(H_info['partner'] != null) partner_name = H_info['partner'].cast<String>();
    if(partner_name != null) for(String ptr in partner_name!) partner_id.add(await getPartnerId(ptr));
    var PM_info;
    for(String partner_id in partner_id) {
      if(partner_name != null) PM_info = await getMethodInfoDoc(partner_id, widget.habitName);
      if(partner_name != null) curr_partner.add(PM_info['week_curr']);
    }
    if(partner_name != null) goal = PM_info['week_goal'];
    if(mounted){
       setState(() {
      reminder = TimeOfDay(hour: R_info['hour'], minute: R_info['minute']);
    });
    }
  }

  Future<void> fetchHabitStreak() async {
      final FirebaseAuth auth = FirebaseAuth.instance;
      FirebaseFirestore db = FirebaseFirestore.instance;
      final User? user = auth.currentUser;
      final userId = user?.uid;
      final DocumentReference<Map<String, dynamic>> habitDocRef = db.collection('Users').doc(userId).collection('Habit_${widget.habitName}').doc('Method_info');
      final DocumentSnapshot<Map<String, dynamic>> habitDocSnapshot = await habitDocRef.get();

      DocumentSnapshot<Map<String, dynamic>> docSnapshot;

      if (habitDocSnapshot.exists) {
        docSnapshot = habitDocSnapshot;
      } else {
        final DocumentReference<Map<String, dynamic>> sharedHabitDocRef = db.collection('Users').doc(userId).collection('SharedHabit_${widget.habitName}').doc('Method_info');
        docSnapshot = await sharedHabitDocRef.get();
      }
      final int fetchedStreak = docSnapshot.data()?['streak'] ?? 0; // Safely access 'streak' and provide a default value
      done_today = docSnapshot.data()?['done_today'] ?? 0;
      if(mounted){
      setState(() {
        habitStreak = fetchedStreak; // Update the habitStreak variable
      });
      }

    }

  Future<void> fetchDescriptionAndUpdate() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseFirestore db = FirebaseFirestore.instance;
    final User? user = auth.currentUser;
    final userId = user?.uid;
    final DocumentReference<Map<String, dynamic>> habitDocRef = db.collection('Users').doc(userId).collection('Habit_${widget.habitName}').doc('Habit_info');
    final DocumentSnapshot<Map<String, dynamic>> habitDocSnapshot = await habitDocRef.get();
    DocumentSnapshot<Map<String, dynamic>> docSnapshot;

    if (habitDocSnapshot.exists) {
      docSnapshot = habitDocSnapshot;
    } else {
      final DocumentReference<Map<String, dynamic>> sharedHabitDocRef = db.collection('Users').doc(userId).collection('SharedHabit_${widget.habitName}').doc('Habit_info');
      docSnapshot = await sharedHabitDocRef.get();
    }
    String description = docSnapshot.data()?['description'] ?? "";

    // Now, update the state with the fetched description
    if (mounted) {
      setState(() {
        m_description = description;
      });
    }
  }

  Future<void> fetchPoints() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseFirestore db = FirebaseFirestore.instance;
    final User? user = auth.currentUser;
    final userId = user?.uid;

    try {
      final DocumentSnapshot<Map<String, dynamic>> docSnapshot = await db.collection('Users').doc(userId).collection('Habit_${widget.habitName}').doc('Method_info').get();
      if (docSnapshot.exists) {
        final int num_points = docSnapshot.data()?['habit_points'] ?? 0;
        if (mounted) {
          setState(() {
            habit_Points = num_points;
          });
        }
      } else {
        throw Exception('Habit collection does not exist');
      }
    } catch (e) {
      // Fallback to SharedHabit collection
      final DocumentSnapshot<Map<String, dynamic>> docSnapshot = await db.collection('Users').doc(userId).collection('SharedHabit_${widget.habitName}').doc('Method_info').get();
      final int num_points = docSnapshot.data()?['habit_points'] ?? 0;
      if (mounted) {
        setState(() {
          habit_Points = num_points;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('app_images/app_wallpaper.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        floatingActionButton: AnimatedFloatingActionButton(
          key: fabKey,
          fabButtons: <Widget>[
            Tooltip(
              message: 'Edit habit',
              child: floatActionButton(Icons.edit, () async {
                // Navigate to the EditHabitWidget and wait for the result
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (context) => EditHabitWidget(name: widget.habitName),
                  ),
                );

                // Check if the result indicates that m_description should be updated
                if (result == true) { // Assuming the EditHabitWidget page returns true if changes were made
                  fetchDescriptionAndUpdate(); // Call the method to fetch the updated description and update the state
                  fetchPoints();
                }
              }),
            ),
            Tooltip(
              message: 'Delete habit',
              child: floatActionButton(Icons.delete, () async {
                if (_isNavigating) return;
                bool is_removed = await removeHabit(context, widget.habitName);
                if (is_removed) {
                  _isNavigating = true;
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => MyBottomNavigation(), // Replace NewPage with your target page
                    ),
                  );
                }
                _isNavigating = false;
              }),
            ),
          ],
          colorStartAnimation: Colors.blue[800]!,
          colorEndAnimation: Colors.red,
          animatedIconData: AnimatedIcons.menu_close, // Use the animatedIconData here
        ),
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.blue[800],
          leading: Tooltip(
            message: 'Go back',
            child: IconButton(
              icon: CircleAvatar(
                backgroundColor: Colors.blue[800], // Background color of the circle
                radius: 20, // Size of the circle
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.white, // Icon color
                  size: 24, // Icon size, adjust accordingly
                  shadows: CustomTextShadow.shadows,
                ),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MyBottomNavigation()),
                );
              },
            ),
          ),
          centerTitle: true,
          title: Tooltip(
            message: 'Habit name',
            child: Text(
              widget.habitName,
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Sriracha',
                fontSize: 30,
                shadows: CustomTextShadow.shadows,
              ),
            ),
          ),
        ),
        
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0), // Adjust the horizontal padding as needed
            child: Padding(
              padding: const EdgeInsets.only(top: 12.0, bottom: 12),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Color.fromARGB(185, 153, 164, 172), // Increase this value for more pronounced round angles
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        (m_description != '')
                            ? Column(
                                children: [
                                  Tooltip(
                                    message: 'Description label',
                                    child: Text(
                                      'Description:',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        shadows: CustomTextShadow.shadows,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Tooltip(
                                    message: 'Description content',
                                    child: Container(
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Colors.blue[800], // Specify the color here, inside the BoxDecoration
                                        borderRadius: BorderRadius.circular(4), // Adjust the radius here
                                      ),
                                      width: 300,
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Text(
                                          m_description,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            shadows: CustomTextShadow.shadows,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 30),
                                ],
                              )
                            : Container(),
                        Center(
                          child: Container(
                            padding: EdgeInsets.only(left: 10, right: 10),
                            child: Tooltip(
                              message: 'Streak information',
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'You are on ',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        shadows: CustomTextShadow.shadows,
                                        fontFamily: 'Sriracha',
                                      ),
                                    ),
                                    WidgetSpan(
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: <Widget>[
                                          Container(
                                            width: 53,
                                            height: 53,
                                            child: Image.asset(
                                              'app_images/fire_icon.png',
                                            ),
                                          ),
                                          Positioned(
                                            top: 23,
                                            child: Text(
                                              '${habitStreak}', // Use streakValue here
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 22,
                                                shadows: CustomTextShadow.shadows,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'days streak,\nkeep up the good work!',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        shadows: CustomTextShadow.shadows,
                                        fontFamily: 'Sriracha',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.only(top: 30, left: 10, right: 10),
                          child: Tooltip(
                            message: 'Total points earned',
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 25,
                                  shadows: CustomTextShadow.shadows,
                                  fontFamily: 'Sriracha',
                                ),
                                children: <TextSpan>[
                                  TextSpan(text: 'Total points earned from this habit: '),
                                  TextSpan(
                                    text: (widget.habitMethod == 'Timer')
                                        ? '${habit_Points}'
                                        : (widget.habitMethod == 'None')
                                            ? '${habit_Points}'
                                            : '${habit_Points}',
                                    style: TextStyle(color: Colors.yellow), // Change the color for this part
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
              
                      SizedBox(height: 130,),
                
                      Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Tooltip(
                            message: 'Navigate to confirmation page',
                            child: AnimatedButton(
                              width: 280,
                              color: Colors.blue[800] ?? Colors.blue,
                              onPressed: () {
                                if ((widget.habitMethod == 'Timer' &&
                                    !(TimeOfDay.now().hour < getTimeOfDayAfterMinutes(widget.timerValue).hour ||
                                        (TimeOfDay.now().hour == getTimeOfDayAfterMinutes(widget.timerValue).hour &&
                                            TimeOfDay.now().minute < getTimeOfDayAfterMinutes(widget.timerValue).minute)))) {
                                  return;
                                }
                                if (widget.habitMethod == 'Multiple Confirmation') {
                                  if (TimeLimitReached(reminder) == 1) {
                                    if (staticValues_MultiConf.habitName != widget.habitName) {
                                      return;
                                    }
                                  }
                                  if (TimeLimitReached(reminder) == 0 &&
                                      staticValues_MultiConf.habitName != widget.habitName &&
                                      staticValues_MultiConf.habitName != '') {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('You are confirming another habit!'),
                                      ),
                                    );
                                    return;
                                  }
                                  if (TimeLimitReached(reminder) == -1) {
                                    return;
                                  }
                                }
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (context) => (widget.habitMethod == 'Timer')
                                        ? TimerPage(habitName: widget.habitName, timerValue: widget.timerValue)
                                        : (widget.habitMethod == 'None')
                                            ? Confirmation(habitName: widget.habitName)
                                            : MultiConf(intervalTime: widget.intervalTime, habitName: widget.habitName),
                                  ),
                                ).then((_) {
                                  fetchHabitStreak();
                                  fetchPoints();
                                });
                              },
                              child: (widget.habitMethod == 'None')
                                ? Text(
                                    'Go to confirmation page',
                                    style: TextStyle(color: Colors.white, shadows: CustomTextShadow.shadows, fontSize: 20),
                                  )
                                : (widget.habitMethod == 'Timer' &&
                                        TimeOfDay.now().hour < getTimeOfDayAfterMinutes(widget.timerValue).hour ||
                                    (TimeOfDay.now().hour == getTimeOfDayAfterMinutes(widget.timerValue).hour &&
                                        TimeOfDay.now().minute < getTimeOfDayAfterMinutes(widget.timerValue).minute))
                                    ? Center(
                                        child: Text(
                                          'Go to confirmation page\n         before ${getTimeOfDayAfterMinutes(widget.timerValue).format(context)}',
                                          style: TextStyle(color: Colors.white, shadows: CustomTextShadow.shadows, fontSize: 20),
                                        ),
                                      )
                                    : (widget.habitMethod == 'Timer')
                                        ? (done_today != 1)
                                            ? Text(
                                                'Too late to confirm',
                                                style: TextStyle(color: Colors.white, shadows: CustomTextShadow.shadows, fontSize: 20),
                                              )
                                            : Text(
                                                'Already confirmed',
                                                style: TextStyle(color: Colors.white, shadows: CustomTextShadow.shadows, fontSize: 20),
                                              )
                                        : (TimeLimitReached(reminder) == -1)
                                            ? Text(
                                                'Too early to confirm',
                                                style: TextStyle(color: Colors.white, shadows: CustomTextShadow.shadows, fontSize: 20),
                                              )
                                            : (TimeLimitReached(reminder) == 0 || staticValues_MultiConf.habitName == widget.habitName)
                                                ? Text(
                                                    'Go to confirmation page,\n         before ${((reminder.hour + (reminder.minute + 10) / 60) % 24).toInt().toString().padLeft(2, '0')}:${((reminder.minute + 10) % 60).toString().padLeft(2, '0')}',
                                                    style: TextStyle(color: Colors.white, shadows: CustomTextShadow.shadows, fontSize: 20),
                                                  )
                                                : (done_today != 1)
                                                    ? Text(
                                                        'Too late to confirm',
                                                        style: TextStyle(color: Colors.white, shadows: CustomTextShadow.shadows, fontSize: 20),
                                                      )
                                                    : Text(
                                                        'Already confirmed',
                                                        style: TextStyle(color: Colors.white, shadows: CustomTextShadow.shadows, fontSize: 20),
                                                      ),
                            ),
                          ),
                        ),
                      ),
                      // Partner progress
                      (partner_name == null || partner_name!.isEmpty)
                          ? SizedBox()
                          : SizedBox(height: 20),
                      (partner_name == null || partner_name!.isEmpty)
                          ? SizedBox()
                          : Column(
                              children: List.generate(partner_name!.length, (index) {
                                return Column(
                                  children: [
                                    Tooltip(
                                      message: 'Partner progress',
                                      child: Text(
                                        'Partner ${partner_name![index]} Progress:',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          shadows: CustomTextShadow.shadows,
                                        ),
                                      ),
                                    ),
                                    Stack(
                                      children: <Widget>[
                                        Padding(
                                          padding: const EdgeInsets.only(top: 24.0),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: Tooltip(
                                              message: 'Progress bar',
                                              child: SizedBox(
                                                height: 30,
                                                child: LinearProgressIndicator(
                                                  value: curr_partner[index] / goal, // Use curr_partner and goal here
                                                  backgroundColor: Colors.blue[300],
                                                  valueColor: AlwaysStoppedAnimation<Color>(
                                                    (curr_partner[index] >= goal)
                                                        ? Colors.green.shade600
                                                        : Color.fromARGB(255, 255, 255, 2), // Conditional color assignment
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
                                              message: 'Progress text',
                                              child: Text(
                                                '${curr_partner[index]} of ${goal} days done!', // Use curr_partner and goal here
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
                                    SizedBox(height: 20), // Add spacing between partners
                                  ],
                                );
                              }),
                            ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        )
      ),
    );
  }
  catch (e) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('app_images/app_wallpaper.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold (
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.blue[800],
           leading: IconButton(
            icon: CircleAvatar(
              backgroundColor: Colors.blue[800], // Background color of the circle
              radius: 20, // Size of the circle
              child: Icon(
                Icons.arrow_back,
                color: Colors.white, // Icon color
                size: 24, // Icon size, adjust accordingly
                shadows: CustomTextShadow.shadows,
              ),
            ),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => MyBottomNavigation()),
              );
            },
          ),
          centerTitle: true,
          title:
               Text(
                widget.habitName,
                style: TextStyle(
                  color: Colors.white,
                  //fontWeight: FontWeight.w900,
                  fontFamily: 'Sriracha',
                  fontSize: 30,
                  shadows: CustomTextShadow.shadows,
                ),
              ),
              
        ),
        
        body: SingleChildScrollView(child: Text(
          'Error: Make sure the partner has not deleted the habit!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            shadows: CustomTextShadow.shadows,
          ),
        ),)
      )
    );
    }
  }
}

int TimeLimitReached(TimeOfDay reminder) {
  DateTime now = DateTime.now();

  // Convert TimeOfDay to DateTime for comparison
  DateTime reminderDateTime = DateTime(now.year, now.month, now.day, reminder.hour, reminder.minute);
  DateTime reminderPlus10Min = reminderDateTime.add(Duration(minutes: 10));

  // Adjust if the reminder is set for the next day (past midnight)
  if (reminderDateTime.isBefore(now) && now.hour < reminder.hour) {
    reminderDateTime = reminderDateTime.add(Duration(days: 1));
    reminderPlus10Min = reminderDateTime.add(Duration(minutes: 10));
  }

  if (now.isBefore(reminderDateTime)) {
    return -1;
  } else if (now.isAfter(reminderDateTime) && now.isBefore(reminderPlus10Min)) {
    return 0;
  } else {
    return 1;
  }
}

TimeOfDay getTimeOfDayAfterMinutes(int minutes) {
  // Calculate the total minutes from midnight
  int totalMinutes = 1440 - (minutes); // 1440 minutes in a day

  // Calculate the hour and minute
  int hour = totalMinutes ~/ 60;
  int minute = totalMinutes % 60;

  return TimeOfDay(hour: hour, minute: minute);
}

