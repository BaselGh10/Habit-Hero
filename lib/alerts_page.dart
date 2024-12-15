import 'package:flutter/material.dart';
import 'package:habit_hero/friendreq.dart';
import 'package:habit_hero/text_shdows.dart';
import 'package:flutter/widgets.dart';
import 'package:bubble_tab_indicator/bubble_tab_indicator.dart';
import 'package:habit_hero/notification.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Number of tabs
      child: Scaffold(
        //backgroundColor: Colors.blueGrey[200],
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.blue[800],
          title: Row(
            mainAxisAlignment:
                MainAxisAlignment.center, // Center row items horizontally
            children: [
              Tooltip(
                message: 'Notification Page Title',
                child: Text(
                  "Notification Page",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    shadows: CustomTextShadow.shadows,
                  ),
                ),
              ),
            ],
          ),
          bottom: const TabBar(
            indicatorSize: TabBarIndicatorSize.tab,
            unselectedLabelColor: Colors.white,
            indicator: BubbleTabIndicator(
              indicatorHeight: 25.0,
              indicatorColor: Colors.blueAccent,
              tabBarIndicatorSize: TabBarIndicatorSize.tab,
            ),
            labelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Sriracha',
              fontSize: 15,
              color: Colors.white, // Example color
            ),
            tabs: [
              Tooltip(
                message: 'Friend Requests Tab',
                child: Tab(
                  child: Text(
                    'Friend Requests',
                    style: TextStyle(
                      fontSize: 15,
                      shadows: CustomTextShadow.shadows,
                    ), // Specify your desired font size here
                  ),
                ),
              ),
              Tooltip(
                message: 'Alerts Tab',
                child: Tab(
                  child: Text(
                    'Alerts',
                    style: TextStyle(
                      fontSize: 15,
                      shadows: CustomTextShadow.shadows,
                    ), // Specify your desired font size here
                  ),
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Tooltip(
              message: 'Friend Requests Page',
              child: FriendreqPage(),
            ),
            Tooltip(
              message: 'Notifications Page',
              child: NotificationsPage(),
            ),
          ],
        ),
      ),
    );
  }
}