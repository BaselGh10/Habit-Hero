import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:habit_hero/text_shdows.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_help_functions.dart';
import 'add_friends.dart';
import 'notify_func.dart';

/*--------------------------------------------------------------------------------MethodSelectorWidget*/

class MethodSelectorWidget extends StatefulWidget {
  final Function(String) onMethodSelected;

  MethodSelectorWidget({Key? key, required this.onMethodSelected}) : super(key: key);

  @override
  _MethodSelectorWidgetState createState() => _MethodSelectorWidgetState();
}

class _MethodSelectorWidgetState extends State<MethodSelectorWidget> {
  String _selectedMethod = 'None';
  final Map<String, String> _methodWords = {
    'None': 'No proving method selected.\nYou will get 2 points for each successful habit completion.',
    'Timer': 'You will get a point for every minute.',
    'Multiple Confirmation': 'You will get 15 point for the confirmation. You will confirm the habit 3 times a day.',
  };

  final GlobalKey _tooltipKey = GlobalKey();

  void _showTooltip() {
    final dynamic tooltip = _tooltipKey.currentState;
    tooltip?.ensureTooltipVisible();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Tooltip(
          message: 'Select a method from the dropdown',
          child: Container(
            height: 40,
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Adjust padding as needed
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border.all(color: Colors.black, width: 2), // Border color and width
              borderRadius: BorderRadius.circular(15), // Border radius
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                //canvasColor: Colors.blue[800], // This changes the dropdown menu background color
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedMethod,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedMethod = newValue!;
                      widget.onMethodSelected(_selectedMethod); // Call the callback function with the new value
                    });
                  },
                  iconEnabledColor: Colors.black, // Change the arrow icon color
                  items: <String>['None', 'Timer', 'Multiple Confirmation']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: TextStyle(color: Colors.black), // Set text color to white
                      ),
                    );
                  }).toList(),
                  // To change the dropdown button's background, you might need to wrap it in a Container
                  // and apply decoration, but this affects the button, not the dropdown menu.
                ),
              )
            ),
          ),
        ),
        Tooltip(
          key: _tooltipKey,
          message: '$_selectedMethod: ${_methodWords[_selectedMethod]}',
          decoration: BoxDecoration(
            color: Colors.grey[100], // Tooltip background color
            borderRadius: BorderRadius.circular(4), // Rounded corners
          ),
          textStyle: TextStyle(color: Colors.black),
          child: IconButton(
            highlightColor: Colors.black,
            icon: Icon(Icons.info, color: Colors.grey[100], shadows: CustomTextShadow.shadows,),
            onPressed: _showTooltip,
          ),
        ),
      ],
    );
  }
}

/*--------------------------------------------------------------------------------MethodSelectorWidget*/
/*--------------------------------------------------------------------------------MyDropdownWidget*/

class MyDropdownWidget<T> extends StatefulWidget {
  final String leadingText;
  final String trailingText;
  final List<T> items;
  final T selectedItem;
  final ValueChanged<T?> onChanged;

  MyDropdownWidget({
    Key? key,
    required this.leadingText,
    required this.trailingText,
    required this.items,
    required this.selectedItem,
    required this.onChanged,
  }) : super(key: key);

  @override
  _MyDropdownWidgetState<T> createState() => _MyDropdownWidgetState<T>();
}

class _MyDropdownWidgetState<T> extends State<MyDropdownWidget<T>> {
  late T _selectedItem;

