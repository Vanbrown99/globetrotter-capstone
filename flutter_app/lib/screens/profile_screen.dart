import 'package:flutter/material.dart';
import 'package:globetrotter_flutter/models/destination.dart';
import 'package:globetrotter_flutter/models/itinerary.dart';
import 'package:globetrotter_flutter/services/api_service.dart';
import 'package:globetrotter_flutter/services/auth_service.dart';
import 'package:globetrotter_flutter/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const ProfileScreen({super.key, required this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<_ProfileData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ProfileData> _load() async {
    final username = await AuthService.getUsername() ?? 'Traveler';
    final email = await AuthService.getEmail() ?? '';
    final token = await AuthService.getToken();

    List<String> preferences = [];
    List<Itinerary> itineraries = [];
    List<Destination> destinations = [];

    if (token != null) {
      try {
        final me = await ApiService.getMe(token);
        preferences = List<String>.from(me['preferences'] as List? ?? []);
      } catch (_) {}
      try {
        itineraries = await ApiService.getItineraries(token);
      } catch (_) {}
    }
    try {
      destinations = await ApiService.getDestinations();
    } catch (_) {}

    // Derive real stats: unique countries visited across all itineraries,
    // by matching itinerary destination names against the catalogue.
    final countryByName = {for (final d in destinations) d.name: d.country};
    final countries = <String>{};
    for (final it in itineraries) {
      for (final name in it.destinations) {
        final country = countryByName[name];
        if (country != null) countries.add(country);
      }
    }

    return _ProfileData(
      username: username,
      email: email,
      preferences: preferences,
      tripCount: itineraries.length,
      countryCount: countries.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ProfileData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data;
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildHeader(data),
            const SizedBox(height: 16),
            if (data != null) _buildStatsRow(data),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('Passport Stamps',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 12),
            if (data != null) _buildStamps(data.preferences),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: OutlinedButton.icon(
                onPressed: widget.onLogout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: AppColors.orangeDark,
                  side: const BorderSide(color: AppColors.orangeDark),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildHeader(_ProfileData? data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      decoration: const BoxDecoration(
        color: AppColors.navyDark,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 38,
            backgroundColor: AppColors.orange,
            child: Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            data?.username ?? '',
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          if (data?.email.isNotEmpty == true)
            Text(data!.email, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _travelerLevel(data?.tripCount ?? 0),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _travelerLevel(int trips) {
    if (trips == 0) return 'Traveler Level: Newcomer';
    if (trips < 3) return 'Traveler Level: Explorer';
    if (trips < 6) return 'Traveler Level: Adventurer';
    return 'Traveler Level: Globetrotter';
  }

  Widget _buildStatsRow(_ProfileData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: _statCard('${data.tripCount}', 'Trips planned')),
          const SizedBox(width: 12),
          Expanded(
              child: _statCard('${data.countryCount}', 'Countries visited')),
          const SizedBox(width: 12),
          Expanded(child: _statCard('${data.preferences.length}', 'Interests')),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.orangeDark)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildStamps(List<String> preferences) {
    if (preferences.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          'Add interests at sign-up to start collecting passport stamps.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: preferences.map((p) => _StampTile(label: p)).toList(),
      ),
    );
  }
}

class _StampTile extends StatelessWidget {
  final String label;
  const _StampTile({required this.label});

  static const _icons = {
    'beach': Icons.beach_access,
    'food': Icons.restaurant,
    'nature': Icons.forest,
    'culture': Icons.museum,
    'adventure': Icons.hiking,
    'nightlife': Icons.nightlife,
  };

  @override
  Widget build(BuildContext context) {
    final icon = _icons[label.toLowerCase()] ?? Icons.emoji_events;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.orangeDark),
          const SizedBox(height: 6),
          Text(label,
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ProfileData {
  final String username;
  final String email;
  final List<String> preferences;
  final int tripCount;
  final int countryCount;

  _ProfileData({
    required this.username,
    required this.email,
    required this.preferences,
    required this.tripCount,
    required this.countryCount,
  });
}
