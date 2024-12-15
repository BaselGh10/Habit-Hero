

import 'package:animated_floating_buttons/animated_floating_buttons.dart';
import 'package:animated_button/animated_button.dart';
import 'package:flutter/material.dart';
import 'package:habit_hero/chell/add_challenge.dart';
import 'package:habit_hero/confirmation.dart';
import 'package:habit_hero/home.dart';
import 'package:habit_hero/muli_confirm.dart';
import 'package:habit_hero/text_shdows.dart';
import 'package:habit_hero/timer.dart';
import '/edit_remove_habit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/firebase_help_functions.dart';
import '/shared_firebase_help.dart';

class ChallangePage extends StatefulWidget {
  final String habitName;
  String habitDescription = '';
  String habitMethod = '';
  int timerValue=0 ;
  int intervalTime=0  ;
  int numConfirmations = 0;
  int habitPoints = 0;
  Future<void> getChallengeAndSearchUser() async {
    try {
      // Get the challenge from Firestore
      DocumentSnapshot challengeSnapshot = await FirebaseFirestore.instance
          .collection('challenges')
          .doc(habitName)
          .get();
      String? currentuser = FirebaseAuth.instance.currentUser!.uid;
      // Get the user collection from Firestore
      var challengeSnapshot1 = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentuser)
          .collection('challenge_$habitName')
          .get();

      if (challengeSnapshot1.docs.isNotEmpty) {
      // challengeName;
     habitDescription = challengeSnapshot1.docs[0]['description'];
        habitMethod = challengeSnapshot1.docs[0]['method'];
        if(habitMethod == 'Timer'){
          timerValue = challengeSnapshot1.docs[1]['timer_val'];
        }
        else if(habitMethod == 'Multiple Confirmation'){
          numConfirmations = challengeSnapshot1.docs[1]['curr_conf_num'];
        }
    
       // timerValue = challengeSnapshot1.docs[1]['timer_val'];
        intervalTime = challengeSnapshot1.docs[1]['interval'];
       // numConfirmations = challengeSnapshot1.docs[1]['curr_conf_num'];
        //habitPoints = challengeSnapshot1.docs[0]['habitPoints'];
      }
    } catch (e) {
      print('Error: $e');
    }
  }


  ChallangePage({
    Key? key,
    required this.habitName,
  String habitDescription = '',
  String habitMethod = '',
  int timerValue=0 ,
  int intervalTime=0  ,
  int numConfirmations = 0,
  int habitPoints = 0,

  }) : super(key: key) {
    getChallengeAndSearchUser();

  }


  @override
  State<ChallangePage> createState() => _HabitPageState();
}

class _HabitPageState extends State<ChallangePage> {
  GlobalKey<AnimatedFloatingActionButtonState> fabKey = GlobalKey();

  bool _isNavigating = false;
  TimeOfDay reminder = TimeOfDay(hour: 0, minute: 0);
  String? partner_name;
  String partner_id = "";
  int curr_partner = 0;
  int goal = 0;
  

  Widget floatActionButton(IconData icon, VoidCallback onPressed) {
    return FloatingActionButton(
      onPressed: onPressed,
      heroTag: null, // Important if you have multiple FABs
      child: Icon(
        icon,
      ),
    );
  }

  int habitStreak = 0;
  int habit_Points = 0;

  @override
  void initState() {
   // updatechallenge(widget.habitName);
    super.initState();
  
    setValues();
   // updatechallenge(widget.habitName);
  }

