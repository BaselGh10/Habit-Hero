import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ChallengeRequestsPage extends StatefulWidget {
  @override
  _ChallengeRequestsPageState createState() => _ChallengeRequestsPageState();
}

class _ChallengeRequestsPageState extends State<ChallengeRequestsPage> {
  late Stream<QuerySnapshot> _challengeRequestsStream;
  List<Map<String, dynamic>> _challengeRequests = [];

  @override
  void initState() {
    super.initState();
    _fetchChallengeRequests();
  }

  void _fetchChallengeRequests() {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    _challengeRequestsStream = FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('challenge_requests')
        .orderBy('timestamp', descending: true)
        .snapshots();

    // Listen to the Firestore stream and update local state
    _challengeRequestsStream.listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        if(mounted){
          setState(() {
            _challengeRequests = snapshot.docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .toList();
          });
        }
      }
    });
  }

  Future<void> _acceptChallenge(
      String challengeId, String challengeName) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final firestore = FirebaseFirestore.instance;

    try {
      // Query to find the specific challenge request
      QuerySnapshot challengeRequestsSnapshot = await firestore
          .collection('Users')
          .doc(userId)
          .collection('challenge_requests')
          .where('challengeId', isEqualTo: challengeId)
          .get();

      // Ensure that a matching request is found
      if (challengeRequestsSnapshot.docs.isNotEmpty) {
        // Get the document ID of the matched challenge request
        String requestDocId = challengeRequestsSnapshot.docs.first.id;

        // Update the challenge request status to 'accepted'
        await firestore
            .collection('Users')
            .doc(userId)
            .collection('challenge_requests')
            .doc(requestDocId)
            .delete();
        

        // Add the challenge to the user's 'user_challenges' collection


        // Update the challenge status in the 'challenges' collection
        await firestore.collection('challenges').doc(challengeId).update({
          'recipients.$userId.status': 'accepted',
        });
        bool isChallengeopen = false;
        final challengeData =
            await firestore.collection('challenges').doc(challengeId).get();
                
        if (challengeData != null) {
          challengeData['recipients'].forEach((key, value) {
            if (value['status'] == 'pending') {
              isChallengeopen = true;
            }
          });
        }
       String senderId= challengeData['senderId'];
  final notificationsRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(senderId)
          .collection('notifications');
      final ref = FirebaseStorage.instance.ref().child('app_images/challenge.png');
      String url = await ref.getDownloadURL();

      await notificationsRef.add({
        'habitName': challengeName,
       
        'timestamp': DateTime.now(),
        'senderPhotoUrl': url,
        'body': ' $userId accepted your challenge challenge : $challengeName',});
        
        if (!isChallengeopen) {
          await firestore.collection('challenges').doc(challengeId).update({
            'status': 'accepted',
          });
        }
        // Update local list
        if(mounted){
          setState(() {
            _challengeRequests.removeWhere(
              (request) => request['challengeId'] == challengeId,
              
            );
          });
        }


        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Challenge accepted!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Challenge request not found')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept challenge: $e')),
      );
    }
  }

  Future<void> _declineChallenge(String challengeId) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    try {
      // Query to find the specific challenge request
      QuerySnapshot challengeRequestsSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('challenge_requests')
          .where('challengeId', isEqualTo: challengeId)
          .get();

      // Ensure that a matching request is found
      if (challengeRequestsSnapshot.docs.isNotEmpty) {
        // Get the document ID of the matched challenge request
        String requestDocId = challengeRequestsSnapshot.docs.first.id;

        // Remove the challenge request
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(userId)
            .collection('challenge_requests')
            .doc(requestDocId)
            .delete();

        // Update local list
        if(mounted){
          setState(() {
            _challengeRequests.removeWhere(
              (request) => request['challengeId'] == challengeId,
            );
          });
        }


        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Challenge declined!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Challenge request not found')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to decline challenge: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _challengeRequests.isEmpty
          ? Center(child: Text('No challenge requests'))
          : ListView.builder(
              itemCount: _challengeRequests.length,
              itemBuilder: (context, index) {
                final request = _challengeRequests[index];
                final challengeId = request['challengeId'] ?? '';
                final challengeName = request['challengeName'] ?? '';

                return Card(
                  elevation: 4,
                  color: Colors.blue[800],
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2.0,
                                ),
                              ),
                              child: ClipOval(
                                child: Image.network(
                                  request['senderPhotoUrl'] ??
                                      'https://example.com/default_photo.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    request['body'] ?? 'No message',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '${(request['timestamp'] as Timestamp).toDate().toLocal()}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[300],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                _acceptChallenge(challengeId, challengeName);
                              },
                              child: Text('Accept'),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                _declineChallenge(challengeId);
                              },
                              child: Text('Decline'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