  @override
  void initState() {
    super.initState();
    _selectedItem = widget.selectedItem;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Tooltip(
          message: 'Leading Text',
          child: Text(
            widget.leadingText,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontFamily: 'Sriracha',
              fontSize: 16,
              shadows: CustomTextShadow.shadows, // Makes the text very bold
            ),
          ),
        ),
        Tooltip(
          message: 'Dropdown Menu',
          child: Container(
            height: 35,
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Adjust padding as needed
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border.all(color: Colors.black, width: 2), // Border color and width
              borderRadius: BorderRadius.circular(15), // Border radius
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                canvasColor: Colors.grey[100], // This changes the dropdown menu background color
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<T>(
                  value: _selectedItem,
                  onChanged: (T? newValue) {
                    if (mounted) {
                      setState(() {
                        _selectedItem = newValue!;
                        widget.onChanged(_selectedItem);
                      });
                    }
                  },
                  iconEnabledColor: Colors.black, // Change the arrow icon color
                  items: widget.items.map<DropdownMenuItem<T>>((T value) {
                    return DropdownMenuItem<T>(
                      value: value,
                      // This changes the text color of the dropdown items
                      child: Text(
                        value.toString(),
                        style: TextStyle(color: Colors.black), // Item text color
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
        Tooltip(
          message: 'Trailing Text',
          child: Text(
            widget.trailingText,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontFamily: 'Sriracha',
              fontSize: 16,
              shadows: CustomTextShadow.shadows, // Makes the text very bold
            ),
            softWrap: true,
            overflow: TextOverflow.clip,
          ),
        ),
      ],
    );
  }
}

/*--------------------------------------------------------------------------------MyDropdownWidget*/
/*--------------------------------------------------------------------------------TimePickerWidget*/

class TimePickerWidget extends StatefulWidget {
  final Function(TimeOfDay) onTimeSelected;

  const TimePickerWidget({Key? key, required this.onTimeSelected}) : super(key: key);

  @override
  _TimePickerWidgetState createState() => _TimePickerWidgetState();
}

class _TimePickerWidgetState extends State<TimePickerWidget> {
  TimeOfDay? _selectedTime;

  Future<void> _selectTime(BuildContext context) async {
    final ThemeData themeData = ThemeData(
      timePickerTheme: TimePickerThemeData(
        dialHandColor: Colors.grey, // Color of the arrow
        dialTextColor: Colors.black, // Numbers color
        dialBackgroundColor: Colors.white, // Background color of the clock
        dayPeriodTextColor: Colors.black, // AM/PM text color
        hourMinuteTextColor: Color(0xFF000000), // Hour and minute text color
        entryModeIconColor: Colors.black,
        backgroundColor: Colors.grey[200],
        cancelButtonStyle: TextButton.styleFrom(
          backgroundColor: Colors.black, // Button background color
          foregroundColor: Colors.white, // Text color
          textStyle: TextStyle(fontFamily: 'Sriracha')
        ),
        dayPeriodColor: Colors.grey,
        confirmButtonStyle: TextButton.styleFrom(
          backgroundColor: Colors.black, // Button background color
          foregroundColor: Colors.white, // Text color
          textStyle: TextStyle(fontFamily: 'Sriracha')
        ),
        helpTextStyle: TextStyle(color: Colors.black, fontSize: 18, fontFamily: 'Sriracha'), // Set "Select time" text to white
      ),
      colorScheme: ColorScheme.light(
        primary: Colors.grey, // This will affect the selection color indirectly
      ),
    );

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: themeData,
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      if(mounted){
        setState(() {
        _selectedTime = picked;
      });
      }
      widget.onTimeSelected(picked); // Call the callback with the selected time
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Tooltip(
            message: 'Select or change the time',
            child: ElevatedButton(
              onPressed: () => _selectTime(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[100], // Button background color
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min, // To keep the row as small as possible
                children: [
                  Icon(Icons.alarm, color: Colors.black), // Alarm icon with white color
                  SizedBox(width: 8), // Space between icon and text
                  Text(
                    _selectedTime == null ? 'Select Time' : 'Change Time',
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_selectedTime != null)
          Center(
            child: Column(
              children: [
                Tooltip(
                  message: 'Selected time',
                  child: Text(
                    'Selected Time: ${_selectedTime!.format(context)}',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      shadows: CustomTextShadow.shadows,
                    ), // Text color changed to white
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/*--------------------------------------------------------------------------------TimePickerWidget*/
/*--------------------------------------------------------------------------------Firestore handling*/


Future<bool> checkCollectionDoesNotExistOrIsEmpty(String name) async {
  FirebaseAuth auth = FirebaseAuth.instance;
  final User? user = auth.currentUser;
  final userId = user?.uid;
  FirestoreService firestoreService = FirestoreService();
  List<String> habitNames = await firestoreService.getHabitNames(userId!);
  if (habitNames.contains(name)) {
    return false;
  }
  return true;
}

Future<String> validateHabitForm (String name, String method, TimeOfDay? time, String timer, List<String>? partners, int iterval) async {
  if (name.isEmpty) {
    return Future.value("The habit name cannot be empty.");
  }

  bool doesNotExistOrIsEmpty = await checkCollectionDoesNotExistOrIsEmpty(name);
  if (!doesNotExistOrIsEmpty) {
    return Future.value("The habit name already exists.");
  }
  if(partners != null) {
    bool doesNotExistOrIsEmpty = await checkPartnerHabitDoesNotExistOrIsEmpty(partners, name);
    if (!doesNotExistOrIsEmpty) {
      return Future.value("The habit name already exists for a partner.");
    }
  }

  int m_timer;

  try {
    if(method == 'Timer') {
      m_timer = int.parse(timer);
      if(m_timer == 0) {
        return Future.value("The timer cannot be 0.");
      }
      if(m_timer > 240)
        return Future.value("The timer cannot be greater than 240.");
    }
  }
  catch (e) {
    return Future.value("The timer value must be a number.");
  }

  if (time == null) {
    return Future.value("The reminder time must be selected.");
  }
  else if (method == 'Multiple Confirmation') {
    if(iterval == 3 && time.hour == 23 && time.minute >= 38) {
      return Future.value("The reminder must be earlier.");
    }
    if(iterval == 5 && time.hour == 23 && time.minute >= 30) {
      return Future.value("The reminder must be earlier.");
    }
    if(iterval == 10 && time.hour == 23 && time.minute >= 10) {
      return Future.value("The reminder must be earlier.");
    }
  }

  return Future.value("true");
}

Future<void> addHabit_toCloud(String name, String description, String method, TimeOfDay time, int goal,
int interval, String timer, List<String>? partner) async {
  try {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;
    final userId = user?.uid; // Directly use uid without converting to string here

    if (userId == null) {
      throw Exception("User not logged in");
    }

    FirebaseFirestore db = FirebaseFirestore.instance;

    // Ensure the user document exists
    DocumentReference userDoc = db.collection('Users').doc(userId);
    final userDocSnapshot = await userDoc.get();
    if (!userDocSnapshot.exists) {
      await userDoc.set({'created_at': Timestamp.now()}); // Example of setting initial data
    }

    Map<String, int> Reminder_info = {'hour': time.hour, 'minute': time.minute};
    Map<String, dynamic> Habit_info;
    if(partner == null) Habit_info = {"name": name, "description": description, "method": method};
    else Habit_info = {"name": name, "description": description, "method": method, "partner": partner, "active": 0, "request": 'from'};
    Map<String, dynamic> Method_info;


    // Your existing logic for Method_info...
    if(method == 'Timer') {
    Method_info = {
      "week_goal": goal,
      "week_curr": 0,
      "timer_val": int.parse(timer),
      "streak": 0,
      "done_today" : 0,
      "habit_points": 0,
    };
  } else if(method == 'Multiple Confirmation') {
    Method_info = {
      "week_goal": goal,
      "week_curr": 0,
      "interval": interval,
      "streak": 0,
      "done_today" : 0,
      "habit_points": 0,
    };
  } else {
    Method_info = {
      "week_goal": goal,
      "week_curr": 0,
      "streak": 0,
      "done_today" : 0,
      "habit_points": 0,
    };
  }

    CollectionReference habitCollection;
    if(partner == null) habitCollection = userDoc.collection('Habit_$name');
    else habitCollection = userDoc.collection('SharedHabit_$name');
    await habitCollection.doc('Habit_info').set(Habit_info);
    await habitCollection.doc('Method_info').set(Method_info);
    await habitCollection.doc('Reminder_info').set(Reminder_info);


    FirestoreService firestoreService = FirestoreService();
    await firestoreService.addHabitName(userId, name);
    List<String> local_partners = List.from(partner ?? []);
    if(partner != null) {
      for(String ptr in local_partners) {
        print('ptr: $ptr');
        await addHabitToPartner(name, description, method, time, goal, interval, timer, ptr, partner);
      }
    }

  } catch (e) {
    print("Error adding habit to cloud: $e");
    // Handle the error appropriately
  }
}
Future<void> addchallenge_toCloud(
  String name,
  String description,
  String method,
  TimeOfDay time,
  int goal,
  int interval,
  String timer,
  List<String>? partners, // Change partner to List<String>?
) async {
  try {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;
    final userId =
        user?.uid; // Directly use uid without converting to string here

    if (userId == null) {
      throw Exception("User not logged in");
    }

    FirebaseFirestore db = FirebaseFirestore.instance;

    // Ensure the user document exists
    DocumentReference userDoc = db.collection('Users').doc(userId);
    final userDocSnapshot = await userDoc.get();
    if (!userDocSnapshot.exists) {
      await userDoc.set(
          {'created_at': Timestamp.now()}); // Example of setting initial data
    }

    Map<String, int> Reminder_info = {'hour': time.hour, 'minute': time.minute};
    Map<String, dynamic> Habit_info = {
      "name": name,
      "description": description,
      "method": method,
    };

    if (partners != null && partners.isNotEmpty) {
      Habit_info["active"] = 'false';
      Habit_info["request"] = 'from';
    }

    Map<String, dynamic> Method_info;

    // Your existing logic for Method_info...
    if (method == 'Timer') {
      Method_info = {
        "week_goal": goal,
        "week_curr": 0,
        "timer_val": int.parse(timer),
        "streak": 0,
        "done_today": 0,
        "habit_points": 0,
      };
    } else if (method == 'Multiple Confirmation') {
      Method_info = {
        "week_goal": goal,
        "week_curr": 0,
        "curr_conf_num": 0,
        "interval": interval,
        "streak": 0,
        "done_today": 0,
        "habit_points": 0,
      };
    } else {
      Method_info = {
        "week_goal": goal,
        "week_curr": 0,
        "streak": 0,
        "done_today": 0,
        "habit_points": 0,
      };
    }

    // Save habit info to the user's collection
    CollectionReference habitCollection = userDoc.collection('challenge_$name');
    await habitCollection.doc('Habit_info').set(Habit_info);
    await habitCollection.doc('Method_info').set(Method_info);
    await habitCollection.doc('Reminder_info').set(Reminder_info);

    // Save habit info to each partner's collection
    if (partners != null) {
      for (String partner in partners) {
        await addHabitTochallenger(
            name, description, method, time, goal, interval, timer, partner);
      }
    }

    FirestoreService firestoreService = FirestoreService();
    await firestoreService.addHabitName(userId, name);
  } catch (e) {
    print("Error adding habit to cloud: $e");
    // Handle the error appropriately
  }
}


/////////////////////////////////////////////////////////////////////////// share habit

class UserCard_forShare {
  final String username;
  final String photoUrl;
  final String rank;
  final int topstreak;

  UserCard_forShare({
    required this.username,
    required this.photoUrl,
    required this.rank,
    required this.topstreak,
  });
}

Future<List<String>?> choosePartners(BuildContext context) async {
  List<UserCard_forShare> friendsList = await fetchFriendsList();
  Set<String> selectedFriends = {};

  return showDialog<List<String>>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: Tooltip(
              message: 'Dialog Title',
              child: Text('Choose partners'),
            ),
            content: Container(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: friendsList.length,
                itemBuilder: (BuildContext context, int index) {
                  bool isSelected = selectedFriends.contains(friendsList[index].username);
                  return Tooltip(
                    message: 'Tap to select or deselect ${friendsList[index].username}',
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(friendsList[index].photoUrl),
                      ),
                      title: Text(friendsList[index].username),
                      trailing: isSelected ? Icon(Icons.check, color: Colors.green) : null,
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedFriends.remove(friendsList[index].username);
                          } else {
                            selectedFriends.add(friendsList[index].username);
                          }
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            actions: <Widget>[
              Tooltip(
                message: 'Cancel selection',
                child: TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              Tooltip(
                message: 'Confirm selection',
                child: TextButton(
                  child: Text('Done'),
                  onPressed: () {
                    Navigator.pop(context, selectedFriends.toList());
                  },
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<List<UserCard_forShare>> fetchFriendsList() async {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;
  String _currentUserId = user?.uid ?? ""; // Use the current user's UID
  List<UserCard_forShare> friendsList = [];

  if (_currentUserId.isNotEmpty) {
    DocumentSnapshot<Map<String, dynamic>> userSnapshot =
        await _firestore.collection('Users').doc(_currentUserId).get();

    if (userSnapshot.exists) {
      List<String> friendsIds =
          List<String>.from(userSnapshot.data()!['friends']);

      if (friendsIds.isNotEmpty) {
        QuerySnapshot<Map<String, dynamic>> friendsSnapshot = await _firestore
            .collection('Users')
            .where("username", whereIn: friendsIds)
            .get();

        friendsList = friendsSnapshot.docs
            .map((friend) => UserCard_forShare(
                  username: friend.data()['username'],
                  photoUrl: friend.data()['imageurl'],
                  rank: friend.data()['rank'],
                  topstreak: friend.data()['top_streak'],
                ))
            .toList();
      }
    }
  }
  return friendsList;
}

Future<String> fetchFriendUserId(String username) async {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;
  String _currentUserId = user?.uid ?? ""; // Use the current user's UID

  if (_currentUserId.isNotEmpty) {
    QuerySnapshot<Map<String, dynamic>> userSnapshot = await _firestore
        .collection('Users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      return userSnapshot.docs.first.id;
    }
  }
  return ""; // Return an empty string if no user is found or if the current user is not authenticated
}
Future<void> addHabitToPartner(String name, String description, String method, TimeOfDay time, int goal,
int interval, String timer, String partnerUsername, List<String> partners) async {
  print('111 partnerUsername: $partnerUsername');
  print('222 partners: $partners');
  try {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;
    final userId = user?.uid;

    if (userId == null) {
      throw Exception("User not logged in");
    }

    FirebaseFirestore db = FirebaseFirestore.instance;

    // Fetch the current user's username
    DocumentReference userDoc = db.collection('Users').doc(userId);
    final userDocSnapshot = await userDoc.get();
    if (!userDocSnapshot.exists) {
      throw Exception("Current user document does not exist");
    }
    final currentUsername = userDocSnapshot.get('username');
    partners.add(currentUsername);
    createNotification('You have a new habit request from ${currentUsername}', name, partnerUsername);

    // Fetch the partner's user ID using the partner's username
    QuerySnapshot partnerSnapshot = await db.collection('Users')
        .where('username', isEqualTo: partnerUsername)
        .limit(1)
        .get();

    if (partnerSnapshot.docs.isEmpty) {
      throw Exception("Partner user not found");
    }
    final partnerUserId = partnerSnapshot.docs.first.id;

    if (partnerUserId.isEmpty) {
      throw Exception("Partner user ID is empty");
    }


    // Ensure the partner's user document exists
    DocumentReference partnerDoc = db.collection('Users').doc(partnerUserId);
    final partnerDocSnapshot = await partnerDoc.get();
    if (!partnerDocSnapshot.exists) {
      await partnerDoc.set({'created_at': Timestamp.now()}); // Example of setting initial data
    }
    partners.remove(partnerUsername);
    print('partners: $partners');
    Map<String, int> Reminder_info = {'hour': time.hour, 'minute': time.minute};
    Map<String, dynamic> Habit_info = {
      "name": name,
      "description": description,
      "method": method,
      "partner": partners,
      "active": 0,
      "request": 'to'
    };
    Map<String, dynamic> Method_info;

    // Your existing logic for Method_info...
    if (method == 'Timer') {
      Method_info = {
        "week_goal": goal,
        "week_curr": 0,
        "timer_val": int.parse(timer),
        "streak": 0,
        "done_today": 0,
        "habit_points": 0,
      };
    } else if (method == 'Multiple Confirmation') {
      Method_info = {
        "week_goal": goal,
        "week_curr": 0,
        "interval": interval,
        "streak": 0,
        "done_today": 0,
        "habit_points": 0,
      };
    } else {
      Method_info = {
        "week_goal": goal,
        "week_curr": 0,
        "streak": 0,
        "done_today": 0,
        "habit_points": 0,
      };
    }

    CollectionReference habitCollection = partnerDoc.collection('SharedHabit_$name');
    await habitCollection.doc('Habit_info').set(Habit_info);
    await habitCollection.doc('Method_info').set(Method_info);
    await habitCollection.doc('Reminder_info').set(Reminder_info);

    FirestoreService firestoreService = FirestoreService();
    await firestoreService.addHabitName(partnerUserId, name);

    partners.add(partnerUsername);
    partners.remove(currentUsername);

  } catch (e) {
    print("Error adding habit to partner: $e");
    // Handle the error appropriately
  }
}

Future<bool> checkPartnerHabitDoesNotExistOrIsEmpty(List<String> partnersUsername, String habitName) async {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final User? user = auth.currentUser;
  final userId = user?.uid;

  if (userId == null) {
    throw Exception("User not logged in");
  }

  FirebaseFirestore db = FirebaseFirestore.instance;

  // Fetch the partner's user ID using the partner's username
  for (String partnerUsername in partnersUsername) {  
    QuerySnapshot partnerSnapshot = await db.collection('Users')
        .where('username', isEqualTo: partnerUsername)
        .limit(1)
        .get();

    if (partnerSnapshot.docs.isEmpty) {
      throw Exception("Partner user not found");
    }
    final partnerUserId = partnerSnapshot.docs.first.id;

    if (partnerUserId.isEmpty) {
      throw Exception("Partner user ID is empty");
    }

    // Fetch the partner's habit names
    DocumentReference partnerDoc = db.collection('Users').doc(partnerUserId);
    final partnerDocSnapshot = await partnerDoc.get();
    if (!partnerDocSnapshot.exists) {
      throw Exception("Partner user document does not exist");
    }

  //List<String> habitNames = List<String>.from(partnerDocSnapshot.get('habitNames') ?? []);
    List<String> habitNames;
    final data = partnerDocSnapshot.data();
    if (data != null && (data as Map<String, dynamic>).containsKey('habitNames')) {
      habitNames = List<String>.from(data['habitNames']);
    } else {
      continue;
    }

    if (habitNames.contains(habitName)) {
      return false;
    }
  }
  return true;
}

Future<void> addHabitTochallenger(String name, String description, String method, TimeOfDay time, int goal,
int interval, String timer, String partnerUsername) async {
  try {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;
    final userId = user?.uid;

    if (userId == null) {
      throw Exception("User not logged in");
    }

    FirebaseFirestore db = FirebaseFirestore.instance;

    // Fetch the current user's username
    DocumentReference userDoc = db.collection('Users').doc(userId);
    final userDocSnapshot = await userDoc.get();
    if (!userDocSnapshot.exists) {
      throw Exception("Current user document does not exist");
    }
    final currentUsername = userDocSnapshot.get('username');

    // Fetch the partner's user ID using the partner's username
    QuerySnapshot partnerSnapshot = await db.collection('Users')
        .where('username', isEqualTo: partnerUsername)
        .limit(1)
        .get();

    if (partnerSnapshot.docs.isEmpty) {
      throw Exception("Partner user not found");
    }
    final partnerUserId = partnerSnapshot.docs.first.id;

    if (partnerUserId.isEmpty) {
      throw Exception("Partner user ID is empty");
    }

    // Ensure the partner's user document exists
    DocumentReference partnerDoc = db.collection('Users').doc(partnerUserId);
    final partnerDocSnapshot = await partnerDoc.get();
    if (!partnerDocSnapshot.exists) {
      await partnerDoc.set({'created_at': Timestamp.now()}); // Example of setting initial data
    }

    Map<String, int> Reminder_info = {'hour': time.hour, 'minute': time.minute};
    Map<String, dynamic> Habit_info = {
      "name": name,
      "description": description,
      "method": method,
      "partner": currentUsername,
      "active": 'false',
      "request": 'to'
    };
    Map<String, dynamic> Method_info;

    // Your existing logic for Method_info...
    if (method == 'Timer') {
      Method_info = {
        "week_goal": goal,
        "week_curr": 0,
        "timer_val": int.parse(timer),
        "streak": 0,
        "done_today": 0,
        "habit_points": 0,
      };
    } else if (method == 'Multiple Confirmation') {
      Method_info = {
        "week_goal": goal,
        "week_curr": 0,
        "curr_conf_num": 0,
        "interval": interval,
        "streak": 0,
        "done_today": 0,
        "habit_points": 0,
      };
    } else {
      Method_info = {
        "week_goal": goal,
        "week_curr": 0,
        "streak": 0,
        "done_today": 0,
        "habit_points": 0,
      };
    }

    CollectionReference habitCollection = partnerDoc.collection('challenge_$name');
    await habitCollection.doc('Habit_info').set(Habit_info);
    await habitCollection.doc('Method_info').set(Method_info);
    await habitCollection.doc('Reminder_info').set(Reminder_info);

    FirestoreService firestoreService = FirestoreService();
    await firestoreService.addHabitName(partnerUserId, name);

  } catch (e) {
    print("Error adding habit to partner: $e");
    // Handle the error appropriately
  }
}