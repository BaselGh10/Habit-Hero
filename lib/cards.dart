import 'package:flutter/material.dart';
import 'package:habit_hero/add_habit_page.dart';
import 'package:habit_hero/text_shdows.dart';
import 'private_list.dart';
import 'firebase_help_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'fix_daily_confirm.dart';

class CardsList extends StatefulWidget {
  @override
  _CardsListState createState() => _CardsListState();
}

class _CardsListState extends State<CardsList> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initHabits();
  }

  Future<void> _initHabits() async {
    await manageHabits(); // Ensure manageHabits is called on widget initialization
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = auth.currentUser;
    final userId = user?.uid;
    FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Tooltip(
        message: 'Add Habit Button',
        child: FloatingActionButton(
          backgroundColor: Colors.blue[800],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          onPressed: () async {
            await pushAddHabitPage(context);
            await manageHabits();
            if (mounted) {
              setState(() {
                print("Add habit button pressed");
              });
            }
          },
          child: Icon(Icons.add, size: 30),
          foregroundColor: Colors.white,
        ),
      ),
      body: _isLoading
          ? Center(
              child: Tooltip(
                message: 'Loading Indicator',
                child: CircularProgressIndicator(color: Colors.blue[800]),
              ),
            )
          : FutureBuilder<List<String>>(
              future: firestoreService.getHabitNames(userId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Tooltip(
                      message: 'Loading Indicator',
                      child: CircularProgressIndicator(color: Colors.blue[800]),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Tooltip(
                      message: 'Error Message',
                      child: Text("Error fetching data"),
                    ),
                  );
                } else if (snapshot.hasData) {
                  return Tooltip(
                    message: 'Habit List',
                    child: StringListViewWidget(stringList: snapshot.data!),
                  );
                } else {
                  return Center(
                    child: Tooltip(
                      message: 'No Data Message',
                      child: Text("No data found"),
                    ),
                  );
                }
              },
            ),
    );
  }
}