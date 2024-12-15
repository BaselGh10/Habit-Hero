import 'package:flutter/material.dart';
import 'package:habit_hero/text_shdows.dart';
import 'dart:async';
import 'package:animated_button/animated_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_help_functions.dart';

String getTimeDifferenceInMinutes(TimeOfDay startTime, TimeOfDay endTime) {
  final now = DateTime.now();
  final startDateTime = DateTime(now.year, now.month, now.day, startTime.hour, startTime.minute);
  final endDateTime = DateTime(now.year, now.month, now.day, endTime.hour, endTime.minute);

  final difference = endDateTime.difference(startDateTime);
  if(difference.inMinutes == 0) return 'less than one';
  if(difference.inMinutes < 0) return (-1 * difference.inMinutes).toString();
  return difference.inMinutes.toString();
}

TimeOfDay addMinutesToTimeOfDay(TimeOfDay time, int minutesToAdd) {
  final int totalMinutes = time.hour * 60 + time.minute + minutesToAdd;
  final int newHour = (totalMinutes ~/ 60) % 24; // Ensure it wraps around 24 hours
  final int newMinute = totalMinutes % 60;
  return TimeOfDay(hour: newHour, minute: newMinute);
}

class TimeOfDayWithSeconds {
  final int hour;
  final int minute;
  final int second;

  const TimeOfDayWithSeconds({required this.hour, required this.minute, required this.second});
}

class staticValues_MultiConf {
  static TimeOfDayWithSeconds firstConfirm = TimeOfDayWithSeconds(hour: 0, minute: 0, second: 0);
  static TimeOfDayWithSeconds secondConfirm = TimeOfDayWithSeconds(hour: 0, minute: 0, second: 0);
  static int conf_num = 0;
  static bool lock = false;
  static String habitName = '';
}

class MultiConf extends StatefulWidget {
  final int intervalTime;
  final String habitName;

  MultiConf({Key? key, required this.intervalTime, required this.habitName}) : super(key: key);

  @override
  _MultiConfState createState() => _MultiConfState();
}

class _MultiConfState extends State<MultiConf> {
  Map<String, dynamic> _Method_info = {'done_today': 0};
  String userId = FirebaseAuth.instance.currentUser!.uid;
  bool _isLoading = true;
  String _buttonStr = 'wait...';
  bool _isButtonDisabled = true;
  Timer? _timer;
  TimeOfDay intervalTimeDone = TimeOfDay(hour: 0, minute: 0);
  TimeOfDay intervalTimeDone_2 = TimeOfDay(hour: 0, minute: 0);

