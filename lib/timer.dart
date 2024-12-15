import 'package:animated_button/animated_button.dart';
import 'package:flutter/material.dart';
import 'package:habit_hero/firebase_help_functions.dart';
import 'package:habit_hero/habit_reminders.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_hero/text_shdows.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:habit_hero/chell/challange.dart';


Future<bool> doesCollectionExist(String userId, String habitName) async {
  var querySnapshot = await FirebaseFirestore.instance
      .collection('Users')
      .doc(userId)
      .collection('Habit_$habitName')
      .limit(1)
      .get();
           var query1Snapshot = await FirebaseFirestore.instance
      .collection('Users')
      .doc(userId)
      .collection('challenge_$habitName')
      .limit(1)
      .get();

  return querySnapshot.docs.isNotEmpty || query1Snapshot.docs.isNotEmpty;
}
Future<bool> doeschallengeExist(String userId, String habitName) async {
  var querySnapshot = await FirebaseFirestore.instance
      .collection('Users')
      .doc(userId)
      .collection('Habit_$habitName')
      .limit(1)
      .get();
        var query1Snapshot = await FirebaseFirestore.instance
      .collection('Users')
      .doc(userId)
      .collection('SharedHabit_$habitName')
      .limit(1)
      .get();


  return querySnapshot.docs.isNotEmpty || query1Snapshot.docs.isNotEmpty;
}

class TimerPage extends StatefulWidget {
  
  final String habitName;
  final int timerValue;

  TimerPage({Key? key, required this.habitName ,required this.timerValue}) : super(key: key);
  
  @override
  _TimerPageState createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  Timer? _timer;
  Timer? _dailyResetTimer;
  //final timeInMinutes = 1; // Set the countdown time here
  int _remainingSeconds = 0;
  bool isTimerRunning = false;
  bool _timerFinished = false;
  bool _isButtonDisabled = false;
  bool _isLoading = true;
  bool isNotShared = true;
  bool isNotchallenge = true;

  void isShared_function() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;
    final userId = user?.uid;
    isNotShared = await doesCollectionExist(userId!, widget.habitName);
    _loadButtonState();
    if(mounted)setState(() {});
  }
  void ischallenge_function() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;
    final userId = user?.uid;
    isNotchallenge = await doeschallengeExist(userId!, widget.habitName);
    _loadButtonState();
    if(mounted)setState(() {});
  }

  @override
  void initState() {
    super.initState();
    isShared_function();
    ischallenge_function();
    _loadButtonState();
    _setDailyReset();
    _remainingSeconds = (widget.timerValue * 60);
  }


