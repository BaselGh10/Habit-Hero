import 'package:flutter/material.dart';
import 'package:habit_hero/text_shdows.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BordersStore extends StatefulWidget {
  final Function onUpdate;

  const BordersStore({Key? key, required this.onUpdate}) : super(key: key);
  @override
  State<BordersStore> createState() => _BordersStoreState();
}

class _BordersStoreState extends State<BordersStore> {
  String _rank = '';
  bool _isLoading = true;

  final List<Map<String, dynamic>> items = [

    {
      'text': 'Bronze Rank',
      'price': '250 points'
    },
    {
      'text': 'Silver Rank',
      'price': '500 points'
    },
    {
      'text': 'Gold Rank',
      'price': '1000 points'
    },
    {
      'text': 'Diamond Rank',
      'price': '2000 points'
    },
  ];

  Future<void> getRank() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseFirestore db = FirebaseFirestore.instance;
    final User? user = auth.currentUser;
    final userId = user?.uid;
    var userDoc = await db.collection('Users').doc(userId).get();
    String rank = userDoc.data()?['rank'] ?? '';
    _rank = rank;
    if(mounted){
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getRank();
  }

  void someFunctionThatUpdatesState() {
    if(mounted){
      setState(() {
        // Your state update logic here
      });
    }
    widget.onUpdate(); // Call the callback function after updating the state
  }

