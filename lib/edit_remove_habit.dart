import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_help_functions.dart';
import 'add_habit_widgets.dart';
import 'package:habit_hero/text_shdows.dart';
import 'shared_firebase_help.dart';
import 'firebase_help_functions.dart';
import 'notify_func.dart';
import 'muli_confirm.dart';

Future<bool> removeHabit(BuildContext context, String name) async {
  bool isRemoving = false;
  bool isDialogPopped = false;
  bool is_removed = false;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder( // Use StatefulBuilder to manage local state
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white, // Set the background color of the AlertDialog
            // shape: RoundedRectangleBorder(
            //   borderRadius: BorderRadius.circular(5),
            // ),
            contentPadding: EdgeInsets.all(30.0),
            title: Tooltip(
              message: 'Dialog title',
              child: Text(
                'Remove Habit',
                style: TextStyle(color: Colors.black), // Set the title text color to white
              ),
            ),
            content: Tooltip(
              message: 'Dialog content',
              child: Text(
                'Are you sure you want to remove $name from your habits list?',
                style: TextStyle(color: Colors.black), // Set the content text color to white
              ),
            ),
            actions: <Widget>[
              Tooltip(
                message: 'No button',
                child: TextButton(
                  child: Text('No'),
                  onPressed: isRemoving ? null : () { // Disable button if isRemoving is true
                    if (!isDialogPopped) { // Check if the dialog has not been popped yet
                      isDialogPopped = true; // Mark the dialog as popped
                      Navigator.of(context).pop(false); // Pop the dialog and return false
                    }
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all<Color>(Colors.white),
                    foregroundColor: WidgetStateProperty.all<Color>(Colors.black),
                    // shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    //   RoundedRectangleBorder(
                    //     borderRadius: BorderRadius.circular(5),
                    //   ),
                    // ),
                  ),
                ),
              ),
              Tooltip(
                message: 'Yes button',
                child: TextButton(
                  child: Text('Yes'),
                  onPressed: isRemoving ? null : () async { // Disable button if isRemoving is true
                    setState(() {
                      isRemoving = true; // Disable both buttons
                    });

                    is_removed = true;
                    final FirebaseAuth auth = FirebaseAuth.instance;
                    final User? user = auth.currentUser;
                    final String? userId = user?.uid;

                    var HabitInfoDoc = await getHabitInfoDoc(userId!, name);
                    if (HabitInfoDoc['partner'] != null) {
                      for (String ptr in HabitInfoDoc['partner']) {
                        delete_partners_habit(name, ptr);
                      }
                    }
                    await removeHabit_fromCloud(name);
                    if (staticValues_MultiConf.habitName == name) {
                      staticValues_MultiConf.habitName = '';
                      staticValues_MultiConf.conf_num = 0;
                    }
                    if (HabitInfoDoc['partner'] != null) {
                      var username = await getUserName();
                      for (String ptr in HabitInfoDoc['partner']) {
                        createNotification('Your shared habit $name has been removed by ${username}', name, ptr);
                      }
                    }

                    if (!isDialogPopped) { // Check if the dialog has not been popped yet
                      isDialogPopped = true; // Mark the dialog as popped
                      Navigator.of(context).pop(true); // Pop the dialog and return true
                    }
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all<Color>(Colors.red),
                    foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
                    // shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    //   RoundedRectangleBorder(
                    //     borderRadius: BorderRadius.circular(5),
                    //   ),
                    // ),
                  ),
                ),
              ),
            ],
          );
        }
      );
    },
  );
  return is_removed; // Return true if "Yes" was pressed, otherwise false
}


class EditHabitWidget extends StatefulWidget {
  final String name;
  const EditHabitWidget({Key? key, required this.name}) : super(key: key);

  

  @override
  _EditHabitWidgetState createState() => _EditHabitWidgetState();
}

