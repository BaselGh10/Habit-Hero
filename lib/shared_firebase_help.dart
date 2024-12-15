import 'firebase_help_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<String> getPartnerId(String partner) async {
  final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;
    final userId = user?.uid;

    if (userId == null) {
      throw Exception("User not logged in");
    }

    FirebaseFirestore db = FirebaseFirestore.instance;

    // Fetch the partner's user ID using the partner's username
    QuerySnapshot partnerSnapshot = await db.collection('Users')
        .where('username', isEqualTo: partner)
        .limit(1)
        .get();

    if (partnerSnapshot.docs.isEmpty) {
      throw Exception("Partner user not found");
    }
    return partnerSnapshot.docs.first.id;
}

void delete_partners_habit(String habitName, String partner) async {
  try {
    
    final partnerUserId = await getPartnerId(partner);
    //Future<void> removeHabitName(String userId, String habitName)
    //Future<void> removeHabit_fromCloud(String name, [String? userId])
    await removeHabit_fromCloud(habitName, partnerUserId);
  }
  catch (e) {
    print("Error deleting partner's habit: $e");
  }
}

void editactive_all(String habitName, List<String> partners) async {
  try {
    for(String partnerName in partners){
      final partnerUserId = await getPartnerId(partnerName);
      await editactive(habitName, partnerUserId);
    }
    await editactive(habitName);
  }
  catch (e) {
    print("Error editing active for both users: $e");
  }
}

Future<void> edit_request_state(String habitName, [String? userId]) async {
  try {

    if (userId == null) {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final User? user = auth.currentUser;
      userId = user?.uid;
    }

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

   // Access the specific habit's Method_info document
  //Map<String, dynamic> methodInfoData = await getMethodInfoDoc(userId, habitName);

  // Update the done_today field
  await FirebaseFirestore.instance
      .collection('Users')
      .doc(userId)
      .collection('SharedHabit_$habitName')
      .doc('Habit_info')
      .update({
        "request": "from",
      });

  } catch (e) {
    print("Error editing request in cloud: $e");
    // Handle the error appropriately
  }
}

Future<void> editactive(String habitName, [String? userId]) async {
  try {

    if (userId == null) {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final User? user = auth.currentUser;
      userId = user?.uid;
    }

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

   // Access the specific habit's Method_info document
  //Map<String, dynamic> methodInfoData = await getMethodInfoDoc(userId, habitName);

  // Update the done_today field
  await FirebaseFirestore.instance
      .collection('Users')
      .doc(userId)
      .collection('SharedHabit_$habitName')
      .doc('Habit_info')
      .update({
        "active": FieldValue.increment(1),
      });

  } catch (e) {
    print("Error editing active in cloud: $e");
    // Handle the error appropriately
  }
}