Future<int> getStreak(String? userId, String habitName) async {
  try {
    // Asynchronously fetch the document
    var documentSnapshot;
    if (isNotShared&&isNotchallenge)
    documentSnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('Habit_$habitName')
        .doc('Method_info')
        .get();
    else if (!isNotShared&&isNotchallenge)
    documentSnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('SharedHabit_$habitName')
        .doc('Method_info')
        .get();
        else
        {
            documentSnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .doc(userId)
            .collection('challenge_$habitName')
            .doc('Method_info')
            .get();

        }
    // Access the document's data
    var data = documentSnapshot.data();
    if (data != null && data['streak'] != null) {
      // Explicitly cast the 'streak' field to an int
      return int.tryParse(data['streak'].toString()) ?? 0;
    } else {
      // Return 0 or handle the case where the document does not exist or has no data
      return 0;
    }
  } catch (e) {
    // Handle any errors that occur during the get operation
    print("Error getting document: $e");
    return 0; // Return 0 or an appropriate error value
  }
}
Future<bool> newTop() async {
  
    final FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseFirestore db = FirebaseFirestore.instance;
    final User? user = auth.currentUser;
    final userId = user?.uid; 
    int streak = 0;
    int top_streak = 0;
  try {
    var docForTop = await db.collection('Users')
                                   .doc(userId)
                                   .get();
    var documentSnapshot;
    if(isNotShared&&isNotchallenge)
    documentSnapshot = await db.collection('Users')
                                   .doc(userId)
                                   .collection('Habit_${widget.habitName}')
                                   .doc('Method_info')
                                   .get();
    else if (!isNotShared&&isNotchallenge)
    documentSnapshot = await db.collection('Users')
                                   .doc(userId)
                                   .collection('SharedHabit_${widget.habitName}')
                                   .doc('Method_info')
                                   .get();
    else if (isNotShared&&!isNotchallenge){
    documentSnapshot = await db.collection('Users')
                                   .doc(userId)
                                   .collection('challenge_${widget.habitName}')
                                   .doc('Method_info')
                                   .get();}
    
    var data = documentSnapshot.data();
    var top_data = docForTop.data();
    if (data != null) {
      streak = data['streak'];
      top_streak = top_data?['top_streak'];
    } else {
      print("Document does not exist or has no data.");
    }
  } catch (e) {
    print("Error getting document: $e");
  }
  return streak > top_streak;
}

  Future<void> _loadButtonState() async {

    final FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseFirestore db = FirebaseFirestore.instance;
    final User? user = auth.currentUser;
    final userId = user?.uid; 
    var methodInfoDoc;
    if (isNotShared && isNotchallenge) {
      methodInfoDoc = await db
        .collection('Users')
        .doc(userId)
        .collection('Habit_${widget.habitName}')
        .doc('Method_info')
        .get();
    } else if (!isNotShared && isNotchallenge) {
      methodInfoDoc = await db
        .collection('Users')
        .doc(userId)
        .collection('SharedHabit_${widget.habitName}')
        .doc('Method_info')
        .get();
    } else if (isNotShared && !isNotchallenge) {
      methodInfoDoc = await db
        .collection('Users')
        .doc(userId)
        .collection('challenge_${widget.habitName}')
        .doc('Method_info')
        .get();
    }
    int done = methodInfoDoc.data()?['done_today'] ?? 0;

    //SharedPreferences prefs = await SharedPreferences.getInstance();
    //int lastFinishTimestamp = prefs.getInt('lastFinishTime') ?? 0;
    //DateTime lastFinishTime = DateTime.fromMillisecondsSinceEpoch(lastFinishTimestamp);

    //DateTime now = DateTime.now();
    //DateTime nextMidnight = DateTime(now.year, now.month, now.day + 1);
    //DateTime previousMidnight = DateTime(now.year, now.month, now.day,0,0);


    if(done == 1 && mounted){
      setState(() {
        _timerFinished = true;
        _isButtonDisabled = true;
        _isLoading = false;
      });
    }

    else {
      if(mounted){
          setState(() {
            _timerFinished = false;
            _isButtonDisabled = false;
            _isLoading = false;
          });
      }

        }
        _isLoading = false;
  }

  void _setDailyReset() {
    
    _dailyResetTimer?.cancel();
    _dailyResetTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      DateTime now = DateTime.now();
      if (now.hour == 0 && now.minute == 0 && mounted) {
        setState(() {
          _timerFinished = false;
          _isButtonDisabled = false;
          editDoneToday(widget.habitName, 0);
        });
      }
    });
  }

  void startTimer() {
    
    final FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseFirestore db = FirebaseFirestore.instance;
    final User? user = auth.currentUser;
    final userId = user?.uid; 

    if (_timer != null) {
      _timer!.cancel();
    }

    if(mounted){
    setState(() {
      isTimerRunning = true;
      _isButtonDisabled = true;
      _remainingSeconds = widget.timerValue * 60;
    });

    }

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0 && mounted) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        if(mounted){
        setState(() {
          isTimerRunning = false;
          _timerFinished = true;
          _isButtonDisabled = true;

          editDoneToday(widget.habitName, 1);
            (isNotShared && isNotchallenge
            ? db.collection('Users').doc(userId).collection('Habit_${widget.habitName}').doc('Method_info')
            : isNotShared && !isNotchallenge
              ? db.collection('Users').doc(userId).collection('challenge_${widget.habitName}').doc('Method_info')
              : db.collection('Users').doc(userId).collection('SharedHabit_${widget.habitName}').doc('Method_info')
            ).set({
            'streak': FieldValue.increment(1),
          }, SetOptions(merge: true)).then((_) async {
          // Retrieve the updated streak value

          var methodInfoDoc = (isNotShared && isNotchallenge)? await db.collection('Users').doc(userId).collection('Habit_${widget.habitName}').doc('Method_info').get()
          : isNotShared && !isNotchallenge ? await db
                        .collection('Users')
                        .doc(userId)
                        .collection('challenge_${widget.habitName}')
                        .doc('Method_info').get()
          : await db.collection('Users').doc(userId).collection('SharedHabit_${widget.habitName}').doc('Method_info').get();
          
          var currentStreak = methodInfoDoc.data()?['streak'];

          // Retrieve the top_streak value
          var userDoc = await db.collection('Users').doc(userId).get();
          var topStreak = userDoc.data()?['top_streak'];

          // Update top_streak if current streak is higher
          if (currentStreak > topStreak) {
            db.collection('Users').doc(userId).set({
              'top_streak': currentStreak,
            }, SetOptions(merge: true));
          }

          var goal = methodInfoDoc.data()?['week_goal'];
          // Increment week_curr and wrap around after 7
          var currentWeekCurr = methodInfoDoc.data()?['week_curr'] ?? 0;
            var newWeekCurr = (currentWeekCurr != goal)?((currentWeekCurr + 1) % (goal+1)) : currentWeekCurr;
            var timer_val = methodInfoDoc.data()?['timer_val'] ?? 0;

            if(isNotShared && isNotchallenge) {
            db.collection('Users').doc(userId).collection('Habit_${widget.habitName}').doc('Method_info').set({
              'week_curr': newWeekCurr,
            }, SetOptions(merge: true));
            } else if (!isNotShared && isNotchallenge) {
            db.collection('Users').doc(userId).collection('SharedHabit_${widget.habitName}').doc('Method_info').set({
              'week_curr': newWeekCurr,
            }, SetOptions(merge: true));
            } else if (isNotShared && !isNotchallenge) {
            db.collection('Users').doc(userId).collection('challenge_${widget.habitName}').doc('Method_info').set({
              'week_curr': newWeekCurr,
            }, SetOptions(merge: true));
            }

          db.collection('Users').doc(userId).set({
          'points': FieldValue.increment(timer_val),
          }, SetOptions(merge: true));
          if(isNotShared&&isNotchallenge)
          db.collection('Users').doc(userId).collection('Habit_${widget.habitName}').doc('Method_info').set({
          'habit_points': FieldValue.increment(widget.timerValue),
          }, SetOptions(merge: true));
          else if(!isNotShared && isNotchallenge)
          db.collection('Users').doc(userId).collection('SharedHabit_${widget.habitName}').doc('Method_info').set({
          'habit_points': FieldValue.increment(widget.timerValue),
          }, SetOptions(merge: true));
          else if (isNotShared && !isNotchallenge) {
            db.collection('Users').doc(userId).collection('challenge_${widget.habitName}').doc('Method_info').set({
              'week_curr': newWeekCurr,
            }, SetOptions(merge: true));
          }
        });
        });
        }

        _saveFinishTime();
      
        timer.cancel();
      }
      
    });
   
  }

  void _saveFinishTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('lastFinishTime', DateTime.now().millisecondsSinceEpoch);
   // updatechallenge(widget.habitName);
  }

  String get timerText {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _dailyResetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // DateTime _now = DateTime.now();
    // DateTime _nextMidnight = DateTime(_now.year, _now.month, _now.day + 1);
    // DateTime _prevMidnight = DateTime(_now.year, _now.month, _now.day - 1);


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
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
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
              Navigator.pop(context);
            },
            tooltip: 'Back',
          ),
        ),
        body: (!_isLoading)?Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Center(
                child: (isTimerRunning || (!_isButtonDisabled))?Tooltip(
                  message: 'Timer: $timerText',
                  child: Text(
                    'Timer: $timerText',
                    style: TextStyle(fontSize: 48, color: Colors.white, shadows: CustomTextShadow.shadows),
                  ),
                ):Container(),
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Column(
                  children: [
                    (!_timerFinished)
                        ? Tooltip(
                          message: isTimerRunning ? 'Timer Running...' : 'Start Timer',
                          child: AnimatedButton(
                            onPressed: startTimer,
                            enabled: !_isButtonDisabled,
                            child: Tooltip(
                              message: isTimerRunning ? 'Timer Running...' : 'Start Timer',
                              child: Text(
                                isTimerRunning ? 'Timer Running...' : 'Start Timer',
                                style: TextStyle(color: Colors.white, shadows: CustomTextShadow.shadows, fontSize: 20),
                              ),
                            ),
                            color: Colors.blue[800] ?? Colors.blue,
                          ),
                        )
                        : Container(
                            width: 120,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Tooltip(
                                message: 'Confirmed!',
                                child: Text(
                                  'Confirmed!',
                                  style: TextStyle(color: Colors.white, fontSize: 18, shadows: CustomTextShadow.shadows),
                                ),
                              ),
                            ),
                          ),
                    (_timerFinished)?Tooltip(
                      message: 'Come back tomorrow to confirm again!',
                      child: Text('\nCome back tomorrow to confirm again!',style: TextStyle(
                        color: Colors.white,
                        shadows: CustomTextShadow.shadows,
                        fontSize: 16,
                      ),),
                    ): Container(),
                    SizedBox(height: 20),
                    isTimerRunning
                        ? Tooltip(
                            message: 'Timer will run for ${widget.timerValue} minutes please don\'t leave this screen!',
                          child: Text(
                              'Timer will run for ${widget.timerValue} minutes\n please don\'t leave this screen!',
                              style: TextStyle(color: Colors.white, shadows: CustomTextShadow.shadows, fontSize: 16),
                              textAlign: TextAlign.center,
                              
                            ),
                        )
                        : SizedBox(height: 40),
                  ],
                ),
              ),

              //Text('today: ${_now.month} - ${_now.day} - ${_now.hour} - ${_now.minute}'),      
              //Text('next midnight: ${_nextMidnight.month} - ${_nextMidnight.day} - ${_nextMidnight.hour} - ${_nextMidnight.minute}'),      
              //Text('prev midnight: ${_prevMidnight.month} - ${_prevMidnight.day} - ${_prevMidnight.hour} - ${_prevMidnight.minute}'),      


              SizedBox(height: 160),
              Tooltip(
                message: 'Status of this habit:',
                child: Text(
                  'Status of this habit:',
                  style: TextStyle(color: Colors.white, shadows: CustomTextShadow.shadows, fontSize: 18),
                ),
              ),
              Tooltip(
                message: _timerFinished ? 'Confirmed!' : 'Not Confirmed!',
                child: Image.asset(
                  _timerFinished ? 'app_images/check.png' : 'app_images/X.png', // Path to your asset image
                  width: 100, // Optional: Set the width of the image
                  height: 100, // Optional: Set the height of the image
                  fit: BoxFit.cover, // Optional: Set how the image should be fit into the widget
                ),
              ),
            ],
          ),
        ) : Center(child: CircularProgressIndicator(color: Colors.blue[800],)),
      ),
    );
  }
}
