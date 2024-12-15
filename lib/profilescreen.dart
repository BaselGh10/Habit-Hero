import 'package:flutter/material.dart';
import 'text_shdows.dart';
import 'shared_habits_friends.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'friends.dart';

class FriendProfileScreen extends StatelessWidget {
  final String username;
  final String photoUrl;
  final String rank;
  final int topStreak;
  final VoidCallback op;
  final String currQuote;
  FriendProfileScreen({
    required this.username,
    required this.photoUrl,
    required this.rank,
    required this.topStreak,
    required this.op,
    required this.currQuote
  });
  bool _isLoading = false;

     Future<String> getCurrQuote() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseFirestore db = FirebaseFirestore.instance;
    final User? user = auth.currentUser;
    final userId = user?.uid;
    String curr_quote = 'No Quote';

    try {
      DocumentSnapshot documentSnapshot =
          await db.collection('Users').doc(userId).get();
      curr_quote = documentSnapshot['curr_quote'];
      return curr_quote;
    } catch (e) {
      print('Error getting current quote: $e');
      return '';
    }
  }
  @override
  
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;
  String _currentUserId = "";

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Tooltip(
            message: 'Dialog title',
            child: Text(
              'Confirm Deletion',
              style: TextStyle(color: Colors.black),
            ),
          ),
          content: Tooltip(
            message: 'Dialog content',
            child: Text(
              'Are you sure you want to delete this friend?',
              style: TextStyle(color: Colors.black),
            ),
          ),
          actions: [
            Tooltip(
              message: 'Cancel the action',
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
            Tooltip(
              message: 'Confirm the deletion',
              child: TextButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.red),
                ),
                onPressed: () {
                  op();
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('app_images/app_wallpaper.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue[800],
          centerTitle: true,
        ),
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                ),
                painter: headCurved(),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 80.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: Tooltip(
                        message: 'Username',
                        child: Text(
                          username,
                          style: TextStyle(
                            shadows: CustomTextShadow.shadows,
                            fontSize: 40,
                            letterSpacing: 1.5,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    Tooltip(
                      message: 'Profile picture',
                      child: Container(
                        padding: EdgeInsets.all(10.0),
                        width: MediaQuery.of(context).size.width / 2,
                        height: MediaQuery.of(context).size.width / 2,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _getRankColor(rank),
                            width: 15,
                          ),
                          shape: BoxShape.rectangle,
                          color: Colors.white,
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            image: NetworkImage(photoUrl),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Tooltip(
                            message: 'Top streak label',
                            child: Text(
                              'Top Streak: ',
                              style: TextStyle(
                                fontSize: 40,
                                color: Colors.white,
                                shadows: CustomTextShadow.shadows,
                              ),
                            ),
                          ),
                          Tooltip(
                            message: 'Top streak value',
                            child: Text(
                              '$topStreak',
                              style: TextStyle(
                                fontSize: 40,
                                color: Colors.white,
                                shadows: CustomTextShadow.shadows,
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Tooltip(
                            message: 'Streak icon',
                            child: Image.asset('app_images/fire_icon.png',
                                width: 50, height: 50),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: currQuote != 'No Quote'
                            ? Tooltip(
                                message: 'Current quote',
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: (rank == 'bronze')
                                        ? Color.fromARGB(187, 145, 100, 2)
                                        : (rank == 'silver')
                                            ? Color.fromARGB(181, 210, 210, 210)
                                            : (rank == 'gold')
                                                ? Color.fromARGB(188, 255, 217, 0)
                                                : (rank == 'diamond')
                                                    ? Color.fromARGB(
                                                        179, 0, 191, 255)
                                                    : const Color.fromARGB(
                                                        179, 0, 0, 0),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      (currQuote == "No Quote")
                                          ? 'No Quote'
                                          : currQuote,
                                      style: TextStyle(
                                          shadows: CustomTextShadow.shadows,
                                          fontSize: 18,
                                          letterSpacing: 1.5,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                ),
                              )
                            : SizedBox(height: 0, width: 0),
                      ),
                    ),
                    SizedBox(height: 15),
                    StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                        return (_isLoading)
                            ? Tooltip(
                                message: 'Loading indicator',
                                child: CircularProgressIndicator(
                                    color: Colors.white),
                              )
                            : Tooltip(
                                message: 'View shared habits',
                                child: ElevatedButton(
                                  onPressed: () async {
                                    setState(() {
                                      _isLoading = true;
                                    });
                                    await showSharedHabitsDialog(
                                        context, username);
                                    setState(() {
                                      _isLoading = false;
                                    });
                                  },
                                  child: Text(
                                    'Shared Habits',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                      shadows: CustomTextShadow.shadows,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[800],
                                  ),
                                ),
                              );
                      },
                    ),
                    SizedBox(height: 15),
                    Tooltip(
                      message: 'Remove friend',
                      child: ElevatedButton(
                        onPressed: () {
                          _showDeleteConfirmationDialog(context);
                        },
                        child: Text(
                          'Remove Friend',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            shadows: CustomTextShadow.shadows,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRankColor(String rank) {
    switch (rank) {
      case 'bronze':
        return Color.fromARGB(255, 145, 100, 2);
      case 'silver':
        return Color.fromARGB(255, 210, 210, 210);
      case 'gold':
        return Color.fromARGB(255, 255, 215, 0);
      case 'diamond':
        return Color.fromARGB(255, 0, 191, 255);
      default:
        return Colors.black;
    }
  }
}

class headCurved extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = const Color.fromRGBO(21, 101, 192, 1);
    Path path = Path()
      ..relativeLineTo(0, 150)
      ..quadraticBezierTo(size.width / 2, 225, size.width, 150)
      ..relativeLineTo(0, -150)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
