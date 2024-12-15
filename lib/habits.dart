import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:habit_hero/cards.dart';
import 'package:bubble_tab_indicator/bubble_tab_indicator.dart';
import 'package:habit_hero/text_shdows.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'shared_cards.dart';
import 'chell/challengeList.dart';

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key});

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}


class _HabitsPageState extends State<HabitsPage> {

  int topStreak = 0; 
  @override
  void initState() {
    super.initState();
    fetchTopStreak();
  }

Future<void> fetchTopStreak() async {

  try {
    final FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseFirestore db = FirebaseFirestore.instance;
    final User? user = auth.currentUser;
    final userId = user?.uid;

    if (userId == null) {
      print("User ID is null");
      return;
    }

    final DocumentSnapshot<Map<String, dynamic>> docSnapshot = await db.collection('Users').doc(userId).get();

    if (!docSnapshot.exists) {
      print("Document does not exist");
      return;
    }

    final int fetchedStreak = docSnapshot.data()?['top_streak'] ?? 0;
    print("Fetched streak: $fetchedStreak");

    if (mounted) {
      setState(() {
        topStreak = fetchedStreak;
      });
    }
  } catch (e) {
    print("Error fetching top streak: $e");
  }
}


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Number of tabs
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.blue[800],
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center, // Center row items horizontally
            children: <Widget>[
              Tooltip(
                message: 'Top Streak Label',
                child: const Text(
                  'Top Streak:',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Sriracha',
                    fontSize: 30,
                    shadows: CustomTextShadow.shadows,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Tooltip(
                message: 'Top Streak Value',
                child: Text(
                  '${topStreak}', // Example number, replace with your dynamic value
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    shadows: CustomTextShadow.shadows,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Tooltip(
                message: 'Fire Icon',
                child: Image.asset('app_images/fire_icon.png', width: 40, height: 40),
              ),
              const SizedBox(width: 10), // Provides spacing between the icon and the text
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
              fontSize: 15,
              color: Colors.white, // Example color
            ),
            tabs: [
              Tooltip(
                message: 'My Habits Tab',
                child: Tab(
                  child: Text(
                    'My Habits',
                    style: TextStyle(fontSize: 15, shadows: CustomTextShadow.shadows), // Specify your desired font size here
                  ),
                ),
              ),
              Tooltip(
                message: 'Shared Habits Tab',
                child: Tab(
                  child: Text(
                    'Shared Habits',
                    style: TextStyle(fontSize: 15, shadows: CustomTextShadow.shadows), // Specify your desired font size here
                  ),
                ),
              ),
              Tooltip(
                message: 'Challenges Tab',
                child: Tab(
                  child: Text(
                    'Challenges',
                    style: TextStyle(fontSize: 15, shadows: CustomTextShadow.shadows), // Specify your desired font size here
                  ),
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            CardsList(),
            CardsList_shared(),
            ChallengesList(),
          ],
        ),
      ),
    );
  }
}
