import 'package:flutter/material.dart';
import 'package:habit_hero/text_shdows.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addQuote(String userId, String newQuote) async {
    DocumentReference userDoc = _db.collection('Users').doc(userId);

    return _db.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(userDoc);

      if (!snapshot.exists) {
        throw Exception("User document does not exist!");
      }

      List<dynamic> currentQuotes = (snapshot.data() as Map<String, dynamic>)['quotes']?.cast<dynamic>() ?? [];
      if (!currentQuotes.contains(newQuote)) {
        currentQuotes.add(newQuote);
        transaction.update(userDoc, {'quotes': currentQuotes});
      }
    });
  }

  Future<void> removeQuote(String userId, String quoteToRemove) async {
    DocumentReference userDoc = _db.collection('Users').doc(userId);

    return _db.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(userDoc);

      if (!snapshot.exists) {
        throw Exception("User document does not exist!");
      }

      List<dynamic> currentQuotes = (snapshot.data() as Map<String, dynamic>)['quotes']?.cast<dynamic>() ?? [];
      if (currentQuotes.contains(quoteToRemove)) {
        currentQuotes.remove(quoteToRemove);
        transaction.update(userDoc, {'quotes': currentQuotes});
      }
    });
  }

  Future<List<String>> getQuotes(String userId) async {
    DocumentReference userDoc = _db.collection('Users').doc(userId);

    DocumentSnapshot snapshot = await userDoc.get();
    List<dynamic> quotes = (snapshot.data() as Map<String, dynamic>?)?['quotes']?.cast<dynamic>() ?? [];
    return quotes.cast<String>(); // Cast to List<String> before returning
  }

}

class QuotesPage extends StatefulWidget {
  final Function onUpdate;
  const QuotesPage({Key? key, required this.onUpdate}) : super(key: key);

  @override
  _QuotesPageState createState() => _QuotesPageState();
}

class _QuotesPageState extends State<QuotesPage> {
  bool _isLoading = true;
  final FirestoreService firestoreService = FirestoreService();
  final List<Map<String, dynamic>> quotes = [
    {
      "quote": 'No Quote',
      "author": '',
      "price": 0,
    },
    {
      "quote": "The greatest glory in living lies not in never falling, but in rising every time we fall.",
      "author": "Nelson Mandela",
      "price": 500,
    },
    {
      "quote": "The way to get started is to quit talking and begin doing.",
      "author": "Walt Disney",
      "price": 500,
    },
    {
      "quote": "Your time is limited, don't waste it living someone else's life.",
      "author": "Steve Jobs",
      "price": 500,
    },
    {
      "quote": "If life were predictable it would cease to be life, and be without flavor.",
      "author": "Eleanor Roosevelt",
      "price": 700,
    },
    {
      "quote": "If you look at what you have in life, you'll always have more. If you look at what you don't have in life, you'll never have enough.",
      "author": "Oprah Winfrey",
      "price": 700,
    },
    {
      "quote": "It isn't the mountains ahead to climb that wear you out, it's the pebble in your shoe.",
      "author": "Muhammad Ali",
      "price": 1000,
    },
    {
      "quote": "There is no substitute for hard work.",
      "author": "Thomas Edison",
      "price": 800,
    },

    {
      "quote": "Success isn't always about greatness. It's about consistency. Consistent hard work leads to success.",
      "author": "Dwayne \"The Rock\" Johnson",
      "price": 1000,
    },

    {
      "quote": "Without a struggle, there can be no progress.",
      "author": "Frederick Douglass",
      "price": 900,
    },

    {
      "quote": "Work to become, not to acquire.",
      "author": "Elbert Hubbard",
      "price": 750,
    },
    {
      "quote": "There is no elevator to success; you have to take the stairs.",
      "author": "Zig Ziglar",
      "price": 900,
    },
  ];

  // make sure size of the two arrays is same as number of quotes
  List<bool> purchasedStatus = [true,false, false, false, false, false,false,false,false,false,false,false]; // Initial purchased status for each quote
  List<bool> equippedStatus = [false,false, false, false, false, false,false,false,false,false,false,false]; // Initial equipped status for each quote

  @override
  void initState() {
    super.initState();
    fetchPurchasedQuotes();
  }

    Future<String> getCurr() async {
    
      final FirebaseAuth auth = FirebaseAuth.instance;
      FirebaseFirestore db = FirebaseFirestore.instance;
      final User? user = auth.currentUser;
      final userId = user?.uid;
      var theDoc = await db.collection('Users').doc(userId).get();
      String currQuote = theDoc.data()?['curr_quote'] ?? '';
      return currQuote;// Cast to List<String> before returning
    }

  Future<void> fetchPurchasedQuotes() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;
    final userId = user?.uid;
    String curr = await getCurr();

