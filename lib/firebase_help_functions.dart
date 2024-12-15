import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'shared_firebase_help.dart';
import 'notify_func.dart';
import 'muli_confirm.dart';
void updatechallenge(String name)async
{
  final FirebaseAuth auth = FirebaseAuth.instance;
  final User? user = auth.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    final   String userId = user!.uid;

    var challengeSnapshot = await FirebaseFirestore.instance
        .collection('challenges')
        .where('challengeName', isEqualTo: name)
        .get();
   var challengeDocs = challengeSnapshot.docs;

if(challengeDocs.isEmpty)
{
  return;
}
  if (challengeDocs.isNotEmpty && challengeDocs[0]['points'] != 0) {
 
  }
 
  CollectionReference habitCollection = await _firestore
      .collection('Users')
      .doc(userId)
      .collection('challenge_${name}');


       var pointscolee=  await _firestore
      .collection('Users')
      .doc(userId).get();
pointscolee.reference.update({'points': FieldValue.increment(75)});



  QuerySnapshot habitSnapshot = await habitCollection.get();
  int currd = await habitSnapshot.docs[1]['week_curr'];
CollectionReference recipCollection = await 
         challengeSnapshot.docs[0].reference.collection('recipients');


  int currw = await habitSnapshot.docs[1]['week_goal'];
  
  if (currd == currw) {
  challengeDocs[0].reference.update({
   // 'points': points1,
    'winners': FieldValue.arrayUnion([userId])
  });
  }
  var reciSnapshot = await challengeDocs[0].reference.get();
  Map<String, dynamic> reci = reciSnapshot['recipients'];
  reci.forEach((key, value) {
    if (key == userId) {
      value['curr_week'] =currd;
    }
  });
  var points1= await reciSnapshot['points']-75;
challengeDocs[0].reference.update({'recipients': reci});
challengeDocs[0].reference.update({'points': points1});

    
}
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Function to add a new habit name to the user's habitNames list
  Future<void> addHabitName(String userId, String habitName) async {
    DocumentReference userDoc = _db.collection('Users').doc(userId);

    return _db.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(userDoc);

      if (!snapshot.exists) {
        throw Exception("User document does not exist!");
      }

      List<dynamic> currentHabitNames = (snapshot.data() as Map<String, dynamic>)['habitNames']?.cast<dynamic>() ?? [];
      if (!currentHabitNames.contains(habitName)) {
        currentHabitNames.add(habitName);
        transaction.update(userDoc, {'habitNames': currentHabitNames});
      }
    });
  }

  // Function to remove a habit name from the user's habitNames list
  Future<void> removeHabitName(String userId, String habitName) async {
    DocumentReference userDoc = _db.collection('Users').doc(userId);

    return _db.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(userDoc);

      if (!snapshot.exists) {
        throw Exception("User document does not exist!");
      }

      List<dynamic> currentHabitNames = (snapshot.data() as Map<String, dynamic>)['habitNames']?.cast<dynamic>() ?? [];
      if (currentHabitNames.contains(habitName)) {
        currentHabitNames.remove(habitName);
        transaction.update(userDoc, {'habitNames': currentHabitNames});
      }
    });
  }

  // Function to get the list of all habit names for a user
  Future<List<String>> getHabitNames(String userId) async {
    DocumentReference userDoc = _db.collection('Users').doc(userId);

    DocumentSnapshot snapshot = await userDoc.get();
    List<dynamic> habitNames = (snapshot.data() as Map<String, dynamic>?)?['habitNames']?.cast<dynamic>() ?? [];
    return habitNames.cast<String>(); // Cast to List<String> before returning
  }

  // Function to get Habit_info for a specific habit
  Future<Map<String, dynamic>> getHabitInfo(String userId, String habitName) async {
    CollectionReference habitCollection = _db.collection('Users').doc(userId).collection('Habit_$habitName');
    DocumentSnapshot habitInfoDoc = await habitCollection.doc('Habit_info').get();

    if (habitInfoDoc.exists) {
      return habitInfoDoc.data() as Map<String, dynamic>;
    } else {
      habitCollection = _db.collection('Users').doc(userId).collection('SharedHabit_$habitName');
      habitInfoDoc = await habitCollection.doc('Habit_info').get();
      if (habitInfoDoc.exists) {
        return habitInfoDoc.data() as Map<String, dynamic>;
      } else {
        habitCollection = _db.collection('Users').doc(userId).collection('challenge_$habitName');
      habitInfoDoc = await habitCollection.doc('Habit_info').get();
      if (habitInfoDoc.exists) {
        return habitInfoDoc.data() as Map<String, dynamic>;}
        else{

        throw Exception("Habit_info document does not exist!");
      }
    }
  }
  }

  Future<Map<String, dynamic>> getMethodInfo(String userId, String habitName) async {
    CollectionReference habitCollection = _db.collection('Users').doc(userId).collection('Habit_$habitName');
    DocumentSnapshot habitInfoDoc = await habitCollection.doc('Method_info').get();

    if (habitInfoDoc.exists) {
      return habitInfoDoc.data() as Map<String, dynamic>;
    } else {
      habitCollection = _db.collection('Users').doc(userId).collection('SharedHabit_$habitName');
      habitInfoDoc = await habitCollection.doc('Method_info').get();
      if (habitInfoDoc.exists) {
        return habitInfoDoc.data() as Map<String, dynamic>;
      } else {
         habitCollection = _db
            .collection('Users')
            .doc(userId)
            .collection('challenge_$habitName');
        habitInfoDoc = await habitCollection.doc('Method_info').get();
        if (habitInfoDoc.exists) {
          return habitInfoDoc.data() as Map<String, dynamic>;
        }else
        throw Exception("Method_info document does not exist!");
      }
    }
  }

  Future<Map<String, dynamic>> getReminderInfo(String userId, String habitName) async {
    CollectionReference habitCollection = _db.collection('Users').doc(userId).collection('Habit_$habitName');
    DocumentSnapshot habitInfoDoc = await habitCollection.doc('Reminder_info').get();

    if (habitInfoDoc.exists) {
      return habitInfoDoc.data() as Map<String, dynamic>;
    } else {
      habitCollection = _db.collection('Users').doc(userId).collection('SharedHabit_$habitName');
      habitInfoDoc = await habitCollection.doc('Reminder_info').get();
      if (habitInfoDoc.exists) {
        return habitInfoDoc.data() as Map<String, dynamic>;
      } else {
        habitCollection = _db.collection('Users').doc(userId).collection('challenge_$habitName');
      habitInfoDoc = await habitCollection.doc('Reminder_info').get();
      if (habitInfoDoc.exists) {
        return habitInfoDoc.data() as Map<String, dynamic>;}
        else{
        throw Exception("Reminder_info document does not exist!");
      }}
    }
  }

}

