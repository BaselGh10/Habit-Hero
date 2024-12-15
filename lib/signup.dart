import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habit_hero/login.dart';
import 'package:habit_hero/text_shdows.dart';
import 'authenication.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:habit_hero/login.dart';
import 'package:habit_hero/home.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _usernamecont = TextEditingController();
  final _passwordcont = TextEditingController();
  final email_cont = TextEditingController();
  final _passwordcontconf = TextEditingController();
  bool _isLoading = false;

  // Check if the username meets your criteria
  bool _isValidUsername(String username) {
    return username.isNotEmpty &&
        username.length >= 3 &&
        username.length <= 15 ;

  }

  // Check if the username is unique in the database
  Future<bool> _isUsernameUnique(String username) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .where('username', isEqualTo: username)
        .get();
    return querySnapshot.docs.isEmpty;
  }

  void _signUp(BuildContext context) async {
    if(mounted){
    setState(() {
      _isLoading = true;
    });

    }

    final userModel = Provider.of<UserModel>(context, listen: false);
    if (_passwordcontconf.text.trim() != _passwordcont.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Passwords do not match')),
      );
      if(mounted){
      setState(() {
        _isLoading = false;
      });
      }

      return;
    }
    // Validate username
    if (!_isValidUsername(_usernamecont.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid username')),
      );
      if(mounted){
      setState(() {
        _isLoading = false;
      });
      }

      return;
    }

    // Check if the username is unique
    bool isUsernameUnique =
        await _isUsernameUnique(_usernamecont.text.trim());
    if (!isUsernameUnique) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Username already taken')),
      );
      if(mounted){
      setState(() {
        _isLoading = false;
      });
      }

      return;
    }
    bool res = await userModel.signUp(
      email_cont.text.trim(),
      _passwordcont.text.trim(),
      _usernamecont.text.trim(),
    );

    if (res == true) {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final User? user = auth.currentUser;
      final userId = user?.uid;
      final ByteData byteData =
          await rootBundle.load('app_images/avatar.png');
      final Uint8List imageBytes = byteData.buffer.asUint8List();

      FirebaseFirestore db = FirebaseFirestore.instance;
      final ref = FirebaseStorage.instance
          .ref()
          .child('user_profiles/$userId/profile_picture.jpg');
      await ref.putData(imageBytes);
      db.collection('Users').doc(userId).set({
        'friends': List<String>.empty(),
      }, SetOptions(merge: true));
      db.collection('Users').doc(userId).set({
        'top_streak': 0,
      }, SetOptions(merge: true));
      db.collection('Users').doc(userId).set({
        'points': 0,
      }, SetOptions(merge: true));
      db.collection('Users').doc(userId).set({
        'habitNames': [],
      },SetOptions(merge: true));
      db.collection('Users').doc(userId).set({
        'imageurl': '',
      }, SetOptions(merge: true));
      db.collection('Users').doc(userId).set({
        'rank': 'black',
      }, SetOptions(merge: true));
      db.collection('Users').doc(userId).set({
        'fcmToken': '',
      }, SetOptions(merge: true));
      db.collection('Users').doc(userId).set({
        'friendRequests': [],
      }, SetOptions(merge: true));
      db.collection('Users').doc(userId).set({
        'notify': {'to': '', 'notify_body': '', 'Do it': false},
      }, SetOptions(merge: true));
        db
          .collection('Users')
          .doc(userId)
          .set({'curr_quote':'No Quote'}, SetOptions(merge: true));
      await userModel.signIn(
          email_cont.text.trim(), _passwordcont.text.trim());
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyBottomNavigation()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign up failed')),
      );
    }

    if(mounted){
    setState(() {
      _isLoading = false;
    });
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[200], // Set background color
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        title: Tooltip(
          message: 'Welcome to Habit Hero',
          child: const Text(
            'Welcome to Habit Hero',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: CustomTextShadow.shadows),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Tooltip(
                  message: 'Welcome! We are happy that you joined us!',
                  child: Text(
                    'Welcome! We are happy that you joined us!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: CustomTextShadow.shadows,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    color: Colors.blueGrey[200],
                    child: Tooltip(
                      message: 'Enter your email address',
                      child: TextFormField(
                        controller: email_cont,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'Enter your email address',
                          prefixIcon: Icon(Icons.person,
                              color: Colors.white,
                              shadows: CustomTextShadow.shadows),
                          labelStyle: TextStyle(
                              color: Colors.white,
                              shadows: CustomTextShadow.shadows),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: Colors.black, width: 2.0),
                          ),
                        ),
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    color: Colors.blueGrey[200],
                    child: Tooltip(
                      message: 'Enter your username',
                      child: TextFormField(
                        controller: _usernamecont,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          hintText: 'Enter your username',
                          prefixIcon: Icon(Icons.person,
                              color: Colors.white,
                              shadows: CustomTextShadow.shadows),
                          labelStyle: TextStyle(
                              color: Colors.white,
                              shadows: CustomTextShadow.shadows),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: Colors.black, width: 2.0),
                          ),
                        ),
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(15),
                        ],
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    color: Colors.blueGrey[200],
                    child: Tooltip(
                      message: 'Enter your password',
                      child: TextFormField(
                        controller: _passwordcont,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          prefixIcon: Icon(Icons.password,
                              color: Colors.white,
                              shadows: CustomTextShadow.shadows),
                          labelStyle: TextStyle(
                              color: Colors.white,
                              shadows: CustomTextShadow.shadows),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: Colors.black, width: 2.0),
                          ),
                        ),
                        obscureText: true,
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    color: Colors.blueGrey[200],
                    child: Tooltip(
                      message: 'Confirm your password',
                      child: TextFormField(
                        controller: _passwordcontconf,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          hintText: 'Enter your password',
                          prefixIcon: Icon(Icons.password,
                              color: Colors.white,
                              shadows: CustomTextShadow.shadows),
                          labelStyle: TextStyle(
                              color: Colors.white,
                              shadows: CustomTextShadow.shadows),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: Colors.black, width: 2.0),
                          ),
                        ),
                        obscureText: true,
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Tooltip(
                  message: 'Sign up',
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            _signUp(context);
                          },
                    style: ButtonStyle(
                      backgroundColor:
                          WidgetStateProperty.all<Color>(Colors.blue.shade800),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white),
                          )
                        : Text('Sign Up',
                            style: TextStyle(
                                color: Colors.white,
                                shadows: CustomTextShadow.shadows)),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => Loginpage()),
                    );
                  },
                  child: Tooltip(
                    message: 'Already have an account? Click here to log in!',
                    child: Text(
                      "Already have an account? Click here to log in!",
                      style: TextStyle(
                        color: Colors.white,
                        shadows: CustomTextShadow.shadows,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: 200,
                  height: 220,
                  child: Image.asset(
                    'app_images/welcome.png',
                    fit: BoxFit.contain,
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
