import 'dart:async';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../services/locale_service.dart';
import '../widgets/app_ui_components.dart';
import 'dashboard_screen.dart';
import 'workout_screen.dart';
import 'food_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static final ValueNotifier<int> tabNotifier = ValueNotifier<int>(0);
  static final ValueNotifier<int> sessionRefreshNotifier = ValueNotifier<int>(0);

  /// Allows any widget anywhere to switch active navigation tabs reliably
  static void switchTab(int index) {
    tabNotifier.value = index;
  }

  /// Triggers a complete recreation of all 4 tabs (e.g. after login / logout)
  static void reloadTabs() {
    sessionRefreshNotifier.value++;
  }

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  Key _tabSessionKey = UniqueKey();
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _currentIndex = MainScreen.tabNotifier.value;
    MainScreen.tabNotifier.addListener(_onTabNotified);
    MainScreen.sessionRefreshNotifier.addListener(_onSessionRefresh);
    _authSubscription = AuthService().authStateChanges.listen((_) {
      _onSessionRefresh();
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    MainScreen.tabNotifier.removeListener(_onTabNotified);
    MainScreen.sessionRefreshNotifier.removeListener(_onSessionRefresh);
    super.dispose();
  }

  void _onSessionRefresh() {
    if (mounted) {
      setState(() {
        _tabSessionKey = UniqueKey();
      });
    }
  }

  void _onTabNotified() {
    if (mounted && _currentIndex != MainScreen.tabNotifier.value) {
      setState(() {
        _currentIndex = MainScreen.tabNotifier.value;
      });
    }
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });
    MainScreen.tabNotifier.value = index;
  }

  final List<Widget> _screens = const [
    DashboardScreen(),
    WorkoutScreen(),
    FoodScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        key: _tabSessionKey,
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _GlassmorphicFloatingNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}

/// Floating glassmorphic dock navigation bar with dynamic blur, neon glow pill,
/// and tactile bouncing touch animations.
class _GlassmorphicFloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _GlassmorphicFloatingNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        margin: EdgeInsets.only(
          left: 18,
          right: 18,
          bottom: bottomInset > 0 ? bottomInset + 4 : 16,
        ),
        height: 68,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xE0121218),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.14),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              child: Row(
                children: [
                  _FloatingTabItem(
                    index: 0,
                    currentIndex: currentIndex,
                    hugeIcon: HugeIcons.strokeRoundedHome01,
                    label: LocaleService.tr('nav_dashboard'),
                    onTap: () => onTap(0),
                  ),
                  _FloatingTabItem(
                    index: 1,
                    currentIndex: currentIndex,
                    hugeIcon: HugeIcons.strokeRoundedDumbbell01,
                    label: LocaleService.tr('nav_activity'),
                    onTap: () => onTap(1),
                  ),
                  _FloatingTabItem(
                    index: 2,
                    currentIndex: currentIndex,
                    hugeIcon: HugeIcons.strokeRoundedApple01,
                    label: LocaleService.tr('nav_food'),
                    onTap: () => onTap(2),
                  ),
                  _FloatingTabItem(
                    index: 3,
                    currentIndex: currentIndex,
                    hugeIcon: HugeIcons.strokeRoundedUser,
                    label: LocaleService.tr('nav_profile'),
                    onTap: () => onTap(3),
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

class _FloatingTabItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final List<List<dynamic>> hugeIcon;
  final String label;
  final VoidCallback onTap;

  const _FloatingTabItem({
    required this.index,
    required this.currentIndex,
    required this.hugeIcon,
    required this.label,
    required this.onTap,
  });

  bool get isSelected => index == currentIndex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: BouncingTap(
        onTap: onTap,
        scaleDown: 0.90,
        duration: const Duration(milliseconds: 100),
        hapticType: AppHapticFeedbackType.light,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : Colors.transparent,
              width: 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 10,
                      spreadRadius: 0.5,
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.14 : 1.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: HugeIcon(
                  icon: hugeIcon,
                  size: 21,
                  color: isSelected ? AppColors.primary : Colors.white60,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                style: AppTheme.font(
                  fontSize: isSelected ? 10.5 : 9.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.white54,
                  letterSpacing: isSelected ? 0.3 : 0.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                child: Text(label),
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 4 : 0,
                height: 4,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.8),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
