import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'shared_firebase_help.dart';
import 'dart:math';

Future<String> getUserName() async{
  final FirebaseAuth auth = FirebaseAuth.instance;
  final User? user = auth.currentUser;
  final userId = user?.uid;
  final collectionRef = FirebaseFirestore.instance
      .collection('Users')
      .doc(userId);
  try {
    final docSnapshot = await collectionRef.get();
    if (docSnapshot.exists) {
      final username = docSnapshot.data()?['username'];
      if (username != null && username is String) {
        return username;
      } else {
        print('Username does not exist or is not a valid map');
      }
    }
    return '';
  }
  catch (e) {
    print('Error getting document: $e');
    return '';
  }
}

String generateAutoId() {
  const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  Random random = Random();
  return List.generate(20, (index) => chars[random.nextInt(chars.length)]).join();
}

Future<void> createNotification(String message, String habitName, String? partner) async {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final User? user = auth.currentUser;
  String? userId = user?.uid;

  if (userId == null) {
    print('User is not logged in');
    return;
  }

  if (partner != null) {
    userId = await getPartnerId(partner);
  }

  final collectionRef = FirebaseFirestore.instance
      .collection('Users')
      .doc(userId)
      .collection('notifications');

  // Check if the collection exists by trying to get a document from it
  final snapshot = await collectionRef.limit(1).get();

  if (snapshot.docs.isEmpty) {
    // Collection does not exist, create a dummy document and delete it
    final dummyDocRef = collectionRef.doc('dummy');
    await dummyDocRef.set({'exists': true});
    await dummyDocRef.delete();
  }

  String notificationId;
  DocumentSnapshot docSnapshot;

  // Ensure the notificationId is unique
  do {
    notificationId = generateAutoId();
    docSnapshot = await collectionRef.doc(notificationId).get();
  } while (docSnapshot.exists);

  final notification = {
    'body': message,
    'habitName': habitName,
    'senderPhotoUrl': 'https://firebasestorage.googleapis.com/v0/b/habithero-17f5e.appspot.com/o/app_images%2Falarm.png?alt=media&token=f8515901-314b-4c50-86ed-6c26ebd3f652',
    'timestamp': DateTime.now(),
  };

  // Add the actual notification document
  await collectionRef.doc(notificationId).set(notification);
}

void cloudFunction_support1(String toMsg, String body) async {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final User? user = auth.currentUser;
  final userId = user?.uid;

  toMsg = await getPartnerId(toMsg);

  if (userId == null) {
    print('User is not logged in');
    return;
  }

  final docRef = FirebaseFirestore.instance
      .collection('Users')
      .doc(userId);

  try {
    final docSnapshot = await docRef.get();
    if (docSnapshot.exists) {
      final notifyMap = docSnapshot.data()?['notify'];
      if (notifyMap != null && notifyMap is Map<String, dynamic>) {
        Map<String, dynamic> updatedNotifyMap = Map<String, dynamic>.from(notifyMap);
        updatedNotifyMap['to'] = toMsg;
        updatedNotifyMap['notify_body'] = body;
        await docRef.update({'notify': updatedNotifyMap});
        updatedNotifyMap['Do it'] = true;
        await docRef.update({'notify': updatedNotifyMap});
      } else {
        print('Notify map does not exist or is not a valid map');
      }
    } else {
      print('Document does not exist');
    }
  } catch (e) {
    print('Error getting document: $e');
  }
}