Future<void> removeHabit_fromCloud(String name, [String? userId]) async {
  print('removing habit from cloud $name');
  if(staticValues_MultiConf.habitName == name) {staticValues_MultiConf.habitName = ''; staticValues_MultiConf.conf_num = 0;}
  try {
    if (userId == null) {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final User? user = auth.currentUser;
      userId = user?.uid;
    }

    if (userId == null) {
      throw Exception("User not logged in");
    }

    FirestoreService firestoreService = FirestoreService();
    await firestoreService.removeHabitName(userId, name);

    FirebaseFirestore db = FirebaseFirestore.instance;

    // Reference to the user's document
    DocumentReference userDoc = db.collection('Users').doc(userId);

    // Reference to the habit sub-collection
    CollectionReference habitCollection = userDoc.collection('Habit_$name');

    // Check if the Habit_$name collection exists
    QuerySnapshot habitCollectionSnapshot = await habitCollection.limit(1).get();

    if (habitCollectionSnapshot.docs.isEmpty) {
      // Habit_$name collection does not exist, check for SharedHabit_$name
      habitCollection = userDoc.collection('SharedHabit_$name');
      habitCollectionSnapshot = await habitCollection.limit(1).get();

      if (habitCollectionSnapshot.docs.isEmpty) {
        habitCollection = userDoc.collection('challenge_$name');
        habitCollectionSnapshot = await habitCollection.limit(1).get();
      }
    }

    // Retrieve all documents from the habit sub-collection
    habitCollectionSnapshot = await habitCollection.get();

    // Delete all documents within the habit sub-collection
    for (QueryDocumentSnapshot doc in habitCollectionSnapshot.docs) {
      await doc.reference.delete();
    }

    // Optionally, delete any other references or data related to this habit in other collections or documents

  } catch (e) {
    print("Error removing habit from cloud: $e");
    // Handle the error appropriately
  }
}

