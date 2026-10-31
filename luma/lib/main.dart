import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'auth/auth_store.dart';
import 'theme/theme_store.dart';

import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/shorts_screen.dart';
import 'screens/create_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AuthStore.instance.loadSession();
  await ThemeStore.instance.loadTheme();

  runApp(const LumaApp());
}

class LumaApp extends StatelessWidget {
  const LumaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeStore.instance,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Luma',

          themeMode: ThemeStore.instance.themeMode,

          // ==================================================
          // LIGHT THEME
          // ==================================================
          theme: ThemeData(
            brightness: Brightness.light,

            scaffoldBackgroundColor: const Color(0xFFF7F7FB),

            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF7C3AED),
              brightness: Brightness.light,
            ),

            textTheme: GoogleFonts.spaceGroteskTextTheme(
              ThemeData.light().textTheme,
            ),

            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF7F7FB),
              foregroundColor: Color(0xFF111827),
              elevation: 0,
            ),

            navigationBarTheme: const NavigationBarThemeData(
              backgroundColor: Color(0xFFFFFFFF),
              indicatorColor: Color(0xFFE9D5FF),
            ),

            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),

            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF7C3AED),
                  width: 1.5,
                ),
              ),
            ),

            useMaterial3: true,
          ),

          // ==================================================
          // DARK THEME
          // ==================================================
          darkTheme: ThemeData(
            brightness: Brightness.dark,

            scaffoldBackgroundColor: const Color(0xFF070A12),

            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF7C3AED),
              brightness: Brightness.dark,
            ),

            textTheme: GoogleFonts.spaceGroteskTextTheme(
              ThemeData.dark().textTheme,
            ),

            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF070A12),
              foregroundColor: Colors.white,
              elevation: 0,
            ),

            navigationBarTheme: const NavigationBarThemeData(
              backgroundColor: Color(0xFF0D111C),
              indicatorColor: Color(0xFF30205C),
            ),

            cardTheme: CardThemeData(
              color: const Color(0xFF111827),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),

            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF111827),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF7C3AED),
                  width: 1.5,
                ),
              ),
            ),

            useMaterial3: true,
          ),

          home: const AuthGate(),
        );
      },
    );
  }
}

// ======================================================
// AUTH GATE
// ======================================================

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthStore.instance,
      builder: (context, child) {
        if (AuthStore.instance.isLoggedIn) {
          return const MainScreen();
        }

        return const AuthScreen();
      },
    );
  }
}

// ======================================================
// MAIN SCREEN
// ======================================================

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ShortsScreen(),
    CreateScreen(),
    MessagesScreen(),
    ProfileScreen(),
  ];

  void _changeScreen(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _changeScreen,

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),

          NavigationDestination(
            icon: Icon(Icons.play_circle_outline),
            selectedIcon: Icon(Icons.play_circle),
            label: 'Shorts',
          ),

          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Create',
          ),

          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),

          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
