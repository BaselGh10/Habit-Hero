import 'package:animated_button/animated_button.dart';
import 'package:flutter/material.dart';
import 'package:habit_hero/firebase_help_functions.dart';
import 'package:habit_hero/text_shdows.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Confirmation extends StatefulWidget {
  final String habitName;
  Confirmation({Key? key, required this.habitName});
  @override
  _ConfirmationState createState() => _ConfirmationState();
}

class _ConfirmationState extends State<Confirmation> {
  bool _isButtonDisabled = false;
  late DateTime _lastPressedTime;
  Duration _remainingTime = Duration(seconds: 10);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadButtonState();
  }

  void _loadButtonState() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseFirestore db = FirebaseFirestore.instance;
    final User? user = auth.currentUser;
    final userId = user?.uid; 
    var methodInfoDoc;
    var habitDoc = await db.collection('Users').doc(userId).collection('Habit_${widget.habitName}').doc('Method_info').get();
   var shareddoc= await db
        .collection('Users')
        .doc(userId)
        .collection('SharedHabit_${widget.habitName}')
        .doc('Method_info')
        .get();
        var challangedoc= await db
        .collection('Users')
        .doc(userId)
        .collection('challenge_${widget.habitName}')
        .doc('Method_info')
        .get();
    if (habitDoc.exists) {
      methodInfoDoc = habitDoc;
    } else {
      if(shareddoc.exists){
        methodInfoDoc = shareddoc;
      }
      else{
        methodInfoDoc = challangedoc;
      }
     
    }


    int done = methodInfoDoc.data()?['done_today'] ?? 0;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int lastPressedTimestamp = prefs.getInt('lastPressedTime') ?? 0;
    _lastPressedTime = DateTime.fromMillisecondsSinceEpoch(lastPressedTimestamp);

    DateTime now = DateTime.now();
    DateTime nextMidnight = DateTime(now.year, now.month, now.day + 1);

    DateTime previousMidnight = DateTime(now.year, now.month, now.day,0,0);

    if(done == 1){
      if(mounted){
        setState(() {
          _isButtonDisabled = true;
          _remainingTime = nextMidnight.difference(now);
          _isLoading = false;
        });
      }

    }

    // if (now.isBefore(nextMidnight) && now.isAfter(_lastPressedTime) && _lastPressedTime.isAfter(previousMidnight)) {
    //   setState(() {
    //     _isButtonDisabled = true;
    //     _remainingTime = nextMidnight.difference(now);
    //     //editDoneToday(widget.habitName, 1);
    //   });
    //   }
      else {
        if(mounted){
        setState(() {
          _isButtonDisabled = false;
          _isLoading = false;
        });
        }
     }
      _isLoading = false;
  }

  void _handleButtonPress() async {

    final FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseFirestore db = FirebaseFirestore.instance;
    final User? user = auth.currentUser;
    final userId = user?.uid; 
    var habitDoc = await db.collection('Users').doc(userId).collection('Habit_${widget.habitName}').doc('Method_info').get();
    var shareddoc= await db
        .collection('Users')
        .doc(userId)
        .collection('SharedHabit_${widget.habitName}')
        .doc('Method_info')
        .get();
        var challangedoc= await db
        .collection('Users')
        .doc(userId)
        .collection('challenge_${widget.habitName}')
        .doc('Method_info')
        .get();
    var methodInfoDoc;
    if (habitDoc.exists) {
      methodInfoDoc = habitDoc;
    } else {
      if(shareddoc.exists){
        methodInfoDoc = shareddoc;
      }
      else{
        methodInfoDoc = challangedoc;
      }
    }
    int done = methodInfoDoc.data()?['done_today'] ?? 0;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    _lastPressedTime = DateTime.now();
    prefs.setInt('lastPressedTime', _lastPressedTime.millisecondsSinceEpoch);

    DateTime now = DateTime.now();
    DateTime nextMidnight = DateTime(now.year, now.month, now.day + 1);

    if(done==0){
      if(mounted){
      setState(() {
        _isButtonDisabled = true;
        _remainingTime = nextMidnight.difference(now);
     });
      }

     var habitCollection = db.collection('Users').doc(userId).collection('Habit_${widget.habitName}');
          var sharedHabitCollection = db.collection('Users').doc(userId).collection('SharedHabit_${widget.habitName}');
var challengeCollection = db.collection('Users').doc(userId).collection('challenge_${widget.habitName}');
          var habitDoc = await habitCollection.doc('Method_info').get();
          var methodInfoDoc;
        var shareddoc=  await sharedHabitCollection.doc('Method_info').get();
          var challangedoc = await challengeCollection.doc('Method_info').get();
          if (habitDoc.exists) {
            methodInfoDoc = habitDoc;
          } else {
            if(shareddoc.exists){
              methodInfoDoc = await sharedHabitCollection.doc('Method_info').get();
            }
            else{
              methodInfoDoc = await challengeCollection.doc('Method_info').get();
            }
          
          }

          await methodInfoDoc.reference.set({
            'streak': FieldValue.increment(1),
          }, SetOptions(merge: true));

          // Retrieve the updated streak value
          var updatedMethodInfoDoc = await methodInfoDoc.reference.get();
          var currentStreak = updatedMethodInfoDoc.data()?['streak'];

          // Retrieve the top_streak value
          var userDoc = await db.collection('Users').doc(userId).get();
          var topStreak = userDoc.data()?['top_streak'];

          // Update top_streak if current streak is higher
          if (currentStreak > topStreak) {
            await db.collection('Users').doc(userId).set({
              'top_streak': currentStreak,
            }, SetOptions(merge: true));
          }

            var goal = methodInfoDoc.data()?['week_goal'];
            // Increment week_curr and wrap around after 7
            var currentWeekCurr = methodInfoDoc.data()?['week_curr'] ?? 0;
            var newWeekCurr = (currentWeekCurr != goal)?((currentWeekCurr + 1) % (goal+1)) : currentWeekCurr;
            //var newWeekCurr = (currentWeekCurr + 1) % (goal+1);

          await methodInfoDoc.reference.set({
            'week_curr': newWeekCurr,
          }, SetOptions(merge: true));

          await db.collection('Users').doc(userId).set({
            'points': FieldValue.increment(2),
          }, SetOptions(merge: true));

          await methodInfoDoc.reference.set({
            'habit_points': FieldValue.increment(2),
          }, SetOptions(merge: true));
     editDoneToday(widget.habitName, 1);
    }

  }

  @override
  Widget build(BuildContext context) {
    //DateTime _now = DateTime.now();
    //DateTime _nextMidnight = DateTime(_now.year, _now.month, _now.day + 1);

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
          leading: Tooltip(
            message: 'Back Button',
            child: IconButton(
              icon: CircleAvatar(
                backgroundColor: Colors.blue[800], // Background color of the circle
                radius: 20, // Size of the circle
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.white, // Icon color
                  size: 24, // Icon size
                  shadows: CustomTextShadow.shadows,
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
        body: (!_isLoading)
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    (!_isButtonDisabled)
                        ? SizedBox(
                            width: 200,
                            height: 70,
                            child: Tooltip(
                              message: 'Confirm Habit Button',
                              child: AnimatedButton(
                                onPressed: _handleButtonPress,
                                enabled: !_isButtonDisabled,
                                child: Text(
                                  'I confirm doing the habit!',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    shadows: CustomTextShadow.shadows,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                color: Colors.blue[800] ?? Colors.blue,
                              ),
                            ),
                          )
                        : Tooltip(
                            message: 'Confirmed Status',
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
                          ),
                    if (_isButtonDisabled)
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: Tooltip(
                          message: 'Come Back Tomorrow Message',
                          child: Text(
                            'Come back tomorrow to confirm again!',
                            style: TextStyle(
                              color: Colors.white,
                              shadows: CustomTextShadow.shadows,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    SizedBox(height: 160),
                    Tooltip(
                      message: 'Habit Status Label',
                      child: Text(
                        'Status of this habit:',
                        style: TextStyle(
                          color: Colors.white,
                          shadows: CustomTextShadow.shadows,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Tooltip(
                      message: 'Habit Status Image',
                      child: Image.asset(
                        _isButtonDisabled ? 'app_images/check.png' : 'app_images/X.png', // Path to your asset image
                        width: 100, // Optional: Set the width of the image
                        height: 100, // Optional: Set the height of the image
                        fit: BoxFit.cover, // Optional: Set how the image should be fit into the widget
                      ),
                    ),
                  ],
                ),
              )
            : Center(
                child: Tooltip(
                  message: 'Loading Indicator',
                  child: CircularProgressIndicator(color: Colors.blue[800]),
                ),
              ),
      ),
    );
  }
}
