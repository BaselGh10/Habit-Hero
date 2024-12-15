import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void showCustomAboutDialog(BuildContext context) {
  showAboutDialog(
    context: context,
    applicationName: 'Habit Hero',
    applicationVersion: '1.0.0',
    applicationIcon: Tooltip(
      message: 'App Icon',
      child: SizedBox(
        width: 50,
        height: 50,
        child: ClipOval(
          child: Image.asset('app_images/appIcon.png'),
        ),
      ),
    ),
  );
}