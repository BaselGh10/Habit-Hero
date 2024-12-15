import 'package:flutter/material.dart';
import 'package:habit_hero/add_habit_page.dart';
import 'shared_list.dart';
import 'firebase_help_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'fix_daily_confirm.dart';

class CardsList_shared extends StatefulWidget {
  @override
  _CardsList_sharedState createState() => _CardsList_sharedState();
}

class _CardsList_sharedState extends State<CardsList_shared> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initHabits();
  }

  Future<void> _initHabits() async {
    await manageHabits(); // Ensure manageHabits is called on widget initialization
    if(mounted){
      setState(() {
        _isLoading = false;
      });
    }
    // setState(() {
    //   _isLoading = false;
    // });
  }

  @override
  Widget build(BuildContext context) {
    final User? user = auth.currentUser;
    final userId = user?.uid;
    FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue[800],
        onPressed: () async{
          await pushAddHabitPage(context);
          await manageHabits();
          if(mounted){
            setState(() {
              print("Add habit button pressed");
            });
          }
        },
        child: Tooltip(
          message: 'Add a new habit',
          child: Icon(Icons.add),
        ),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
      ? Center(child: CircularProgressIndicator(color: Colors.blue[800]))
      :  FutureBuilder<List<String>>(
        future: firestoreService.getHabitNames(userId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Colors.blue[800],));
          } else if (snapshot.hasError) {
            return Center(child: Text("Error fetching data"));
          } else if (snapshot.hasData) {
            return StringListViewWidget_shared(stringList: snapshot.data!);
          } else {
            return Center(child: Text("No data found"));
          }
        },
      ),
    );
  }
}