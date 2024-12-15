import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:habit_hero/add_habit_page.dart';
import 'package:habit_hero/text_shdows.dart';
import 'add_challenge.dart'; // Import the Add Challenge screen
import 'challengepage.dart'; // Import the Challenge Details Page

class ChallengesList extends StatefulWidget {
  @override
  _ChallengesListState createState() => _ChallengesListState();
}

class _ChallengesListState extends State<ChallengesList> {
  List<ChallengeCard> challengesList = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;
  String _currentUserId = "";

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _currentUserId = user!.uid;
      _fetchChallenges();
    }
  }

  Future<void> _fetchChallenges() async {
    if (user == null) return;

    // Fetch challenges where the user is a recipient and the status is 'accepted'
    QuerySnapshot<Map<String, dynamic>> receivedChallengesSnapshot =
        await _firestore
            .collection('challenges')
            .where('recipients.$_currentUserId')
            .get();

    // Fetch challenges created by the user
    QuerySnapshot<Map<String, dynamic>> createdChallengesSnapshot =
        await _firestore
            .collection('Users')
            .doc(_currentUserId)
            .collection('user_challenges')
            .get();

    List<ChallengeCard> fetchedChallenges = [];

    // Process received challenges
    for (var doc in receivedChallengesSnapshot.docs) {
      var data = doc.data();
      List<String> friends = [];
      // Fetch usernames of recipients
      final recipients = data['recipients'] ?? {};
     if (!recipients.containsKey(_currentUserId)) {
        continue;
      }
      recipients.forEach((userId, userData) {
        if (userData['status'] == 'accepted') {
          friends.add(userData['username'] ?? 'Unknown');
        }
      });

      fetchedChallenges.add(
        ChallengeCard(
          challengeId: doc.id, // Pass challenge ID to ChallengeCard
          challengeDetails: data['challengeDetails'] ?? 'No details',
          challengeName: data['challengeName'] ?? 'N/A',
          habitId: data['habitId'] ?? 'N/A',
          points: data['points'] ?? 0,
          status: recipients[_currentUserId]['status'] ?? 'unknown',
          challengestatus: data['status'] ?? 'unknown',
          friends: friends, // Pass friends list
          confirmationMethod:
              data['challengeType'] ?? 'N/A', // Pass confirmation method
          onComplete: _fetchChallenges,
        ),
      );
    }

    // Process created challenges
    for (var doc in createdChallengesSnapshot.docs) {
      var data = doc.data();
      List<String> recipient = [];
      final recipientsData = data['recipients'] ?? {};
      for (var userId in recipientsData.keys) {
        var userData = recipientsData[userId];
        recipient.add(userData['username'] ?? 'Unknown');
      }
   
    }

    if (mounted) {
      setState(() {
        challengesList = fetchedChallenges;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Tooltip(
        message: 'Add a new habit',
        child: FloatingActionButton(
          backgroundColor: Colors.blue[800],
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddHabitPage()),
            );
          },
          child: Icon(Icons.add),
          foregroundColor: Colors.white,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: challengesList.length,
              itemBuilder: (context, index) {
                return Tooltip(
                  message: 'Challenge item',
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    child: challengesList[index],
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


class ChallengeCard extends StatelessWidget {
  final String challengeId; // Challenge ID
  final String challengeDetails;
  final String challengeName; 
  final String habitId;
  final int points;
  final String status;
  final String challengestatus;
  final List<String> friends; // List of friends
  final String confirmationMethod; // Method for confirmation
  final VoidCallback onComplete;
  ChallengeCard({
    required this.challengeId,
    required this.challengeDetails,
    required this.challengeName,
    required this.habitId,
    required this.points,
    required this.status,
    required this.challengestatus,
    required this.friends,
    required this.confirmationMethod,
    required this.onComplete,
  });


Future<void> acceptChallenge(BuildContext context, String challengeId) async {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final User? user = auth.currentUser;

  if (user == null) return;

  final userId = user.uid;
  final userDoc = _firestore.collection('Users').doc(userId);

  try {
    await _firestore.runTransaction((transaction) async {
      // Fetch user points
      final userSnapshot = await transaction.get(userDoc);
      if (!userSnapshot.exists) {
        throw Exception("User not found");
      }

      final userData = userSnapshot.data()!;
      final userPoints = userData['points'] as int;

      if (userPoints < 50) {
        // User does not have enough points
        
        throw Exception("Not enough points to accept the challenge");
        
      }

      final challengeDoc = _firestore.collection('challenges').doc(challengeId);
      final challengeSnapshot = await transaction.get(challengeDoc);
      if (!challengeSnapshot.exists) {
        throw Exception("Challenge not found");
      }

      final challengeData = challengeSnapshot.data()!;
      final recipients = challengeData['recipients'] as Map<dynamic, dynamic>;

      // Update the recipient's status to 'accepted'
      if (recipients.containsKey(userId)) {
        recipients[userId]['status'] = 'accepted';
      }

      // Check if all recipients have accepted
      String status1 = 'accepted';
      for (String friendId in recipients.keys) {
        if (recipients[friendId]['status'] != 'accepted') {
          status1 = 'pending';
        }
      }

      await transaction.update(challengeDoc, {
        'recipients': recipients,
        'status': status1,
      });

      // Optionally, update user-specific collections or perform additional actions
      // E.g., deduct points from the user
      await transaction.update(userDoc, {
        'points': userPoints - 50, // Deduct 50 points
      });
        var pointsc = challengeData['points'] ;
        var points1 = pointsc + 75;
        await transaction.update(challengeDoc, {
          'points': points1,
        });
          //   onComplete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Challenge accepted!')),
      );
     // onComplete();
        Navigator.pop(context);
        onComplete();
    });
  } catch (e) {
    //print("Error accepting challenge: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );

      Navigator.pop(context);
  }
}

   

  Future<void> _declineChallenge(BuildContext context) async {
    try {
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;
      final FirebaseAuth auth = FirebaseAuth.instance;
      final User? user = auth.currentUser;

      if (user == null) return;

      final userId = user.uid;
      final challengeDoc = _firestore.collection('challenges').doc(challengeId);

      await _firestore.runTransaction((transaction) async {
        final challengeSnapshot = await transaction.get(challengeDoc);
        if (!challengeSnapshot.exists) {
          throw Exception("Challenge not found");
        }

        final challengeData = challengeSnapshot.data()!;
        final recipients = challengeData['recipients'] as Map<dynamic, dynamic>;

        // Remove the recipient from the list
        if (recipients.containsKey(userId)) {
          recipients.remove(userId);
        }

        await transaction.update(challengeDoc, {
          'recipients': recipients,
        });
        if (recipients.length == 1) {
          await transaction.delete(challengeDoc);
        }
        // Optionally, update user-specific collections or perform additional actions
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Challenge declined!')),
      );
      onComplete();
     // Navigator.pop(context);
    } catch (e) {
      print("Error declining challenge: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error declining challenge')),
      );
       // Navigator.pop(context);
    }
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (challengestatus == "accepted") {
          // Navigate to the challenge page when the card is tapped
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Challengepage(
                challengeId: challengeId,
                challengeName: challengeName,
                habitId: habitId,
                points: points,
                status: status,
                friends: friends,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Challenge is not opened yet!')),
          );
        }
      },
      child: Card(
        elevation: 4,
        color: Colors.blue[800],
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Tooltip(
                      message: 'Challenge Name',
                      child: Text(
                        'Challenge: $challengeName',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          shadows: CustomTextShadow.shadows,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    if (status == 'accepted') ...[
                      Tooltip(
                        message: 'Challenge Status',
                        child: Text(
                          'You are in the tournament',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (status == 'pending') ...[
                SizedBox(width: 50),
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Confirmation'),
                              content: Text('Accepting this challenge will cost you 50 points. Are you sure you want to proceed?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Cancel' ,style: TextStyle(color: Colors.black)),
                                ),
                                TextButton(
                                  onPressed: () {
                                   
                                    acceptChallenge(context, challengeId);
                                    // Navigator.pop(context);
                                  },
                                  child: Text('Accept', style: TextStyle(color: Colors.white)),
                                   style: TextButton.styleFrom(backgroundColor: Colors.blue[800]),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Text('Accept', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                    SizedBox(height: 8),
                    Tooltip(
                      message: 'Decline Challenge',
                      child: ElevatedButton(
                        onPressed: () => _declineChallenge(context),
                        child: Text('Decline', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                ] else if (challengestatus == 'accepted') ...[
                SizedBox(width: 15),
                Tooltip(
                  message: 'Challenge Accepted',
                  child: Icon(Icons.whatshot, color: Colors.orange),
                ),
              ] else if (challengestatus == 'pending') ...[
                SizedBox(width: 15),
                Column(
                  children: [
                    Tooltip(
                      message: 'Challenge Pending',
                      child: Icon(Icons.lock_rounded, color: Colors.white),
                    ),
                    IconButton(
                      icon: Tooltip(
                        message: 'Delete this item',
                        child: Icon(Icons.delete),
                      ),
                      color: Colors.grey[400],
                      onPressed: () {
                        _declineChallenge(context);
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
     ),
);
}
}