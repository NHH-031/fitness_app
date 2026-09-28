import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../theme.dart';
import '../services/locale_service.dart';
import 'dashboard_screen.dart';
import 'workout_screen.dart';
import 'food_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static final ValueNotifier<int> tabNotifier = ValueNotifier<int>(0);

  /// Allows any widget anywhere to switch active navigation tabs reliably
  static void switchTab(int index) {
    tabNotifier.value = index;
  }

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = MainScreen.tabNotifier.value;
    MainScreen.tabNotifier.addListener(_onTabNotified);
  }

  @override
  void dispose() {
    MainScreen.tabNotifier.removeListener(_onTabNotified);
    super.dispose();
  }

  void _onTabNotified() {
    if (mounted && _currentIndex != MainScreen.tabNotifier.value) {
      setState(() {
        _currentIndex = MainScreen.tabNotifier.value;
      });
    }
  }

  void setTab(int index) {
    MainScreen.switchTab(index);
  }
  
  final List<Widget> _screens = [
    const DashboardScreen(),
    const WorkoutScreen(),
    const FoodScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedHome01,
              size: 22,
            ),
            label: LocaleService.tr('nav_dashboard'),
          ),
          BottomNavigationBarItem(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedDumbbell01,
              size: 22,
            ),
            label: LocaleService.tr('nav_activity'),
          ),
          BottomNavigationBarItem(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedApple01,
              size: 22,
            ),
            label: LocaleService.tr('nav_food'),
          ),
          BottomNavigationBarItem(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedUser,
              size: 22,
            ),
            label: LocaleService.tr('nav_profile'),
          ),
        ],
      ),
    );
  }
}
