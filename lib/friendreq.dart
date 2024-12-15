import 'dart:math';
import 'package:flutter/material.dart';
import 'package:habit_hero/text_shdows.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FriendreqPage extends StatefulWidget {
  @override
  _FriendreqPage createState() => _FriendreqPage();
}

class _FriendreqPage extends State<FriendreqPage> {
  List<FriendRequest> friendRequests = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;
  String _currentUserId = "";

  @override
  void initState() {
    super.initState();
    _currentUserId = user!.uid;
     FirebaseMessaging.instance.requestPermission();

    // Configure message handlers
   

    _fetchFriendRequests();
    //_fetchFriendRequests();
  }

void _fetchFriendRequests() async {
    // Fetch the user's document snapshot
    DocumentSnapshot<Map<String, dynamic>> userSnapshot =
        await _firestore.collection('Users').doc(_currentUserId).get();

    // Check if the user document exists
    if (userSnapshot.exists) {
      // Retrieve the friend requests list from the user data
      List<dynamic> requests =
          List<dynamic>.from(userSnapshot.data()!['friendRequests']);
if(requests.isEmpty){return;}
      // Use Future.wait to fetch all friend requests asynchronously
      List<FriendRequest> fetchedRequests =
          await Future.wait(requests.map((request) async {
        // Fetch the sender's user data
        var userData =
            await _firestore.collection('Users').doc(request['senderId']).get();
        return FriendRequest(
          senderId: request['senderId'],
          senderUsername: request['senderUsername'],
          rank: userData.data()!['rank'],
          imageurl: userData.data()!['imageurl'],
          top_streak: userData.data()!['top_streak'],
        );
      }));

      // Update the state with the fetched friend requests
     if(mounted){
      setState(() {
        friendRequests = fetchedRequests;
      });}
    }
  }

  Future<bool> _checkIfUserExists(String senderId) async {
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('Users').doc(senderId).get();
    return doc.exists;
  }

  void _acceptFriendRequest(String senderId, String senderUsername) async {
    bool userExists = await _checkIfUserExists(senderId);
    if (userExists) {
      DocumentReference<Map<String, dynamic>> userDoc =
          _firestore.collection('Users').doc(_currentUserId);

      DocumentSnapshot<Map<String, dynamic>> userSnapshot = await userDoc.get();

      if (userSnapshot.exists) {
        List<String> friends = List<String>.from(userSnapshot.data()!['friends']);
        List<dynamic> friendRequestsuser =
            List<dynamic>.from(userSnapshot.data()!['friendRequests']);

        if (!friends.contains(senderUsername)) {
          friends.add(senderUsername);

          // Remove the request
          friendRequestsuser.removeWhere(
              (request) => request['senderId'] == senderId);

          // Update current user's document
          await userDoc.update({
            'friends': friends,
            'friendRequests': friendRequestsuser,
          });

          // Update the sender's document to add the current user as a friend
          DocumentReference<Map<String, dynamic>> senderDoc =
              _firestore.collection('Users').doc(senderId);

          DocumentSnapshot<Map<String, dynamic>> senderSnapshot =
              await senderDoc.get();
          if (senderSnapshot.exists) {
            List<String> senderFriends =
                List<String>.from(senderSnapshot.data()!['friends']);

            senderFriends.add(userSnapshot.data()!['username']);
        final ref = FirebaseStorage.instance.ref().child('app_images/freinds.jpg');
        String url = await ref.getDownloadURL();

            await senderDoc.update({'friends': senderFriends});
              await _firestore
                .collection('Users')
                .doc(senderId)
                .collection('notifications')
                .add({
              
              'body':
                  '${userSnapshot.data()!["username"]} accepted your friend request.',
              'timestamp': FieldValue.serverTimestamp(),
              'senderId': _currentUserId,
              'senderUsername': userSnapshot.data()!["username"],
              'senderPhotoUrl': url,
              
            });
          }
          if(mounted){
          setState(() {
            friendRequests.removeWhere(
                (request) => request._senderUsername == senderUsername);
            //_fetchFriends();
          });
          }


          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Friend request accepted!')),
          );
        }
      }
    }
    else {
      // Show a message that the user no longer exists
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('The user no longer exists.')),
      );
    }
  }

  void _declineFriendRequest(String senderId) async {
    DocumentReference<Map<String, dynamic>> userDoc =
        _firestore.collection('Users').doc(_currentUserId);

    DocumentSnapshot<Map<String, dynamic>> userSnapshot = await userDoc.get();

    if (userSnapshot.exists) {
      List<dynamic> friendRequestsuser =
          List<dynamic>.from(userSnapshot.data()!['friendRequests']);

      // Remove the request
      friendRequestsuser.removeWhere((request) => request['senderId'] == senderId);

      // Update current user's document
      await userDoc.update({
        'friendRequests': friendRequestsuser,
      });
      if(mounted){
      setState(() {
         friendRequests
            .removeWhere((request) => request._senderId == senderId);
      });
      }


      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request declined!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Display Friend Requests
          if (friendRequests.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: friendRequests.length,
                itemBuilder: (context, index) {
                  final request = friendRequests[index];
                  return Tooltip(
                    message: 'Friend Request Card',
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
                                    color: (request.rank == 'bronze')
                                        ? Color.fromARGB(255, 145, 100, 2)
                                        : (request.rank == 'silver')
                                            ? Color.fromARGB(255, 210, 210, 210)
                                            : (request.rank == 'gold')
                                                ? Color.fromARGB(255, 255, 215, 0)
                                                : (request.rank == 'diamond')
                                                    ? Color.fromARGB(255, 0, 191, 255)
                                                    : Colors.black,
                                    width: 4.5,
                                  ),
                                ),
                                child: ClipOval(
                                  child: Image.network(
                                    request.imageurl,
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
                                    message: 'Sender Username',
                                    child: Text(
                                      request.senderUsername,
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
                                            '${request.top_streak}',
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
                            SizedBox(width: 16),
                            Column(
                              children: [
                                Tooltip(
                                  message: 'Accept Button',
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _acceptFriendRequest(
                                          request.senderId, request.senderUsername);
                                    },
                                    child: Text('Accept'),
                                  ),
                                ),
                                Tooltip(
                                  message: 'Decline Button',
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _declineFriendRequest(request.senderId);
                                    },
                                    child: Text('Decline'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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

class FriendRequest {
  final String senderId;
  final String senderUsername;
  final String imageurl;
  final String rank ;
  final int top_streak;


  FriendRequest({
    required this.senderId,
    required this.senderUsername,
   required this.imageurl,
   required this.rank,
   required this.top_streak

  });
  String get _senderId => this.senderId;
  String get _senderUsername => this.senderUsername;

}
