// lib/screens/main_navigation_page.dart

import 'package:farming_new/screens/field_page.dart';
import 'package:flutter/material.dart';
import 'custom_notch.dart';
import 'home_page.dart';
import 'bot_page.dart';
import 'services_page.dart';
import 'profile_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(), // 0
    FieldPage(), // 1
    ServicesPage(), // 2
    ProfilePage(), // 3
  ];

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),

      // MAIN PAGE BODY
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      // ====== FIXED: FAB ALWAYS VISIBLE ======
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.22),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.auto_awesome, size: 24, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BotPage()),
            );
          },
        ),
      ),

      // ====== BOTTOM NAVIGATION BAR ======
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BottomAppBar(
            color: Colors.white,
            shape: BigFabNotch(),
            notchMargin: 6,
            elevation: 6,
            child: SizedBox(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _BottomNavItem(
                    icon: Icons.home_outlined,
                    label: 'Home',
                    index: 0,
                    currentIndex: _currentIndex,
                    onTap: _onTabSelected,
                  ),
                  _BottomNavItem(
                    icon: Icons.map_outlined,
                    label: 'Field',
                    index: 1,
                    currentIndex: _currentIndex,
                    onTap: _onTabSelected,
                  ),

                  const SizedBox(width: 40), // Space for FAB

                  _BottomNavItem(
                    icon: Icons.show_chart_outlined,
                    label: 'Activity',
                    index: 2,
                    currentIndex: _currentIndex,
                    onTap: _onTabSelected,
                  ),
                  _BottomNavItem(
                    icon: Icons.person_outline,
                    label: 'Profile',
                    index: 3,
                    currentIndex: _currentIndex,
                    onTap: _onTabSelected,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = index == currentIndex;

    return InkWell(
      onTap: () => onTap(index),
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? Colors.black : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.black : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
