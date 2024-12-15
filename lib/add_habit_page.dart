/*
Notes:
- This file contains the AddHabitPage widget, which is the page where users can add a new habit to track.
- Nadeen is working on this file.
todo:
- Make sure there is no duplicate code between this file and the main.dart file.
*/

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habit_hero/text_shdows.dart';
import 'add_habit_widgets.dart';
import 'chell/add_challenge.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';




Future<void> pushAddHabitPage(BuildContext context) async {
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) {
        return AddHabitPage();
      },
    ),
  );
}

/*--------------------------------------------------------------------------------AddHabitPage*/

class AddHabitPage extends StatefulWidget {
  @override
  _AddHabitPageState createState() => _AddHabitPageState();
}

class _AddHabitPageState extends State<AddHabitPage> {
  int _selectedItem_int = 1;
  String _m_selectedMethod = 'None';
  TimeOfDay? _selectedTime;
  bool _isLoading = false;
  int _habitInterval = 3;

  final TextEditingController _habitNameController = TextEditingController();
  final TextEditingController _habitDescriptionController =
      TextEditingController();
  final TextEditingController _habitTimeController = TextEditingController();

Future<void> _createChallenge() async {
  if(mounted){
    setState(() {
      _isLoading = true;
    });
  }

  // Fetch user points
  final userId = FirebaseAuth.instance.currentUser!.uid; // Replace with the current user's ID
  final userDoc = await FirebaseFirestore.instance.collection('Users').doc(userId).get();

  if (!userDoc.exists) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User not found.')),
    );
    if(mounted){
      setState(() {
        _isLoading = false;
      });
    }

