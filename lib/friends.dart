import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_friends.dart';
import 'package:habit_hero/text_shdows.dart';
import 'profilescreen.dart';
import 'shared_habits_friends.dart';

class FriendsList extends StatefulWidget {
  @override
  _FriendsListState createState() => _FriendsListState();
}

class _FriendsListState extends State<FriendsList> {
  List<UserCard> friendsList = [];
   String currQuote = '';
   bool _isLoading=false;
  
  
  
  Future<String> getCurrQuote() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseFirestore db = FirebaseFirestore.instance;
    final User? user = auth.currentUser;
    final userId = user?.uid;
    String curr_quote = '';

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
   Future<void> fetchCurrQuote() async {
    String curr_new = await getCurrQuote();
    if (mounted) {
      setState(() {
        currQuote = curr_new;
        _isLoading = false;
      });
    }
  }
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;
  String _currentUserId = "";
  void _removeFriend(String friendId) async {
    DocumentReference<Map<String, dynamic>> userDoc =
        _firestore.collection('Users').doc(_currentUserId);

    DocumentSnapshot<Map<String, dynamic>> userSnapshot = await userDoc.get();

    if (userSnapshot.exists) {
      List<String> friends = List<String>.from(userSnapshot.data()!['friends']);

      if (friends.contains(friendId)) {
        friends.remove(friendId);

        await userDoc.update({'friends': friends});

        QuerySnapshot<Map<String, dynamic>> friendsSnapshot = await _firestore
            .collection('Users')
            .where("username", isEqualTo:  friendId)
            .get();
          String toremoveid = friendsSnapshot.docs[0].id;

        // Remove current user from the friend's friend list
        DocumentReference<Map<String, dynamic>> friendDoc =
            _firestore.collection('Users').doc(toremoveid);

        DocumentSnapshot<Map<String, dynamic>> friendSnapshot =
            await friendDoc.get();

        if (friendSnapshot.exists) {
          List<String> friendFriends =
              List<String>.from(friendSnapshot.data()!['friends']);

          friendFriends.remove(userSnapshot.data()!['username']);

          await friendDoc.update({'friends': friendFriends});
           // friendsList.removeWhere((friend) => friend.username == friendId);
          
        }
        if(mounted){
        setState(() {
          friendsList.removeWhere((friend) => friend.username == friendId);
          
        });
        }


        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Friend removed!')),
        );
      }
    }
  }
  @override
  void initState() {
    super.initState();
    _currentUserId = user!.uid;
    _fetchFriends();
     fetchCurrQuote();
    //_fetchFriendRequests();
  }

  void _fetchFriends() async {
    DocumentSnapshot<Map<String, dynamic>> userSnapshot =
        await _firestore.collection('Users').doc(_currentUserId).get();

    if (userSnapshot.exists) {
      List<String> friendsIds =
          List<String>.from(userSnapshot.data()!['friends']);

      if (friendsIds.isNotEmpty) {
        QuerySnapshot<Map<String, dynamic>> friendsSnapshot = await _firestore
            .collection('Users')
            .where("username", whereIn: friendsIds)
            .get();
if(mounted){
        setState(() {
          friendsList = friendsSnapshot.docs
              .map((friend) => UserCard(
                    username: friend.data()['username'],
                    photoUrl: friend.data()['imageurl'],
                    rank: friend.data()['rank'],
                    topstreak: friend.data()['top_streak'],
                    op: () => _removeFriend(friend.data()['username']),
                    removeoradd: false,
                    currQuote: friend.data()['curr_quote'],
                  ))
              .toList();
        });
      }
      }
    }
  }

   

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        title: Tooltip(
          message: 'Friends List Title',
          child: const Text(
            'Friends List',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              shadows: CustomTextShadow.shadows,
            ),
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: Tooltip(
        message: 'Add Friend Button',
        child: FloatingActionButton(
          backgroundColor: Colors.blue[800],
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddFriendScreen()),
            );
          },
          child: Icon(Icons.search),
          foregroundColor: Colors.white,
        ),
      ),
      body: Column(
        children: [
          // Display Friend Requests
          Expanded(
            child: ListView.builder(
              itemCount: friendsList.length,
              itemBuilder: (context, index) {
                return Tooltip(
                  message: 'Friend Item',
                  child: Container(
                    margin: const EdgeInsets.all(0),
                    child: friendsList[index],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


class UserCard extends StatelessWidget {
  final String username;
  final String photoUrl;
  final String rank;
  final int topstreak;
  final VoidCallback op;
  final bool removeoradd;
  final String currQuote;

  UserCard({
    required this.username,
    required this.photoUrl,
    required this.rank,
    required this.topstreak,
    required this.op,
    required this.removeoradd,
    required this.currQuote
  });

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.blue[800],
          title: Text(
            'Confirm Deletion',
            style: TextStyle(color: Colors.white),
          ),
          content: Tooltip(
            message: 'Delete Friend Confirmation',
            child: Text(
              'Are you sure you want to delete this friend?',
              style: TextStyle(color: Colors.white),
            ),
          ),
          actions: [
            Tooltip(
              message: 'Cancel button',
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            Tooltip(
              message: 'Delete button',
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  op();
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

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FriendProfileScreen(
          username: username,
          photoUrl: photoUrl,
          rank: rank,
          topStreak: topstreak,
          op: op,
          currQuote: currQuote,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool _isLoading = false;
    return GestureDetector(
      onTap: () => _navigateToProfile(context),
      child: Tooltip(
        message: 'Friend Card',
        child: Card(
          elevation: 4,
          color: Colors.blue[800],
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Tooltip(
                  message: 'Profile Picture',
                  child: Container(
                    width: 75,
                    height: 75,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (rank == 'bronze')
                            ? Color.fromARGB(255, 145, 100, 2)
                            : (rank == 'silver')
                                ? Color.fromARGB(255, 210, 210, 210)
                                : (rank == 'gold')
                                    ? Color.fromARGB(255, 255, 215, 0)
                                    : (rank == 'diamond')
                                        ? Color.fromARGB(255, 0, 191, 255)
                                        : Colors.black,
                        width: 4.5,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Tooltip(
                        message: 'Username',
                        child: Text(
                          username,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            shadows: CustomTextShadow.shadows,
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Tooltip(
                              message: 'Top Streak Label',
                              child: Text(
                                'Top Streak: ',
                                style: TextStyle(
                                  color: Colors.white,
                                  shadows: CustomTextShadow.shadows,
                                ),
                              ),
                            ),
                            Tooltip(
                              message: 'Top Streak Value',
                              child: Text(
                                '$topstreak',
                                style: TextStyle(
                                  color: Colors.white,
                                  shadows: CustomTextShadow.shadows,
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Tooltip(
                              message: 'Fire Icon',
                              child: Image.asset(
                                'app_images/fire_icon.png',
                                width: 20,
                                height: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}