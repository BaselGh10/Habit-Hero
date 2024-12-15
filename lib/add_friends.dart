import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'text_shdows.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AddFriendScreen extends StatefulWidget {
  @override
  _AddFriendScreenState createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _searchResults = [];
// Timer for debouncing search queries

  // Function to search users in Firestore
  void _searchUsers(String query) async {
    if (query.isNotEmpty) {
      // Firestore query to search users by username
      QuerySnapshot<Map<String, dynamic>> users = await _firestore
          .collection('Users')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      User? user = FirebaseAuth.instance.currentUser;
      String currentUserId = user!.uid;
      DocumentSnapshot<Map<String, dynamic>> userSnapshot =
        await  _firestore.collection('Users').doc(currentUserId).get();
      List<dynamic> friends = userSnapshot.data()?['friends'] ?? [];
    if(mounted){
      setState(() {
        _searchResults = users.docs
            .where((user) => user.id != currentUserId &&
             !friends.contains(user.data()['username']) ) // Exclude current user and non-friends
            .toList();
      });
      }
    } else {
      if(mounted){
      setState(() {
        _searchResults = [];
      });
      }
    }
  }

  // Function to check if a user is a friend

    // Check if the user is in the friend list

    
  bool _already = false;
  // Function to send friend request
  void _sendFriendRequest(
      String friendId, String friendUsername, String friendImageUrl) async {
    User? user = FirebaseAuth.instance.currentUser;
    String currentUserId = user!.uid;
    

    DocumentReference<Map<String, dynamic>> userDoc =
        _firestore.collection('Users').doc(currentUserId);

    DocumentSnapshot<Map<String, dynamic>> userSnapshot=
        await userDoc.get();
    DocumentReference<Map<String, dynamic>> friendDoc =
        _firestore.collection('Users').doc(friendId);

    DocumentSnapshot<Map<String, dynamic>> friendSnapshot =
        await friendDoc.get();


    if (friendSnapshot.exists) {
      List<dynamic> friendRequests =
          friendSnapshot.data()!['friendRequests'] ?? [];
          
      List<dynamic> notification =
          friendSnapshot.data()!['friendRequests'] ?? [];
           final ref = FirebaseStorage.instance.ref().child('app_images/freinds.jpg');
      String url = await ref.getDownloadURL();

    
            await _firestore
              .collection('Users')
              .doc(friendId)
              .collection('notifications')
              .add({
            
            'body':
                '${userSnapshot['username']} sent you a friend request.',
            'timestamp': FieldValue.serverTimestamp(),
            'senderId': currentUserId,
            'senderUsername': userSnapshot.data()!["username"],
            'senderPhotoUrl': url,
            
          });
        
      // Check if request already exists
      bool requestExists =
          friendRequests.any((request) => request['senderId'] == currentUserId);

      if (!requestExists) {
        if(mounted){
          setState(() {
            _already = false;
          });
        }

        // Add friend request to recipient's document
        friendRequests.add({
          'senderId': currentUserId,
          'senderUsername':
              userSnapshot.data()!["username"] ?? "Unknown User", // Assuming displayName is set
        // Assuming photoURL is set
        });

        await friendDoc.update({'friendRequests': friendRequests});
       
        

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Friend request sent!')),
        );
      } else {
        if(mounted){
          setState(() {
          _already = true;
        });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Friend request already sent!')),
        );
      }
    }
  }

  void _getAlready(
      String friendId, String friendUsername, String friendImageUrl) async {
    User? user = FirebaseAuth.instance.currentUser;
    String currentUserId = user!.uid;
    

    DocumentReference<Map<String, dynamic>> userDoc =
        _firestore.collection('Users').doc(currentUserId);

    DocumentSnapshot<Map<String, dynamic>> userSnapshot=
        await userDoc.get();
    DocumentReference<Map<String, dynamic>> friendDoc =
        _firestore.collection('Users').doc(friendId);

    DocumentSnapshot<Map<String, dynamic>> friendSnapshot =
        await friendDoc.get();

    if (friendSnapshot.exists) {
      List<dynamic> friendRequests =
          friendSnapshot.data()!['friendRequests'] ?? [];

      // Check if request already exists
      bool requestExists =
          friendRequests.any((request) => request['senderId'] == currentUserId);

      if (!requestExists) {
        if(mounted){
          setState(() {
            _already = false;
          });
        }
      } else {
        if(mounted){
          setState(() {
          _already = true;
        });
        }
      }
    }
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
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Tooltip(
            message: 'Add Friends Page Title',
            child: Text(
              'Add Friends',
              style: TextStyle(
                color: Colors.white,
                shadows: CustomTextShadow.shadows,
              ),
            ),
          ),
          backgroundColor: Colors.blue[800],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Tooltip(
                message: 'Search for users',
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search Users',
                    fillColor: Colors.grey[100],
                    filled: true,
                    labelStyle: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Sriracha',
                      fontSize: 18,
                      shadows: CustomTextShadow.shadows,
                    ),
                    border: OutlineInputBorder(),
                    suffixIcon: Tooltip(
                      message: 'Clear search',
                      child: IconButton(
                        icon: Icon(Icons.clear, color: Colors.black),
                        onPressed: () {
                          _searchController.clear();
                          _searchUsers('');
                        },
                      ),
                    ),
                  ),
                  style: TextStyle(color: Colors.black), // Set the input text color to white
                  onChanged: _searchUsers, // Trigger search on text change
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  return Tooltip(
                    message: 'User card for ${user.data()['username']}',
                    child: UserCard(
                      op1: () => _getAlready(
                        user!.id,
                        user.data()['rank'],
                        user.data()['imageurl'],
                      ),
                      username: user.data()['username'],
                      photoUrl: user.data()['imageurl'],
                      rank: user.data()['rank'],
                      topstreak: user.data()['top_streak'],
                      op: () => _sendFriendRequest(
                        user!.id,
                        user.data()['rank'],
                        user.data()['imageurl'],
                      ),
                      removeoradd: true,
                      already: _already,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserCard extends StatefulWidget {
  final VoidCallback op1;
  final String username;
  final String photoUrl;
  final String rank;
  final int topstreak;
  final VoidCallback op;
  final bool removeoradd;
  final bool already;



  // true=add false=remove
  UserCard({
    required this.op1,
    required this.username,
    required this.photoUrl,
    required this.rank,
    required this.topstreak,
    required this.op,
    required this.removeoradd,
    required this.already, 
  });

  @override
  State<UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  

  @override
  Widget build(BuildContext context) {

    //widget.op1();
    return Card(
      elevation: 4,
      color: Colors.blue[800], // Add this line to set the background color to blue
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
              message: 'User profile picture',
              child: Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (widget.rank == 'bronze')
                        ? Color.fromARGB(255, 145, 100, 2)
                        : (widget.rank == 'silver')
                            ? Color.fromARGB(255, 210, 210, 210)
                            : (widget.rank == 'gold')
                                ? Color.fromARGB(255, 255, 215, 0)
                                : (widget.rank == 'diamond')
                                    ? Color.fromARGB(255, 0, 191, 255)
                                    : Colors.black,
                    width: 4.5,
                  ),
                ),
                child: ClipOval(
                  child: Image.network(
                    widget.photoUrl,
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
                      widget.username,
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
                          message: 'Top streak label',
                          child: Text(
                            'Top Streak: ',
                            style: TextStyle(
                              color: Colors.white,
                              shadows: CustomTextShadow.shadows,
                            ),
                          ),
                        ),
                        Tooltip(
                          message: 'Top streak value',
                          child: Text(
                            '${widget.topstreak}',
                            style: TextStyle(
                              color: Colors.white,
                              shadows: CustomTextShadow.shadows,
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Tooltip(
                          message: 'Top streak icon',
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
            Tooltip(
              message: widget.removeoradd ? 'Add friend' : 'Remove friend',
              child: IconButton(
                icon: Icon(
                  widget.removeoradd ? Icons.person_add : Icons.person_remove,
                  color: Colors.white,
                ),
                onPressed: widget.op,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
