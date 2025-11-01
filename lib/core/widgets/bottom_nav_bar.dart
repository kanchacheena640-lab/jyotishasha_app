import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: Colors.deepPurple,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.wb_sunny), label: 'Today'),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month),
          label: 'Panchang',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'You'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
