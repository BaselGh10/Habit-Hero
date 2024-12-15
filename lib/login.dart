import 'package:flutter/material.dart';
import 'authenication.dart';
import 'home.dart';
import 'signup.dart';
import 'package:provider/provider.dart';
import 'package:connectivity/connectivity.dart';
import 'text_shdows.dart';

class Loginpage extends StatefulWidget {
  @override
  _loginPageState createState() => _loginPageState();
}

class _loginPageState extends State<Loginpage> {
  final _usernamecont = TextEditingController();
  final _passwordcont = TextEditingController();
  bool _loading = false;


 void _login(BuildContext context) async {
  if(mounted){
  setState(() {
    _loading = true; // Show loading indicator
  });
  }


  final userModel = Provider.of<UserModel>(context, listen: false);
  var connectivityResult = await (Connectivity().checkConnectivity());

  if (connectivityResult == ConnectivityResult.mobile || connectivityResult == ConnectivityResult.wifi) {
    try {
      await userModel.signIn(
        _usernamecont.text.trim(),
        _passwordcont.text.trim(),
      );

      if (!mounted) return; // Ensure the widget is still mounted

      // Login successful, navigate to main screen
      if (userModel.status == Status.Authenticated) {
        // Navigator.pushReplacement(context,
        //   MaterialPageRoute(
        //     builder: (context) => MyBottomNavigation(),
        //   ),
        // );
        //Navigator.pop(context); // Navigate back if needed
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MyBottomNavigation()),
        );
      }
    } catch (e) {
      //Navigator.pop(context); 
      if (mounted) {
        // Show error message using SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: /*Text('There was an error logging into the app: $e'),*/Text('There was an error logging into the app!'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false; // Hide loading indicator
        });
      }
    }
  } else {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No internet connection'),
        ),
      );
      if(mounted){
      setState(() {
        _loading = false; // Hide loading indicator
      });
      }

    }
  }
  _loading = false;
}

  @override
  Widget build(BuildContext context) {
  
      // I am connected to a mobile network.
   
      // I am connected to a wifi network.
    
      // No internet connection
    
    final userModel = Provider.of<UserModel>(context);
    
    return Scaffold(
      backgroundColor: Colors.blueGrey[200], // Set background color
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        title: Tooltip(
          message: 'App title',
          child: Text(
            'Welcome to Habit Hero',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: CustomTextShadow.shadows,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: Colors.blueGrey[200],
                child: Column(
                  children: [
                    Tooltip(
                      message: 'Login prompt',
                      child: Text(
                        'Hurry up and login to get started!',
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
                    Container(
                      color: Colors.blueGrey[200],
                      child: Tooltip(
                        message: 'Enter your email address',
                        child: TextFormField(
                          controller: _usernamecont,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your email address',
                            prefixIcon: Icon(Icons.email, color: Colors.white, shadows: CustomTextShadow.shadows,),
                            labelStyle: TextStyle(color: Colors.white, shadows: CustomTextShadow.shadows),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.black, width: 2.0), // Change color and width as needed
                            ),
                          ),
                          style: TextStyle(color: Colors.black,),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      color: Colors.blueGrey[200],
                      child: Tooltip(
                        message: 'Enter your password',
                        child: TextFormField(
                          controller: _passwordcont,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: Icon(Icons.password, color: Colors.white, shadows: CustomTextShadow.shadows,),
                            labelStyle: TextStyle(color: Colors.white, shadows: CustomTextShadow.shadows),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.black, width: 2.0), // Change color and width as needed
                            ),
                          ),
                          obscureText: true,
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    userModel.status == Status.Authenticating
                        ? Center(child: CircularProgressIndicator(color: Colors.blue[800],))
                        : (!_loading)?Tooltip(
                            message: 'Log in to your account',
                            child: ElevatedButton(
                              onPressed: () {
                                _login(context);
                              },
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all<Color>(
                                    Colors.blue.shade800),
                              ),
                              child: Text('Log in',
                                  style: TextStyle(color: Colors.white, shadows: CustomTextShadow.shadows)),
                            ),
                          ):Center(child: CircularProgressIndicator(color: Colors.blue[800],)),
                    SizedBox(height: 5),
                    Tooltip(
                      message: 'Sign up for a new account',
                      child: InkWell(
                        onTap: () {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SignUpPage()));
                        },
                        child: Text(
                          "Don't have an account? Click here to sign up!",
                          style: TextStyle(
                            color: Colors.white,
                            shadows: CustomTextShadow.shadows,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40,),
              Tooltip(
                message: 'App background image',
                child: SizedBox(
                  width: 200, height: 200,
                  child: FittedBox(
                    child: Image.asset(
                      'app_images/background.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
