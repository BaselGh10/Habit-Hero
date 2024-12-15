import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/widgets.dart';
import 'package:habit_hero/chell/add_challenge.dart';
import 'package:habit_hero/text_shdows.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:habit_hero/authenication.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as Path1;
import 'dart:io';
import 'package:habit_hero/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'about_info.dart';
import 'firebase_help_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'muli_confirm.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 0;

  bool _hasPermission = false;
  int topStreak = 0;
  String currQuote = '';
  String _rank = '';
  bool _isLoading = true;

  @override
  Future<void> _checkPermissions() async {
    bool permission = await requestPermissions();
    if (mounted) {
      setState(() {
        _hasPermission = permission;
      });
    }
    // setState(() {
    //   _hasPermission = permission;
    // });

    if (!_hasPermission) {
      _showPermissionDialog();
    }
  }

  Future<int> getTopStreak() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseFirestore db = FirebaseFirestore.instance;
    final User? user = auth.currentUser;
    final userId = user?.uid;
    int topStreak = 0;

    try {
      DocumentSnapshot documentSnapshot =
          await db.collection('Users').doc(userId).get();
      topStreak = documentSnapshot['top_streak'];
      return topStreak;
    } catch (e) {
      print('Error getting top streak: $e');
      return 0;
    }
  }

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

  Future<void> getRank() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseFirestore db = FirebaseFirestore.instance;
    final User? user = auth.currentUser;
    final userId = user?.uid;
    String rank = '';

    try {
      DocumentSnapshot documentSnapshot =
          await db.collection('Users').doc(userId).get();
      rank = documentSnapshot['rank'];
      _rank = rank;
    } catch (e) {
      print('Error getting top streak: $e');
      return;
    }
  }

  Future<void> fetchTopStreak() async {
    int topStreak_new = await getTopStreak();
    if (mounted) {
      setState(() {
        topStreak = topStreak_new;
        _isLoading = false;
      });
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

  @override
  void initState() {
    super.initState();
    fetchTopStreak();
    fetchCurrQuote();
    getRank();
  }

  Future<bool> requestPermissions() async {
    PermissionStatus status = await Permission.photos.status;

    // Request permission for photos
    status = await Permission.photos.request();

    // If permission is granted, exit the loop
    if (status.isGranted) {
      return true;
    }
    // If permission is permanently denied, exit the loop
    else if (status.isPermanentlyDenied) {
      status = await Permission.photos.request();
      // openAppSettings();
      _showPermissionDialog();
      return false;

      // If denied (but not permanently), the loop will continue and ask again
    }

    return status.isGranted;
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Tooltip(
          message: 'Dialog title',
          child: Text('Permissions Required'),
        ),
        content: Tooltip(
          message: 'Dialog content',
          child: Text('This app needs storage permission to access images.'),
        ),
        actions: <Widget>[
          Tooltip(
            message: 'Cancel the action',
            child: TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Tooltip(
            message: 'Open app settings',
            child: TextButton(
              child: Text("Open Settings"),
              onPressed: () {
                openAppSettings(); // Open app settings
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    if (!_hasPermission) {
      // Request permission if not already granted
      _hasPermission = true; //await requestPermissions();
    }
    if (_hasPermission) {
      final userModel = Provider.of<UserModel>(context,
          listen: false); // Replace UserModel with your actual user model class
      final userId = userModel.user?.uid;
      final picker = ImagePicker();
      final pickedFile = await picker.getImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        ImageProvider imageUrl = FileImage(imageFile);
        // Step 4: Implement the image uploading function
        try {
          String fileName = Path1.basename(imageFile.path);
          Reference ref = FirebaseStorage.instance.ref().child(
              'user_profiles/${userModel.user?.uid}/profile_picture.jpg');

          UploadTask uploadTask = ref.putFile(imageFile!);
          //  String imageUrlfire = await ref.getDownloadURL();

          if (mounted) {
            setState(() {
              userModel.imageUrl = imageUrl;
              // imageUrl =imageFile ;
            });
          }
        } catch (e) {
          print("Error uploading image: $e");
          throw e;
        }
      }
    } else {
      // Handle the case when permission is denied
      print('Photos permission is denied.');
    }
  }

  void _confirmDeletePicture(String? userId) async {
    final userModel = Provider.of<UserModel>(context, listen: false);
    final ByteData byteData = await rootBundle.load('app_images/avatar.png');
    final Uint8List imageBytes = byteData.buffer.asUint8List();

    FirebaseFirestore db = FirebaseFirestore.instance;
    final ref = FirebaseStorage.instance
        .ref()
        .child('user_profiles/$userId/profile_picture.jpg');
    await ref.putData(imageBytes);
    final imageUrl = await ref.getDownloadURL();
    FirebaseFirestore.instance.collection('Users').doc(userId).update({
      'imageUrl': imageUrl,
    });
    if (mounted) {
      setState(() {
        userModel.imageUrl = NetworkImage(imageUrl);
      });
    }
  }

  Future<void> removeallfriends() async {
    final _auth = FirebaseAuth.instance;
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final userModel = Provider.of<UserModel>(context,
        listen: false); // Replace UserModel with your actual user model class
    String id=auth.currentUser!.uid;
    final userId = userModel.user?.uid;
    final userUsername = userModel.username;

    DocumentSnapshot<Map<String, dynamic>> userSnapshot =
        await _firestore.collection('Users').doc(userId).get();
        

    List<dynamic> friendsUsernames = [];
    List<dynamic> friendsreq = [];
    if (userSnapshot.exists) {
      Map<String, dynamic>? data = userSnapshot.data();
      if (data != null && data.containsKey('friends')) {
        friendsUsernames = data['friends'] ?? [];
      }
      
    }

    // Remove the user from each friend's list
    for (String friendUsername in friendsUsernames) {
      QuerySnapshot friendQuery = await _firestore
          .collection('Users')
          .where('username', isEqualTo: friendUsername)
          .get();
    
      if (friendQuery.docs.isNotEmpty) {
        DocumentReference friendRef = friendQuery.docs.first.reference;
        await friendRef.update({
          'friends': FieldValue.arrayRemove([userUsername])
        });
      }}
     
    QuerySnapshot usersSnapshot = await _firestore.collection('Users').get();



for (DocumentSnapshot userDoc in usersSnapshot.docs) {
  // Retrieve the friendRequests array
  List<dynamic> friendRequests = (userDoc.data() as Map<String, dynamic>)?['friendRequests'] ?? [];

  // Find and remove the map with the matching senderId
  List<dynamic> updatedFriendRequests = friendRequests.where((friendRequest) {
    // Each friendRequest is a map, so check if the senderId matches
    return friendRequest['senderId'] != id;
  }).toList();

  // Update the user document with the new friendRequests array
  if (updatedFriendRequests.length != friendRequests.length) {
    await userDoc.reference.update({
      'friendRequests': updatedFriendRequests
    });


      
  }    
  }
   QuerySnapshot challengesSnapshot = await _firestore.collection('challenges').get();

for (DocumentSnapshot challengeDoc in challengesSnapshot.docs) {
  // Retrieve the recipients map
  Map<String, dynamic> recipients = (challengeDoc.data() as Map<String, dynamic>)?['recipients'] ?? {};

  // Check if the senderId exists as a key in the recipients map
  if (recipients.containsKey(id)) {
    // Remove the senderId from the recipients map
    recipients.remove(id);

    // Update the challenge document with the new recipients map
    await challengeDoc.reference.update({
      'recipients': recipients
    });

    print('Removed senderId from recipients in challenge: ${challengeDoc.id}');
  }
}}
  void _onItemTapped(int index) {
    if (mounted) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _deleteAccount() async {
    final userModel = Provider.of<UserModel>(context,
        listen: false); // Replace UserModel with your actual user model class
    final _auth = FirebaseAuth.instance;
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final userId = userModel.user?.uid;

    if (userModel.user != null) {
      try {
        try {
          // Del
          //ete user profile image from Firebase Storage

          removeallfriends();

          await removeAllHabitsFromCloud();

          String filePath =
              'user_profiles/${userModel.user?.uid}/profile_picture.jpg';
          Reference ref = FirebaseStorage.instance.ref().child(filePath);

          await ref.delete();
        } catch (e) {}
        // Delete user data from Firestore
        await _firestore.collection('Users').doc(userModel.user?.uid).delete();

        // Delete user authentication
        await userModel.user?.delete();

        // Sign out the user
        staticValues_MultiConf.habitName = '';
        await _auth.signOut();

        // Navigate to the sign-in page or show a message
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => Loginpage()));

      } catch (e) {
        print('Error deleting account: $e');
        // Show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting account: $e')),
        );
      }
    }
  }

  Future<void> _confirmDeleteAccount() async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Tooltip(
          message: 'Dialog title',
          child: Text('Confirm Delete'),
        ),
        content: Tooltip(
          message: 'Dialog content',
          child: Text(
              'Are you sure you want to delete your account? This action cannot be undone!'),
        ),
        actions: [
          Tooltip(
            message: 'Cancel the action',
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: Colors.black)),
            ),
          ),
          Tooltip(
            message: 'Confirm the deletion',
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete', style: TextStyle(color: Colors.white)),
              style: TextButton.styleFrom(backgroundColor: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      _deleteAccount();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel>(context, listen: false);
    final userModel = Provider.of<UserModel>(context,
        listen: false); // Replace UserModel with your actual user model class
    final _auth = FirebaseAuth.instance;
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final userId = userModel.user?.uid;

    // imageUrl = user.imageUrl;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.white),
            onPressed: () => {showCustomAboutDialog(context)},
            tooltip: 'Show information',
          ),
          Spacer(),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              staticValues_MultiConf.habitName = '';
              user.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => Loginpage()),
              );
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      backgroundColor: Colors.transparent,
      body: (!_isLoading)
          ? Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                  ),
                  painter: headCurved(),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        user.username,
                        style: TextStyle(
                            shadows: CustomTextShadow.shadows,
                            fontSize: 40,
                            letterSpacing: 1.5,
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: 95,
                        ),
                        Container(
                          padding: EdgeInsets.all(10.0),
                          width: MediaQuery.of(context).size.width / 2,
                          height: MediaQuery.of(context).size.width / 2,
                          decoration: BoxDecoration(
                              border: Border.all(
                                  color: (_rank == 'bronze')
                                      ? Color.fromARGB(255, 145, 100, 2)
                                      : (_rank == 'silver')
                                          ? Color.fromARGB(255, 210, 210, 210)
                                          : (_rank == 'gold')
                                              ? Color.fromARGB(255, 255, 215, 0)
                                              : (_rank == 'diamond')
                                                  ? Color.fromARGB(
                                                      255, 0, 191, 255)
                                                  : Colors.black,
                                  width: 15),
                              shape: BoxShape.rectangle,
                              color: Colors.white,
                              image: DecorationImage(
                                fit: BoxFit.cover,
                                image: user.imageUrl,
                              )),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 160.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Edit Profile Picture'),
                                      content: Text('Choose an option:'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _pickAndUploadImage();
                                          },
                                          child: Text('Edit'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _confirmDeletePicture(userId);
                                          },
                                          child: Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: Tooltip(
                                  message: 'Edit profile picture',
                                  child: CircleAvatar(
                                    backgroundColor: Colors.blue[800],
                                    radius: 20,
                                    child: Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 290),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Top Streak: ',
                                style: TextStyle(
                                  fontSize: 40,
                                  color: Colors.white,
                                  shadows: CustomTextShadow.shadows,
                                ),
                              ),
                              Text(
                                '${topStreak}',
                                style: TextStyle(
                                  fontSize: 40,
                                  color: Colors.white,
                                  shadows: CustomTextShadow.shadows,
                                ),
                              ),
                              SizedBox(width: 10),
                              Image.asset('app_images/fire_icon.png',
                                  width: 50, height: 50),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.all(20),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10.0),
                              child: currQuote != "No Quote"
                                  ? Container(
                                      decoration: BoxDecoration(
                                        color: (_rank == 'bronze')
                                            ? Color.fromARGB(187, 145, 100, 2)
                                            : (_rank == 'silver')
                                                ? Color.fromARGB(
                                                    181, 210, 210, 210)
                                                : (_rank == 'gold')
                                                    ? Color.fromARGB(
                                                        188, 255, 217, 0)
                                                    : (_rank == 'diamond')
                                                        ? Color.fromARGB(
                                                            179, 0, 191, 255)
                                                        : const Color.fromARGB(
                                                            179, 0, 0, 0),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          (currQuote == "No Quote")
                                              ? ''
                                              : currQuote,
                                          style: TextStyle(
                                              shadows: CustomTextShadow.shadows,
                                              fontSize: 18,
                                              letterSpacing: 1.5,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900),
                                        ),
                                      ),
                                    )
                                  : SizedBox(height: 0, width: 0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Tooltip(
                      message: 'Remove account',
                      child: ElevatedButton(
                        onPressed: () => _confirmDeleteAccount(),
                        child: Text(
                          'Remove Account',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            shadows: CustomTextShadow.shadows,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Center(
              child: CircularProgressIndicator(
              color: Colors.blue[800],
            )),
    );
  }
}

class headCurved extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = const Color.fromRGBO(21, 101, 192, 1);
    Path path = Path()
      ..relativeLineTo(0, 150)
      ..quadraticBezierTo(size.width / 2, 225, size.width, 150)
      ..relativeLineTo(0, -150)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
