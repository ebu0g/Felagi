import 'package:flutter/material.dart';

import 'patient_home.dart';
import 'search_medicine.dart';
import 'patient_profile.dart';

class PatientNavigation extends StatefulWidget {
  const PatientNavigation({super.key});

  @override
  State<PatientNavigation> createState() => _PatientNavigationState();
}

class _PatientNavigationState extends State<PatientNavigation> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      PatientHome(
        onOpenSearchTab: () => setState(() => _currentIndex = 1),
      ),
      const SearchMedicine(),
      const PatientProfile(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],

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
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