Future<void> editHabit_inCloud(String name, String newDescription, TimeOfDay newTime, int newGoal) async {
  try {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;
    final userId = user?.uid;

    if (userId == null) {
      throw Exception("User not logged in");
    }

    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference userDoc = db.collection('Users').doc(userId);
    CollectionReference habitCollection = userDoc.collection('Habit_$name');

    // Update Habit_info with new description
    await habitCollection.doc('Habit_info').update({
      "description": newDescription,
    });

    // Update Reminder_info with new time
    await habitCollection.doc('Reminder_info').update({
      "hour": newTime.hour,
      "minute": newTime.minute,
    });

    // Update Method_info with new goal
    await habitCollection.doc('Method_info').update({
      "week_goal": newGoal,
    });

  } catch (e) {
    print("Error editing habit in cloud: $e");
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;
    final userId = user?.uid;
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference userDoc = db.collection('Users').doc(userId);
    CollectionReference habitCollection = userDoc.collection('SharedHabit_$name');
    await habitCollection.doc('Habit_info').update({
      "description": newDescription,
    });
    List<String> partnerIds = await habitCollection.doc('Habit_info').get().then((doc) async {
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('partner')) {
          List<String> partnerList = List<String>.from(data['partner']);
          List<String> ids = [];
          for (String partner in partnerList) {
            ids.add(await getPartnerId(partner));
          }
          return ids;
        }
      }
      throw Exception('Partners not found');
    });

    for (String partnerId in partnerIds) {
      DocumentReference partnerDoc = db.collection('Users').doc(partnerId);
      CollectionReference habitCollection_forP = partnerDoc.collection('SharedHabit_$name');
      await habitCollection_forP.doc('Habit_info').update({
        "description": newDescription,
      });
    }
  }
}

Future<void> editDoneToday(String habitName, int doneToday) async {
  try {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;
    final userId = user?.uid;

    if (userId == null) {
      throw Exception("User not logged in");
    }

    FirebaseFirestore db = FirebaseFirestore.instance;

    // Check if the user document exists
    DocumentReference userDoc = db.collection('Users').doc(userId);
    final userDocSnapshot = await userDoc.get();
    if (!userDocSnapshot.exists) {
      throw Exception("User document does not exist");
    }

    // Access the specific habit's Method_info document data
  Map<String, dynamic> methodInfoData = await getMethodInfoDoc(userId, habitName);

  // Update the done_today field
  await FirebaseFirestore.instance
      .collection('Users')
      .doc(userId)
      .collection('Habit_$habitName')
      .doc('Method_info')
      .update({
        "done_today": doneToday,
      });

  } 
  catch (e) {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final User? user = auth.currentUser;
      final userId = user?.uid;

      if (userId == null) {
        throw Exception("User not logged in");
      }
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('SharedHabit_$habitName')
          .doc('Method_info')
          .update({
        "done_today": doneToday,
      });
    }
     catch (e) {
      try{
         final FirebaseAuth auth = FirebaseAuth.instance;
      final User? user = auth.currentUser;
      final userId = user?.uid;

           await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('challenge_$habitName')
          .doc('Method_info')
          .update({
        "done_today": doneToday,
      });
      updatechallenge(habitName);
    }
    catch (e) {
      print("Error editing done_today in SharedHabit_$habitName: $e");
      // Handle the error appropriately, e.g., show a message to the user
    }
  }
  }
  }

Future<Map<String, dynamic>> getMethodInfoDoc(String userId, String habitName) async {
  FirebaseFirestore db = FirebaseFirestore.instance;

  // Check if the Habit_$habitName collection exists
  CollectionReference habitCollection = db.collection('Users').doc(userId).collection('Habit_$habitName');
  QuerySnapshot habitSnapshot = await habitCollection.limit(1).get();

  if (habitSnapshot.docs.isNotEmpty) {
    // Habit_$habitName collection exists
    DocumentSnapshot methodInfoDoc = await habitCollection.doc('Method_info').get();
    return methodInfoDoc.data() as Map<String, dynamic>;
  } else {
    // Check if the SharedHabit_$habitName collection exists
    CollectionReference sharedHabitCollection = db.collection('Users').doc(userId).collection('SharedHabit_$habitName');
    QuerySnapshot sharedHabitSnapshot = await sharedHabitCollection.limit(1).get();

    if (sharedHabitSnapshot.docs.isNotEmpty) {
      // SharedHabit_$habitName collection exists
      DocumentSnapshot sharedMethodInfoDoc = await sharedHabitCollection.doc('Method_info').get();
      return sharedMethodInfoDoc.data() as Map<String, dynamic>;
    }   else
    {
       // Check if the SharedHabit_$habitName collection exists
    CollectionReference sharedHabitCollection = db.collection('Users').doc(userId).collection('challenge_$habitName');
    QuerySnapshot sharedHabitSnapshot = await sharedHabitCollection.limit(1).get();

    if (sharedHabitSnapshot.docs.isNotEmpty) {
      // SharedHabit_$habitName collection exists
      DocumentSnapshot sharedReminderInfoDoc = await sharedHabitCollection.doc('Method_info').get();
      return sharedReminderInfoDoc.data() as Map<String, dynamic>;
    }
    
     else {
      throw Exception("Neither Habit_$habitName nor SharedHabit_$habitName collections exist");
    }
  }
}}

