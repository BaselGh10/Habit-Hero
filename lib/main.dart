import 'dart:developer'; // Import the 'dart:developer' library
import 'package:flutter/material.dart';
import 'package:habit_hero/home.dart';
import 'package:habit_hero/login.dart';
import 'package:habit_hero/signup.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Import the package that contains the 'RemoteMessage' class
import 'authenication.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import "package:habit_hero/habit_reminders.dart";
import 'package:timezone/data/latest.dart' as tz; 

Future<void> _backgroundHandler(RemoteMessage msg) async {
await Firebase.initializeApp();
//log("Handling a background msg: ${msg.messageId}");
}
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
Future<void> showNotification(String title, String body) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'your_channel_id',
    'your_channel_name',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker',
     // Add this line to enable sound notification
  );
  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );
  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    platformChannelSpecifics,
    payload: 'item x',
  );
}
void main() async{
  
  WidgetsFlutterBinding.ensureInitialized();
 await Firebase.initializeApp();
   const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
     

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  tz.initializeTimeZones();
  await initializeNotifications();
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  
    if (message.notification != null) {
     
      showNotification(message.notification!.title.toString(),message.notification!.body.toString());
    }
  });



  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    log('A new onMessageOpenedApp event was published!');
  });


  FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
FirebaseMessaging.instance.requestPermission(
  alert: true,
  announcement: true,
  badge: true,
  carPlay: false,
  criticalAlert: true,
  provisional: true,
  sound: true,
// Enable volume control for notifications

);

  runApp(App());

}

class App extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
          body: Center(
          child: Text(snapshot.error.toString(),
          textDirection: TextDirection.ltr)));
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return MyApp();
        }
        return Center(child: CircularProgressIndicator(color: Colors.blue[800],));
      },
    );
  }
}

//
class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
  
    return ChangeNotifierProvider(  
     create: (ctx) => UserModel(FirebaseAuth.instance),
      child: Consumer<UserModel>(
        builder: (context, userModel, _) {
//showNotification();
         
          Widget homeWidget;
          switch (userModel.status) {
            case Status.Authenticated:
             // checkAndScheduleReminder, habitName)
              homeWidget = MyBottomNavigation();
            //userModel.signIn(userModel.email, userModel.password);
              break;
            case Status.Unauthenticated:
              homeWidget = Loginpage();
              break;
            default:
              homeWidget = /*Loginpage();*/ Center(child: CircularProgressIndicator(color: Colors.blue[800],));
              break;

          }
       
      return MaterialApp(
            title: 'Flutter Demo',
            theme: ThemeData(
              fontFamily: 'Sriracha', // Custom font
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue[800] ?? Colors.blue),
              useMaterial3: true,
            ),
            home:homeWidget,
            
          );
        },
        ),
    );
  }
    Future<void> showNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await flutterLocalNotificationsPlugin.show(
      0,
      'Hello!',
      'This is a notification.',
      platformChannelSpecifics,
      payload: 'item x',
    );
  }

  }


  
