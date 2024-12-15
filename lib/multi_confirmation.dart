/*
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:habit_hero/text_shdows.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:animated_button/animated_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_help_functions.dart';
import 'dart:async';

class MultiConf extends StatefulWidget {
  final int intervalTime;
  final String habitName;

  MultiConf({Key? key, required this.intervalTime, required this.habitName}) : super(key: key);

  @override
  _MultiConfState createState() => _MultiConfState();
}

class _MultiConfState extends State<MultiConf> {
  bool _isButtonDisabled = false;
  late DateTime _firstPressedTime;
  List<DateTime> _confirmationTimes = [];
  bool intervalPassed = false;
  bool _isLoading = true;
  int _curr_conf = 0;  
  Timer? _dailyResetTimer;
  bool _done = false;
  bool _restareted = false;
  bool _afterInterval = false;
  Timer? _minuteUpdateTimer;
  TimeOfDay? _timeOfButtonPress = null;

  @override
  void initState() {
    super.initState();
    _setDailyReset();
    fetchCurr();
    _loadButtonState();
    _startMinuteUpdateTimer();
  }

  void _startMinuteUpdateTimer() {
    _minuteUpdateTimer = Timer.periodic(Duration(minutes: 1), (Timer t) {
      setState(() {
        // This block will be executed every 1 minute
        // Update any state you need here
      });
    });
  }

  @override
  void dispose() {
    _dailyResetTimer?.cancel();
    _minuteUpdateTimer?.cancel(); // Cancel the periodic timer
    super.dispose();
  }

  void _loadButtonState() async {

    final FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseFirestore db = FirebaseFirestore.instance;
    final User? user = auth.currentUser;
    final userId = user?.uid;
    var methodInfoDoc = await db.collection('Users').doc(userId).collection('Habit_${widget.habitName}').doc('Method_info').get();
    int done = methodInfoDoc.data()?['done_today'] ?? 0;
    int curr = methodInfoDoc.data()?['curr_conf_num'] ?? 0;
    _curr_conf = curr;  

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int firstPressedTimestamp = prefs.getInt('firstPressedTime') ?? 0;
    _firstPressedTime = DateTime.fromMillisecondsSinceEpoch(firstPressedTimestamp);
    //_curr_conf = prefs.getInt('confirmations') ?? 0;
    
    if(done == 1 && mounted){
      setState(() {
        _isButtonDisabled = true;
        _done = true;
        _isLoading = false;
      });  
    }
    else{
      _confirmationTimes = [];
      for (int i = 0; i < _curr_conf; i++) {
        int timestamp = prefs.getInt('confirmationTime_$i') ?? 0;
        _confirmationTimes.add(DateTime.fromMillisecondsSinceEpoch(timestamp));
      }

      DateTime now = DateTime.now();
      if(_confirmationTimes.isNotEmpty) {
        DateTime lastConfirmationTime = _confirmationTimes.last;
        if (now.difference(lastConfirmationTime) > Duration(minutes: 2*widget.intervalTime) && mounted) {
          setState(() {
            intervalPassed = true;
            _restareted = true; 
            _afterInterval = false;
            editCurrConf(widget.habitName, 0);
            _confirmationTimes.clear();
            _curr_conf = 0;
            _isButtonDisabled = false;
            _done = false;
            _isLoading = false;
          });   
        }   
      }

      if (_curr_conf > 0) {
        if (_curr_conf < 3) {
          DateTime nextAllowedTime = _firstPressedTime.add(Duration(minutes: widget.intervalTime * _curr_conf));
          if (now.isBefore(nextAllowedTime) && mounted) {
            setState(() {
              _isButtonDisabled = true;
              _afterInterval = false;
              _isLoading = false;
              _done = false;
            });
          } else {
            if(mounted){
              setState(() {
                _afterInterval = true;
                _isButtonDisabled = false;
                _isLoading = false;
                _done = false;
              });
            }
          }
        } else {
          if(mounted){
            setState(() {
              _isButtonDisabled = true;
              _isLoading = false;
              _done = true;
              _confirmationTimes.clear(); 
            });
          }
        }
      } else {
        if(mounted){
          setState(() {
          _isButtonDisabled = false;
          prefs.setInt('confirmations', 0);
          _isLoading = false;
          _afterInterval = false;
          _done = false;
        });       
        }
      }
      _isLoading = false;
    }
  }

  void _setDailyReset() {
    _dailyResetTimer?.cancel();
    _dailyResetTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      DateTime now = DateTime.now();
      if (now.hour == 0 && now.minute == 0) {
        if(mounted) {
          setState(() {
            _isButtonDisabled = false;
            _done = false;
            editDoneToday(widget.habitName, 0);
            editCurrConf(widget.habitName, 0);
            _confirmationTimes.clear();
          });
        }
      }
    });
  }

  void _handleButtonPress() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseFirestore db = FirebaseFirestore.instance;
    final User? user = auth.currentUser;
    final userId = user?.uid;
    await fetchCurr();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    DateTime now = DateTime.now();

    if (_curr_conf > 0 && _confirmationTimes.isNotEmpty) {
      print('if 1');
      DateTime lastConfirmationTime = _confirmationTimes.last;
      if (now.difference(lastConfirmationTime) > Duration(minutes: 2*widget.intervalTime) && mounted) {
        print('if 2');
        setState(() {
          _afterInterval = false;
          intervalPassed = true;
          editCurrConf(widget.habitName, 0);
          _confirmationTimes.clear();
          _curr_conf = 0;
          _isButtonDisabled = false;
          _restareted = true;
        });
        prefs.setInt('confirmations', 0);
        return;
      }
    }

    if (_curr_conf == 0) {
      print('if 3\n${_curr_conf}');
      _firstPressedTime = now;
      prefs.setInt('firstPressedTime', _firstPressedTime.millisecondsSinceEpoch);
    }
    if(mounted){
      setState(() {
        _confirmationTimes.add(now);
        editCurrConf(widget.habitName, (_curr_conf + 1) % 4);
        prefs.setInt('confirmationTime_$_curr_conf', now.millisecondsSinceEpoch);
        _curr_conf = (_curr_conf + 1) % 4;
        intervalPassed = false;
        _afterInterval = true;
      });
    }


    if (_curr_conf < 3) {
      print('if 4\n${_curr_conf}');
      DateTime nextAllowedTime = _firstPressedTime.add(Duration(minutes: widget.intervalTime * _curr_conf));
      if(mounted){
        setState(() {
          _isButtonDisabled = true;
          _afterInterval = true;
        });
      }
    } else {
      if(mounted){
        setState(() {
          print('else 1');
          _isButtonDisabled = true;
          _done = true;
          _confirmationTimes.clear(); // Clear confirmation times when _curr_conf reaches 3
        });
      }

      await db.collection('Users').doc(userId).collection('Habit_${widget.habitName}').doc('Method_info').set({
        'streak': FieldValue.increment(1),
      }, SetOptions(merge: true)).then((_) async {
        var methodInfoDoc = await db.collection('Users').doc(userId).collection('Habit_${widget.habitName}').doc('Method_info').get();
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

        var goal = methodInfoDoc.data()?['week_goal'];
        var currentWeekCurr = methodInfoDoc.data()?['week_curr'] ?? 0;
        //var newWeekCurr = (currentWeekCurr + 1) % (goal + 1);
        var newWeekCurr = (currentWeekCurr != goal)?((currentWeekCurr + 1) % (goal+1)) : currentWeekCurr;

        db.collection('Users').doc(userId).collection('Habit_${widget.habitName}').doc('Method_info').set({
          'week_curr': newWeekCurr,
        }, SetOptions(merge: true));
        db.collection('Users').doc(userId).set({
          'points': FieldValue.increment(15),
        }, SetOptions(merge: true));
        db.collection('Users').doc(userId).collection('Habit_${widget.habitName}').doc('Method_info').set({
        'habit_points': FieldValue.increment(15),
        }, SetOptions(merge: true));        
      });
    }
  }

  Future<void> fetchCurr() async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      FirebaseFirestore db = FirebaseFirestore.instance;
      final User? user = auth.currentUser;
      final userId = user?.uid;
      var methodInfoDoc = await db.collection('Users').doc(userId).collection('Habit_${widget.habitName}').doc('Method_info').get();

      if (userId == null) {
        print("User ID is null");
        return;
      }

      final DocumentSnapshot<Map<String, dynamic>> docSnapshot = await db.collection('Users').doc(userId).get();

      if (!docSnapshot.exists) {
        print("Document does not exist");
        return;
      }

      final int fetchedCurr = methodInfoDoc.data()?['curr_conf_num'] ?? 0;
      print("Fetched points: $fetchedCurr");

      if (mounted) {
        setState(() {
          _curr_conf = fetchedCurr;
          _done = (fetchedCurr == 3) ? true : false;
          //_isButtonDisabled = (_done) ? true : false;
        });
      }
    } catch (e) {
      print("Error fetching curr: $e");
    }
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
            icon: CircleAvatar(
              backgroundColor: Colors.blue[800],
              radius: 20,
              child: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
                shadows: CustomTextShadow.shadows,
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: (!_isLoading) ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                (!_done)?SizedBox(
                width: 200,
                height: 70,
                child: AnimatedButton(
                  child: Text(
                    (!_isButtonDisabled)?((!intervalPassed || !_restareted)?((_afterInterval)?'Interval done, confirm again!' : 'I confirm doing the habit!' ): 'Start over!' ): 'Wait for the interval...',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      shadows: CustomTextShadow.shadows,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  onPressed: () async{
                    setState(() {
                      _isButtonDisabled = true;
                    });
                    final FirebaseAuth auth = FirebaseAuth.instance;
                    FirebaseFirestore db = FirebaseFirestore.instance;
                    final User? user = auth.currentUser;
                    final userId = user?.uid;
                    await db.collection('Users').doc(userId).collection('Habit_${widget.habitName}').doc('Reminder_info').set({
                      'm_min': DateTime.now().minute,
                      'm_hr': DateTime.now().hour
                    }, SetOptions(merge: true));
                    _handleButtonPress();
                    Future.delayed(Duration(minutes: widget.intervalTime, seconds: 3), () {
                      setState(() {
                        _isButtonDisabled = false;
                      });
                    });
                  },
                  enabled: (_isButtonDisabled) ? false : true,
                  color: Colors.blue[800] ?? Colors.blue,
                  shadowDegree: ShadowDegree.dark,
                ),
              ) : (_done) ? Container(
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
              ) : Container(),
              if (_isButtonDisabled)
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: (_curr_conf < 3) ? Text(
                    (_curr_conf == 1) ? 'Confirmed $_curr_conf time!' : 'Confirmed $_curr_conf times!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      shadows: CustomTextShadow.shadows,
                    ),
                  ) : Container(),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: (_isButtonDisabled) ? Text(
                  (_curr_conf < 3) ? 'Come back after the interval!' : 'Come back tomorrow to confirm again!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    shadows: CustomTextShadow.shadows,
                  ),
                ) : (_curr_conf < 3) ? Text(
                  (intervalPassed || _restareted) ? 'Interval passed! Start again!' :
                  (_curr_conf == 1) ? 'Confirmed $_curr_conf time!' : 'Confirmed $_curr_conf times!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    shadows: CustomTextShadow.shadows,
                  ),
                ) : Container(),
              ),
              SizedBox(height: 80),
              FutureBuilder<String>(
                future: getTextValue(), // Assuming getTextValue() returns a Future<String>
                builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator()); // Center loading indicator
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Press the button to confirm doing the habit!', style: TextStyle(color: Colors.white, fontSize: 18, shadows: CustomTextShadow.shadows),)); // Center error message
                  } else {
                    return Center( // Center the Text widget
                      child: Text(
                        snapshot.data!, // Use the data
                        style: TextStyle(color: Colors.white, fontSize: 18, shadows: CustomTextShadow.shadows),
                        textAlign: TextAlign.center, // Ensure text is centered if it spans multiple lines
                      ),
                    );
                  }
                },
              ),
              SizedBox(height: 80),
              Text(
                'Status of this habit:',
                style: TextStyle(color: Colors.white, fontSize: 18, shadows: CustomTextShadow.shadows),
              ),
              Image.asset(
                _done ? 'app_images/check.png' : 'app_images/X.png',
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ],
          ),
        ) : Center(child: CircularProgressIndicator(color: Colors.blue[800],)),
      ),
    );
  }

  Future<String> getTextValue() async {
    
    final FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseFirestore db = FirebaseFirestore.instance;
    final User? user = auth.currentUser;
    final userId = user?.uid;
    var ReminderInfoDoc = await db.collection('Users').doc(userId).collection('Habit_${widget.habitName}').doc('Reminder_info').get();
    _timeOfButtonPress = TimeOfDay(hour: ReminderInfoDoc.data()?['m_hr'], minute: ReminderInfoDoc.data()?['m_min']);
    var MethodInfoDoc = await db.collection('Users').doc(userId).collection('Habit_${widget.habitName}').doc('Method_info').get();
    int n_interval = widget.intervalTime;
    DateTime now = DateTime.now();
    int currentMinutes = now.hour * 60 + now.minute;
    int buttonPressMinutes = 0;
    buttonPressMinutes = _timeOfButtonPress!.hour * 60 + _timeOfButtonPress!.minute;
    int minutesLeft = 0;

    if (!_isButtonDisabled) {
      if (!intervalPassed || !_restareted) {
        if (_afterInterval) {
          // "Interval done, confirm again!" case
          minutesLeft = buttonPressMinutes + n_interval - currentMinutes;
          if(minutesLeft == 0) return "Almost there!";
          return "Interval done at ${_timeOfButtonPress!.hour}:${_timeOfButtonPress!.minute + n_interval % 60},\n confirm again before ${_timeOfButtonPress!.hour}:${(_timeOfButtonPress!.minute + 2 * n_interval) % 60}!\n You have $minutesLeft minutes left.";
        } else {
          // "I confirm doing the habit!" case
          return "Press the button to confirm doing the habit!";
        }
      } else {
        // "Start over!" case
        return "You have not confirmed for the last $n_interval minutes, start over!";
      }
    } else {
      // "Wait for the interval..." case
      minutesLeft = buttonPressMinutes + n_interval - currentMinutes;
      if(MethodInfoDoc.data()?['curr_conf_num'] == 3){
        return "You have confirmed for today!";
      }
      if(minutesLeft == 0) return "Almost there!";
      return "You pressed the button at ${_timeOfButtonPress!.hour}:${_timeOfButtonPress!.minute},\n come back after the $n_interval minutes interval at ${_timeOfButtonPress!.hour}:${(_timeOfButtonPress!.minute + n_interval) % 60}.\n You have $minutesLeft minutes left.";
    }
  }
}
*/