    return;
  }

  final userPoints = userDoc.data()?['points'] ?? 0;

  // Check if user has at least 50 points
  if (userPoints < 50) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('You need at least 50 points to create a challenge.')),
    );
    if(mounted){
      setState(() {
        _isLoading = false;
      });
    }   
    return;
  }

  // Continue with the challenge creation
  List<String>? partner = await Choose_challenges(context);
  if (partner == null || partner.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No partner selected!')),
    );
    if(mounted){
      setState(() {
        _isLoading = false;
      });
    }

    return;
  }

  String validation = await validateHabitForm(
    _habitNameController.text,
    _m_selectedMethod,
    _selectedTime,
    _habitTimeController.text,
    null,
    _habitInterval,
  );

  if (validation != "true") {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(validation)),
    );
    if(mounted){
      setState(() {
        _isLoading = false;
      });
    }

    return;
  }

  TimeOfDay time = (_selectedTime == null)
      ? TimeOfDay(hour: 0, minute: 0)
      : _selectedTime!;

  await addchallenge_toCloud(
    _habitNameController.text,
    _habitDescriptionController.text,
    _m_selectedMethod,
    time,
    _selectedItem_int,
    _habitInterval,
    _habitTimeController.text,
    partner,
  );

  await createAndSendChallenge(
    context,
    _habitNameController.text,
    _habitDescriptionController.text,
    partner,
  );
  final points=userPoints-50;

  // Update user points
  await userDoc.reference.update({'points': points});




  
    
    userDoc.data()?['points']=userPoints-50;
    if(mounted){
      setState(() {
        _isLoading = false;
        Navigator.of(context).pop();
      });
    }
}

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    _habitNameController.dispose();
    _habitDescriptionController.dispose();
    _habitTimeController.dispose();
    super.dispose();
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
      child: Scaffold(
          //backgroundColor: Colors.blueGrey[200],
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor:
                Colors.transparent, // Set the AppBar background color
            elevation: 0, // Remove shadow
            leading: Tooltip(
              message: 'Go back', // Tooltip message
              child: IconButton(
                icon: CircleAvatar(
                  backgroundColor:
                      Colors.blue[800], // Background color of the circle
                  radius: 20, // Size of the circle
                  child: Icon(
                    Icons.arrow_back,
                    color: Colors.white, // Icon color
                    size: 24, // Icon size, adjust accordingly
                    shadows: CustomTextShadow.shadows,
                  ),
                ), // Left arrow icon, change color as needed
                onPressed: () {
                  Navigator.of(context)
                      .pop(); // Action to perform on press, typically to go back
                },
              ),
            ),
            /*title: Row(
              mainAxisAlignment: MainAxisAlignment.center, // Center row items horizontally
              children: <Widget>[
                BlurContainerWidget(
                  width: MediaQuery.of(context).size.width * 0.55,
                  height: 150,
                  borderRadius: BorderRadius.circular(10),
                  child: Center(
                    child: Text(
                      'New Habit',
                        style: TextStyle(
                          ///color: Colors.blue,
                          fontWeight: FontWeight.w900,
                          fontSize: 30,
                          color: Colors.blue[800],
                          shadows: CustomTextShadow.shadows,  // Ensure text color is set correctly for visibility
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 60,),
              ],
            ),*/
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12.0), // Adjust the horizontal padding as needed
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0, bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Color.fromARGB(199, 21, 101,
                        192), // Increase this value for more pronounced round angles
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.all(8), // Adjust padding as needed
                        decoration: BoxDecoration(
                          color: Color.fromARGB(194, 0, 0,
                              0), // Adjust the background color as needed
                          borderRadius: BorderRadius.circular(
                              10), // Adjust the border radius for round angles
                        ),
                        child: Text(
                          ' Create a New Habit!',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Sriracha',
                            fontSize: 22,
                            shadows: CustomTextShadow
                                .shadows, // Makes the text very bold
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '   Enter the new habit:',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Sriracha',
                            fontSize: 16,
                            shadows: CustomTextShadow
                                .shadows, // Makes the text very bold
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50), // Adjust the padding as needed
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            textSelectionTheme: TextSelectionThemeData(
                              selectionHandleColor: Colors.blue
                                  .shade800, // Set the color of the selection handle here
                            ),
                          ),
                          child: Form(
                            child: Column(
                              children: <Widget>[
                                Tooltip(
                                  message: 'Enter the habit name',
                                  child: TextFormField(
                                    controller: _habitNameController,
                                    style: TextStyle(color: Colors.black),
                                    cursorColor: Colors.black,
                                    decoration: InputDecoration(
                                      filled: true,
                                      hintText: 'Enter Habit Name',
                                      fillColor: Colors.grey[100],
                                      prefixIcon: Icon(Icons.task_alt,
                                          color: Colors.black),
                                      hintStyle: TextStyle(color: Colors.black),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors
                                              .black, // Specify the border color here
                                          width:
                                              1.0, // Specify the border width here
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors
                                              .white, // Original border color when the field is enabled
                                          width: 1.0,
                                        ),
                                      ),
                                      focusedBorder: const OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors
                                              .black, // Ensure the border color is blue when focused
                                          width:
                                              1.0, // Optional: You can change the width for focused state if you like
                                        ),
                                      ),
                                    ),
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(
                                          20), // Limit to 20 characters
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '   Describe your new habit (optional):',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Sriracha',
                            fontSize: 16,
                            shadows: CustomTextShadow
                                .shadows, // Makes the text very bold
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50), // Adjust the padding as needed
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            textSelectionTheme: TextSelectionThemeData(
                              selectionHandleColor: Colors.blue
                                  .shade800, // Set the color of the selection handle here
                            ),
                          ),
                          child: Form(
                            child: Column(
                              children: <Widget>[
                                Tooltip(
                                  message: 'Enter the habit description',
                                  child: TextFormField(
                                    controller: _habitDescriptionController,
                                    style: TextStyle(color: Colors.black),
                                    cursorColor: Colors.black,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      hintText: 'Enter Habit Description',
                                      hintStyle: TextStyle(color: Colors.black),
                                      prefixIcon: Icon(Icons.description,
                                          color: Colors.black),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors
                                              .black, // Specify the border color here
                                          width:
                                              1.0, // Specify the border width here
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors
                                              .white, // Original border color when the field is enabled
                                          width: 1.0,
                                        ),
                                      ),
                                      focusedBorder: const OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors
                                              .black, // Ensure the border color is blue when focused
                                          width:
                                              1.0, // Optional: You can change the width for focused state if you like
                                        ),
                                      ),
                                    ),
                                    keyboardType: TextInputType.multiline,
                                    maxLines:
                                        null, // Allows the input to grow in height
                                    minLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      MyDropdownWidget<int>(
                        leadingText: 'I want to do this habit  ',
                        trailingText: '  times a week.',
                        items: List.generate(7, (index) => index + 1),
                        selectedItem: _selectedItem_int,
                        onChanged: (newValue) {
                          if(mounted){
                            setState(() {
                              _selectedItem_int = newValue!;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 25),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '   Reminder Time:',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Sriracha',
                            fontSize: 16,
                            shadows: CustomTextShadow
                                .shadows, // Makes the text very bold
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TimePickerWidget(
                        onTimeSelected: (TimeOfDay time) {
                          // Do something with the selected time
                          _selectedTime = time;
                        },
                      ),
                      const SizedBox(height: 30),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '   Choose a proving method:',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Sriracha',
                            fontSize: 16,
                            shadows: CustomTextShadow
                                .shadows, // Makes the text very bold
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      MethodSelectorWidget(
                        onMethodSelected: (selectedMethod) {
                          if(mounted){
                            setState(() {
                              _m_selectedMethod = selectedMethod;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      if (_m_selectedMethod == 'Timer')
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50), // Adjust the padding as needed
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              textSelectionTheme: TextSelectionThemeData(
                                selectionHandleColor: Colors.blue
                                    .shade800, // Set the color of the selection handle here
                              ),
                            ),
                            child: Form(
                              child: Column(
                                children: <Widget>[
                                  Tooltip(
                                    message: 'Enter the time in minutes',
                                    child: TextFormField(
                                      controller: _habitTimeController,
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(color: Colors.black),
                                      cursorColor: Colors.black,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.grey[100],
                                        hintText: 'Enter the time in minutes',
                                        hintStyle: TextStyle(color: Colors.black),
                                        prefixIcon: Icon(Icons.timer,
                                            color: Colors.black),
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.blue
                                                .shade800, // Specify the border color here
                                            width:
                                                1.0, // Specify the border width here
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors
                                                .white, // Original border color when the field is enabled
                                            width: 1.0,
                                          ),
                                        ),
                                        focusedBorder: const OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors
                                                .black, // Ensure the border color is blue when focused
                                            width:
                                                1.0, // Optional: You can change the width for focused state if you like
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (_m_selectedMethod == 'Multiple Confirmation')
                        Column(
                          children: <Widget>[
                            MyDropdownWidget<int>(
                              leadingText: 'Pick iterval time in minutes:  ',
                              trailingText: '',
                              items: [3, 5, 10],
                              selectedItem: _habitInterval,
                              onChanged: (newValue) {
                                if(mounted){
                                  setState(() {
                                    _habitInterval = newValue!;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      const SizedBox(height: 20),
                      _isLoading
                          ? CircularProgressIndicator(
                              color: Colors.blue[800],
                            )
                          : Center(
                              // Centers the Row widget horizontally and vertically in the screen
                              child: Column(
                                children: [
                                  Tooltip(
                                    message: 'Create habit',
                                    child: ElevatedButton(
                                      onPressed: () async{
                                        if(mounted){
                                          setState(() {
                                            _isLoading = true;
                                          });
                                        }
                                        String validation = await validateHabitForm(_habitNameController.text, _m_selectedMethod, _selectedTime, _habitTimeController.text, null, _habitInterval);
                                        if(validation != "true") {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(validation),
                                            ),
                                          );
                                          if(mounted){
                                            setState(() {
                                              _isLoading = false;
                                            });
                                          }
                                          return;
                                        }
                                        TimeOfDay time = (_selectedTime == null) ? TimeOfDay(hour: 0, minute: 0) : _selectedTime!;
                                        await addHabit_toCloud(_habitNameController.text, _habitDescriptionController.text, _m_selectedMethod, time,
                                        _selectedItem_int, _habitInterval, _habitTimeController.text, null);
                                        Navigator.of(context).pop();
                                        if(mounted){
                                          setState(() {
                                            _isLoading = false;
                                          });
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color.fromARGB(194, 0, 0, 0), // Background color
                                        foregroundColor: Colors.blue[800], // Text color
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min, // To minimize the row's size to its children size
                                        children: [
                                          Text('Create habit', style: TextStyle(color: Colors.white)), // Text with white color                        
                                          SizedBox(width: 8), // Space between icon and text
                                          Icon(Icons.add_task, color: Colors.white), // Icon with white color
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 30), // Provides spacing between the buttons
                                  SizedBox(height: 12),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 11.0),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 160,
                                          child: Tooltip(
                                            message: 'Share habit',
                                            child: ElevatedButton(
                                              onPressed: () async {
                                                if(mounted){
                                                  setState(() {
                                                    _isLoading = true;
                                                  });
                                                }
                                                                                  
                                                List<String>? partner = await choosePartners(context);
                                                if(partner == null || partner.isEmpty) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('No partner selected!'),
                                                    ),
                                                  );
                                                  if(mounted){
                                                    setState(() {
                                                      _isLoading = false;
                                                    });
                                                  }
                                                                                
                                                  return;
                                                }
                                                String validation = await validateHabitForm(_habitNameController.text, _m_selectedMethod, _selectedTime, _habitTimeController.text, partner, _habitInterval);
                                                if(validation != "true") {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(validation),
                                                    ),
                                                  );
                                                  if(mounted){
                                                    setState(() {
                                                      _isLoading = false;
                                                    });
                                                  }
                                                                                     
                                                  return;
                                                }
                                                TimeOfDay time = (_selectedTime == null) ? TimeOfDay(hour: 0, minute: 0) : _selectedTime!;
                                                await addHabit_toCloud(_habitNameController.text, _habitDescriptionController.text, _m_selectedMethod, time,
                                                _selectedItem_int, _habitInterval, _habitTimeController.text, partner ?? []);
                                                if(mounted) Navigator.of(context).pop();
                                                if(mounted) {
                                                  setState(() {
                                                  _isLoading = false;
                                                });
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                
                                                backgroundColor: Color.fromARGB(194, 0, 0, 0),// Background color
                                                foregroundColor: Colors.white, // Text color
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min, // To minimize the row's size to its children size
                                                children: [
                                                  Text('Share habit', style: TextStyle(color: Colors.white)), // Text with white color                        
                                                  SizedBox(width: 8), // Space between icon and text
                                                  Icon(Icons.share, color: Colors.white), // Icon with white color
                                                ],
                                              ),
                                            ),
                                          ),
                                        ), // Provides spacing between the buttons
                                        SizedBox(width: 10), // Provides spacing between the buttons
                                        SizedBox(
                                          width: 178,
                                          child: Tooltip(
                                            message: 'Challenge habit',
                                            child: ElevatedButton(
                                                                                  
                                              onPressed: () async {
                                                showDialog(
                                                context: context,
                                                builder: (BuildContext context) {
                                                  return AlertDialog(
                                                  title: Text('Challenge Confirmation'),
                                                  content: Text('This challenge will cost you 50 points. Are you sure you want to proceed?'),
                                                  actions: [
                                                    TextButton(
                                                    onPressed:() {
                                                          
                                                      Navigator.of(context).pop();
                                                    },
                                                    child: Text('Cancel'),
                                                    ),
                                                    TextButton(
                                                    onPressed: () async {
                                                      // Navigator.of(context).pop();
                                                      await _createChallenge();
                                                    },
                                                    child: Text('Proceed'),
                                                    ),
                                                  ],
                                                  );
                                                },
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Color.fromARGB(194, 0, 0, 0), // Background color
                                                foregroundColor: Colors.white, // Text color
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize
                                                    .min, // To minimize the row's size to its children size
                                                children: [
                                                  Text('Challenge habit',
                                                      style: TextStyle(
                                                            color:
                                                                Colors.white)), // Text with white color
                                                  SizedBox(width: 1), // Space between icon and text
                                                  Icon(Icons.whatshot,
                                                      color: Colors.white), // Icon with white color
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
              ),
            ),
          )),
          )
    ),);
  }
}