  setValues() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;
    final userId = user?.uid;
    var R_info = await getReminderInfoDoc(userId!, widget.habitName);
    var H_info = await getHabitInfoDoc(userId, widget.habitName);
    partner_name = H_info['partner'];
    if (partner_name != null)
      print(partner_name! + ' partner_name');
    else
      print('no partner');
    if (partner_name != null) partner_id = await getPartnerId(partner_name!);
    var PM_info;
    if (partner_name != null)
      PM_info = await getMethodInfoDoc(partner_id, widget.habitName);
    if (partner_name != null) curr_partner = PM_info['week_curr'];
    if (partner_name != null) goal = PM_info['week_goal'];
    if (mounted)
      setState(() {
        reminder = TimeOfDay(hour: R_info['hour'], minute: R_info['minute']);
      });
  }


  final GlobalKey _tooltipKey = GlobalKey();

  void _showTooltip() {
    final dynamic tooltip = _tooltipKey.currentState;
    tooltip?.ensureTooltipVisible();
  }
 

  @override
  Widget build(BuildContext context) {
    
      return Container(
          width: double.infinity,
          height: double.infinity,
       
        
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14.0), // Adjust the horizontal padding as needed
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0, bottom: 12),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Color.fromARGB(185, 153, 164,
                              172) //Color.fromARGB(191, 158, 158, 158), // Increase this value for more pronounced round angles
                          ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              (widget.habitDescription != '')
                                  ? Column(
                                      children: [
                                        Text(
                                          'Description:',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            shadows: CustomTextShadow.shadows,
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        Container(
                                          //color: Colors.blue[800],
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: Colors.blue[
                                                800], // Specify the color here, inside the BoxDecoration
                                            borderRadius: BorderRadius.circular(
                                                4), // Adjust the radius here
                                          ),
                                          width: 300,
                                          child: Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: Text(
                                            widget.habitDescription,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                shadows: CustomTextShadow.shadows,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          height: 30,
                                        ),
                                      ],
                                    )
                                  : Container(),
                              //SizedBox(height: 550,),
                           
                    
                              //SizedBox(),
                    
                              Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: AnimatedButton(
                                    width: 280,
                                    color: Colors.blue[800] ?? Colors.blue,
                                    //color: Color.fromARGB(194, 0, 0, 0),
                                    onPressed: () {
                                      if ((widget.habitMethod == 'Timer' &&
                                          !(TimeOfDay.now().hour <
                                                  getTimeOfDayAfterMinutes(
                                                          widget.timerValue)
                                                      .hour ||
                                              (TimeOfDay.now().hour ==
                                                      getTimeOfDayAfterMinutes(
                                                              widget.timerValue)
                                                          .hour &&
                                                  TimeOfDay.now().minute <
                                                      getTimeOfDayAfterMinutes(
                                                              widget.timerValue)
                                                          .minute)))) {
                                        return;
                                      }
                                      if (widget.habitMethod ==
                                              'Multiple Confirmation' &&
                                          TimeLimitReached(
                                                  widget.habitName, reminder) !=
                                              0) {
                                        return;
                                      }
                                      Navigator.of(context)
                                          .push(
                                        MaterialPageRoute<void>(
                                          builder: (context) => (widget
                                                      .habitMethod ==
                                                  'Timer')
                                              ? TimerPage(
                                                  habitName: widget.habitName,
                                                  timerValue: widget.timerValue,
                                                )
                                              : (widget.habitMethod == 'None')
                                                  ? Confirmation(
                                                      habitName: widget.habitName,
                                                    )
                                                  : MultiConf(
                                                      intervalTime:
                                                          widget.intervalTime,
                                                      habitName: widget.habitName,
                                                    ),
                                        ),
                                      )
                                          .then((_) {
                                       
                                        //fetchHabitStreak();
                                        //fetchPoints();
                                      });
                                    },
                                    child: (widget.habitMethod == 'None')
                                        ? Text(
                                            'Go to confirmation page',
                                            style: TextStyle(
                                                color: Colors.white,
                                                shadows: CustomTextShadow.shadows,
                                                fontSize: 20),
                                          )
                                        : (widget.habitMethod == 'Timer' &&
                                                    TimeOfDay.now().hour <
                                                        getTimeOfDayAfterMinutes(
                                                                widget.timerValue)
                                                            .hour ||
                                                (TimeOfDay.now().hour ==
                                                        getTimeOfDayAfterMinutes(
                                                                widget.timerValue)
                                                            .hour &&
                                                    TimeOfDay.now().minute <
                                                        getTimeOfDayAfterMinutes(
                                                                widget.timerValue)
                                                            .minute))
                                            ? Center(
                                                child: Text(
                                                'Go to confirmation page\n         before ${getTimeOfDayAfterMinutes(widget.timerValue).format(context)}',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    shadows:
                                                        CustomTextShadow.shadows,
                                                    fontSize: 20),
                                              ))
                                            : (widget.habitMethod == 'Timer')
                                                ? Text(
                                                    'Too late to cofirm',
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        shadows: CustomTextShadow
                                                            .shadows,
                                                        fontSize: 20),
                                                  )
                                                : (TimeLimitReached(
                                                            widget.habitName,
                                                            reminder) == -1)
                                                    ? Text(
                                                        'Too early to confirm',
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            shadows:
                                                                CustomTextShadow
                                                                    .shadows,
                                                            fontSize: 20),
                                                      )
                                                    : (TimeLimitReached(
                                                                widget.habitName,
                                                                reminder) == 0)
                                                        ? Text(
                                                            'Go to confirmation page,\n         before ${((reminder.hour + (reminder.minute + 10) / 60) % 24).toInt().toString().padLeft(2, '0')}:${((reminder.minute + 10) % 60).toString().padLeft(2, '0')}',
                                                            style: TextStyle(
                                                                color: Colors.white,
                                                                shadows:
                                                                    CustomTextShadow
                                                                        .shadows,
                                                                fontSize: 20),
                                                          )
                                                        : Text(
                                                            'Too late to confirm',
                                                            style: TextStyle(
                                                                color: Colors.white,
                                                                shadows:
                                                                    CustomTextShadow
                                                                        .shadows,
                                                                fontSize: 20),
                                                          ),
                                  ),
                                ),
                              ),
                              //partner progress
                              (partner_name == null)
                                  ? SizedBox()
                                  : SizedBox(
                                      height: 20,
                                    ),
                              (partner_name == null)
                                  ? SizedBox()
                                  : Text(
                                      'Partner $partner_name Progress:',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        shadows: CustomTextShadow.shadows,
                                      ),
                                    ),
                              (partner_name == null)
                                  ? SizedBox()
                                  : Stack(
                                      children: <Widget>[
                                        Padding(
                                          padding: const EdgeInsets.only(top: 24.0),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: SizedBox(
                                              height: 30,
                                              child: LinearProgressIndicator(
                                                value: curr_partner /
                                                    goal, // Use curr_days and goal_days here
                                                backgroundColor: Colors.blue[300],
                                                valueColor:
                                                    AlwaysStoppedAnimation<Color>(
                                                  //widget.is_confirmed ? Colors.green.shade600 : Color.fromARGB(255, 255, 255, 2), // Conditional color assignment
                                                  (curr_partner >= goal)
                                                      ? Colors.green.shade600
                                                      : Color.fromARGB(
                                                          255,
                                                          255,
                                                          255,
                                                          2), // Conditional color assignment
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.center,
                                          child: Container(
                                            margin: EdgeInsets.only(
                                                top:
                                                    20), // Adjust this value to lower the text as needed
                                            child: Text(
                                              '${curr_partner} of ${goal} days done!', // Use curr_days and goal_days here
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                shadows: CustomTextShadow.shadows,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                              (partner_name == null)
                                  ? SizedBox()
                                  : SizedBox(
                                      height: 20,
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    /////////////////////////////
                    Tooltip(
                      key: _tooltipKey,
                      message: 'Challenge rules: Entering the challenge will cost you 50 points. But in exchange, commiting to habits in challenges will make you earn much more points! The big prize (sum of all points that are earned by all participants if they do the habit if it was normal) will be shared among the winners (only those who made it to the goal!). The more you commit, the more you earn!',
                     preferBelow: true, 
                      decoration: BoxDecoration(
                        color: Colors.grey[100], // Tooltip background color
                        borderRadius: BorderRadius.circular(4), // Rounded corners
                      ),
                      textStyle: TextStyle(color: Colors.black),
                      child: IconButton(
                        highlightColor: Colors.black,
                        icon: Icon(Icons.info, color: Colors.grey[100], shadows: CustomTextShadow.shadows,),
                        onPressed: _showTooltip,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
            floatingActionButton: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: () async {
                        if (_isNavigating) return;
                   DocumentSnapshot chal = await FirebaseFirestore.instance
                    .collection('challenges')
                    .where('challengeName', isEqualTo: widget.habitName)
                    .get()
                    .then((snapshot) => snapshot.docs.first);

// Update the map field to remove the user ID
                await chal.reference.update({
                  'recipients.${auth.currentUser!.uid}': FieldValue.delete(),
                });
                   
                bool is_removed = await removeHabit(context, widget.habitName);

                if (is_removed) {
                  _isNavigating = true;
                  // Remove the habit from participants in the challenge in Firestore
                  
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => MyBottomNavigation(),
                    ),
                  );
                }
                _isNavigating = false;
                  },
                  child: Icon(Icons.delete),
                  backgroundColor: Colors.blue[800],
                ),
              
              ],
            ),
        ),
      );
  }}

int TimeLimitReached(String habit, TimeOfDay reminder) {
  DateTime now = DateTime.now();
  TimeOfDay nowTime = TimeOfDay(hour: now.hour, minute: now.minute);

  // Convert TimeOfDay to DateTime for comparison
  DateTime reminderDateTime =
      DateTime(now.year, now.month, now.day, reminder.hour, reminder.minute);
  DateTime reminderPlus10Min = reminderDateTime.add(Duration(minutes: 10));
  DateTime nowDateTime =
      DateTime(now.year, now.month, now.day, nowTime.hour, nowTime.minute);
  if (nowDateTime.isBefore(reminderDateTime)) {
    return -1;
  } else if ((nowDateTime.isAfter(reminderDateTime) &&
          nowDateTime.isBefore(reminderPlus10Min)) ||
      nowDateTime.isAtSameMomentAs(reminderDateTime) ||
      nowDateTime.isAtSameMomentAs(reminderPlus10Min)) {
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
