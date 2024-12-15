import 'package:flutter/material.dart';
import 'package:bubble_tab_indicator/bubble_tab_indicator.dart';
import 'package:habit_hero/chell/add_challenge.dart';
import 'package:habit_hero/habit_page.dart';
import 'package:habit_hero/habit_reminders.dart';
import 'challange.dart'; // Ensure this import is correct
import '/text_shdows.dart'; 
import 'challenge_freinds.dart';
import 'package:habit_hero/habit_page.dart';// Import the custom text shadows
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Challengepage extends StatelessWidget {
final String challengeId;
  final String challengeName;
  final String habitId;
  final int points;
  final String status;
  final List<String> friends;
@override


   Challengepage({
    Key? key,
   required this.challengeId,
    required this.challengeName,
    required this.habitId,
    required this.points,
    required this.status,
    required this.friends,
  
  }) : super(key: key) {
      getChallengeAndSearchUser();
  }
  String habitName = '';
  String habitDescription = '';
  String habitMethod = '';
  int timerValue = 1;
  int intervalTime = 1;
  int numConfirmations = 0;
  int habitPoints = 0;
  Future<void> getChallengeAndSearchUser() async {
    try {
      // Get the challenge from Firestore
      DocumentSnapshot challengeSnapshot = await FirebaseFirestore.instance
          .collection('challenges')
          .doc(challengeId)
          .get();
     String ? currentuser = FirebaseAuth.instance.currentUser!.uid;
      // Get the user collection from Firestore
     var challengeSnapshot1 = await FirebaseFirestore.instance.collection('Users').doc(currentuser)
      .collection('challenge_$challengeName').get();
    
      if (challengeSnapshot1.docs.isNotEmpty) {
    
        // challengeName;
        habitDescription = challengeSnapshot1.docs[0]['description'];
        habitMethod = challengeSnapshot1.docs[0]['method'];
        timerValue = challengeSnapshot1.docs[1]['timer_val'];
        intervalTime = challengeSnapshot1.docs[1]['timer_val'];
       
      }
      
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
      getChallengeAndSearchUser();
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('app_images/app_wallpaper.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      
    child:  DefaultTabController(
      
      length: 2, // Number of tabs
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.blue[800],
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                "${challengeName } challenge", // Update the title as needed
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  shadows: CustomTextShadow.shadows,
                ),
              ),
              SizedBox(width: 55),
            ],
          ),
          bottom: const TabBar(
            indicatorSize: TabBarIndicatorSize.tab,
            unselectedLabelColor: Colors.white,
            indicator: BubbleTabIndicator(
              indicatorHeight: 25.0,
              indicatorColor: Colors.blueAccent,
              tabBarIndicatorSize: TabBarIndicatorSize.tab,
            ),
            labelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Sriracha',
              fontSize: 13, // Adjust font size as needed
              color: Colors.white,
            ),
            tabs: [
              Tab(
                child: Text(
                  'Challenges', // Updated tab title
                  style: TextStyle(
                    color: Colors.white, // Change text color
                    fontSize: 16, // Change font size
                    shadows: CustomTextShadow.shadows,
                  ),
                ),
              ),
              Tab(
                child: Text(
                  'Participents', // Updated tab title
                  style: TextStyle(
                    color: Colors.white, // Change text color
                    fontSize: 16, // Change font size
                    shadows: CustomTextShadow.shadows,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        body: TabBarView(
          children: [ 
           ChallangePage(habitName:challengeName),
            ChallengeFriends(
                challangeId: challengeId,habit_name:challengeName), // Pass friends list to ChallengeFriends
          ],
        ),
      ),
    ));
  }
}