class _EditHabitWidgetState extends State<EditHabitWidget> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  late TextEditingController _habitDescriptionController = TextEditingController();
  late int _selectedItemInt = 1;
  Map<String, dynamic> habitInfo = {};
  Map<String, dynamic> methodInfo = {};
  Map<String, dynamic> reminderInfo = {};
  TimeOfDay? _selectedTime = null;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  Future<void> initializeData() async {
    final User? user = auth.currentUser;
    final String? userId = user?.uid;

    if (userId == null) {
      throw Exception("User not logged in");
    }
    FirestoreService _firestoreService = FirestoreService();
    habitInfo = await _firestoreService.getHabitInfo(userId, widget.name);
    methodInfo = await _firestoreService.getMethodInfo(userId, widget.name);
    reminderInfo = await _firestoreService.getReminderInfo(userId, widget.name);
    if(mounted){
      setState(() {
      _habitDescriptionController = TextEditingController(text: habitInfo['description']);
      _selectedItemInt = methodInfo['week_goal'];
      _isLoading = false;
    });
    }

  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('app_images/app_wallpaper.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: AlertDialog(
        title: Tooltip(
          message: 'Dialog title',
          child: Text('Edit Habit', style: TextStyle(color: Colors.blue[800])),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Tooltip(
                  message: 'Edit description label',
                  child: Text(
                    'Edit the description of your habit:',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Sriracha',
                      fontSize: 18,
                      shadows: CustomTextShadow.shadows,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Tooltip(
                message: 'Description input field',
                child: TextFormField(
                  controller: _habitDescriptionController,
                  style: TextStyle(color: Colors.blue[800]),
                  cursorColor: Colors.blue[800],
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.blue[50],
                    hintText: 'Enter Habit Description',
                    hintStyle: TextStyle(color: Colors.blue[800]),
                    prefixIcon: Icon(Icons.description, color: Colors.blue[800]),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.blue.shade800,
                        width: 1.0,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.blue.shade800,
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFF1565C0),
                        width: 1.0,
                      ),
                    ),
                  ),
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  minLines: 1,
                ),
              ),
              const SizedBox(height: 20),
              (habitInfo['partner'] != null)
                  ? Container()
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: _isLoading
                          ? Tooltip(
                              message: 'Loading indicator',
                              child: CircularProgressIndicator(color: Colors.blue[800]),
                            )
                          : Tooltip(
                              message: 'Dropdown for new weekly goal',
                              child: MyDropdownWidget<int>(
                                leadingText: 'New weekly goal: ',
                                trailingText: '',
                                items: List.generate(7, (index) => index + 1),
                                selectedItem: _selectedItemInt,
                                onChanged: (newValue) {
                                  if (mounted) {
                                    setState(() {
                                      _selectedItemInt = newValue!;
                                    });
                                  }
                                },
                              ),
                            ),
                    ),
              const SizedBox(height: 20),
              (habitInfo['method'] != 'Multiple Confirmation')
                  ? Tooltip(
                      message: 'Time picker widget',
                      child: TimePickerWidget(
                        onTimeSelected: (TimeOfDay time) {
                          _selectedTime = time;
                        },
                      ),
                    )
                  : Container(),
              (habitInfo['method'] != 'Multiple Confirmation') ? const SizedBox(height: 10) : Container(),
              (habitInfo['method'] != 'Multiple Confirmation')
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Tooltip(
                        message: 'Old reminder time',
                        child: Text(
                          'Your old reminder time was ${reminderInfo['hour'].toString().padLeft(2, '0')}:${reminderInfo['minute'].toString().padLeft(2, '0')}.',
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Sriracha',
                            fontSize: 18,
                            shadows: CustomTextShadow.shadows,
                          ),
                        ),
                      ),
                    )
                  : Container(),
            ],
          ),
        ),
        actions: <Widget>[
          Tooltip(
            message: 'Cancel button',
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('Cancel', style: TextStyle(color: Colors.blue[800])),
            ),
          ),
          Tooltip(
            message: 'Save button',
            child: TextButton(
              onPressed: () async {
                if (_selectedTime == null) {
                  _selectedTime = TimeOfDay(hour: reminderInfo['hour'], minute: reminderInfo['minute']);
                }
                await editHabit_inCloud(widget.name, _habitDescriptionController.text, _selectedTime!, _selectedItemInt);
                Navigator.of(context).pop(true);
              },
              child: Text('Save', style: TextStyle(color: Colors.blue[800])),
            ),
          ),
        ],
      ),
    );
  }
}