  @override
  void initState() {
    super.initState();
    setValues();
    performPeriodicTask();
    startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void setValues() async {
    _Method_info = await getMethodInfoDoc(userId,widget.habitName);
    if(mounted){
    setState(() {
      _isLoading = false;
    });
    }

  }

  void startTimer() {
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      performPeriodicTask();
    });
  }

  void performPeriodicTask() {
    setButton();
  }

  void setButton() async {
    if (_Method_info['done_today'] == 1) {
      if(mounted){
      setState(() {
        _buttonStr = 'Confirmed!';
        _isButtonDisabled = true;
      });
      }

      return;
    }
    if(_Method_info['done_today'] == -1) {
      if(mounted){
      setState(() {
        _buttonStr = 'You missed the interval time';
        _isButtonDisabled = true;
      });
      }

      return;
    }
    if (staticValues_MultiConf.conf_num == 0) {
      if(mounted){
      setState(() {
        _buttonStr = 'Press to Confirm';
        _isButtonDisabled = false;
      });
      }

    }
    if (staticValues_MultiConf.conf_num == 1) {
      TimeOfDay confirming_time = TimeOfDay(hour: staticValues_MultiConf.firstConfirm.hour, minute: staticValues_MultiConf.firstConfirm.minute);
      intervalTimeDone = addMinutesToTimeOfDay(confirming_time, widget.intervalTime);
      intervalTimeDone_2 = addMinutesToTimeOfDay(intervalTimeDone, widget.intervalTime);
      TimeOfDay now = TimeOfDay.now();
      bool isAfterIntervalTimeDone = (now.hour > intervalTimeDone.hour) || (now.hour == intervalTimeDone.hour && now.minute > intervalTimeDone.minute);
      bool isBeforeIntervalTimeDone_2 = (now.hour < intervalTimeDone_2.hour) || (now.hour == intervalTimeDone_2.hour && now.minute < intervalTimeDone_2.minute);
      bool isAfterIntervalTimeDone_2 = (now.hour > intervalTimeDone_2.hour) || (now.hour == intervalTimeDone_2.hour && now.minute > intervalTimeDone_2.minute);
      if((staticValues_MultiConf.firstConfirm.second <= DateTime.now().second && now.hour == intervalTimeDone.hour && now.minute == intervalTimeDone.minute) || (isAfterIntervalTimeDone && isBeforeIntervalTimeDone_2) || (staticValues_MultiConf.firstConfirm.second >= DateTime.now().second && now.hour == intervalTimeDone_2.hour && now.minute == intervalTimeDone_2.minute)) {
        if(mounted){
        setState(() {
          _buttonStr = 'Press to Confirm again';
          _isButtonDisabled = false;
        });
        }

      }
      else if (isAfterIntervalTimeDone_2 || (staticValues_MultiConf.firstConfirm.second <= DateTime.now().second && now.hour == intervalTimeDone_2.hour && now.minute == intervalTimeDone_2.minute)){
        await editDoneToday(widget.habitName, -1);
        staticValues_MultiConf.habitName = '';
        if(mounted){
          setState(() {
          _buttonStr = 'You missed the interval time';
          _isButtonDisabled = true;
          staticValues_MultiConf.lock = false;
          staticValues_MultiConf.conf_num = 0;
          setValues();
        });
        }

      }
      else {
        if(mounted){
        setState(() {
          _buttonStr = 'Wait for ' + intervalTimeDone.hour.toString().padLeft(2, '0') + ':' + intervalTimeDone.minute.toString().padLeft(2, '0');
          _isButtonDisabled = true;
        });
        }

      }
    }
    if (staticValues_MultiConf.conf_num == 2) {
      TimeOfDay confirming_time = TimeOfDay(hour: staticValues_MultiConf.secondConfirm.hour, minute: staticValues_MultiConf.secondConfirm.minute);
      intervalTimeDone = addMinutesToTimeOfDay(confirming_time, widget.intervalTime);
      intervalTimeDone_2 = addMinutesToTimeOfDay(intervalTimeDone, widget.intervalTime);
      TimeOfDay now = TimeOfDay.now();
      bool isAfterIntervalTimeDone = (now.hour > intervalTimeDone.hour) || (now.hour == intervalTimeDone.hour && now.minute >= intervalTimeDone.minute);
      bool isBeforeIntervalTimeDone_2 = (now.hour < intervalTimeDone_2.hour) || (now.hour == intervalTimeDone_2.hour && now.minute < intervalTimeDone_2.minute);
      bool isAfterIntervalTimeDone_2 = (now.hour > intervalTimeDone_2.hour) || (now.hour == intervalTimeDone_2.hour && now.minute > intervalTimeDone_2.minute);
      if((staticValues_MultiConf.secondConfirm.second <= DateTime.now().second && now.hour == intervalTimeDone.hour && now.minute == intervalTimeDone.minute) || (isAfterIntervalTimeDone && isBeforeIntervalTimeDone_2) || (staticValues_MultiConf.secondConfirm.second >= DateTime.now().second && now.hour == intervalTimeDone_2.hour && now.minute == intervalTimeDone_2.minute)) {
        if(mounted){
        setState(() {
          _buttonStr = 'Press to Confirm again';
          _isButtonDisabled = false;
        });
        }

      }
      else if (isAfterIntervalTimeDone_2 || (staticValues_MultiConf.secondConfirm.second <= DateTime.now().second && now.hour == intervalTimeDone_2.hour && now.minute == intervalTimeDone_2.minute)){
        await editDoneToday(widget.habitName, -1);
        staticValues_MultiConf.habitName = '';
        if(mounted){
        setState(() {
          _buttonStr = 'You missed the interval time';
          _isButtonDisabled = true;
          staticValues_MultiConf.lock = false;
          staticValues_MultiConf.conf_num = 0;
          setValues();
        });
        }

      }
      else {
        if(mounted){
        setState(() {
          _buttonStr = 'Wait for ' + intervalTimeDone.hour.toString().padLeft(2, '0') + ':' + intervalTimeDone.minute.toString().padLeft(2, '0');
          _isButtonDisabled = true;
        });
        }

      }
    }
    if (staticValues_MultiConf.conf_num == 3) {
      await editDoneToday(widget.habitName, 1);
      staticValues_MultiConf.habitName = '';
      if(mounted){
      setState(() {
        staticValues_MultiConf.lock = false;
        _buttonStr = 'Confirmed!';
        _isButtonDisabled = true;
        setValues();
      });
      }

    }
  }

  Future<bool> _handleButtonPress() async {
    if(mounted){
      setState(() {
      _isButtonDisabled = true;
      _buttonStr = 'Wait...';
    });
    }

    if(staticValues_MultiConf.habitName != widget.habitName && staticValues_MultiConf.habitName != ''){
      _isButtonDisabled = true;
      return false;
    }
    else if(staticValues_MultiConf.habitName != widget.habitName) {staticValues_MultiConf.lock = true;
    staticValues_MultiConf.habitName = widget.habitName;
    staticValues_MultiConf.conf_num = 0;}

    if(staticValues_MultiConf.conf_num == 0){
      int sec = DateTime.now().second;
      if(sec >= 50) sec = 49;
      staticValues_MultiConf.firstConfirm = TimeOfDayWithSeconds(hour: DateTime.now().hour, minute: DateTime.now().minute, second: sec);
      staticValues_MultiConf.conf_num++;
    }
    else if(staticValues_MultiConf.conf_num == 1){
      int sec = DateTime.now().second;
      if(sec >= 50) sec = 49;
      staticValues_MultiConf.secondConfirm = TimeOfDayWithSeconds(hour: DateTime.now().hour, minute: DateTime.now().minute, second: sec);
      staticValues_MultiConf.conf_num++;
    }
    else if(staticValues_MultiConf.conf_num == 2){
      if(_Method_info['done_today'] == 0) confirmHabitSuccess();
      await editDoneToday(widget.habitName, 1);
      staticValues_MultiConf.habitName = '';
      staticValues_MultiConf.conf_num = 0;
      staticValues_MultiConf.lock = false;
      setValues();
      if(mounted){
      setState(() {
        _buttonStr = 'Confirmed!';
        _isButtonDisabled = true;
      });
      }

    }
    setButton();
    return true;
  }

  void confirmHabitSuccess() async {
    print('confirmed');
    FirebaseFirestore db = FirebaseFirestore.instance;
    String habitCollection = 'Habit_${widget.habitName}';
    String sharedHabitCollection = 'SharedHabit_${widget.habitName}';
    String challangecollection = 'challenge_${widget.habitName}';

    // Check if the Habit collection exists
    var habitCollectionExists = await db.collection('Users').doc(userId).collection(habitCollection).get().then((snapshot) => snapshot.docs.isNotEmpty);
var sharedhabitCollectionExists = await db.collection('Users').doc(userId).collection(sharedHabitCollection).get().then((snapshot) => snapshot.docs.isNotEmpty);
    if (!habitCollectionExists&&sharedhabitCollectionExists) {
      habitCollection = sharedHabitCollection;
    }
    if (!habitCollectionExists&&!sharedhabitCollectionExists) {
      habitCollection = challangecollection;
    }

    await db.collection('Users').doc(userId).collection(habitCollection).doc('Method_info').set({
      'streak': FieldValue.increment(1),
    }, SetOptions(merge: true)).then((_) async {
      var methodInfoDoc = await db.collection('Users').doc(userId).collection(habitCollection).doc('Method_info').get();
      var currentStreak = methodInfoDoc.data()?['streak'];
      var userDoc = await db.collection('Users').doc(userId).get();
      var topStreak = userDoc.data()?['top_streak'];

      if (currentStreak > topStreak) {
        print('if 5');
        db.collection('Users').doc(userId).set({
          'top_streak': currentStreak,
        }, SetOptions(merge: true));
      }
      editDoneToday(widget.habitName, 1);
      staticValues_MultiConf.habitName = '';

      var goal = methodInfoDoc.data()?['week_goal'];
      var currentWeekCurr = methodInfoDoc.data()?['week_curr'] ?? 0;
      var newWeekCurr = (currentWeekCurr + 1) % (goal + 1);

      db.collection('Users').doc(userId).collection(habitCollection).doc('Method_info').set({
        'week_curr': newWeekCurr,
      }, SetOptions(merge: true));
      db.collection('Users').doc(userId).set({
        'points': FieldValue.increment(15),
      }, SetOptions(merge: true));
      db.collection('Users').doc(userId).collection(habitCollection).doc('Method_info').set({
        'habit_points': FieldValue.increment(15),
      }, SetOptions(merge: true));
    });
  }

  @override
  Widget build(BuildContext context) {
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
            icon: Tooltip(
              message: 'Go back',
              child: CircleAvatar(
                backgroundColor: Colors.blue[800],
                radius: 20,
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                  shadows: CustomTextShadow.shadows,
                ),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: (widget.habitName != staticValues_MultiConf.habitName && staticValues_MultiConf.habitName != '')? 
        Center(
          child: Text("Another habit is getting\nconfirmed right now.\nCome back after you\nfinish it!", style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        shadows: CustomTextShadow.shadows,
                      ),),
        ): (!_isLoading) ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                ((_Method_info['done_today'] == 0))?SizedBox(
                width: 200,
                height: 70,
                child: Tooltip(
                  message: 'Press to confirm',
                  child: AnimatedButton(
                    child: Text(
                      _buttonStr,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        shadows: CustomTextShadow.shadows,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    onPressed: () async {
                      if (!(await _handleButtonPress())) {
                        print('lego'+staticValues_MultiConf.habitName);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('You are confirming another habit at the moment!')),
                        );
                      } else {
                        // Handle button press here
                      }
                    },
                    enabled: !_isButtonDisabled,
                    color: Colors.blue[800] ?? Colors.blue,
                    shadowDegree: ShadowDegree.dark,
                  ),
                ),
              ) : ((_Method_info['done_today'] == 1))? Tooltip(
                message: 'Habit confirmed',
                child: Container(
                  height: 30,
                  width: 110,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'Confirmed!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        shadows: CustomTextShadow.shadows,
                      ),
                    ),
                  ),
                ),
              ) :
              Tooltip(
                message: 'Cannot confirm again',
                child: Container(
                  height: 30,
                  width: 300,
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 220, 35, 11),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'You cannot confirm again!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        shadows: CustomTextShadow.shadows,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 60),
              (staticValues_MultiConf.habitName != widget.habitName && staticValues_MultiConf.habitName != '') ? Text(
                'You are confirming another habit at the moment!, ${staticValues_MultiConf.habitName}.',
                style: TextStyle(color: Colors.white, fontSize: 18, shadows: CustomTextShadow.shadows),
              ) : 
              (staticValues_MultiConf.lock && staticValues_MultiConf.habitName == widget.habitName) ? Text(
                'You have confirmed this habit\n ${staticValues_MultiConf.conf_num} times out of 3',
                style: TextStyle(color: Colors.white, fontSize: 18, shadows: CustomTextShadow.shadows),
              ) : SizedBox(),
              SizedBox(height: 20),
              (_buttonStr == 'Wait...') ? Text('You pressed the button', style: TextStyle(color: Colors.white, fontSize: 18, shadows: CustomTextShadow.shadows),) : SizedBox(),
              (_buttonStr == 'Confirmed!') ? Text('Good job!', style: TextStyle(color: Colors.white, fontSize: 18, shadows: CustomTextShadow.shadows),) : SizedBox(),
              (_buttonStr == 'You missed the interval time') ? Text('Oops! You forgot to confirm!', style: TextStyle(color: Colors.white, fontSize: 18, shadows: CustomTextShadow.shadows),) : SizedBox(),
              (_buttonStr == 'Press to Confirm again') ? ((staticValues_MultiConf.conf_num == 1) ? Text('You have ${getTimeDifferenceInMinutes(TimeOfDay.now(), addMinutesToTimeOfDay(TimeOfDay(hour: staticValues_MultiConf.firstConfirm.hour,minute: staticValues_MultiConf.firstConfirm.minute), widget.intervalTime*2))} min left', style: TextStyle(color: Colors.white, fontSize: 18, shadows: CustomTextShadow.shadows),) : Text('You have ${getTimeDifferenceInMinutes(TimeOfDay.now(), addMinutesToTimeOfDay(TimeOfDay(hour: staticValues_MultiConf.secondConfirm.hour,minute: staticValues_MultiConf.secondConfirm.minute), widget.intervalTime*2) )} min left', style: TextStyle(color: Colors.white, fontSize: 18, shadows: CustomTextShadow.shadows),)) : SizedBox(),
              (_buttonStr.contains('Wait for')) ? ((staticValues_MultiConf.conf_num == 1) ? Text('You have ${getTimeDifferenceInMinutes(TimeOfDay.now(), addMinutesToTimeOfDay(TimeOfDay(hour: staticValues_MultiConf.firstConfirm.hour,minute: staticValues_MultiConf.firstConfirm.minute), widget.intervalTime))} min left', style: TextStyle(color: Colors.white, fontSize: 18, shadows: CustomTextShadow.shadows),) : Text('You have ${getTimeDifferenceInMinutes(TimeOfDay.now(), addMinutesToTimeOfDay(TimeOfDay(hour: staticValues_MultiConf.secondConfirm.hour,minute: staticValues_MultiConf.secondConfirm.minute), widget.intervalTime) )} min left', style: TextStyle(color: Colors.white, fontSize: 18, shadows: CustomTextShadow.shadows),)) : SizedBox(),
              SizedBox(height: 80),
              Text(
                'Status of this habit:',
                style: TextStyle(color: Colors.white, fontSize: 18, shadows: CustomTextShadow.shadows),
              ),
              Tooltip(
                message: 'Habit status',
                child: Image.asset(
                  _Method_info['done_today'] == 1 ? 'app_images/check.png' : 'app_images/X.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ) : Center(child: CircularProgressIndicator(color: Colors.blue[800],)),
      ),
    );
  }
}