  @override
  Widget build(BuildContext context) {

    return (!_isLoading)?Scaffold(
      backgroundColor: Colors.transparent,
      body: GridView.builder(
        padding: EdgeInsets.all(8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Adjust number of columns
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          String color_text = items[index]['text'];

          return GestureDetector(
            onTap: () async {
              // Handle tap
              String curr_tap = items[index]['text'];
              print('Tapped on $curr_tap');
              if (_rank == 'black' && curr_tap == 'Bronze Rank') {
                await buyBorder(context, curr_tap, 250, 'bronze');
                if (mounted) {
                  setState(() {
                    if (getRank() == 'bronze') {
                      _rank = 'bronze';
                    }
                  });
                }

                someFunctionThatUpdatesState();
                return;
              }
              if (_rank == 'bronze' && curr_tap == 'Silver Rank') {
                await buyBorder(context, curr_tap, 500, 'silver');
                if (mounted) {
                  setState(() {
                    if (getRank() == 'silver') {
                      _rank = 'silver';
                    }
                  });
                }

                someFunctionThatUpdatesState();
                return;
              }
              if (_rank == 'silver' && curr_tap == 'Gold Rank') {
                await buyBorder(context, curr_tap, 1000, 'gold');
                if (mounted) {
                  setState(() {
                    if (getRank() == 'gold') {
                      _rank = 'gold';
                    }
                  });
                }

                someFunctionThatUpdatesState();
                return;
              }
              if (_rank == 'gold' && curr_tap == 'Diamond Rank') {
                await buyBorder(context, curr_tap, 2000, 'diamond');
                if (mounted) {
                  setState(() {
                    if (getRank() == 'diamond') {
                      _rank = 'diamond';
                    }
                  });
                }
                someFunctionThatUpdatesState();
                return;
              }

              if (_rank == 'diamond' ||
                  (_rank == 'gold' && curr_tap != 'Diamond Rank') ||
                  (_rank == 'silver' &&
                      curr_tap != 'Diamond Rank' &&
                      curr_tap != 'Gold Rank') ||
                  (_rank == 'bronze' && curr_tap == 'Bronze Rank')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('You already purchased this border!'),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'You need to buy the previous ranks to buy the $curr_tap!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Tooltip(
              message: 'Border Card',
              child: Container(
                decoration: BoxDecoration(
                  color: (_rank == 'bronze' && color_text == 'Bronze Rank')
                      ? Color.fromARGB(168, 136, 136, 136)
                      : (_rank == 'silver' &&
                              (color_text == 'Silver Rank' ||
                                  color_text == 'Bronze Rank'))
                          ? Color.fromARGB(168, 136, 136, 136)
                          : (_rank == 'gold' &&
                                  (color_text == 'Gold Rank' ||
                                      color_text == 'Silver Rank' ||
                                      color_text == 'Bronze Rank'))
                              ? Color.fromARGB(168, 136, 136, 136)
                              : (_rank == 'diamond' &&
                                      (color_text == 'Diamond Rank' ||
                                          color_text == 'Gold Rank' ||
                                          color_text == 'Silver Rank' ||
                                          color_text == 'Bronze Rank'))
                                  ? Color.fromARGB(168, 136, 136, 136)
                                  : Color.fromARGB(199, 21, 101, 192),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.5),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Tooltip(
                      message: 'Rank Text',
                      child: Text(
                        items[index]['text'],
                        style: TextStyle(
                          color: (color_text == 'Bronze Rank')
                              ? Color.fromARGB(255, 145, 100, 2)
                              : (color_text == 'Silver Rank')
                                  ? Color.fromARGB(255, 210, 210, 210)
                                  : (color_text == 'Gold Rank')
                                      ? Color.fromARGB(255, 255, 215, 0)
                                      : Color.fromARGB(255, 0, 191, 255),
                          fontSize: 26,
                          shadows: CustomTextShadow.shadows,
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    Tooltip(
                      message: 'Price or Status Text',
                      child: Text(
                        (_rank == 'bronze' && color_text == 'Bronze Rank')
                            ? 'Already Reached!'
                            : (_rank == 'silver' &&
                                    (color_text == 'Silver Rank' ||
                                        color_text == 'Bronze Rank'))
                                ? 'Already Reached!'
                                : (_rank == 'gold' &&
                                        (color_text == 'Gold Rank' ||
                                            color_text == 'Silver Rank' ||
                                            color_text == 'Bronze Rank'))
                                    ? 'Already Reached!'
                                    : (_rank == 'diamond' &&
                                            (color_text == 'Diamond Rank' ||
                                                color_text == 'Gold Rank' ||
                                                color_text == 'Silver Rank' ||
                                                color_text == 'Bronze Rank'))
                                        ? 'Already Reached!'
                                        : items[index]['price'],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          shadows: CustomTextShadow.shadows,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ):Center(child: CircularProgressIndicator(color: Colors.blue[800],));
  }
}


Future<bool> buyBorder(BuildContext context, String rank, int price, String new_rank) async {
  bool isBuying = false;
  final result = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder( // Use StatefulBuilder to manage local state
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white, // Set the background color of the AlertDialog
            contentPadding: EdgeInsets.all(30.0),
            title: Tooltip(
              message: 'Dialog Title',
              child: Text(
                'Buy Rank',
                style: TextStyle(color: Colors.black), // Set the title text color to black
              ),
            ),
            content: Tooltip(
              message: 'Dialog Content',
              child: Text(
                'Are you sure you want to buy the $rank with $price points?',
                style: TextStyle(color: Colors.black), // Set the content text color to black
              ),
            ),
            actions: <Widget>[
              Tooltip(
                message: 'No Button',
                child: TextButton(
                  child: Text('No'),
                  onPressed: () {
                    Navigator.of(context).pop(false); // Pop the dialog and return false
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all<Color>(Colors.white),
                    foregroundColor: WidgetStateProperty.all<Color>(Colors.black),
                  ),
                ),
              ),
              Tooltip(
                message: 'Yes Button',
                child: TextButton(
                  child: Text('Yes'),
                  onPressed: isBuying ? null : () async { // Disable button if isBuying is true
                    setState(() => isBuying = true); // Update local state to disable the button
                    await updateRankAndPoints(context, new_rank, price);
                    Navigator.of(context).pop(true); // Pop the dialog and return true
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all<Color>(Colors.blue.shade800),
                    foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
                  ),
                ),
              ),
            ],
          );
        }
      );
    },
  );
  return result ?? false; // Return false if dialog is dismissed without selecting Yes/No
}

Future<void> updateRankAndPoints(BuildContext context, String newRank, int price) async {
  final FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore db = FirebaseFirestore.instance;
  final User? user = auth.currentUser;
  final userId = user?.uid;

  if (userId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User not found.')),
    );
    return;
  }

  var userDoc = await db.collection('Users').doc(userId).get();
  int currentPoints = userDoc.data()?['points'] ?? 0;

  if (currentPoints >= price) {
    await db.collection('Users').doc(userId).update({
      'rank': newRank,
      'points': FieldValue.increment(-price),
    });
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('You do not have enough points to make the purchase.')),
    );
  }
}