Future<Map<String, dynamic>> getHabitInfoDoc(String userId, String habitName) async {
  FirebaseFirestore db = FirebaseFirestore.instance;

  // Check if the Habit_$habitName collection exists
  CollectionReference habitCollection = db.collection('Users').doc(userId).collection('Habit_$habitName');
  QuerySnapshot habitSnapshot = await habitCollection.limit(1).get();

  if (habitSnapshot.docs.isNotEmpty) {
    // Habit_$habitName collection exists
    DocumentSnapshot habitInfoDoc = await habitCollection.doc('Habit_info').get();
    return habitInfoDoc.data() as Map<String, dynamic>;
  } else {
    // Check if the SharedHabit_$habitName collection exists
    CollectionReference sharedHabitCollection = db.collection('Users').doc(userId).collection('SharedHabit_$habitName');
    QuerySnapshot sharedHabitSnapshot = await sharedHabitCollection.limit(1).get();

    if (sharedHabitSnapshot.docs.isNotEmpty) {
      // SharedHabit_$habitName collection exists
      DocumentSnapshot sharedHabitInfoDoc = await sharedHabitCollection.doc('Habit_info').get();
      return sharedHabitInfoDoc.data() as Map<String, dynamic>;
    }   else
    {
       // Check if the SharedHabit_$habitName collection exists
    CollectionReference sharedHabitCollection = db.collection('Users').doc(userId).collection('challenge_$habitName');
    QuerySnapshot sharedHabitSnapshot = await sharedHabitCollection.limit(1).get();

    if (sharedHabitSnapshot.docs.isNotEmpty) {
      // SharedHabit_$habitName collection exists
      DocumentSnapshot sharedReminderInfoDoc = await sharedHabitCollection.doc('Reminder_info').get();
      return sharedReminderInfoDoc.data() as Map<String, dynamic>;
    }
     
    else {
      throw Exception("Neither Habit_$habitName nor SharedHabit_$habitName collections exist");
    }
  }
}}

Future<Map<String, dynamic>> getReminderInfoDoc(String userId, String habitName) async {
  FirebaseFirestore db = FirebaseFirestore.instance;

  // Check if the Habit_$habitName collection exists
  CollectionReference habitCollection = db.collection('Users').doc(userId).collection('Habit_$habitName');
  QuerySnapshot habitSnapshot = await habitCollection.limit(1).get();

  if (habitSnapshot.docs.isNotEmpty) {
    // Habit_$habitName collection exists
    DocumentSnapshot reminderInfoDoc = await habitCollection.doc('Reminder_info').get();
    return reminderInfoDoc.data() as Map<String, dynamic>;
  } else {
    // Check if the SharedHabit_$habitName collection exists
    CollectionReference sharedHabitCollection = db.collection('Users').doc(userId).collection('SharedHabit_$habitName');
    QuerySnapshot sharedHabitSnapshot = await sharedHabitCollection.limit(1).get();

    if (sharedHabitSnapshot.docs.isNotEmpty) {
      // SharedHabit_$habitName collection exists
      DocumentSnapshot sharedReminderInfoDoc = await sharedHabitCollection.doc('Reminder_info').get();
      return sharedReminderInfoDoc.data() as Map<String, dynamic>;
    } 
    else
    {
       // Check if the SharedHabit_$habitName collection exists
    CollectionReference challengeHabitCollection = db.collection('Users').doc(userId).collection('challenge_$habitName');
    QuerySnapshot sharedHabitSnapshot = await challengeHabitCollection.limit(1).get();

    if (sharedHabitSnapshot.docs.isNotEmpty) {
      // SharedHabit_$habitName collection exists
      DocumentSnapshot sharedReminderInfoDoc = await challengeHabitCollection.doc('Reminder_info').get();
      return sharedReminderInfoDoc.data() as Map<String, dynamic>;
    }
    
    else {
      throw Exception("Neither Habit_$habitName nor SharedHabit_$habitName collections exist");
    }
  }
}
}

