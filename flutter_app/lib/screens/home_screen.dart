import 'package:flutter/material.dart';
import 'package:globetrotter_flutter/services/auth_service.dart';
import 'package:globetrotter_flutter/screens/globe_screen.dart';
import 'package:globetrotter_flutter/screens/explore_screen.dart';
import 'package:globetrotter_flutter/screens/itinerary_screen.dart';
import 'package:globetrotter_flutter/screens/social_screen.dart';
import 'package:globetrotter_flutter/screens/profile_screen.dart';

/// Root shell of the app: hosts the 5-tab bottom navigation
/// (Globe / Explore / Itinerary / Social / Profile) shown in the reference
/// design. Each tab is its own screen/widget so it can be developed and
/// wired to the backend independently.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ExploreScreenState> _exploreKey =
      GlobalKey<ExploreScreenState>();

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _goToExplore() {
    setState(() => _selectedIndex = 1);
    _exploreKey.currentState?.focusSearch();
  }

  void _goToItinerary() {
    setState(() => _selectedIndex = 2);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      GlobeScreen(onSearchTapped: _goToExplore, onSeeAllTrips: _goToItinerary),
      ExploreScreen(key: _exploreKey),
      const ItineraryScreen(),
      const SocialScreen(),
      ProfileScreen(onLogout: _logout),
    ];

    return Scaffold(
      body: SafeArea(
        top: _selectedIndex != 2, // ItineraryScreen supplies its own AppBar
        child: IndexedStack(index: _selectedIndex, children: screens),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.public), label: 'Globe'),
          NavigationDestination(icon: Icon(Icons.explore), label: 'Explore'),
          NavigationDestination(icon: Icon(Icons.card_travel), label: 'Itinerary'),
          NavigationDestination(icon: Icon(Icons.groups), label: 'Social'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
