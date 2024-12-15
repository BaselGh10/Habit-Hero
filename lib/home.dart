import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:habit_hero/alerts_page.dart';
import 'package:habit_hero/habits.dart';
import 'package:habit_hero/store.dart';
import 'package:habit_hero/profile.dart';
import 'package:habit_hero/friends.dart';


class MyBottomNavigation extends StatefulWidget {
  const MyBottomNavigation({super.key});

  @override
  State<MyBottomNavigation> createState() => _MyBottomNavigationState();
}

class _MyBottomNavigationState extends State<MyBottomNavigation> {
  int _selectedIndex = 2;
  bool _isLoading = true; 
  // // Step 1: Define a list of widgets/screens
  final List<Widget> _screens = [
    ProfilePage(), // Placeholder for your Profile screen widget
    FriendsList(), // Placeholder for your Friends screen widget
    HabitsPage(), // Placeholder for your My Habits screen widget
    StorePage(), // Placeholder for your Store screen widget
    AlertsPage(), // Placeholder for your Notifications screen widget
  ];
 
  @override
  void initState() {
    super.initState();
    _isLoading = false;
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
        backgroundColor: Colors.transparent,
        body:  (!_isLoading)?_getScreen(_selectedIndex): Center(child: CircularProgressIndicator(color: Colors.blue[800],)), // Step 3: Display the selected screen
        bottomNavigationBar: ConvexAppBar(
          backgroundColor: Colors.blue[800],
          activeColor: Colors.white,
          color: Colors.white,
        
          items: const [
            TabItem(icon: Icons.person, title: 'Profile'),
            TabItem(icon: Icons.group, title: 'Friends'),
            TabItem(icon: Icons.home, title: 'My Habits'),
            TabItem(icon: Icons.shopping_cart, title: 'Store'),
            TabItem(icon: Icons.notifications, title: 'Alerts'),
          ],
          initialActiveIndex: _selectedIndex,
          onTap: _onItemTapped, 
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    
    if(mounted){
      setState(() {
        _selectedIndex = index;
        _isLoading = false;
      });
    }
  }

  Widget _getScreen(int index) {
    if (index >= 0 && index < _screens.length) {
      return _screens[index];
    }
    return Center(child: Text('Screen not found'));
  }
}