//This function will either reset the streak to 0 or increment it by 1 based on the parameter passed.
Future<void> editStreak(String habitName, bool reset, String? ptr) async {
  try {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;
    final userId = user?.uid;

    if (userId == null) {
      throw Exception("User not logged in");
    }

    Map<String, dynamic> methodInfoData = await getMethodInfoDoc(userId, habitName);
    if (reset) {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('Habit_$habitName')
          .doc('Method_info')
          .update({'streak': 0});
    } else {
      int currentStreak = methodInfoData['streak'] ?? 0;
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('Habit_$habitName')
          .doc('Method_info')
          .update({'streak': currentStreak + 1});
    }
  } catch (e) {
    print("Error editing streak: $e");
    try {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;
    final userId = user?.uid;

    if (userId == null) {
      throw Exception("User not logged in");
    }

    Map<String, dynamic> methodInfoData = await getMethodInfoDoc(userId, habitName);
    if (reset) {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('SharedHabit_$habitName')
          .doc('Method_info')
          .update({'streak': 0});
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('SharedHabit_$habitName')
          .doc('Habit_info')
          .get();
      Map<String, dynamic>? data = docSnapshot.data() as Map<String, dynamic>?;
      List<dynamic> partner = data?['partner'];
      for(String partner in partner) {
        String partner_id = await getPartnerId(partner);
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(partner_id)
            .collection('SharedHabit_$habitName')
            .doc('Method_info')
            .update({'streak': 0});
        var username= await getUserName();
        if(ptr == null) createNotification("$username has lost your habit's ($habitName) streak.", habitName, partner);
        else if(ptr != partner) createNotification("$ptr has lost your habit's ($habitName) streak.", habitName, partner);
        else createNotification("You lost your habit's ($habitName) streak.", habitName, partner);
      }
    } else {
      int currentStreak = methodInfoData['streak'] ?? 0;
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('SharedHabit_$habitName')
          .doc('Method_info')
          .update({'streak': currentStreak + 1});
    }
  } catch (e) {
    print("Error editing streak: $e");
    // Handle the error appropriately
  }
  }
}

//This function will either reset week_curr to 0 or increment it by 1 based on the parameter passed.
Future<void> editWeekCurr(String habitName, bool reset) async {
  try {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;
    final userId = user?.uid;

    if (userId == null) {
      throw Exception("User not logged in");
    }

    Map<String, dynamic> methodInfoData = await getMethodInfoDoc(userId, habitName);

    if (reset) {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('Habit_$habitName')
          .doc('Method_info')
          .update({'week_curr': 0});
    } else {
      int currentWeekCurr = methodInfoData['week_curr'] ?? 0;
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('Habit_$habitName')
          .doc('Method_info')
          .update({'week_curr': currentWeekCurr + 1});
    }
  } catch (e) {
    print("Error editing week_curr: $e");
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;
    final userId = user?.uid;

    if (userId == null) {
      throw Exception("User not logged in");
    }

    Map<String, dynamic> methodInfoData = await getMethodInfoDoc(userId, habitName);

    if (reset) {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('SharedHabit_$habitName')
          .doc('Method_info')
          .update({'week_curr': 0});
    } else {
      int currentWeekCurr = methodInfoData['week_curr'] ?? 0;
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('SharedHabit_$habitName')
          .doc('Method_info')
          .update({'week_curr': currentWeekCurr + 1});
    }
  }
}

Future<void> removeAllHabitsFromCloud() async {
  try {
    print('removing all habits from cloud');
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;
    final String? userId = user?.uid;

    if (userId == null) {
      throw Exception("User not logged in");
    }

    FirestoreService firestoreService = FirestoreService();
    List<String> habitNames = await firestoreService.getHabitNames(userId);

    for (String name in habitNames) {
      final habitInfoData = await getHabitInfoDoc(userId, name);
      List<dynamic>? partners = habitInfoData['partner'] ?? null;
      if (partners != null) {
        // Remove the habit from the partner's account as well
        for (String partner in partners) {
          print('partner to remove the habit from: $partner');
          delete_partners_habit(name, partner);
        }
      }
      await removeHabit_fromCloud(name);
    }
  } catch (e) {
    print("Error removing all habits from cloud: $e");
    // Handle the error appropriately
  }
}