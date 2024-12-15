import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart'; // Import the path_provider package

import 'package:flutter/material.dart';
import 'package:habit_hero/home.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'login.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_messaging/firebase_messaging.dart';

// Firestore instance
final _firestore = FirebaseFirestore.instance;

enum Status {
  Uninitialized,
  Authenticated,
  Authenticating,
  Unauthenticated,
}

Future<File> convertAssetToFile(String assetPath) async {
  // Load the asset as bytes
  final byteData = await rootBundle.load(assetPath);
  final buffer = byteData.buffer;

  // Get a temporary directory
  Directory tempDir = await getTemporaryDirectory();
  String tempPath = tempDir.path;

  // Create a file in the temporary directory
  var filePath = path.join(tempPath,
      path.basename(assetPath));
  File file = File(filePath);
  await file.writeAsBytes(
      buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

  return file;
}
class UserModel extends ChangeNotifier {
  FirebaseAuth _auth;
  User? _user;
  Status _status = Status.Uninitialized;
  ImageProvider imageUrl = AssetImage("app_images/avatar.png");
  String username = '';
  String _email = '';
  String _password = '';

  UserModel(this._auth) {
    _auth.authStateChanges().listen((User? user) {
      _onAuthStateChanged(user);
    });
  }
  Future<void> fetchUserData() async {
    if (_user != null) {
      try {
        // Fetch user data from Firestore
        DocumentSnapshot userDoc =
            await _firestore.collection('Users').doc(_user!.uid).get();
        if (userDoc.exists) {
          username = userDoc['username'];
          // Optionally, fetch other user data here
        }
        await _loadProfileImage(); // Load profile image
      } catch (e) {
        print("Error fetching user data: $e");
      }
    }
  }

  // Getter for status
  Status get status => _status;
  User? get user => _user;
  String get email => _email;
  String get password => _password;
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _status = Status.Unauthenticated;
    } else {
      _user = firebaseUser;
      _status = Status.Authenticated;
      
      await fetchUserData(); // Fetch user data when a user signs in
    }
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _status = Status.Authenticating;
    //  notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _email = email;
      _password = password;
      await _loadProfileImage();
      FirebaseMessaging messaging = FirebaseMessaging.instance;
       // Get the token and save it to Firestore
      String? token = await messaging.getToken();
      if (token != null) {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          FirebaseFirestore.instance.collection('Users').doc(user.uid).update({
            'fcmToken': token,
          });
        }
      }
      await _firestore.collection('Users').doc(_user!.uid).get().then((value) {
        username = value['username'];
      });
      _status = Status.Authenticated;
      return true;
    } 
    catch (e) {
         SnackBar(content: Text('Login Failed: $e'));
     //  throw e;
     
    
      _status = Status.Unauthenticated;
      notifyListeners();
      throw e;
    return false;
    }
  }

  Future<void> _loadProfileImage() async {
    // Access the user model from the provider
    // Replace UserModel with your actual user model class
     final FirebaseAuth auth = FirebaseAuth.instance;
    String id = auth.currentUser!.uid;
   

    FirebaseFirestore db = FirebaseFirestore.instance;
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('user_profiles/$id/profile_picture.jpg');
    String url= await ref.getDownloadURL();

      imageUrl = NetworkImage(url);
        db.collection('Users').doc(id).update({
        'imageurl': url,
      });
    } catch (e) {
      print("Failed to load image: $e");

      //imageUrl = null; // Or set to a default image URL
    }
  } // Assuming your user model has an id property

  Future<bool> signUp(String email, String password, String username) async {
    try {
      _status = Status.Authenticating;
      notifyListeners(); // Notify listeners of state change
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      User? newUser = userCredential.user;
      if (newUser != null) {
        // Create or update the user document in Firestore
        DocumentReference userRef =
            FirebaseFirestore.instance.collection('Users').doc(newUser!.uid);
        DocumentSnapshot userDoc = await userRef.get();

        //final userRef = _firestore.collection('users').doc(_user!.uid);
        //final userDoc = await userRef.get();
         final ref = FirebaseStorage.instance
            .ref()
            .child('user_profiles/$newUser!.uid/profile_picture.jpg');
        if (!userDoc.exists) {
          await userRef.set({'username': username});
        } else {
          await userRef.update({'username': username});
        }
        //signIn(email, password);
      }
      return true;
    } catch (e) {
      // print(e);
      _status = Status.Unauthenticated;
      notifyListeners(); // Notify listeners of state change

      SnackBar(content: Text('Sign Up Failed: $e'));
      // throw e;
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;

    _status = Status.Unauthenticated;
    notifyListeners();
  }
}

class WaitingPage extends StatefulWidget {
  @override
  _WaitingPage createState() => _WaitingPage();
}
class _WaitingPage extends State<WaitingPage>
 
 {
  @override
  Widget build(BuildContext context) {
     final userModel = Provider.of<UserModel>(context);
    return MaterialApp(
    home: userModel.status ==Status.Authenticated
          ? MyBottomNavigation()
          : Loginpage(),
    );
  }
 }