    if (userId != null) {
      List<String> purchasedQuotes = await firestoreService.getQuotes(userId);
      if(mounted){
      setState(() {
        if(curr == 'No Quote' || curr == '') {
          equippedStatus[0] = true;
        }
        for (int i = 1; i < quotes.length; i++) {
          purchasedStatus[i] = purchasedQuotes.contains(quotes[i]['quote']);
          equippedStatus[i] = (quotes[i]['quote'] == curr);
        }
        _isLoading = false;
      });
      }

    }
  }

  Future<bool> updateQuote(BuildContext context, String newQuote, int price, int index) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;
    final userId = user?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not found.')),
      );
      return false;
    }

    var userDoc = await FirebaseFirestore.instance.collection('Users').doc(userId).get();
    int currentPoints = userDoc.data()?['points'] ?? 0;

    if (currentPoints >= price) {
      await FirebaseFirestore.instance.collection('Users').doc(userId).update({
        'curr_quote': newQuote,
        'points': FieldValue.increment(-price),
      });
      await firestoreService.addQuote(userId, newQuote);
      if(mounted){
      setState(() {
        purchasedStatus[index] = true; // Mark the quote as purchased
      });
      }

      widget.onUpdate(); // Call the callback function after updating the state
      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You do not have enough points to make the purchase.')),
      );
      return false;
    }
  }

  Future<bool> buyQuote(BuildContext context, String newQuote, int price, int index) async {
    bool isBuying = false;
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder( // Use StatefulBuilder to manage local state
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white, // Set the background color of the AlertDialog
              // shape: RoundedRectangleBorder(
              //   borderRadius: BorderRadius.circular(5),
              // ),
              contentPadding: EdgeInsets.all(30.0),
              title: Tooltip(
                message: 'Dialog Title',
                child: Text(
                  'Buy Quote',
                  style: TextStyle(color: Colors.black), // Set the title text color to white
                ),
              ),
              content: Tooltip(
                message: 'Dialog Content',
                child: Text(
                  'Are you sure you want to buy this quote with $price points?',
                  style: TextStyle(color: Colors.black), // Set the content text color to white
                ),
              ),
              actions: <Widget>[
                Tooltip(
                  message: 'Cancel the action',
                  child: TextButton(
                    child: Text('No'),
                    onPressed: () {
                      Navigator.of(context).pop(false); // Pop the dialog and return false
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all<Color>(Colors.white),
                      foregroundColor: WidgetStateProperty.all<Color>(Colors.black),
                      // shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      //   RoundedRectangleBorder(
                      //     borderRadius: BorderRadius.circular(5),
                      //   ),
                      // ),
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Confirm the action',
                  child: TextButton(
                    child: Text('Yes'),
                    onPressed: isBuying ? null : () async { // Disable button if isBuying is true
                      if (mounted) setState(() => isBuying = true); // Update local state to disable the button
                      bool is_updated = await updateQuote(context, newQuote, price, index);
                      if (is_updated) Navigator.of(context).pop(true); // Pop the dialog and return true
                      else {
                        Navigator.of(context).pop(false);
                      }
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all<Color>(Colors.blue.shade800),
                      foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
                      // shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      //   RoundedRectangleBorder(
                      //     borderRadius: BorderRadius.circular(5),
                      //   ),
                      // ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    return result ?? false; // Return false if dialog is dismissed without selecting Yes/No
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
      body: ListView.builder(
        itemCount: quotes.length,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: purchasedStatus[index]
                ? () {
                    if (mounted) {
                      setState(() {
                        for (int i = 0; i < equippedStatus.length; i++) {
                          equippedStatus[i] = false;
                        }
                        equippedStatus[index] = true;
                        FirebaseFirestore.instance.collection('Users').doc(FirebaseAuth.instance.currentUser!.uid).update({
                          'curr_quote': quotes[index]['quote'],
                        });
                        fetchPurchasedQuotes();
                      });
                    }
                  }
                : () async {
                    // Handle tap
                    String currTap = quotes[index]['quote'];
                    print('Tapped on $currTap');
                    bool bought = await buyQuote(context, currTap, quotes[index]['price'], index);
                    if (bought) {
                      for (int i = 0; i < equippedStatus.length; i++) {
                        equippedStatus[i] = false;
                      }
                      equippedStatus[index] = true;
                      FirebaseFirestore.instance.collection('Users').doc(FirebaseAuth.instance.currentUser!.uid).update({
                        'curr_quote': quotes[index]['quote'],
                      });
                    }

                    someFunctionThatUpdatesState(); // Call the function to update the state
                  },
            child: Tooltip(
              message: purchasedStatus[index] ? 'Tap to equip this quote' : 'Tap to buy this quote',
              child: Card(
                color: equippedStatus[index]
                    ? Color.fromARGB(197, 97, 97, 97)
                    : purchasedStatus[index]
                        ? Color.fromARGB(191, 158, 158, 158)
                        : Color.fromARGB(199, 21, 101, 192),
                margin: EdgeInsets.all(10.0),
                child: Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Tooltip(
                        message: 'Quote text',
                        child: Text(
                          quotes[index]['quote']!,
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 229, 227, 227),
                            shadows: CustomTextShadow.shadows,
                          ),
                        ),
                      ),
                      SizedBox(height: 5.0),
                      Tooltip(
                        message: 'Author of the quote',
                        child: Text(
                          (quotes[index]['quote'] == 'No Quote') ? '' : "- ${quotes[index]['author']}",
                          style: TextStyle(
                            fontSize: 16.0,
                            fontStyle: FontStyle.italic,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      SizedBox(height: 10.0),
                      Tooltip(
                        message: equippedStatus[index]
                            ? 'This quote is chosen for your profile page'
                            : purchasedStatus[index]
                                ? 'You own this quote'
                                : 'Price of the quote in points',
                        child: Text(
                          equippedStatus[index]
                              ? 'Chosen to profile page!'
                              : purchasedStatus[index]
                                  ? 'Owned!'
                                  : "Price: ${quotes[index]['price']} points",
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Color.fromARGB(255, 216, 206, 21),
                            shadows: CustomTextShadow.shadows,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ):Center(child: CircularProgressIndicator(color: Colors.blue[800],));
  }
}
