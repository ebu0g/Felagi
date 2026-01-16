import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/admin_controller.dart';
import 'admin_home.dart';
import 'admin_profile.dart';

class AdminNavigation extends StatefulWidget {
  const AdminNavigation({super.key});

  @override
  State<AdminNavigation> createState() => _AdminNavigationState();
}

class _AdminNavigationState extends State<AdminNavigation> {
  int _currentIndex = 0;

  Widget _getCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return const AdminHome();
      case 1:
        return const AdminProfile();
      default:
        return const AdminHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminController(),
      child: Scaffold(
        body: _getCurrentScreen(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
