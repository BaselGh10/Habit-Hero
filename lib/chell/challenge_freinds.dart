import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:habit_hero/text_shdows.dart';
import '/profilescreen.dart';
int index = 1;
class ChallengeFriends extends StatefulWidget {
  String challangeId; 
  String habit_name;// List of friends' usernames

  ChallengeFriends({required this.challangeId,
  required this.habit_name});

  @override
  _ChallengeFriendsState createState() => _ChallengeFriendsState();
}

class _ChallengeFriendsState extends State<ChallengeFriends> {
  List<UserCard> friendsList = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;
  String _currentUserId = "";

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _currentUserId = user!.uid;
      _fetchChallengeFriends();
    }
  }

  void _fetchChallengeFriends() async {
      DocumentSnapshot<Map<String, dynamic>> friendschallange = await _firestore
        .collection('challenges')
        .doc(widget.challangeId)
        .get();
        Map<String,dynamic> friendsrec =friendschallange.data()!['recipients'];
        List<String> friendIds = friendsrec.keys.toList();
        friendIds.sort((a, b) {
      int pointsA = friendsrec[a]['curr_week'];
      int pointsB = friendsrec[b]['curr_week'];
      return pointsB.compareTo(pointsA);
        });

        List<UserCard> sortedFriendsList = [];
        for (String friendId in friendIds) {
      DocumentSnapshot<Map<String, dynamic>> friendSnapshot = await _firestore
          .collection('Users')
          .doc(friendId)
          .get();
      CollectionReference habitCollection =await
          _firestore.collection('Users').doc(friendId).collection('challenge_${widget.habit_name}');
            QuerySnapshot habitSnapshot = await habitCollection.get();
          int currd=  await habitSnapshot.docs[1]['week_curr'];
       
      int currw = await habitSnapshot.docs[1]['week_goal'];
      if (friendSnapshot.exists) {
        Map<String, dynamic> friendData = friendSnapshot.data()!;
        sortedFriendsList.add(UserCard(
         
          username: friendData['username'],
          photoUrl: friendData['imageurl'],
          rank: friendData['rank'],
          topstreak: friendData['top_streak'],
            curr_days: currd,
          goal_days: currw,
          op: () => _removeFriend(friendData['username']),
          removeoradd: false,
          
        ));
      }
        }

        if (mounted) {
          setState(() {
            friendsList = sortedFriendsList;
            index = 1;
          });
        }
        }

  void _removeFriend(String friendUsername) async {
    DocumentReference<Map<String, dynamic>> userDoc =
        _firestore.collection('Users').doc(_currentUserId);

    DocumentSnapshot<Map<String, dynamic>> userSnapshot = await userDoc.get();

    if (userSnapshot.exists) {
      List<String> friends = List<String>.from(userSnapshot.data()!['friends']);

      if (friends.contains(friendUsername)) {
        friends.remove(friendUsername);

        await userDoc.update({'friends': friends});

        QuerySnapshot<Map<String, dynamic>> friendsSnapshot = await _firestore
            .collection('Users')
            .where("username", isEqualTo: friendUsername)
            .get();

        if (friendsSnapshot.docs.isNotEmpty) {
          String friendId = friendsSnapshot.docs[0].id;

          DocumentReference<Map<String, dynamic>> friendDoc =
              _firestore.collection('Users').doc(friendId);

          DocumentSnapshot<Map<String, dynamic>> friendSnapshot =
              await friendDoc.get();

          if (friendSnapshot.exists) {
            List<String> friendFriends =
                List<String>.from(friendSnapshot.data()!['friends']);

            friendFriends.remove(userSnapshot.data()!['username']);

            await friendDoc.update({'friends': friendFriends});
          }
          if(mounted){
            setState(() {
              friendsList
                  .removeWhere((friend) => friend.username == friendUsername);
                
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Friend removed!')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
     return Container(
    
    child:  Scaffold(
      backgroundColor: Colors.transparent,
     
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: friendsList.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.all(8),
                  child: friendsList[index],
                );
              },
            ),
          ),
        ],
      ),
    ));
  }
}

class UserCard extends StatelessWidget {

  final String username;
  final String photoUrl;
  final String rank;
  final int topstreak;
  final VoidCallback op;
  final bool removeoradd;
  final int curr_days ;

  final int goal_days;


  UserCard({
 
    required this.username,
    required this.photoUrl,
    required this.rank,
    required this.topstreak,
    required this.op,
    required this.removeoradd,
    required this.curr_days,
    required this.goal_days,
    
  });




  @override
  Widget build(BuildContext context) {
   
   return InkWell(
    
      child: Card(
        color: Color.fromARGB(199, 21, 101, 192),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Container(
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
                      SizedBox(width:16 ),
                      Text(
                        username,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          shadows: CustomTextShadow.shadows,
                        ),
                      ),
                    ],
                  ),
                
                        
                        ],
                      ),
                    
                  
                
              
              Row(
                children: <Widget>[
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: Stack(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(top: 24.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                height: 30,
                                child: LinearProgressIndicator(
                                  value: curr_days /
                                      goal_days, // Use curr_days and goal_days here
                                  backgroundColor: Colors.blue[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    //widget.is_confirmed ? Colors.green.shade600 : Color.fromARGB(255, 255, 255, 2), // Conditional color assignment
                                    (curr_days >= goal_days)
                                        ? Colors.green.shade600
                                        : Color.fromARGB(255, 255, 255,
                                            2), // Conditional color assignment
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Container(
                              margin: EdgeInsets.only(
                                  top:
                                      20), // Adjust this value to lower the text as needed
                              child: Text(
                                '${curr_days} of ${goal_days} days done!', // Use curr_days and goal_days here
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  shadows: CustomTextShadow.shadows,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )]
          ),
        ),
      ),
          )
        ;
      
    
    
}
}
