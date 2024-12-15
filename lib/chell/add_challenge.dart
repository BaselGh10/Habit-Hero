import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:blur_container/blur_container.dart';
import 'package:flutter/services.dart';
import 'package:habit_hero/text_shdows.dart';
import '/add_habit_widgets.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart';
var _friends=[];
FirebaseAuth auth = FirebaseAuth.instance;
FirebaseFirestore _firestore = FirebaseFirestore.instance;
final User? _user = auth.currentUser;
  Future<void> _fetchFriends() async {
    if (_user == null) return;

    DocumentSnapshot userDoc =
        await _firestore.collection('Users').doc(_user!.uid).get();
    List<dynamic> friendsList = userDoc['friends'] ?? [];

    List<Map<String, dynamic>> friendsDetails = [];
    for (String username in friendsList) {
      QuerySnapshot userDocs = await _firestore
          .collection('Users')
          .where('username', isEqualTo: username)
          .get();

      if (userDocs.docs.isNotEmpty) {
        DocumentSnapshot friendDoc = userDocs.docs.first;
        friendsDetails.add({
          'id': friendDoc.id,
          'username': friendDoc['username'],
          'photoUrl': friendDoc['imageurl'],
        });
      }
    }
    _friends=friendsDetails;
  
  
  setstate(){
      _friends = friendsDetails;}
    
  }

Future<List<String>?> Choose_challenges(BuildContext context) async {
  List<UserCard_forShare> friendsList = await fetchFriendsList();
  
  List<String>? selectedFriends = [];

  return showDialog<List<String>?>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Choose challengers'),
        content: Container(
          width: double.maxFinite,
          child: MultiSelectDialogField(
            items: friendsList
                .map((friend) => MultiSelectItem<String>(
                  friend.username,
                  friend.username,
                ))
                .toList(),
            title: Text('Select friends'),
            selectedItemsTextStyle: TextStyle(color: Colors.blue),
            buttonText: Text('Select'),
            onConfirm: (List<String> values) {
              selectedFriends = values;
              Navigator.pop(context, selectedFriends);
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      );
    },
  );
}

 

  Future<void> createAndSendChallenge(context,challengename, description,_selectedFriends) async {
      FirebaseAuth auth = FirebaseAuth.instance;
       FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = auth.currentUser;
 await _fetchFriends();
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not logged in')),
      );
      return;
    }

  

    String senderId = _user!.uid;
    String challengeName = challengename;
    String challengeDetails = description;


    Map<String, Map<String, dynamic>> recipientsMap = {};
    List<String> recipientIds = [];
    for (String friendId in _selectedFriends) {
      QuerySnapshot userDocs = await _firestore
        .collection('Users')
        .where('username', isEqualTo: friendId)
        .get();

   //String username = (await _firestore.collection('Users').doc(friendId).get()).data()!['username'];
        recipientsMap[userDocs.docs.first.id] = {
          'username': friendId,
          'status': 'pending',
          
          'curr_week':0,
        };
        recipientIds.add(friendId);
      }
    for (String friendId in _selectedFriends) {
      final friendDocs = await FirebaseFirestore.instance
          .collection('Users')
          .where('username', isEqualTo: friendId)
          .get();
      final friendDoc = friendDocs.docs.first;
      final friend = friendDoc.id;
         
final notificationsRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(friend)
          .collection('notifications');
      final ref = FirebaseStorage.instance.ref().child('app_images/challenge.png');
      String url = await ref.getDownloadURL();

      await notificationsRef.add({
        'habitName': challengeName,
       
        'timestamp': DateTime.now(),
        'senderPhotoUrl': url,
        'body': 'It\'s time to challenge : $challengeName',});
        }
    // Add current user as recipient
    String currentUserId = _user!.uid;
  String username = (await _firestore.collection('Users').doc(currentUserId).get()).data()!['username'];
    
  
      recipientsMap[currentUserId] = {
      'id' : currentUserId,
      'username': username,
      'status': 'accepted',
      'curr_week': 0,
      };
      recipientIds.add(currentUserId);
    

    // Create challenge in 'challenges' collection
    CollectionReference challenges = _firestore.collection('challenges');
    DocumentReference challengeRef = await challenges.add({
      'senderId': senderId,
      'challengeName': challengeName,
      'challengeDetails': challengeDetails,
     
      'status': 'pending',
      'challengeTime': Timestamp.now(),
    'points':75,
    'winners':[], 
      'recipients': recipientsMap,
      'active':true,
    });



    // Update friends' lists, add challenge requests, and send notifications
    for (String friendId in recipientIds) {
      DocumentReference friendDoc =
          _firestore.collection('Users').doc(friendId);
      await friendDoc.get();

      var userDoc = await _firestore.collection('Users').doc(_user!.uid).get();
if (friendId != currentUserId) {
      // Add challenge request to each friend's 'challenge_requests' collection


      // Send notification to each friend
     



    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Challenge sent and notifications added!')),
    );

    Navigator.of(context).pop();
  }

    }} 