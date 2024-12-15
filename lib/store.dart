import 'package:flutter/material.dart';
import 'package:bubble_tab_indicator/bubble_tab_indicator.dart';
import 'package:habit_hero/quotes.dart';
import 'package:habit_hero/text_shdows.dart';
import 'borders.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {

  int points = 0;

  @override
  void initState() {
    super.initState();
    fetchPoints();
  }


  Future<void> fetchPoints() async {
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

      final int fetchedPoints = docSnapshot.data()?['points'] ?? 0;
      print("Fetched points: $fetchedPoints");

      if (mounted) {
        setState(() {
          points = fetchedPoints;
        });
      }
    } catch (e) {
      print("Error fetching points: $e");
    }
  }

  void updateStorePageState() async {
    await fetchPoints();
    print("Store page state updated");
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Number of tabs
      child: Scaffold(
        //backgroundColor: Colors.blueGrey[200],
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.blue[800],
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(width: 10),
              Tooltip(message: 'My Points:',  child: Text('My Points: ', style: TextStyle(color: Colors.white, fontSize: 30, shadows: CustomTextShadow.shadows))),
              Tooltip(message: '${points}', child: Text('${points}', style: TextStyle(color: Colors.yellow, fontSize: 30, shadows: CustomTextShadow.shadows))),
              SizedBox(width: 10),
            ],
          ),
          bottom: const TabBar(
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BubbleTabIndicator(
              indicatorHeight: 25.0,
              indicatorColor: Colors.blueAccent,
              tabBarIndicatorSize: TabBarIndicatorSize.tab,
            ),
            tabs: [
              Tab(
                child: Tooltip(
                  message: 'Borders',
                  child: Text(
                    'Borders',
                    style: TextStyle(fontSize: 20, color: Colors.white,shadows: CustomTextShadow.shadows,), // Specify your desired font size here
                  ),
                ),
              ),
              Tab(
                child: Tooltip(
                  message: 'Quotes',
                  child: Text(
                    'Quotes',
                    style: TextStyle(fontSize: 20, color: Colors.white, shadows: CustomTextShadow.shadows,), // Specify your desired font size here
                  ),
                ),
              ),
            ],          
        ),

      ),
        body: TabBarView(
          children: [
            BordersStore(onUpdate: updateStorePageState),
            //const Center(child: Text('Quotes store here', style: TextStyle(fontSize: 24))),
            QuotesPage(onUpdate: updateStorePageState),
          ],
        ),
    ),
    );
  }
}